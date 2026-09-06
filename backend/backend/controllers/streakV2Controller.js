import mongoose from 'mongoose';
import User from '../models/User.js';
import SoloStreak from '../models/SoloStreak.js';
import SoloDailyProgress from '../models/SoloDailyProgress.js';
import Group from '../models/Group.js';
import GroupMember from '../models/GroupMember.js';
import GroupDailyProgress from '../models/GroupDailyProgress.js';
import GroupDailySummary from '../models/GroupDailySummary.js';
import GroupActivity from '../models/GroupActivity.js';
import JoinRequest from '../models/JoinRequest.js';
import PushToken from '../models/PushToken.js';
import { PRAYERS, todayKeyInTz } from '../services/streakLogic.js';
import {
  GROUP_MEMBER_LIMIT_DEFAULT,
  GROUP_NAME_MAX,
  ACTIVITY_PAGE_SIZE,
  DISCOVER_PAGE_SIZE,
  randomCode,
  newGroupId,
  effectiveFromForJoin,
  isMemberEligibleOn,
  isGroupDaySatisfied,
  currentRunFromDays,
  longestRunFromDays,
  buildMonthHistory,
} from '../services/streakV2Logic.js';

const fail = (res, status, code, message) =>
  res.status(status).json({ success: false, code, message });

const resolveUser = async (req) => {
  const id = String(req.user?.id || req.user?._id);
  let displayName = req.user?.displayName || req.user?.name || 'Anonymous';
  let timezone = req.user?.timezone || 'Asia/Karachi';
  try {
    const u = await User.findById(id).select('displayName timezone notificationsSeenAt').lean();
    if (u) {
      if (u.displayName) displayName = u.displayName;
      if (u.timezone) timezone = u.timezone;
    }
  } catch (_) { /* token fallback */ }
  return { id, displayName, timezone };
};

const prayerOf = (raw) => String(raw || '').trim().toLowerCase();

// ─────────────────────────────────────────────────────────────────────────
// STREAK DERIVATION — streaks are computed from daily records, never
// incremented by a tap. Bounded walk: cost = current streak length.
// ─────────────────────────────────────────────────────────────────────────

const rollForwardSolo = async (solo, userId, timezone) => {
  const today = todayKeyInTz(timezone);
  const rows = await SoloDailyProgress.find({ userId, isDayComplete: true })
    .select('dateKey').lean();
  const days = new Set(rows.map((r) => r.dateKey));
  const { run, startDate } = currentRunFromDays(days, today);
  const best = Math.max(longestRunFromDays(days), run);
  let doc = solo;
  if (!doc) doc = await SoloStreak.create({ userId });
  let changed = false;
  if (doc.currentStreak !== run) { doc.currentStreak = run; changed = true; }
  if (doc.bestStreak !== best) { doc.bestStreak = best; changed = true; }
  if (doc.currentStreakStartDate !== startDate) { doc.currentStreakStartDate = startDate; changed = true; }
  const last = [...days].sort().pop() || null;
  if (doc.lastCompletedDay !== last) { doc.lastCompletedDay = last; changed = true; }
  if (doc.lastEvaluatedDay !== today) { doc.lastEvaluatedDay = today; changed = true; }
  if (changed) await doc.save();
  return doc;
};

const rollForwardGroup = async (group) => {
  const today = todayKeyInTz(group.timezone);
  const rows = await GroupDailySummary.find({ groupId: group.groupId, isGroupDayComplete: true })
    .select('dateKey').lean();
  const days = new Set(rows.map((r) => r.dateKey));
  const { run, startDate } = currentRunFromDays(days, today);
  const best = Math.max(longestRunFromDays(days), run);
  let changed = false;
  if (group.currentStreak !== run) { group.currentStreak = run; changed = true; }
  if (group.bestStreak !== best) { group.bestStreak = best; changed = true; }
  if (group.currentStreakStartDate !== startDate) { group.currentStreakStartDate = startDate; changed = true; }
  if (group.lastEvaluatedDay !== today) { group.lastEvaluatedDay = today; changed = true; }
  if (changed) await group.save();
  return group;
};

const soloPayload = (solo, todayRow) => ({
  started: true,
  currentStreak: solo?.currentStreak || 0,
  bestStreak: solo?.bestStreak || 0,
  currentStreakStartDate: solo?.currentStreakStartDate || null,
  lastCompletedDay: solo?.lastCompletedDay || null,
  today: {
    fajr: !!todayRow?.fajr,
    dhuhr: !!todayRow?.dhuhr,
    asr: !!todayRow?.asr,
    maghrib: !!todayRow?.maghrib,
    isha: !!todayRow?.isha,
    completedCount: todayRow?.completedCount || 0,
    isDayComplete: !!todayRow?.isDayComplete,
  },
});

// ─────────────────────────────────────────────────────────────────────────
// PRAYER COMPLETION — ONE canonical action. Updates Solo + every group +
// activity, idempotent per (context, user, dateKey, prayer).
// ─────────────────────────────────────────────────────────────────────────

