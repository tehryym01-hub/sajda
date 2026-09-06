// Pure, DB-free streak logic. Extracted so it can be unit-tested with
// `node --test` without a database, and reused by the controller.
//
// DATE MODEL (authoritative rule):
// A streak day is a CALENDAR DAY key 'YYYY-MM-DD' in the USER'S location
// timezone. It is NEVER a rolling 24-hour window. 23:59 belongs to the
// current day; 00:00 belongs to the next day, regardless of when the
// previous prayer was completed.

export const PRAYERS = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

const pad = (n) => String(n).padStart(2, '0');

/// Calendar day key of `now` (an instant) in `timezone` (IANA id).
export const dateKeyOfInstant = (now, timezone) => {
  try {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone || 'Asia/Karachi',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(now);
  } catch (_) {
    // Invalid timezone id — fall back to UTC to stay deterministic.
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: 'UTC',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(now);
  }
};

export const todayKeyInTz = (timezone, now = new Date()) => dateKeyOfInstant(now, timezone);

/// '2026-09-06' -> '2026-09-05' (calendar arithmetic, NOT 24h subtraction).
export const previousDateKey = (dateKey) => {
  const [y, m, d] = String(dateKey).split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() - 1);
  return `${dt.getUTCFullYear()}-${pad(dt.getUTCMonth() + 1)}-${pad(dt.getUTCDate())}`;
};

const isCompleteEntry = (c) => !!c && c.isComplete === true;

/// Current + longest consecutive-day streaks from completion records.
///
/// `completions`: [{ date: 'YYYY-MM-DD', isComplete: bool }]
/// `todayKey`:    current day key in the user's timezone
/// `sinceKey`:    optional lower bound for the CURRENT run (a streak must
///                not count prayer days recorded before the streak started).
///
/// Rules:
///  - a day qualifies only when isComplete (all 5 prayers) is true
///  - today counts if complete; if today is not complete yet the streak is
///    still alive through yesterday (the user has the rest of today)
///  - one missed (or absent) day breaks the consecutive run
///  - longest streak is measured over the whole history
export const computeStreaks = (completions, todayKey, sinceKey = null) => {
  const byDate = new Map();
  for (const c of completions || []) {
    byDate.set(String(c.date), isCompleteEntry(c));
  }

  // ── current run ──
  let currentStreak = 0;
  let cursor = todayKey;
  if (!byDate.get(cursor)) {
    // Today not (yet) complete — the streak survives until midnight via
    // yesterday. Anything older-than-yesterday breaks it.
    cursor = previousDateKey(todayKey);
  }
  while (byDate.get(cursor) && (!sinceKey || cursor >= sinceKey)) {
    currentStreak += 1;
    cursor = previousDateKey(cursor);
  }

  // ── longest run (whole history) ──
  let longestStreak = 0;
  let run = 0;
  let prevComplete = null;
  const dates = [...byDate.keys()].sort();
  for (const d of dates) {
    if (byDate.get(d)) {
      run = prevComplete !== null && nextDateKey(prevComplete) === d ? run + 1 : 1;
      if (run > longestStreak) longestStreak = run;
      prevComplete = d;
    } else {
      run = 0;
      prevComplete = null;
    }
  }

  return { currentStreak, longestStreak: Math.max(longestStreak, currentStreak) };
};

export const nextDateKey = (dateKey) => {
  const [y, m, d] = String(dateKey).split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + 1);
  return `${dt.getUTCFullYear()}-${pad(dt.getUTCMonth() + 1)}-${pad(dt.getUTCDate())}`;
};

export const normalizePrayerName = (value) =>
  String(value || '').trim().toLowerCase();

export const isValidPrayer = (value) => PRAYERS.includes(normalizePrayerName(value));
