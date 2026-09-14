# Streak Module Test Report
**Date:** 2026-09-14 · **Scope:** Streak v2 module (Solo + Friends & Family) · **Environment:** Local + Live Railway

---

## Verdict

| Area | Status |
|---|---|
| Flutter streak tests (51/51) | ✅ PASS |
| Backend streak logic tests (40/40) | ✅ PASS |
| `flutter analyze` | ✅ 0 issues |
| Client ↔ Server endpoint contract (26/26 endpoints) | ✅ MATCH |
| Railway base URL migration (app client) | ✅ DONE |
| Render cleanup (backend) | ⚠️ 3 leftovers found → cleaned in this commit |
| **LIVE Railway server** | ❌ **DOWN — MongoDB unreachable (root cause fixed, redeploy needed)** |

**Broken functionality:** 1 (deployment-level, not streak code). Details below.

---

## 1. Critical Finding — Railway DB Down (Root Cause Found & Fixed)

`/api/db-status` (live) ne yeh bataya:

```json
{ "dbConnected": false, "lastError": "ReferenceError: crypto is not defined", "nodeVersion": "v18.20.5" }
```

- **Root cause:** Railway (Nixpacks) Node **v18** use kar raha hai. Global `crypto` (WebCrypto) Node 19+ se hi default hota hai. `mongoose@9` / `mongodb@7` connection path global `crypto` use karta hai → connect crash → `dbConnected=false` → **har DB-backed endpoint 503** (auth/register, streak v2 sab).
- Render par yeh issue nahi hota tha kyunke `render.yaml` mein `NODE_VERSION: 20` tha — Railway migration mein yeh setting transfer nahi hui.
- **Fix applied (this commit):**
  - `backend/package.json` → `"engines": { "node": ">=20.0.0" }`
  - `backend/.node-version` → `20` (Nixpacks dono detect karta hai)
- **Action required:** Railway par **redeploy** karo, phir `GET /api/db-status` se confirm karo ke `dbConnected: true` hai.

> Isi wajah se live streak API flow test complete nahi ho saka (server account bana hi nahi pa raha tha). Live test script ready hai: `temp_policy/test_streak_live.ps1` — redeploy ke baad chalao (32 live checks cover karta hai: solo start → 5 prayer ticks → undo/redo → history → group create/join/rename/rotate/invite/archive → notifications → devices).

---

## 2. Local Test Results (all green)

| Suite | Tests | Result |
|---|---|---|
| `backend/test/streakV2Logic.test.js` (group join rules, day satisfaction, run building, daily rules) | 23 | ✅ PASS |
| `backend/test/streakLogic.test.js` (v1 logic, idempotent ticks, clamps) | 17 | ✅ PASS |
| `flutter test` (full suite: streak models, invite text, day boundary, date service, widget) | 51 | ✅ PASS |
| `flutter analyze` | — | ✅ No issues |

*(Note: `node --test test/` directory-form Windows/Node-24 pe MODULE_NOT_FOUND deta hai — file list pass karke chalao: `node --test test/streakLogic.test.js test/streakV2Logic.test.js`. Code issue nahi hai.)*

---

## 3. Endpoint Contract — Client ↔ Server (26/26 verified)

Client: `lib/services/streak_v2_api.dart` → Server: `backend/routes/streakV2Routes.js` (mount: `/api/streak/v2`, `server.js:108`)