const flippedTrue = async (Model, filter, prayer) => {
  const r = await Model.updateOne(
    { ...filter, [prayer]: { $ne: true } },
    { $set: { [prayer]: true }, $inc: { completedCount: 1 } },
  );
  return r.modifiedCount === 1;
};

const flippedFalse = async (Model, filter, prayer) => {
  const r = await Model.updateOne(
    { ...filter, [prayer]: true },
    { $set: { [prayer]: false }, $inc: { completedCount: -1 } },
  );
  return r.modifiedCount === 1;
};

const markDayComplete = async (Model, filter, complete) => {
  await Model.updateOne(
    { ...filter, isDayComplete: { $ne: !!complete } },
    {
      $set: { isDayComplete: !!complete, ...(complete ? { completedAt: new Date() } : {}) },
      ...(complete ? {} : { $unset: { completedAt: '' } }),
    },
  );
  const row = await Model.findOne(filter).lean();
  return row;
};

// Checks ALL eligible active members and — only when everyone is 5/5 —
// flips the summary COMPLETE exactly once (atomic conditional update).
const maybeCompleteGroupDay = async (group, dateKey, actor) => {
  const eligible = await GroupMember.find({
    groupId: group.groupId, status: 'active', effectiveFromDate: { $lte: dateKey },
  }).select('userId').lean();
  if (eligible.length === 0) return false;
  const rows = await GroupDailyProgress.find({ groupId: group.groupId, dateKey, eligible: true })
    .select('userId isDayComplete').lean();
  if (!isGroupDaySatisfied(eligible, rows)) return false;

  const updated = await GroupDailySummary.findOneAndUpdate(
    { groupId: group.groupId, dateKey, isGroupDayComplete: false },
    {
      $setOnInsert: { groupId: group.groupId, dateKey },
      $set: {
        isGroupDayComplete: true,
        completedAt: new Date(),
        eligibleCount: eligible.length,
        completedCount: rows.filter((r) => r.isDayComplete).length,
      },
    },
    { upsert: true, new: true },
  );
  // The conditional update guarantees exactly one writer sees false→true,
  // but upsert races can still land here; verify the flip we own.
  if (!updated) return false;
  await GroupActivity.create({
    groupId: group.groupId,
    userId: actor?._id || actor,
    displayName: actor?.displayName || 'Someone',
    type: 'group_day_completed',
    dateKey,
  });
  await rollForwardGroup(group);
  return true;
};

const revertGroupDay = async (group, dateKey) => {
  const updated = await GroupDailySummary.findOneAndUpdate(
    { groupId: group.groupId, dateKey, isGroupDayComplete: true },
    { $set: { isGroupDayComplete: false }, $unset: { completedAt: '' } },
    { new: true },
  );
  if (!updated) return false;
  await GroupActivity.deleteOne({ groupId: group.groupId, type: 'group_day_completed', dateKey });
  await rollForwardGroup(group);
  return true;
};

