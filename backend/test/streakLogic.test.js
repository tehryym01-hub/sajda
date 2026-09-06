import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  PRAYERS,
  todayKeyInTz,
  dateKeyOfInstant,
  previousDateKey,
  nextDateKey,
  computeStreaks,
  normalizePrayerName,
  isValidPrayer,
} from '../backend/services/streakLogic.js';

// ---------------------------------------------------------------------------
// DATE MODEL — a streak day is a CALENDAR DAY in the user's timezone.
// It is NEVER a rolling 24-hour window.
// ---------------------------------------------------------------------------

test('23:59 and 00:01 are different calendar days (Karachi midnight boundary)', () => {
  // 2026-09-06 18:59 UTC == 2026-09-06 23:59 in Asia/Karachi (+05)
  const beforeMidnight = dateKeyOfInstant(new Date(Date.UTC(2026, 8, 6, 18, 59)), 'Asia/Karachi');
  // 2026-09-06 19:01 UTC == 2026-09-07 00:01 in Asia/Karachi
  const afterMidnight = dateKeyOfInstant(new Date(Date.UTC(2026, 8, 6, 19, 1)), 'Asia/Karachi');
  assert.equal(beforeMidnight, '2026-09-06');
  assert.equal(afterMidnight, '2026-09-07');
});

test('one minute crossing midnight changes the day — NOT 24h elapsed', () => {
  // Exactly 60 seconds apart, different days: proves the boundary is the
  // calendar midnight, not a Duration(hours: 24) timer.
  const a = new Date(Date.UTC(2026, 8, 6, 18, 59, 59));
  const b = new Date(Date.UTC(2026, 8, 6, 19, 0, 1));
  assert.notEqual(
    dateKeyOfInstant(a, 'Asia/Karachi'),
    dateKeyOfInstant(b, 'Asia/Karachi'),
  );
});

test('a prayer at 23:00 and one 24h later fall on two different days', () => {
  const day1 = dateKeyOfInstant(new Date(Date.UTC(2026, 8, 5, 18, 0)), 'Asia/Karachi'); // 23:00 local Sep 6? no: 18:00Z == 23:00 local
  const day2 = dateKeyOfInstant(new Date(Date.UTC(2026, 8, 6, 18, 0)), 'Asia/Karachi'); // exactly +24h
  assert.notEqual(day1, day2);
  assert.equal(nextDateKey(day1), day2);
});

test('timezone is respected: same instant, different local dates', () => {
  const instant = new Date(Date.UTC(2026, 8, 6, 20, 0)); // 20:00 UTC
  assert.equal(dateKeyOfInstant(instant, 'Asia/Karachi'), '2026-09-07'); // +5 → Sep 7 01:00
  assert.equal(dateKeyOfInstant(instant, 'America/New_York'), '2026-09-06'); // -4/5 → Sep 6
  assert.equal(dateKeyOfInstant(instant, 'Asia/Tokyo'), '2026-09-07'); // +9
});

test('previousDateKey / nextDateKey do calendar arithmetic across months', () => {
  assert.equal(previousDateKey('2026-09-01'), '2026-08-31');
  assert.equal(previousDateKey('2026-03-01'), '2026-02-28');
  assert.equal(nextDateKey('2026-02-28'), '2026-03-01');
  assert.equal(nextDateKey('2024-02-28'), '2024-02-29'); // leap year
  assert.equal(previousDateKey(nextDateKey('2026-09-06')), '2026-09-06');
});

test('invalid timezone falls back to UTC deterministically', () => {
  const key = dateKeyOfInstant(new Date(Date.UTC(2026, 8, 6, 23, 30)), 'Not/AZone');
  assert.equal(key, '2026-09-06');
});

