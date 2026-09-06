import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  GROUP_MEMBER_LIMIT_DEFAULT,
  randomCode,
  newGroupId,
  effectiveFromForJoin,
  isMemberEligibleOn,
  isGroupDaySatisfied,
  currentRunFromDays,
  longestRunFromDays,
  buildMonthHistory,
  relativeTime,
} from '../backend/services/streakV2Logic.js';
import { todayKeyInTz, nextDateKey, previousDateKey } from '../backend/services/streakLogic.js';

// ---------------------------------------------------------------------------
// NEW-MEMBER RULE: a member joining today only counts from the NEXT day —
// they can never retroactively break an existing group streak.
// ---------------------------------------------------------------------------

test('effectiveFromForJoin returns TOMORROW in the group timezone', () => {
  // 2026-09-06 10:00 UTC == 15:00 Karachi — join "today" = 2026-09-06
  const now = new Date(Date.UTC(2026, 8, 6, 10, 0));
  assert.equal(effectiveFromForJoin(now, 'Asia/Karachi'), '2026-09-07');
});

test('a join just before group midnight is effective the next group day', () => {
  // 2026-09-06 18:59 UTC == 23:59 Karachi (one minute before midnight)
  const now = new Date(Date.UTC(2026, 8, 6, 18, 59));
  assert.equal(effectiveFromForJoin(now, 'Asia/Karachi'), '2026-09-07');
  // one minute later it is already Sep 7 in Karachi → effective Sep 8
  const afterMidnight = new Date(Date.UTC(2026, 8, 6, 19, 1));
  assert.equal(effectiveFromForJoin(afterMidnight, 'Asia/Karachi'), '2026-09-08');
});

test('isMemberEligibleOn respects effectiveFromDate and status', () => {
  const member = { status: 'active', effectiveFromDate: '2026-09-07' };
  assert.equal(isMemberEligibleOn(member, '2026-09-06'), false); // join day: not required
  assert.equal(isMemberEligibleOn(member, '2026-09-07'), true);  // from next day
  assert.equal(isMemberEligibleOn(member, '2026-09-10'), true);
  assert.equal(isMemberEligibleOn({ ...member, status: 'left' }, '2026-09-10'), false);
  assert.equal(isMemberEligibleOn(null, '2026-09-10'), false);
});

// ---------------------------------------------------------------------------
// GROUP DAY COMPLETION — ALL eligible active members must be 5/5.
// ---------------------------------------------------------------------------

test('group day completes only when EVERY eligible member is complete', () => {
  const members = [
    { userId: 'u1', status: 'active', effectiveFromDate: '2026-09-01' },
    { userId: 'u2', status: 'active', effectiveFromDate: '2026-09-01' },
    { userId: 'u3', status: 'active', effectiveFromDate: '2026-09-01' },
  ];
  const rows = (ids) => ids.map((id) => ({ userId: id, isDayComplete: true }));
  assert.equal(isGroupDaySatisfied(members, rows(['u1', 'u2', 'u3'])), true);
  assert.equal(isGroupDaySatisfied(members, rows(['u1', 'u2'])), false); // u3 at 4/5
  assert.equal(isGroupDaySatisfied(members, rows(['u1'])), false);
  assert.equal(isGroupDaySatisfied(members, []), false);
});

test('missing progress rows count as incomplete', () => {
  const members = [{ userId: 'u1', status: 'active' }];
  assert.equal(isGroupDaySatisfied(members, [{ userId: 'u2', isDayComplete: true }]), false);
});

test('a member who joined today is NOT required for today', () => {
  const members = [
    { userId: 'u1', status: 'active', effectiveFromDate: '2026-09-01' },
    { userId: 'new', status: 'active', effectiveFromDate: '2026-09-07' },
  ];
  // Only u1 is eligible on 09-06; u1 complete → day satisfied even though
  // the new member (who joins ON 09-06) has no progress yet.
  const eligible = members.filter((m) => isMemberEligibleOn(m, '2026-09-06'));
  assert.equal(isGroupDaySatisfied(eligible, [{ userId: 'u1', isDayComplete: true }]), true);
});

test('empty group never completes a day', () => {
  assert.equal(isGroupDaySatisfied([], []), false);
});

// ---------------------------------------------------------------------------
// STREAK RUNS — derived from completed-day records (no ++ from a tap).
// ---------------------------------------------------------------------------