export const completePrayer = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const prayer = prayerOf(req.body?.prayer);
    if (!PRAYERS.includes(prayer)) {
      return fail(res, 400, 'INVALID_PRAYER', 'Invalid prayer name');
    }
    const completed = req.body?.completed !== false; // default true
    const soloKey = todayKeyInTz(user.timezone);
    const groupsTouched = [];

    // ── SOLO ──
    let solo = await SoloStreak.findOne({ userId: user.id });
    if (completed && !solo) solo = await SoloStreak.create({ userId: user.id });
    const soloRowFilter = { userId: new mongoose.Types.ObjectId(user.id), dateKey: soloKey };
    // Ensure today's row exists BEFORE the conditional flip — a plain
    // updateOne cannot create it, so the first tick of a fresh day would
    // otherwise be a silent no-op (same pattern as the group fan-out below).
    if (completed) {
      await SoloDailyProgress.updateOne(
        soloRowFilter,
        { $setOnInsert: { ...soloRowFilter, completedCount: 0 } },
        { upsert: true },
      );
    }
    const flip = completed
      ? await flippedTrue(SoloDailyProgress, soloRowFilter, prayer)
      : await flippedFalse(SoloDailyProgress, soloRowFilter, prayer);
    const soloRow = await markDayComplete(SoloDailyProgress, soloRowFilter, completed);
    solo = await rollForwardSolo(solo, user.id, user.timezone);

    // ── GROUPS (fan-out of the SAME single tick) ──
    const memberships = await GroupMember.find({ userId: user.id, status: 'active' }).lean();
    const groupIds = memberships.map((m) => m.groupId);
    const groups = groupIds.length
      ? await Group.find({ groupId: { $in: groupIds }, status: 'active' })
      : [];
    for (const group of groups) {
      const gKey = todayKeyInTz(group.timezone);
      const membership = memberships.find((m) => m.groupId === group.groupId);
      const eligible = isMemberEligibleOn(membership, gKey);
      const rowFilter = { groupId: group.groupId, userId: new mongoose.Types.ObjectId(user.id), dateKey: gKey };
      if (completed) {
        await GroupDailyProgress.updateOne(
          rowFilter,
          { $setOnInsert: { ...rowFilter }, $set: { eligible } },
          { upsert: true },
        );
        const did = await flippedTrue(GroupDailyProgress, rowFilter, prayer);
        if (did) {
          await GroupActivity.create({
            groupId: group.groupId, userId: user.id, displayName: user.displayName,
            type: 'prayer_completed', prayer,
          });
        }
        const row = await markDayComplete(GroupDailyProgress, rowFilter, completed);
        if (eligible) await maybeCompleteGroupDay(group, gKey, { _id: user.id, displayName: user.displayName });
      } else {
        const did = await flippedFalse(GroupDailyProgress, rowFilter, prayer);
        if (did) {
          await GroupActivity.deleteOne({
            groupId: group.groupId, userId: new mongoose.Types.ObjectId(user.id),
            type: 'prayer_completed', prayer, dateKey: { $exists: false }, createdAt: { $gte: new Date(Date.now() - 26 * 3600 * 1000) },
          });
        }
        await markDayComplete(GroupDailyProgress, rowFilter, false);
        if (eligible) await revertGroupDay(group, gKey);
      }
      groupsTouched.push({
        groupId: group.groupId,
        name: group.name,
        dateKey: gKey,
        currentStreak: group.currentStreak,
      });
    }

    res.json({
      success: true,
      data: {
        prayer,
        completed,
        solo: soloPayload(solo, soloRow),
        groups: groupsTouched,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ─────────────────────────────────────────────────────────────────────────
// SOLO
// ─────────────────────────────────────────────────────────────────────────

export const getSolo = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const today = todayKeyInTz(user.timezone);
    const row = await SoloDailyProgress.findOne({ userId: user.id, dateKey: today }).lean();
    if (!row) {
      const solo = await SoloStreak.findOne({ userId: user.id }).lean();
      if (!solo) return res.json({ success: true, data: { started: false, today: { completedCount: 0, isDayComplete: false } } });
      const fresh = await rollForwardSolo(await SoloStreak.findById(solo._id), user.id, user.timezone);
      return res.json({ success: true, data: soloPayload(fresh, null) });
    }
    const solo = await rollForwardSolo(await SoloStreak.findOne({ userId: user.id }), user.id, user.timezone);
    res.json({ success: true, data: soloPayload(solo, row) });
  } catch (error) {
    next(error);
  }
};

export const startSolo = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const solo = await rollForwardSolo(await SoloStreak.findOne({ userId: user.id }), user.id, user.timezone);
    res.status(201).json({ success: true, data: soloPayload(solo, null) });
  } catch (error) {
    next(error);
  }
};