test('todayKeyInTz uses the current instant', () => {
  const now = new Date();
  assert.equal(todayKeyInTz('UTC', now), new Intl.DateTimeFormat('en-CA', {
    timeZone: 'UTC', year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(now));
});

// ---------------------------------------------------------------------------
// STREAK CONTINUATION LOGIC
// ---------------------------------------------------------------------------

const C = (date, complete = true) => ({ date, isComplete: complete });

test('current streak counts consecutive complete days ending today', () => {
  const today = '2026-09-06';
  const completions = [C('2026-09-04'), C('2026-09-05'), C('2026-09-06')];
  const { currentStreak, longestStreak } = computeStreaks(completions, today);
  assert.equal(currentStreak, 3);
  assert.equal(longestStreak, 3);
});

test('today incomplete keeps the streak alive through yesterday', () => {
  const today = '2026-09-07';
  const completions = [C('2026-09-05'), C('2026-09-06')]; // today 0/5 so far
  const { currentStreak } = computeStreaks(completions, today);
  assert.equal(currentStreak, 2);
});

test('a missed day breaks the current run but keeps the longest run', () => {
  const today = '2026-09-08';
  const completions = [
    C('2026-09-03'), C('2026-09-04'), C('2026-09-05'),
    { date: '2026-09-06', isComplete: false }, // missed
    C('2026-09-07'), C('2026-09-08'),
  ];
  const { currentStreak, longestStreak } = computeStreaks(completions, today);
  assert.equal(currentStreak, 2); // Sep 7 + Sep 8
  assert.equal(longestStreak, 3); // Sep 3-5 preserved
});

test('missing record (no row at all) also breaks the run', () => {
  const today = '2026-09-08';
  const completions = [C('2026-09-05'), C('2026-09-07'), C('2026-09-08')]; // gap on 09-06
  const { currentStreak, longestStreak } = computeStreaks(completions, today);
  assert.equal(currentStreak, 2);
  assert.equal(longestStreak, 2);
});

test('streak never counts days recorded before the streak started (sinceKey)', () => {
  const today = '2026-09-08';
  const completions = [C('2026-09-02'), C('2026-09-03'), C('2026-09-04'), C('2026-09-05')];
  // Streak began Sep 5 — days before it must not inflate the current run.
  const { currentStreak, longestStreak } = computeStreaks(completions, today, '2026-09-05');
  assert.equal(currentStreak, 0); // Sep 6,7,8 missing → broken anyway after Sep 5
  assert.equal(longestStreak, 4); // longest stays global history
});

test('sinceKey bounds the run right after streak creation', () => {
  const today = '2026-09-08';
  const completions = [C('2026-09-05'), C('2026-09-06'), C('2026-09-07'), C('2026-09-08')];
  const { currentStreak } = computeStreaks(completions, today, '2026-09-05');
  assert.equal(currentStreak, 4);
});

test('empty history → zero streaks', () => {
  const r = computeStreaks([], '2026-09-06');
  assert.equal(r.currentStreak, 0);
  assert.equal(r.longestStreak, 0);
});

test('currentStreak is clamped by longestStreak', () => {
  const today = '2026-09-06';
  const completions = [C(today)];
  const { currentStreak, longestStreak } = computeStreaks(completions, today);
  assert.equal(currentStreak, 1);
  assert.equal(longestStreak, 1);
});

test('duplicate records for the same day do not double-count (idempotent)', () => {
  const today = '2026-09-06';
  const completions = [C('2026-09-05'), C('2026-09-05'), C('2026-09-06'), C('2026-09-06')];
  const { currentStreak, longestStreak } = computeStreaks(completions, today);
  assert.equal(currentStreak, 2);
  assert.equal(longestStreak, 2);
});

// ---------------------------------------------------------------------------
// PRAYER NAME NORMALIZATION (notification check-ins send 'Fajr' etc.)
// ---------------------------------------------------------------------------

test('prayer names are normalized case/whitespace-insensitively', () => {
  assert.equal(normalizePrayerName('Fajr'), 'fajr');
  assert.equal(normalizePrayerName('  ISHA '), 'isha');
  assert.equal(normalizePrayerName('Maghrib'), 'maghrib');
  assert.ok(isValidPrayer('Dhuhr'));
  assert.ok(!isValidPrayer('Sunrise'));
  assert.ok(!isValidPrayer(null));
  assert.deepEqual(PRAYERS, ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
});