test('current run counts consecutive complete days with yesterday grace', () => {
  const days = new Set(['2026-09-04', '2026-09-05', '2026-09-06']);
  // today = 09-07, still 3/5 → streak alive via yesterday
  let r = currentRunFromDays(days, '2026-09-07');
  assert.equal(r.run, 3);
  assert.equal(r.startDate, '2026-09-04');
  // today complete too → 4
  r = currentRunFromDays(new Set([...days, '2026-09-07']), '2026-09-07');
  assert.equal(r.run, 4);
});

test('a missed day breaks the current run', () => {
  const days = new Set(['2026-09-01', '2026-09-02', '2026-09-03', '2026-09-06', '2026-09-07']);
  // gap on 09-04/05 → current run = 2 (09-06..09-07 via yesterday grace today=09-08)
  const r = currentRunFromDays(days, '2026-09-08');
  assert.equal(r.run, 2);
  assert.equal(r.startDate, '2026-09-06');
});

test('empty history → zero run', () => {
  const r = currentRunFromDays(new Set(), '2026-09-08');
  assert.equal(r.run, 0);
  assert.equal(r.startDate, null);
});

test('longest run spans whole history and ignores duplicate keys', () => {
  const days = ['2026-09-01', '2026-09-02', '2026-09-03', '2026-09-05', '2026-09-06', '2026-09-02'];
  assert.equal(longestRunFromDays(new Set(days)), 3);
  assert.equal(longestRunFromDays([]), 0);
  assert.equal(longestRunFromDays(['2026-09-01']), 1);
});

// ---------------------------------------------------------------------------
// HISTORY CALENDAR — ✓ complete / ✗ missed / future / today / none.
// ---------------------------------------------------------------------------

test('buildMonthHistory marks complete, missed, today, future and pre-join days', () => {
  const days = new Set(['2026-09-01', '2026-09-02', '2026-09-04']);
  const cal = buildMonthHistory(days, 2026, 9, '2026-09-01', '2026-09-05');
  const byDay = Object.fromEntries(cal.map((d) => [d.day, d.state]));
  assert.equal(byDay[1], 'complete');
  assert.equal(byDay[3], 'missed');   // after first required day, not complete
  assert.equal(byDay[4], 'complete');
  assert.equal(byDay[5], 'today');
  assert.equal(byDay[6], 'future');
});

test('days before the first required day are marked none (not missed)', () => {
  const cal = buildMonthHistory(new Set(['2026-09-03']), 2026, 9, '2026-09-03', '2026-09-05');
  const byDay = Object.fromEntries(cal.map((d) => [d.day, d.state]));
  assert.equal(byDay[1], 'none');
  assert.equal(byDay[2], 'none');
  assert.equal(byDay[4], 'missed'); // after streak started but not completed
});

// ---------------------------------------------------------------------------
// CODES & IDS
// ---------------------------------------------------------------------------

test('invite codes use the unambiguous alphabet and requested length', () => {
  const code = randomCode(6);
  assert.equal(code.length, 6);
  assert.match(code, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]+$/);
  const codes = new Set(Array.from({ length: 200 }, () => randomCode(6)));
  assert.ok(codes.size > 190, 'codes should be near-unique');
});

test('group ids have the grp_ prefix', () => {
  assert.match(newGroupId(), /^grp_[a-z0-9]{10}$/);
});

test('member limit is a single configurable constant', () => {
  assert.ok(Number.isInteger(GROUP_MEMBER_LIMIT_DEFAULT) && GROUP_MEMBER_LIMIT_DEFAULT >= 10);
});

test('relativeTime buckets sensibly', () => {
  const now = new Date('2026-09-07T12:00:00Z');
  assert.equal(relativeTime(new Date('2026-09-07T11:59:40Z'), now), 'just now');
  assert.equal(relativeTime(new Date('2026-09-07T11:30:00Z'), now), '30 min ago');
  assert.equal(relativeTime(new Date('2026-09-07T09:00:00Z'), now), '3h ago');
});

// ---------------------------------------------------------------------------
// Calendar-day helpers re-verified in the group context (group timezone).
// ---------------------------------------------------------------------------

test('group dateKey uses the GROUP timezone, not the actor device clock', () => {
  const instant = new Date(Date.UTC(2026, 8, 6, 20, 0)); // 20:00 UTC
  assert.equal(todayKeyInTz('Asia/Karachi', instant), '2026-09-07'); // +5 → 01:00 next day
  assert.equal(todayKeyInTz('America/New_York', instant), '2026-09-06'); // -4 → 16:00
  assert.equal(previousDateKey(todayKeyInTz('Asia/Karachi', instant)), '2026-09-06');
  assert.equal(nextDateKey(previousDateKey('2026-09-07')), '2026-09-07');
});