export const getSoloHistory = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const now = new Date();
    const year = Number(req.query?.year) || now.getUTCFullYear();
    const month = Number(req.query?.month) || now.getUTCMonth() + 1;
    const todayKey = todayKeyInTz(user.timezone);
    const rows = await SoloDailyProgress.find({
      userId: user.id,
      dateKey: { $regex: `^${year}-${String(month).padStart(2, '0')}` },
    }).select('dateKey isDayComplete completedCount').lean();
    const days = new Set(rows.filter((r) => r.isDayComplete).map((r) => r.dateKey));
    const byDate = Object.fromEntries(rows.map((r) => [r.dateKey, r]));
    const solo = await SoloStreak.findOne({ userId: user.id }).lean();
    const firstRequired = solo?.currentStreakStartDate || null;
    const calendar = buildMonthHistory(days, year, month, firstRequired, todayKey)
      .map((d) => ({ ...d, completedCount: byDate[d.dateKey]?.completedCount || 0 }));
    const fresh = await rollForwardSolo(await SoloStreak.findOne({ userId: user.id }), user.id, user.timezone);
    res.json({
      success: true,
      data: {
        year, month, calendar,
        currentStreak: fresh.currentStreak,
        bestStreak: fresh.bestStreak,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ─────────────────────────────────────────────────────────────────────────
// GROUPS — membership helpers
// ─────────────────────────────────────────────────────────────────────────

const memberOf = async (groupId, userId) =>
  GroupMember.findOne({ groupId, userId: new mongoose.Types.ObjectId(userId) });

const requireMembership = async (res, groupId, userId, { activeOnly = true } = {}) => {
  const group = await Group.findOne({ groupId });
  if (!group) {
    fail(res, 404, 'GROUP_NOT_FOUND', 'Group no longer exists');
    return null;
  }
  const member = await memberOf(groupId, userId);
  if (!member || (activeOnly && member.status !== 'active')) {
    fail(res, 403, 'NOT_MEMBER', 'You are not an active member of this group');
    return null;
  }
  return { group, member };
};

const addMemberToGroup = async (group, user, role = 'member') => {
  const effectiveFrom = effectiveFromForJoin(new Date(), group.timezone);
  const existing = await memberOf(group.groupId, user.id);
  if (existing) {
    existing.status = 'active';
    existing.role = role;
    existing.joinedAt = new Date();
    existing.effectiveFromDate = effectiveFrom; // rejoin restarts eligibility next day
    existing.displayName = user.displayName;
    existing.leftAt = null;
    await existing.save();
  } else {
    await GroupMember.create({
      groupId: group.groupId, userId: new mongoose.Types.ObjectId(user.id),
      displayName: user.displayName, role, status: 'active', effectiveFromDate: effectiveFrom,
    });
  }
  const count = await GroupMember.countDocuments({ groupId: group.groupId, status: 'active' });
  group.memberCount = count;
  await group.save();
  await GroupActivity.create({
    groupId: group.groupId, userId: new mongoose.Types.ObjectId(user.id),
    displayName: user.displayName, type: 'member_joined',
  });
};

const generateInviteCode = async () => {
  for (let i = 0; i < 8; i++) {
    const code = randomCode(6);
    const clash = await Group.exists({ inviteCode: code });
    if (!clash) return code;
  }
  return randomCode(10);
};

// ─────────────────────────────────────────────────────────────────────────
// GROUPS — CRUD / listing
// ─────────────────────────────────────────────────────────────────────────

export const getMyGroups = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const memberships = await GroupMember.find({ userId: user.id, status: 'active' })
      .sort({ createdAt: -1 }).lean();
    if (memberships.length === 0) return res.json({ success: true, data: { groups: [] } });
    const groups = await Group.find({ groupId: { $in: memberships.map((m) => m.groupId) } }).lean();
    const out = [];
    for (const g of groups) {
      const fresh = await rollForwardGroup(g);
      const gKey = todayKeyInTz(g.timezone);
      const myRow = await GroupDailyProgress.findOne({
        groupId: g.groupId, userId: new mongoose.Types.ObjectId(user.id), dateKey: gKey,
      }).lean();
      const membership = memberships.find((m) => m.groupId === g.groupId);
      const eligible = isMemberEligibleOn(membership, gKey);
      const requiredToday = await GroupMember.countDocuments({
        groupId: g.groupId, status: 'active', effectiveFromDate: { $lte: gKey },
      });
      const doneToday = await GroupDailyProgress.countDocuments({
        groupId: g.groupId, dateKey: gKey, eligible: true, isDayComplete: true,
      });
      const summaryToday = await GroupDailySummary.findOne({ groupId: g.groupId, dateKey: gKey }).select('isGroupDayComplete').lean();
      out.push({
        groupId: g.groupId,
        name: g.name,
        status: g.status,
        visibility: g.visibility,
        timezone: g.timezone,
        memberCount: g.memberCount,
        role: membership.role,
        currentStreak: fresh.currentStreak,
        bestStreak: fresh.bestStreak,
        myToday: {
          completedCount: myRow?.completedCount || 0,
          isDayComplete: !!myRow?.isDayComplete,
          eligible,
        },
        today: { required: requiredToday, completed: doneToday, isGroupDayComplete: !!summaryToday?.isGroupDayComplete },
        isOwner: String(g.ownerId) === user.id,
      });
    }
    res.json({ success: true, data: { groups: out } });
  } catch (error) {
    next(error);
  }
};

export const createGroup = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const name = String(req.body?.name || '').trim().slice(0, GROUP_NAME_MAX);
    const visibility = req.body?.visibility === 'public' ? 'public' : 'invite';
    if (name.length < 2) {
      return fail(res, 400, 'VALIDATION', 'Group name must be at least 2 characters');
    }
    const inviteCode = await generateInviteCode();
    const group = await Group.create({
      groupId: newGroupId(),
      name,
      ownerId: new mongoose.Types.ObjectId(user.id),
      inviteCode,
      visibility,
      timezone: user.timezone,
      memberCount: 1,
    });
    await addMemberToGroup(group, user, 'owner');
    await GroupActivity.create({
      groupId: group.groupId, userId: new mongoose.Types.ObjectId(user.id),
      displayName: user.displayName, type: 'group_created',
    });
    res.status(201).json({
      success: true,
      data: { groupId: group.groupId, name: group.name, inviteCode: group.inviteCode, visibility: group.visibility, timezone: group.timezone },
    });
  } catch (error) {
    next(error);
  }
};

