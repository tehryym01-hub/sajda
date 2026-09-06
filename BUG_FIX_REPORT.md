# SAJDA APP — STREAK SYSTEM AUDIT & FIX REPORT (This Pass)

## A. Date model (authoritative rule)
A streak day is a **calendar day** key `YYYY-MM-DD` in the user's **selected-location timezone** — NEVER a rolling 24-hour window. 23:59 belongs to the current day; 00:00 starts the next day. The client computes the key (`DateService.formatDateAsYYYYMMDD`) and sends `date`+`timezone` with every completion; the server derives the same key from the fresh `User.timezone` (`backend/services/streakLogic.js`). Both sides are unit-tested against each other.

## B. Root causes found & fixed
1. **Prayer-completion race** — read-modify-write lost parallel prayer flags. Now an atomic `findOneAndUpdate` + conditional `isComplete` flip (all-5-flags-at-write-time), with one retry on upsert-11000.
2. **Rejoin wiped history** — `joinSharedStreak` reset `streakHistory=[]`/`currentDay=0`. Now reactivation/creation never destroys history or progress.
3. **No Leave / End / Cancel** — the only Leave UI lived in a dead, unreachable screen. Added `POST /streak/cancel` (personal; creator-only for shared via end path), `POST /streak/shared/:id/end` (creator, ends for everyone, history preserved) and surfaced Leave/End in the board + detail screens with confirmation dialogs.
4. **String-only errors** — every streak endpoint (and auth middleware) now returns a machine-readable `code` (INVALID_INVITE, STREAK_NOT_ACTIVE, HAVE_ACTIVE_STREAK, STREAK_FULL, ALREADY_MEMBER reason, OWNER_ONLY, NOT_MEMBER, NO_ACTIVE_STREAK, VALIDATION, UNAUTHORIZED...). `ApiException` carries `code`/`status`; Flutter branches on codes, never on message text.
5. **Streak Detail screen was dead code** — `MyStreakScreen` was never reachable and `loadStreakHistory()` was never called. Detail screen is now wired (streak tab card, Home "View", post-join, already-member "Open My Streak") and shows: header stats, start date, owner, status (incl. cancelled), today's 5-prayer progress, week strip, members, full day history, past streaks (`GET /streak/past`), and role-aware actions.
6. **"Already joined" dead end** — invite lookup (`GET /invite/:code`) is viewer-aware (`viewerMembership`, `joinable`, `reason`) so the Join screen renders: Join / Rejoin / "Already a member → Open My Streak" / ended → Create New / full. Joining never strands the user; success and already-member both land on the Streak Detail.
7. **Board "You" badge never worked** — `getSharedStreak` omitted member `userId`. Now sends `userId` + `isCurrentUser`.
8. **Self-heal lost dates** — `getMyStreak` heal recreated streaks with `startDate=now`. Now it reactivates the user's previous streak document (history/startDate preserved); only creates when none exists; never resurrects goal-reached streaks.
9. **Inflated streaks** — `currentStreak` counted prayer days recorded before the streak began. `computeStreaks(..., sinceKey=startDate's local key)` bounds the current run to the streak's lifetime (longest stays global).
10. **Nonsense group counter** — `SharedStreak.currentDay` summed every member's completion. Now it is the furthest any member has reached (`max`).
11. **Check-in notifications always 400** — payload sent `'Fajr'`; server compared lowercase. Prayer names are now normalized case-insensitively.
12. **Stale-token timezone** — streak endpoints trusted the 30-day JWT timezone. They now read fresh `User.timezone`/displayName from the DB.
13. **401 dead end** — expired token left a permanent error banner. `AppState` auto-recovers: clear → deviceId login → retry once (streak load, join, invite lookup).
14. **Wrong next-prayer when device tz ≠ location tz** — "now" was device-local while times were location-local. `DateService.nowHmInTimezone` now measures now in the location timezone.
15. **Stale prayer times after location change** — cache was input-agnostic. Cache is now keyed by lat/lng/city/country/timezone/date/method/school; prayer-times also invalidated implicitly on any input change.
16. **Device-local date keys in UI** — week strip and board "Done today" now use the location-timezone date key (`lastCompletedDate === todayKey`).
17. **Duplicate submissions** — in-flight guard on prayer completion; unique `(streakId,userId)` membership index plus 11000-recovery keeps concurrent joins idempotent.

