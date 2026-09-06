// Pure, DB-free business rules for the v2 streak system (Friends & Family
// groups + Solo). Unit-tested with `node --test`. Reuses the shared
// calendar-day logic from streakLogic.js — a streak day is a CALENDAR DAY
// key in a defined timezone, never a rolling 24-hour window.
import crypto from 'crypto';
import {
  todayKeyInTz,
  nextDateKey,
  previousDateKey,
} from './streakLogic.js';

// Unambiguous alphabet (no 0/O/1/I) so codes can be read from share text
// and typed reliably.
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export const GROUP_MEMBER_LIMIT_DEFAULT = 50; // configurable, one source of truth
export const GROUP_NAME_MAX = 60;
export const ACTIVITY_PAGE_SIZE = 20;
export const DISCOVER_PAGE_SIZE = 20;

export const randomCode = (length = 6) => {
  const bytes = crypto.randomBytes(length);
  let out = '';
  for (let i = 0; i < length; i++) {
    out += CODE_ALPHABET[bytes[i] % CODE_ALPHABET.length];
  }
  return out;
};

export const newGroupId = () => `grp_${randomCode(10).toLowerCase()}`;

/// The first dateKey a NEW member counts towards group completion.
/// Rule: a member joining today becomes a required member from the NEXT
/// streak day — they can never retroactively break an existing streak.
export const effectiveFromForJoin = (now, groupTimezone) =>
  nextDateKey(todayKeyInTz(groupTimezone, now));

/// Whether a member counts towards group completion on [dateKey].
export const isMemberEligibleOn = (member, dateKey) => {
  if (!member || member.status !== 'active') return false;
  return String(member.effectiveFromDate) <= String(dateKey);
};

/// Group day completion check over today's member rows.
/// `rows`: [{ userId, isDayComplete }] — one per ACTIVE ELIGIBLE member
/// (missing row = member has not started/prayed = incomplete).
/// A group day completes ONLY when EVERY eligible active member is 5/5.
export const isGroupDaySatisfied = (eligibleMembers, rows) => {
  if (!eligibleMembers || eligibleMembers.length === 0) return false;
  const completeByUser = new Set(
    (rows || []).filter((r) => r.isDayComplete).map((r) => String(r.userId)),
  );
  return eligibleMembers.every((m) => completeByUser.has(String(m.userId)));
};

/// Current streak walk over day-complete records.
/// `completeDays`: Set of dateKeys that were completed.
/// Walks back from today (if complete) else yesterday — the streak stays
/// alive through yesterday while today is still in progress — and stops at
/// the first missing/incomplete past day. Returns the run length and the
/// run's first day.
export const currentRunFromDays = (completeDays, todayKey) => {
  const set = completeDays instanceof Set ? completeDays : new Set(completeDays || []);
  let cursor = todayKey;
  if (!set.has(cursor)) cursor = previousDateKey(todayKey); // today still in progress
  let run = 0;
  while (set.has(cursor)) {
    run += 1;
    cursor = previousDateKey(cursor);
  }
  return { run, startDate: run > 0 ? nextDateKey(cursor) : null };
};

/// Longest run of consecutive completed day keys (whole history).
export const longestRunFromDays = (completeDays) => {
  const keys = [...(completeDays instanceof Set ? completeDays : new Set(completeDays || []))]
    .filter(Boolean)
    .sort();
  let best = 0;
  let run = 0;
  let prev = null;
  for (const k of keys) {
    run = prev !== null && nextDateKey(prev) === k ? run + 1 : 1;
    if (run > best) best = run;
    prev = k;
  }
  return best;
};

/// History calendar for a month: marks each day ✓ complete / ✗ missed /
/// future. Only days from [firstRequiredDay] onward count as missed.
export const buildMonthHistory = (completeDays, year, month, firstRequiredDay, todayKey) => {
  const set = completeDays instanceof Set ? completeDays : new Set(completeDays || []);
  const pad = (n) => String(n).padStart(2, '0');
  const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const days = [];
  for (let d = 1; d <= daysInMonth; d++) {
    const key = `${year}-${pad(month)}-${pad(d)}`;
    let state = 'future';
    if (key < todayKey) {
      state = set.has(key) ? 'complete' : 'missed';
      if (firstRequiredDay && key < firstRequiredDay) state = 'none'; // before streak/join
    } else if (key === todayKey) {
      state = 'today';
    }
    days.push({ dateKey: key, day: d, state });
  }
  return days;
};

/// Relative time label helper for feeds (English; UI localizes if needed).
export const relativeTime = (date, now = new Date()) => {
  const s = Math.max(0, Math.floor((now - date) / 1000));
  if (s < 60) return 'just now';
  const m = Math.floor(s / 60);
  if (m < 60) return `${m} min ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 7) return `${d}d ago`;
  return date.toISOString().slice(0, 10);
};