export const getGroupDashboard = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id, { activeOnly: false });
    if (!ctx) return;
    const { group, member } = ctx;
    const fresh = await rollForwardGroup(group);
    const gKey = todayKeyInTz(group.timezone);

    const members = await GroupMember.find({ groupId, status: 'active' })
      .select('userId displayName role effectiveFromDate').lean();
    const rows = await GroupDailyProgress.find({ groupId, dateKey: gKey }).lean();
    const rowByUser = new Map(rows.map((r) => [String(r.userId), r]));
    const eligibleMembers = members.filter((m) => isMemberEligibleOn(m, gKey));
    const memberProgress = members
      .map((m) => {
        const row = rowByUser.get(String(m.userId));
        return {
          userId: String(m.userId),
          displayName: m.displayName,
          role: m.role,
          eligible: isMemberEligibleOn(m, gKey),
          completedCount: row?.completedCount || 0,
          isDayComplete: !!row?.isDayComplete,
          isMe: String(m.userId) === user.id,
        };
      })
      .sort((a, b) => (a.isDayComplete === b.isDayComplete ? b.completedCount - a.completedCount : (a.isDayComplete ? -1 : 1)));

    const required = eligibleMembers.length;
    const done = memberProgress.filter((m) => m.eligible && m.isDayComplete).length;
    const summary = await GroupDailySummary.findOne({ groupId, dateKey: gKey }).lean();

    const activity = await GroupActivity.find({ groupId })
      .sort({ createdAt: -1 }).limit(ACTIVITY_PAGE_SIZE).lean();

    res.json({
      success: true,
      data: {
        group: {
          groupId: fresh.groupId,
          name: fresh.name,
          status: fresh.status,
          visibility: fresh.visibility,
          timezone: fresh.timezone,
          memberCount: fresh.memberCount,
          inviteCode: member.status === 'active' || String(fresh.ownerId) === user.id ? fresh.inviteCode : null,
          currentStreak: fresh.currentStreak,
          bestStreak: fresh.bestStreak,
          currentStreakStartDate: fresh.currentStreakStartDate,
          isOwner: String(fresh.ownerId) === user.id,
          myRole: member.role,
          dateKey: gKey,
        },
        members: memberProgress,
        today: {
          required,
          completed: done,
          isGroupDayComplete: !!summary?.isGroupDayComplete,
        },
        activity: activity.map(activityDto),
      },
    });
  } catch (error) {
    next(error);
  }
};

const activityDto = (a) => ({
  id: a._id,
  groupId: a.groupId,
  userId: String(a.userId),
  displayName: a.displayName,
  type: a.type,
  prayer: a.prayer || null,
  dateKey: a.dateKey || null,
  createdAt: a.createdAt,
});

export const getGroupActivity = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id, { activeOnly: false });
    if (!ctx) return;
    const limit = Math.min(Number(req.query?.limit) || ACTIVITY_PAGE_SIZE, 50);
    const before = req.query?.before ? new Date(req.query.before) : null;
    const q = { groupId, ...(before ? { createdAt: { $lt: before } } : {}) };
    const items = await GroupActivity.find(q).sort({ createdAt: -1 }).limit(limit + 1).lean();
    const hasMore = items.length > limit;
    res.json({
      success: true,
      data: {
        items: items.slice(0, limit).map(activityDto),
        hasMore,
        nextCursor: hasMore ? items[limit - 1].createdAt : null,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getGroupHistory = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id, { activeOnly: false });
    if (!ctx) return;
    const { group } = ctx;
    const fresh = await rollForwardGroup(group);
    const now = new Date();
    const year = Number(req.query?.year) || now.getUTCFullYear();
    const month = Number(req.query?.month) || now.getUTCMonth() + 1;
    const todayKey = todayKeyInTz(group.timezone);
    const summaries = await GroupDailySummary.find({
      groupId,
      dateKey: { $regex: `^${year}-${String(month).padStart(2, '0')}` },
    }).select('dateKey isGroupDayComplete').lean();
    const days = new Set(summaries.filter((s) => s.isGroupDayComplete).map((s) => s.dateKey));
    const firstMember = await GroupMember.findOne({ groupId }).sort({ joinedAt: 1 }).select('effectiveFromDate').lean();
    const firstRequired = firstMember?.effectiveFromDate || null;
    const calendar = buildMonthHistory(days, year, month, firstRequired, todayKey);
    // previous streak period (run before the current one)
    res.json({
      success: true,
      data: {
        year, month, calendar,
        currentStreak: fresh.currentStreak,
        bestStreak: fresh.bestStreak,
        currentStreakStartDate: fresh.currentStreakStartDate,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ─────────────────────────────────────────────────────────────────────────
// INVITE / JOIN / DISCOVER
// ─────────────────────────────────────────────────────────────────────────

export const getInvitePreview = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const code = String(req.params?.code || '').trim().toUpperCase();
    const group = await Group.findOne({ inviteCode: code }).lean();
    if (!group || group.status !== 'active') {
      return fail(res, 404, 'INVALID_INVITE', 'This invite is invalid or the group has ended');
    }
    const fresh = await rollForwardGroup(group);
    const member = await memberOf(group.groupId, user.id);
    const request = await JoinRequest.findOne({ groupId: group.groupId, userId: new mongoose.Types.ObjectId(user.id) });
    const owner = await User.findById(group.ownerId).select('displayName').lean();
    res.json({
      success: true,
      data: {
        group: {
          groupId: fresh.groupId,
          name: fresh.name,
          currentStreak: fresh.currentStreak,
          memberCount: fresh.memberCount,
          maxMembers: GROUP_MEMBER_LIMIT_DEFAULT,
          visibility: fresh.visibility,
          timezone: fresh.timezone,
          ownerName: owner?.displayName || 'Someone',
        },
        inviteCode: group.inviteCode,
        viewerState: member?.status === 'active'
          ? 'member'
          : request?.status === 'pending'
            ? 'pending'
            : request?.status === 'declined'
              ? 'declined'
              : 'none',
      },
    });
  } catch (error) {
    next(error);
  }
};

export const joinByInviteCode = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const code = String(req.params?.code || '').trim().toUpperCase();
    const group = await Group.findOne({ inviteCode: code });
    if (!group || group.status !== 'active') {
      return fail(res, 404, 'INVALID_INVITE', 'This invite is invalid or the group has ended');
    }
    const existing = await memberOf(group.groupId, user.id);
    if (existing?.status === 'active') {
      return res.json({
        success: true,
        data: { alreadyMember: true, groupId: group.groupId, name: group.name, message: 'You are already a member of this group' },
      });
    }
    const activeCount = await GroupMember.countDocuments({ groupId: group.groupId, status: 'active' });
    if (activeCount >= GROUP_MEMBER_LIMIT_DEFAULT) {
      return fail(res, 400, 'GROUP_FULL', 'This group has reached its member limit');
    }
    await addMemberToGroup(group, user);
    // Cancel any pending request — the user is in.
    await JoinRequest.updateOne(
      { groupId: group.groupId, userId: new mongoose.Types.ObjectId(user.id), status: 'pending' },
      { $set: { status: 'cancelled' } },
    );
    res.json({
      success: true,
      data: { alreadyMember: false, groupId: group.groupId, name: group.name, message: 'Joined! Your progress counts for the group from tomorrow.' },
    });
  } catch (error) {
    next(error);
  }
};

export const discoverGroups = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const q = String(req.query?.q || '').trim();
    const page = Math.max(0, Number(req.query?.page) || 0);
    if (q.length < 2) return res.json({ success: true, data: { items: [], page, hasMore: false } });
    const search = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const [items, total] = await Promise.all([
      Group.find({ status: 'active', visibility: 'public', name: { $regex: search, $options: 'i' } })
        .sort({ memberCount: -1 })
        .skip(page * DISCOVER_PAGE_SIZE)
        .limit(DISCOVER_PAGE_SIZE + 1)
        .select('groupId name ownerId memberCount currentStreak bestStreak timezone')
        .lean(),
      Group.countDocuments({ status: 'active', visibility: 'public', name: { $regex: search, $options: 'i' } }),
    ]);
    const hasMore = items.length > DISCOVER_PAGE_SIZE;
    const mine = await GroupMember.find({ userId: user.id, status: 'active' }).select('groupId').lean();
    const myGroupIds = new Set(mine.map((m) => m.groupId));
    const ownerIds = [...new Set(items.map((g) => g.ownerId))];
    const owners = ownerIds.length
      ? await User.find({ _id: { $in: ownerIds } }).select('displayName').lean()
      : [];
    const ownerName = new Map(owners.map((o) => [String(o._id), o.displayName]));
    res.json({
      success: true,
      data: {
        page,
        hasMore,
        total,
        items: items.slice(0, DISCOVER_PAGE_SIZE).map((g) => ({
          groupId: g.groupId,
          name: g.name,
          memberCount: g.memberCount,
          currentStreak: g.currentStreak,
          ownerName: ownerName.get(String(g.ownerId)) || 'Someone',
          isMember: myGroupIds.has(g.groupId),
        })),
      },
    });
  } catch (error) {
    next(error);
  }
};