## C. Backend changes
- `backend/backend/services/streakLogic.js` (NEW): pure, tested logic — date-key math, calendar previous/next day, `computeStreaks` (current run + longest, `sinceKey` clamping), prayer-name normalization.
- `backend/backend/controllers/streakController.js`: rewritten per above (atomic completion, coded errors, fresh-user timezone, idempotent join, history-preserving rejoin/heal, group `max` day, new cancel/end/past endpoints, viewer-aware invite lookup).
- `backend/backend/routes/streakRoutes.js`: + `POST /cancel`, `POST /shared/:id/end`, `GET /past`.
- `backend/backend/models/Streak.js` & `SharedStreak.js`: added `'cancelled'` status (additive enum — backward compatible; no migration needed, existing documents valid).
- `backend/backend/middleware/auth.js`: 401s carry `code`.
- `backend/test/streakLogic.test.js` (NEW): 17 tests — midnight boundary (23:59/00:00/00:01), 24h-NOT-boundary, tz matrix, month/leap arithmetic, run continuation/break/sinceKey, duplicate-day idempotency, prayer normalization.

## D. Flutter changes
- `services/api_client.dart`: `ApiException{code,status}` + isAuthError/isNetworkError; coded error parsing; input-keyed prayer-times cache; tz-aware next-prayer; new endpoints (cancel/end/past).
- `services/date_service.dart`: `nowHmInTimezone`.
- `state/app_state.dart`: 401 auto-recovery; structured join/invite results; leave/end/cancel refresh full state; past-streaks + creator state; shared-board fetch guard (60s) to avoid duplicate API calls; completion in-flight guard.
- `models/models.dart`: `cancelled` status + `hasEnded`, `SharedStreakModel.creatorName`, `StreakMemberModel.isCurrentUser`.
- `screens/my_streak_screen.dart`: full Streak Detail (was dead code) — see B5.
- `screens/join_streak_screen.dart`: complete lookup state machine; network vs invalid distinct errors; never a dead end.
- `screens/shared_streak_board_screen.dart`: Leave/End actions with confirmations; tz-correct "Done today"; fixed `isMe`.
- `screens/streak_screen.dart`: card → detail; ended state incl. cancelled + "View History".
- `screens/home_screen.dart`: Home streak card "View" → detail; ended detection includes cancelled.
- Deleted dead `screens/shared_streak_screen.dart`.

## E. Verification (actually run)
- `flutter analyze` → **No issues found**
- `flutter test` → **55/55 passed** (incl. 12 new day-boundary + 16 model/error-code tests; existing Hijri/Maghrib, invite-text, providers, Quran suites untouched & green)
- `node --test backend/test/streakLogic.test.js` → **17/17 passed**; `node --check` on all changed backend files → OK
- `flutter build apk --release` → **built** (83.3MB; only pre-existing KGP deprecation warnings from flutter_timezone/in_app_review plugins)

## F. Backward compatibility
- Status enums extended additively; existing docs remain valid without migration.
- Self-heal/reactivation paths preserve old records; nothing deletes streak/history rows (except account deletion, pre-existing).
- API responses are supersets of the old shapes; old clients keep working.

## G. Known residuals / notes
- Concurrent joins can transiently exceed `maxMembers` (check-then-create without transactions — no replica-set on current hosting); the unique index still prevents duplicate memberships.
- Deep links remain out of scope (no intent filters); invite code travels in every share text (single source: `lib/utils/streak_invite_text.dart`, unit-tested).
- "Broken" streak rule (documented in code): a missed calendar day resets the consecutive count (recomputed from history) but does not end the streak document; streaks end only by goal completion, leave, cancel or owner-end — always history-preserving.
- On-device two-user E2E against a live server was not runnable here; verified via analyzer, 72 automated tests, and code-path tracing.