| Client call | Server route | Status |
|---|---|---|
| `getSolo` | `GET /solo` | ✅ |
| `startSolo` | `POST /solo/start` | ✅ |
| `completePrayer` (canonical tick) | `POST /prayers/complete` | ✅ |
| `getSoloHistory` | `GET /solo/history` | ✅ |
| `getMyGroups` | `GET /groups` | ✅ |
| `createGroup` | `POST /groups` | ✅ |
| `discoverGroups` | `GET /groups/discover` | ✅ |
| `getGroupDashboard` | `GET /groups/:id/dashboard` | ✅ |
| `getGroupHistory` | `GET /groups/:id/history` | ✅ |
| `getGroupActivity` | `GET /groups/:id/activity` | ✅ |
| `getMemberDetail` | `GET /groups/:id/members/:uid` | ✅ |
| `leaveGroup` | `POST /groups/:id/leave` | ✅ |
| `removeMember` | `POST /groups/:id/members/:uid/remove` | ✅ |
| `renameGroup` | `POST /groups/:id/rename` | ✅ |
| `rotateInviteCode` | `POST /groups/:id/invite/rotate` | ✅ |
| `transferOwnership` | `POST /groups/:id/transfer` | ✅ |
| `archiveGroup` | `POST /groups/:id/archive` | ✅ |
| `requestToJoin` | `POST /groups/:id/join-request` | ✅ |
| `getGroupRequests` | `GET /groups/:id/requests` | ✅ |
| `approveRequest` / `declineRequest` | `POST /requests/:id/approve|decline` | ✅ |
| `getInvitePreview` | `GET /invite/:code` | ✅ |
| `joinByInviteCode` | `POST /invite/:code/join` | ✅ |
| `getNotifications` | `GET /notifications` | ✅ |
| `markNotificationsSeen` | `POST /notifications/seen` | ✅ |
| `registerDevice` | `POST /devices` | ✅ |

Response field mapping (`SoloStreakData`, `GroupSummary`, `GroupDashboardData`, `InvitePreview.viewerState`, `JoinResult.alreadyMember`, activity/notification shapes) — controller DTOs ke saath line-by-line verified, koi mismatch nahi.

Server-only (client unused, intentional): `GET /requests/me`, `GET/POST /admin-repair/*`.

Client state wiring (`StreakState`, `PrayerCheckinService` notification "yes" action → `completePrayer`) — correct; optimistic update + rollback + auth-recovery + per-prayer in-flight guard sab theek.

---

## 4. Railway Migration Check

| Location | URL | Status |
|---|---|---|
| `lib/config.dart:4` (API base) | `backend-production-04292.up.railway.app/api` | ✅ Railway |
| `.github/workflows/keep-alive.yml:14` | Railway `/api/health` ping | ✅ Railway |
| `lib/screens/legal_screen.dart` (policy site) | `policy-production-980a.up.railway.app` | ✅ Railway |
| Live `/api/health` | `{"status":"ok"}` | ✅ Responding |
| Live `/api/db-status` | deployed code = HEAD (commit 0ca64e0) | ✅ Up-to-date deploy |

App client mein **kahin bhi render URL nahi** hai ✅

## 5. Render Cleanup — Leftovers Found & Removed

1. ✅ **`backend/render.yaml`** — DELETED (obsolete Render deploy config)
2. ✅ **`server.js` `startKeepAlive()`** — REMOVED (`RENDER_EXTERNAL_URL` Render-specific tha; Railway pe dead code — keep-alive ab GitHub workflow handle karta hai)
3. ✅ **`server.js:31` comment** — "Render sits behind…" → "Railway sits behind…" (comment fixed)
4. ℹ️ **`server.js` CORS**: `sajda-privacy.onrender.com` legacy entry — **kept** (policy-site migration safety, comment marked legacy). Chaaho to hata sakte ho jab old site fully dead ho jaye.

## 6. Recommendations (non-blocking)

1. **REPAIR_KEY hardcoded** (`streakV2Controller.js:1155`) — source mein secret commit hai; endpoints `/api/streak/v2/admin-repair/*` publicly mounted hain. Env var mein move karo aur kaam ho jane par endpoints remove karo (khud ka comment bhi "REMOVE after use" kehta hai).
2. Express JSON parse errors 500 dete hain (400 hone chahiye) — cosmetic.
3. Redeploy ke baad live E2E script zaroor chalao: `powershell -File temp_policy/test_streak_live.ps1`

---

**Bottom line:** Streak module ka code (client + backend) bilkul theek hai — tests, contract, wiring sab pass. Sirf Railway deployment Node 18 pe atki thi jo ab fix ho chuki; **redeploy zaroori hai**, uske baad streaks production mein kaam karengi.