// ─────────────────────────────────────────────────────────────────────────
// JOIN REQUESTS (search flow: request → owner approves/declines)
// ─────────────────────────────────────────────────────────────────────────

export const requestToJoin = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const group = await Group.findOne({ groupId, status: 'active' });
    if (!group) return fail(res, 404, 'GROUP_NOT_FOUND', 'Group no longer exists');
    if (group.visibility !== 'public') {
      return fail(res, 403, 'INVITE_ONLY', 'This group is invite-only — ask a member for the invite code');
    }
    const member = await memberOf(groupId, user.id);
    if (member?.status === 'active') {
      return res.json({ success: true, data: { state: 'member', groupId } });
    }
    const activeCount = await GroupMember.countDocuments({ groupId, status: 'active' });
    if (activeCount >= GROUP_MEMBER_LIMIT_DEFAULT) {
      return fail(res, 400, 'GROUP_FULL', 'This group has reached its member limit');
    }
    // One row per (group,user): pending → return as-is; declined/cancelled → re-request.
    let request = await JoinRequest.findOne({ groupId, userId: new mongoose.Types.ObjectId(user.id) });
    if (!request) {
      request = await JoinRequest.create({
        groupId, userId: new mongoose.Types.ObjectId(user.id), displayName: user.displayName, status: 'pending',
      });
    } else if (request.status !== 'pending') {
      request.status = 'pending';
      request.decidedAt = null;
      request.displayName = user.displayName;
      await request.save();
    }
    res.status(201).json({ success: true, data: { state: 'pending', requestId: request._id } });
  } catch (error) {
    next(error);
  }
};

export const getMyRequests = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const items = await JoinRequest.find({ userId: new mongoose.Types.ObjectId(user.id), status: 'pending' })
      .sort({ createdAt: -1 }).lean();
    const names = items.length
      ? await Group.find({ groupId: { $in: items.map((i) => i.groupId) } }).select('groupId name').lean()
      : [];
    const nameMap = new Map(names.map((n) => [n.groupId, n.name]));
    res.json({
      success: true,
      data: {
        items: items.map((i) => ({ id: i._id, groupId: i.groupId, groupName: nameMap.get(i.groupId) || 'Group', status: i.status, createdAt: i.createdAt })),
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getGroupRequests = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id);
    if (!ctx) return;
    if (!['owner', 'admin'].includes(ctx.member.role)) {
      return fail(res, 403, 'ADMIN_ONLY', 'Only the owner or an admin can view join requests');
    }
    const items = await JoinRequest.find({ groupId, status: 'pending' }).sort({ createdAt: 1 }).lean();
    res.json({
      success: true,
      data: {
        items: items.map((i) => ({ id: i._id, userId: String(i.userId), displayName: i.displayName, createdAt: i.createdAt })),
      },
    });
  } catch (error) {
    next(error);
  }
};

const decideRequest = async (req, res, approve) => {
  const user = await resolveUser(req);
  const { requestId } = req.params;
  const request = await JoinRequest.findById(requestId);
  if (!request || request.status !== 'pending') {
    return fail(res, 404, 'REQUEST_NOT_FOUND', 'No pending request found');
  }
  const group = await Group.findOne({ groupId: request.groupId });
  if (!group || group.status !== 'active') {
    return fail(res, 404, 'GROUP_NOT_FOUND', 'Group no longer exists');
  }
  const actor = await memberOf(request.groupId, user.id);
  if (!actor || actor.status !== 'active' || !['owner', 'admin'].includes(actor.role)) {
    return fail(res, 403, 'ADMIN_ONLY', 'Only the owner or an admin can decide requests');
  }
  if (String(request.userId) === user.id) {
    return fail(res, 403, 'FORBIDDEN', 'You cannot decide your own request');
  }
  if (approve) {
    const activeCount = await GroupMember.countDocuments({ groupId: request.groupId, status: 'active' });
    if (activeCount >= GROUP_MEMBER_LIMIT_DEFAULT) {
      return fail(res, 400, 'GROUP_FULL', 'This group has reached its member limit');
    }
    const target = await User.findById(request.userId).select('displayName').lean();
    await addMemberToGroup(group, { id: String(request.userId), displayName: target?.displayName || request.displayName });
  }
  request.status = approve ? 'approved' : 'declined';
  request.decidedAt = new Date();
  await request.save();
  res.json({ success: true, data: { status: request.status } });
};

export const approveRequest = async (req, res, next) => {
  try { await decideRequest(req, res, true); } catch (e) { next(e); }
};
export const declineRequest = async (req, res, next) => {
  try { await decideRequest(req, res, false); } catch (e) { next(e); }
};

// ─────────────────────────────────────────────────────────────────────────
// GROUP MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────

export const leaveGroup = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id);
    if (!ctx) return;
    const { group, member } = ctx;
    if (member.role === 'owner') {
      return fail(res, 400, 'OWNER_MUST_TRANSFER', 'Transfer ownership or archive the group before leaving');
    }
    member.status = 'left';
    member.leftAt = new Date();
    await member.save();
    group.memberCount = await GroupMember.countDocuments({ groupId, status: 'active' });
    await group.save();
    await GroupActivity.create({
      groupId, userId: new mongoose.Types.ObjectId(user.id),
      displayName: user.displayName, type: 'member_left',
    });
    res.json({ success: true, data: { message: 'You left the group. History is preserved.' } });
  } catch (error) {
    next(error);
  }
};

export const removeMember = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId, userId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id);
    if (!ctx) return;
    const { group, member } = ctx;
    if (!['owner', 'admin'].includes(member.role)) {
      return fail(res, 403, 'ADMIN_ONLY', 'Only the owner or an admin can remove members');
    }
    const target = await memberOf(groupId, userId);
    if (!target || target.status !== 'active') {
      return fail(res, 404, 'NOT_MEMBER', 'That user is not an active member');
    }
    if (target.role === 'owner') {
      return fail(res, 403, 'FORBIDDEN', 'The owner cannot be removed');
    }
    if (String(userId) === user.id) {
      return fail(res, 400, 'USE_LEAVE', 'Use leave group instead');
    }
    target.status = 'removed';
    target.leftAt = new Date();
    await target.save();
    group.memberCount = await GroupMember.countDocuments({ groupId, status: 'active' });
    await group.save();
    await GroupActivity.create({
      groupId, userId: new mongoose.Types.ObjectId(userId),
      displayName: target.displayName, type: 'member_removed',
    });
    res.json({ success: true, data: { message: 'Member removed. History is preserved.' } });
  } catch (error) {
    next(error);
  }
};

export const renameGroup = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id);
    if (!ctx) return;
    if (!['owner', 'admin'].includes(ctx.member.role)) {
      return fail(res, 403, 'ADMIN_ONLY', 'Only the owner or an admin can rename the group');
    }
    const name = String(req.body?.name || '').trim().slice(0, GROUP_NAME_MAX);
    if (name.length < 2) return fail(res, 400, 'VALIDATION', 'Group name must be at least 2 characters');
    ctx.group.name = name; // names are display-only — duplicates allowed
    await ctx.group.save();
    res.json({ success: true, data: { name } });
  } catch (error) {
    next(error);
  }
};

export const rotateInviteCode = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id);
    if (!ctx) return;
    if (!['owner', 'admin'].includes(ctx.member.role)) {
      return fail(res, 403, 'ADMIN_ONLY', 'Only the owner or an admin can rotate the invite code');
    }
    ctx.group.inviteCode = await generateInviteCode();
    await ctx.group.save();
    res.json({ success: true, data: { inviteCode: ctx.group.inviteCode } });
  } catch (error) {
    next(error);
  }
};

export const transferOwnership = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const targetUserId = String(req.body?.userId || '');
    const ctx = await requireMembership(res, groupId, user.id);
    if (!ctx) return;
    if (ctx.member.role !== 'owner') {
      return fail(res, 403, 'OWNER_ONLY', 'Only the owner can transfer ownership');
    }
    const target = await memberOf(groupId, targetUserId);
    if (!target || target.status !== 'active') {
      return fail(res, 404, 'NOT_MEMBER', 'That user is not an active member');
    }
    if (String(targetUserId) === user.id) {
      return fail(res, 400, 'VALIDATION', 'You already own this group');
    }
    ctx.member.role = 'admin';
    await ctx.member.save();
    target.role = 'owner';
    await target.save();
    ctx.group.ownerId = new mongoose.Types.ObjectId(targetUserId);
    await ctx.group.save();
    await GroupActivity.create({
      groupId, userId: new mongoose.Types.ObjectId(targetUserId),
      displayName: target.displayName, type: 'ownership_transferred',
    });
    res.json({ success: true, data: { message: 'Ownership transferred' } });
  } catch (error) {
    next(error);
  }
};

export const archiveGroup = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { groupId } = req.params;
    const ctx = await requireMembership(res, groupId, user.id);
    if (!ctx) return;
    if (ctx.member.role !== 'owner') {
      return fail(res, 403, 'OWNER_ONLY', 'Only the owner can archive the group');
    }
    if (ctx.group.status === 'archived') {
      return res.json({ success: true, data: { message: 'Group already archived' } });
    }
    ctx.group.status = 'archived';
    ctx.group.archivedAt = new Date();
    await ctx.group.save();
    await GroupActivity.create({
      groupId, userId: new mongoose.Types.ObjectId(user.id),
      displayName: user.displayName, type: 'group_archived',
    });
    res.json({ success: true, data: { message: 'Group archived. Full history is preserved.' } });
  } catch (error) {
    next(error);
  }
};

// ─────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS (in-app feed; FCM-ready — streak never depends on them)
// ─────────────────────────────────────────────────────────────────────────

export const getNotifications = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const me = await User.findById(user.id).select('notificationsSeenAt').lean();
    const seenAt = me?.notificationsSeenAt || new Date(0);
    const memberships = await GroupMember.find({ userId: user.id, status: 'active' }).select('groupId').lean();
    const groupIds = memberships.map((m) => m.groupId);
    if (groupIds.length === 0) return res.json({ success: true, data: { items: [], unread: 0 } });
    const groups = await Group.find({ groupId: { $in: groupIds } }).select('groupId name').lean();
    const nameMap = new Map(groups.map((g) => [g.groupId, g.name]));
    const items = await GroupActivity.find({
      groupId: { $in: groupIds },
      userId: { $ne: new mongoose.Types.ObjectId(user.id) }, // never your own actions
      type: { $in: ['prayer_completed', 'group_day_completed', 'member_joined', 'member_left', 'member_removed'] },
    })
      .sort({ createdAt: -1 })
      .limit(30)
      .lean();
    const unread = await GroupActivity.countDocuments({
      groupId: { $in: groupIds },
      userId: { $ne: new mongoose.Types.ObjectId(user.id) },
      type: { $in: ['prayer_completed', 'group_day_completed', 'member_joined', 'member_left', 'member_removed'] },
      createdAt: { $gt: seenAt },
    });
    res.json({
      success: true,
      data: {
        unread,
        items: items.map((a) => ({ ...activityDto(a), groupName: nameMap.get(a.groupId) || '' })),
      },
    });
  } catch (error) {
    next(error);
  }
};

export const markNotificationsSeen = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    await User.updateOne({ _id: user.id }, { $set: { notificationsSeenAt: new Date() } });
    res.json({ success: true, data: { seen: true } });
  } catch (error) {
    next(error);
  }
};

export const registerDevice = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const token = String(req.body?.token || '').trim();
    if (!token) return fail(res, 400, 'VALIDATION', 'Token is required');
    await PushToken.updateOne(
      { userId: new mongoose.Types.ObjectId(user.id), token },
      { $set: { platform: req.body?.platform || 'android' } },
      { upsert: true },
    );
    res.json({ success: true, data: { registered: true } });
  } catch (error) {
    next(error);
  }
};
