import Streak from '../models/Streak.js';
import SharedStreak from '../models/SharedStreak.js';
import StreakMember from '../models/StreakMember.js';
import PrayerCompletion from '../models/PrayerCompletion.js';
import User from '../models/User.js';
import { v4 as uuidv4 } from 'uuid';
import {
  PRAYERS,
  todayKeyInTz,
  dateKeyOfInstant,
  previousDateKey,
  computeStreaks,
  normalizePrayerName,
  isValidPrayer,
} from '../services/streakLogic.js';

// ============================================
// HELPERS
// ============================================

// Every error carries a machine-readable `code` so clients never have to
// parse human-readable strings to decide what UI to show.
const fail = (res, status, code, message) =>
  res.status(status).json({ success: false, code, message });

// The JWT may be up to 30 days old; always prefer the fresh DB profile for
// displayName/timezone so streak day-keying agrees with the client.
const resolveUser = async (req) => {
  const id = String(req.user?.id || req.user?._id);
  let displayName = req.user?.displayName || req.user?.name || 'Anonymous';
  let timezone = req.user?.timezone || 'Asia/Karachi';
  try {
    const u = await User.findById(id).select('displayName timezone').lean();
    if (u) {
      if (u.displayName) displayName = u.displayName;
      if (u.timezone) timezone = u.timezone;
    }
  } catch (_) { /* fall back to token claims */ }
  return { id, displayName, timezone };
};

const emptyProgress = () => ({
  fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false,
});

const progressOf = (completion) => (completion ? {
  fajr: !!completion.fajr,
  dhuhr: !!completion.dhuhr,
  asr: !!completion.asr,
  maghrib: !!completion.maghrib,
  isha: !!completion.isha,
} : emptyProgress());

const streakSummary = (streak) => ({
  id: streak._id,
  goalDays: streak.goalDays,
  currentDay: streak.currentDay,
  currentStreak: streak.currentStreak,
  longestStreak: streak.longestStreak,
  startDate: streak.startDate,
  endDate: streak.endDate,
  status: streak.status,
  isShared: streak.isShared,
  sharedStreakId: streak.sharedStreakId,
  lastCompletedDate: streak.lastCompletedDate,
});

const sharedSummary = (shared, { inviteCode = undefined, creatorName = null } = {}) => {
  const out = {
    id: shared._id,
    title: shared.title,
    goalDays: shared.goalDays,
    currentDay: shared.currentDay,
    startDate: shared.startDate,
    endDate: shared.endDate,
    status: shared.status,
    maxMembers: shared.maxMembers,
    isRevoked: shared.isRevoked,
    creatorName,
  };
  if (inviteCode !== undefined) out.inviteCode = inviteCode;
  return out;
};

// ============================================
// PERSONAL STREAK ENDPOINTS
// ============================================

export const getMyStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { id: userId, timezone } = user;

    let streak = await Streak.findOne({ userId, status: { $in: ['active', 'paused'] } })
      .sort({ createdAt: -1 });

    // ── Membership self-heal ──────────────────────────────────────────
    // The user may have an ACTIVE membership whose linked personal streak
    // is missing or ended (reinstall, new build, earlier goal completion).
    // Never strand a member: reactivate their old streak (history and
    // startDate preserved) or recreate it from the membership progress.
    if (!streak) {
      const membership = await StreakMember.findOne({ userId, status: 'active' })
        .sort({ joinedAt: -1 });
      if (membership) {
        const shared = await SharedStreak.findById(membership.streakId);
        if (shared && shared.status === 'active' && !shared.isRevoked) {
          const previous = await Streak.findOne({ userId, sharedStreakId: shared._id })
            .sort({ createdAt: -1 });
          if (previous && previous.currentDay < shared.goalDays) {
            // Reactivate the SAME document — history survives untouched.
            previous.status = 'active';
            previous.goalDays = shared.goalDays;
            const end = new Date(previous.startDate);
            end.setDate(end.getDate() + shared.goalDays);
            previous.endDate = end;
            await previous.save();
            streak = previous;
          } else if (!previous) {
            const startDate = new Date();
            const endDate = new Date();
            endDate.setDate(endDate.getDate() + shared.goalDays);
            streak = await Streak.create({
              userId,
              goalDays: shared.goalDays,
              startDate,
              endDate,
              status: 'active',
              isShared: true,
              sharedStreakId: shared._id,
              currentDay: Math.min(membership.currentDay || 0, shared.goalDays),
            });
          }
          // If a previous streak exists and its goal is already reached,
          // leave it in its ended state — history stays honest.
        }
      }
    }

    if (!streak) {
      return res.json({
        success: true,
        data: {
          streak: null,
          todayProgress: emptyProgress(),
          stats: { currentStreak: 0, longestStreak: 0, completionRate: 0 },
        },
      });
    }

    const today = todayKeyInTz(timezone);
    const todayCompletion = await PrayerCompletion.findOne({ userId, date: today }).lean();

    // Authoritative streak math from the date-keyed completion history.
    // The current run never counts days recorded before this streak began.
    const completions = await PrayerCompletion.find({ userId }).select('date isComplete').lean();
    const sinceKey = streak.startDate ? dateKeyOfInstant(new Date(streak.startDate), timezone) : null;
    const { currentStreak, longestStreak } = computeStreaks(completions, today, sinceKey);

    if (streak.currentStreak !== currentStreak || streak.longestStreak !== longestStreak) {
      streak.currentStreak = currentStreak;
      streak.longestStreak = Math.max(streak.longestStreak || 0, longestStreak);
      await streak.save();
    }

    const totalDays = streak.streakHistory?.length || 0;
    const completedDays = streak.streakHistory?.filter((d) => d.isComplete).length || 0;
    const completionRate = totalDays > 0 ? Math.round((completedDays / totalDays) * 100) : 0;

    res.json({
      success: true,
      data: {
        streak: streakSummary(streak),
        todayProgress: progressOf(todayCompletion),
        stats: { currentStreak, longestStreak, completionRate },
      },
    });
  } catch (error) {
    next(error);
  }
};

export const createPersonalStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { goalDays } = req.body || {};

    const target = Number.parseInt(goalDays, 10);
    if (!Number.isInteger(target) || target < 3 || target > 365) {
      return fail(res, 400, 'VALIDATION', 'Goal days must be between 3 and 365');
    }

    const existing = await Streak.findOne({ userId: user.id, status: { $in: ['active', 'paused'] } });
    if (existing) {
      return fail(res, 400, 'HAVE_ACTIVE_STREAK', 'You already have an active streak. Complete, cancel or leave it first.');
    }

    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + target);

    const streak = await Streak.create({ userId: user.id, goalDays: target, startDate, endDate, status: 'active' });
    res.status(201).json({ success: true, data: { streak: streakSummary(streak) } });
  } catch (error) {
    next(error);
  }
};

const DATE_KEY_RE = /^\d{4}-\d{2}-\d{2}$/;

// Marks one prayer for one date-key. Idempotent and race-safe: the prayer
// flag is set with an ATOMIC update (no read-modify-write), and `isComplete`
// is only flipped true when all five flags are true at write time.
const markPrayerComplete = async (userId, rawPrayer, completed, timezone, date) => {
  const prayer = normalizePrayerName(rawPrayer);
  if (!PRAYERS.includes(prayer)) throw Object.assign(new Error('Invalid prayer name'), { code: 'INVALID_PRAYER' });

  const tz = timezone || 'Asia/Karachi';
  const targetDate = date && DATE_KEY_RE.test(date) ? date : todayKeyInTz(tz);

  const update = { $set: { [prayer]: !!completed, timezone: tz } };
  if (completed) update.$set[`completedAt.${prayer}`] = new Date();
  else update.$unset = { [`completedAt.${prayer}`]: '' };

  // Upsert race (two devices completing prayers at the same instant) can hit
  // the unique (userId, date) index — retry once as an update.
  let doc;
  for (let attempt = 0; ; attempt++) {
    try {
      doc = await PrayerCompletion.findOneAndUpdate(
        { userId, date: targetDate },
        update,
        { upsert: true, new: true, setDefaultsOnInsert: true },
      );
      break;
    } catch (e) {
      if (e.code === 11000 && attempt === 0) continue;
      throw e;
    }
  }

  if (completed) {
    // Flip complete ONLY when all five are true in the same write — two
    // concurrent prayer taps can never clobber each other's flag.
    await PrayerCompletion.updateOne(
      { _id: doc._id, fajr: true, dhuhr: true, asr: true, maghrib: true, isha: true, isComplete: { $ne: true } },
      { $set: { isComplete: true } },
    );
  } else {
    await PrayerCompletion.updateOne(
      { _id: doc._id, isComplete: true },
      { $set: { isComplete: false } },
    );
  }

  const fresh = await PrayerCompletion.findById(doc._id);
  if (targetDate === todayKeyInTz(tz)) {
    await updateStreakProgress(userId, tz);
  }
  return fresh;
};

export const confirmPrayerFromNotification = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { prayer } = req.body || {};
    if (!prayer) return fail(res, 400, 'VALIDATION', 'Prayer is required');
    const completion = await markPrayerComplete(user.id, prayer, true, user.timezone);
    res.json({ success: true, message: 'Prayer marked as complete', data: { completion } });
  } catch (error) {
    if (error.code === 'INVALID_PRAYER') return fail(res, 400, 'INVALID_PRAYER', 'Invalid prayer name');
    next(error);
  }
};

export const updatePrayerCompletion = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { prayer, completed, date, timezone } = req.body || {};
    if (!prayer) return fail(res, 400, 'VALIDATION', 'Prayer is required');
    if (date && !DATE_KEY_RE.test(date)) return fail(res, 400, 'VALIDATION', 'Date must be YYYY-MM-DD');
    try {
      const completion = await markPrayerComplete(user.id, prayer, !!completed, timezone || user.timezone, date);
      res.json({ success: true, data: { completion } });
    } catch (e) {
      if (e.code === 'INVALID_PRAYER') return fail(res, 400, 'INVALID_PRAYER', 'Invalid prayer name');
      throw e;
    }
  } catch (error) {
    next(error);
  }
};

// The ONE authoritative rule for streak growth:
// a day is counted ONLY when all 5 prayers of that calendar day are complete
// AND the day was not already counted. Nothing else increments a streak.
const updateStreakProgress = async (userId, timezone) => {
  const today = todayKeyInTz(timezone);
  const completion = await PrayerCompletion.findOne({ userId, date: today });
  if (!completion || !completion.isComplete) return;

  const streak = await Streak.findOne({ userId, status: { $in: ['active', 'paused'] } });
  if (!streak) return;

  const alreadyCounted = streak.streakHistory?.some((d) => d.date === today && d.isComplete);
  if (alreadyCounted) return;

  streak.currentDay = (streak.currentDay || 0) + 1;
  streak.lastCompletedDate = today;
  streak.streakHistory = streak.streakHistory || [];
  streak.streakHistory.push({ date: today, isComplete: true, prayerCounts: 5 });

  // Keep the consecutive count in sync with the completion history.
  const completions = await PrayerCompletion.find({ userId }).select('date isComplete').lean();
  const sinceKey = streak.startDate ? dateKeyOfInstant(new Date(streak.startDate), timezone) : null;
  const { currentStreak, longestStreak } = computeStreaks(completions, today, sinceKey);
  streak.currentStreak = currentStreak;
  streak.longestStreak = Math.max(streak.longestStreak || 0, longestStreak);

  if (streak.currentDay >= streak.goalDays) {
    streak.status = 'completed';
    streak.endDate = new Date();
  }
  await streak.save();

  if (streak.isShared && streak.sharedStreakId) {
    const member = await StreakMember.findOneAndUpdate(
      { streakId: streak.sharedStreakId, userId },
      { $inc: { currentDay: 1 }, lastCompletedDate: today },
      { new: true },
    );
    // Group day = the furthest any member has reached (not a sum).
    if (member) {
      await SharedStreak.updateOne(
        { _id: streak.sharedStreakId, currentDay: { $lt: member.currentDay } },
        { $set: { currentDay: member.currentDay } },
      );
    }
  }
};

export const pauseStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const streak = await Streak.findOne({ userId: user.id, status: 'active' });
    if (!streak) return fail(res, 404, 'NO_ACTIVE_STREAK', 'No active streak found');
    streak.status = 'paused';
    await streak.save();
    res.json({ success: true, data: { streak: streakSummary(streak) } });
  } catch (error) {
    next(error);
  }
};

export const resumeStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const streak = await Streak.findOne({ userId: user.id, status: 'paused' });
    if (!streak) return fail(res, 404, 'NO_PAUSED_STREAK', 'No paused streak found');
    streak.status = 'active';
    await streak.save();
    res.json({ success: true, data: { streak: streakSummary(streak) } });
  } catch (error) {
    next(error);
  }
};

// Increase the target WITHOUT resetting progress. For shared streaks only
// the creator may change the group target; every member's personal target
// is updated to match.
export const extendStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { goalDays } = req.body || {};
    const target = Number.parseInt(goalDays, 10);
    if (!Number.isInteger(target) || target < 3 || target > 365) {
      return fail(res, 400, 'VALIDATION', 'Goal days must be between 3 and 365');
    }

    const streak = await Streak.findOne({ userId: user.id, status: { $in: ['active', 'paused'] } });
    if (!streak) return fail(res, 404, 'NO_ACTIVE_STREAK', 'No active streak found');
    if (target <= streak.goalDays) {
      return fail(res, 400, 'TARGET_NOT_LARGER', 'New target must be greater than the current target');
    }

    if (streak.isShared && streak.sharedStreakId) {
      const shared = await SharedStreak.findById(streak.sharedStreakId);
      if (!shared) return fail(res, 404, 'NOT_FOUND', 'Shared streak not found');
      if (String(shared.creatorId) !== user.id) {
        return fail(res, 403, 'OWNER_ONLY', 'Only the streak creator can change the group target');
      }
      shared.goalDays = target;
      const sharedEnd = new Date(shared.startDate);
      sharedEnd.setDate(sharedEnd.getDate() + target);
      shared.endDate = sharedEnd;
      await shared.save();

      const memberStreaks = await Streak.find({ sharedStreakId: shared._id, status: { $in: ['active', 'paused'] } });
      for (const m of memberStreaks) {
        m.goalDays = target;
        const end = new Date(m.startDate);
        end.setDate(end.getDate() + target);
        m.endDate = end;
        await m.save();
      }
    } else {
      streak.goalDays = target;
      const end = new Date(streak.startDate);
      end.setDate(end.getDate() + target);
      streak.endDate = end;
      await streak.save();
    }

    const updated = await Streak.findById(streak._id);
    res.json({ success: true, data: { streak: streakSummary(updated) } });
  } catch (error) {
    next(error);
  }
};

// Cancel (abandon) the current personal streak. History is PRESERVED — the
// streak is moved to 'cancelled' and appears in past streaks. For a shared
// streak only the creator may cancel (it ends for everyone via the same
// path as end); members must use leave instead.
export const cancelStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const streak = await Streak.findOne({ userId: user.id, status: { $in: ['active', 'paused'] } });
    if (!streak) return fail(res, 404, 'NO_ACTIVE_STREAK', 'No active streak found');

    if (streak.isShared && streak.sharedStreakId) {
      const shared = await SharedStreak.findById(streak.sharedStreakId);
      if (shared && String(shared.creatorId) !== user.id) {
        return fail(res, 403, 'OWNER_ONLY', 'Only the creator can end this group streak. You can leave instead.');
      }
      if (shared) {
        await endSharedStreakDocument(shared);
        return res.json({ success: true, data: { message: 'Group streak ended for all members', streak: streakSummary(await Streak.findById(streak._id)) } });
      }
    }

    streak.status = 'cancelled';
    streak.endDate = new Date();
    await streak.save();
    res.json({ success: true, data: { streak: streakSummary(streak) } });
  } catch (error) {
    next(error);
  }
};

export const getStreakHistory = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const streak = await Streak.findOne({ userId: user.id }).sort({ createdAt: -1 });
    res.json({ success: true, data: { history: streak?.streakHistory || [] } });
  } catch (error) {
    next(error);
  }
};

// Past (ended) streaks — history is never deleted, so users can always see
// completed / expired / cancelled streaks alongside their current one.
export const getPastStreaks = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const past = await Streak.find({ userId: user.id, status: { $in: ['completed', 'expired', 'cancelled'] } })
      .sort({ createdAt: -1 })
      .select('goalDays currentDay currentStreak longestStreak startDate endDate status isShared sharedStreakId')
      .lean();
    res.json({ success: true, data: { streaks: past } });
  } catch (error) {
    next(error);
  }
};

export const getStreakCalendar = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { year, month } = req.query; // month 1-12

    const completions = await PrayerCompletion.find({ userId }).sort({ date: 1 }).lean();

    let filtered = completions;
    if (year && month) {
      const start = `${year}-${String(month).padStart(2, '0')}-01`;
      const lastDay = new Date(Date.UTC(Number(year), Number(month), 0)).getUTCDate();
      const end = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
      filtered = completions.filter((c) => c.date >= start && c.date <= end);
    }

    res.json({ success: true, data: { calendar: filtered } });
  } catch (error) {
    next(error);
  }
};

// ============================================
// SHARED STREAK ENDPOINTS
// ============================================

export const createSharedStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { goalDays, title } = req.body || {};

    const target = Number.parseInt(goalDays, 10);
    if (!Number.isInteger(target) || target < 3 || target > 365) {
      return fail(res, 400, 'VALIDATION', 'Goal days must be between 3 and 365');
    }
    const cleanTitle = (title || '').toString().trim().slice(0, 60);

    // Validate BEFORE creating anything — a failure must never leave orphan
    // SharedStreak / StreakMember records behind.
    const existing = await Streak.findOne({ userId: user.id, status: { $in: ['active', 'paused'] } });
    if (existing) {
      return fail(res, 400, 'HAVE_ACTIVE_STREAK', 'You already have an active streak. Complete, cancel or leave it first.');
    }

    const inviteCode = uuidv4().slice(0, 8).toUpperCase();

    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + target);

    const sharedStreak = await SharedStreak.create({
      creatorId: user.id,
      title: cleanTitle || `${target}-Day Salah Streak`,
      goalDays: target,
      startDate,
      endDate,
      status: 'active',
      inviteCode,
    });

    await StreakMember.create({
      streakId: sharedStreak._id,
      userId: user.id,
      displayName: user.displayName,
      status: 'active',
    });

    const personalStreak = await Streak.create({
      userId: user.id,
      goalDays: target,
      startDate,
      endDate,
      status: 'active',
      isShared: true,
      sharedStreakId: sharedStreak._id,
    });

    res.status(201).json({
      success: true,
      data: {
        sharedStreak: sharedSummary(sharedStreak, { inviteCode, creatorName: user.displayName }),
        personalStreakId: personalStreak._id,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getSharedStreak = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await resolveUser(req);

    const shared = await SharedStreak.findById(id).populate('creatorId', 'displayName name');
    if (!shared) return fail(res, 404, 'NOT_FOUND', 'Streak not found');

    const members = await StreakMember.find({ streakId: id, status: 'active' })
      .select('displayName userId currentDay lastCompletedDate')
      .lean();

    const isMember = members.some((m) => String(m.userId) === user.id);
    const isCreator = String(shared.creatorId._id || shared.creatorId) === user.id;
    const creatorName = shared.creatorId?.displayName || shared.creatorId?.name || 'Someone';

    res.json({
      success: true,
      data: {
        sharedStreak: sharedSummary(shared, {
          inviteCode: isMember || isCreator ? shared.inviteCode : undefined,
          creatorName,
        }),
        members: members.map((m) => ({
          id: m._id,
          userId: m.userId, // needed by clients to highlight "You"
          displayName: m.displayName,
          currentDay: m.currentDay,
          lastCompletedDate: m.lastCompletedDate,
          isCurrentUser: String(m.userId) === user.id,
        })),
        isMember,
        isCreator,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Ensures the user has a usable personal streak linked to a shared streak.
// Reactivates their previous streak (history preserved) or creates one.
// Returns null when blocked by another active streak.
const ensureLinkedPersonalStreak = async (user, sharedStreak, membership) => {
  const existing = await Streak.findOne({
    userId: user.id, sharedStreakId: sharedStreak._id, status: { $in: ['active', 'paused'] },
  });
  if (existing) return existing;

  const previous = await Streak.findOne({ userId: user.id, sharedStreakId: sharedStreak._id })
    .sort({ createdAt: -1 });
  if (previous) {
    if (previous.currentDay < sharedStreak.goalDays) {
      previous.status = 'active';
      previous.goalDays = sharedStreak.goalDays;
      const end = new Date(previous.startDate);
      end.setDate(end.getDate() + sharedStreak.goalDays);
      previous.endDate = end;
      await previous.save();
      return previous;
    }
    return previous; // goal already reached — stays ended, history intact
  }

  const other = await Streak.findOne({
    userId: user.id,
    status: { $in: ['active', 'paused'] },
    sharedStreakId: { $ne: sharedStreak._id },
  });
  if (other) return null;

  const startDate = new Date();
  const endDate = new Date();
  endDate.setDate(endDate.getDate() + sharedStreak.goalDays);
  return Streak.create({
    userId: user.id,
    goalDays: sharedStreak.goalDays,
    startDate,
    endDate,
    status: 'active',
    isShared: true,
    sharedStreakId: sharedStreak._id,
    currentDay: Math.min(membership?.currentDay || 0, sharedStreak.goalDays),
  });
};

export const joinSharedStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const code = String(req.body?.inviteCode || '').trim().toUpperCase();
    if (!code) return fail(res, 400, 'VALIDATION', 'Invite code is required');

    const sharedStreak = await SharedStreak.findOne({ inviteCode: code, isRevoked: false });
    if (!sharedStreak) {
      return fail(res, 404, 'INVALID_INVITE', 'Invalid or expired invite code');
    }

    const membership = await StreakMember.findOne({ streakId: sharedStreak._id, userId: user.id });
    const memberCount = await StreakMember.countDocuments({ streakId: sharedStreak._id, status: 'active' });
    const isCreator = String(sharedStreak.creatorId) === user.id;

    const payload = (alreadyMember, message) => ({
      success: true,
      data: {
        alreadyMember,
        sharedStreak: sharedSummary(sharedStreak, {
          inviteCode: sharedStreak.inviteCode,
          creatorName: user.displayName,
        }),
        memberCount,
        message,
      },
    });

    // ── Already an ACTIVE member: idempotent success, never an error. ──
    if (membership && membership.status === 'active') {
      await ensureLinkedPersonalStreak(user, sharedStreak, membership);
      return res.json(payload(true, 'You are already a member of this streak'));
    }

    if (sharedStreak.status !== 'active') {
      return fail(res, 400, 'STREAK_NOT_ACTIVE', 'This streak is no longer active');
    }

    // ── (Re)joining: validate everything BEFORE mutating any record. ──
    const otherStreak = await Streak.findOne({ userId: user.id, status: { $in: ['active', 'paused'] } });
    if (otherStreak && String(otherStreak.sharedStreakId) !== String(sharedStreak._id)) {
      return fail(res, 400, 'HAVE_ACTIVE_STREAK', 'You already have an active streak. Complete, cancel or leave it first.');
    }

    if (membership) {
      // Rejoining after leaving — membership record is reused, progress kept.
      membership.status = 'active';
      membership.displayName = user.displayName;
      await membership.save();
    } else {
      if (memberCount >= sharedStreak.maxMembers) {
        return fail(res, 400, 'STREAK_FULL', 'This streak has reached its member limit');
      }
      try {
        await StreakMember.create({
          streakId: sharedStreak._id,
          userId: user.id,
          displayName: user.displayName,
        });
      } catch (e) {
        if (e.code === 11000) {
          // Lost a race against a simultaneous join — treat as joined.
          await StreakMember.updateOne(
            { streakId: sharedStreak._id, userId: user.id },
            { $set: { status: 'active', displayName: user.displayName } },
          );
        } else {
          throw e;
        }
      }
    }

    // Reactivate or create the linked personal streak — PROGRESS AND
    // HISTORY ARE NEVER RESET on rejoin.
    await ensureLinkedPersonalStreak(user, sharedStreak, membership);

    res.json(payload(false, 'Successfully joined the streak!'));
  } catch (error) {
    next(error);
  }
};

export const leaveSharedStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { id } = req.params;

    const member = await StreakMember.findOne({ streakId: id, userId: user.id });
    if (!member || member.status !== 'active') {
      return fail(res, 404, 'NOT_MEMBER', 'You are not an active member of this streak');
    }

    member.status = 'left';
    await member.save();

    // End the personal view of this streak — history preserved.
    const personalStreak = await Streak.findOne({ userId: user.id, sharedStreakId: id, status: { $in: ['active', 'paused'] } });
    if (personalStreak) {
      personalStreak.status = 'expired';
      personalStreak.endDate = new Date();
      await personalStreak.save();
    }

    res.json({ success: true, data: { message: 'Left the streak' } });
  } catch (error) {
    next(error);
  }
};

// Ends a shared streak document for EVERYONE (creator only). All members'
// personal streaks are expired (history preserved) and memberships closed.
const endSharedStreakDocument = async (shared) => {
  shared.status = 'cancelled';
  shared.endDate = new Date();
  await shared.save();

  const members = await StreakMember.find({ streakId: shared._id, status: 'active' });
  for (const m of members) {
    m.status = 'left';
    await m.save();
  }

  await Streak.updateMany(
    { sharedStreakId: shared._id, status: { $in: ['active', 'paused'] } },
    { $set: { status: 'expired', endDate: new Date() } },
  );
};

export const endSharedStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { id } = req.params;

    const shared = await SharedStreak.findById(id);
    if (!shared) return fail(res, 404, 'NOT_FOUND', 'Streak not found');
    if (String(shared.creatorId) !== user.id) {
      return fail(res, 403, 'OWNER_ONLY', 'Only the streak creator can end this streak');
    }
    if (shared.status === 'cancelled') {
      return res.json({ success: true, data: { message: 'Streak already ended' } });
    }

    await endSharedStreakDocument(shared);
    res.json({ success: true, data: { message: 'Streak ended for all members' } });
  } catch (error) {
    next(error);
  }
};

// Invite lookup — viewer-aware so the client can render the correct state
// BEFORE joining: joinable / already a member / previously left / ended /
// full. Errors carry `code`; successes describe the streak + viewer state.
export const getSharedStreakInvite = async (req, res, next) => {
  try {
    const { code } = req.params;
    const user = await resolveUser(req);

    const sharedStreak = await SharedStreak.findOne({
      inviteCode: String(code || '').trim().toUpperCase(),
      isRevoked: false,
    }).populate('creatorId', 'displayName name');

    if (!sharedStreak) {
      return fail(res, 404, 'INVALID_INVITE', 'Invalid or expired invite code');
    }

    const creatorName = sharedStreak.creatorId?.displayName || sharedStreak.creatorId?.name || 'Someone';
    const memberCount = await StreakMember.countDocuments({
      streakId: sharedStreak._id,
      status: 'active',
    });

    const membership = await StreakMember.findOne({ streakId: sharedStreak._id, userId: user.id });
    const viewerMembership = !membership ? null : membership.status; // 'active' | 'left' | 'removed'
    const isCreator = String(sharedStreak.creatorId._id || sharedStreak.creatorId) === user.id;

    let joinable = sharedStreak.status === 'active';
    let reason = null;
    if (sharedStreak.status !== 'active') {
      reason = 'STREAK_NOT_ACTIVE';
      joinable = false;
    } else if (viewerMembership === 'active') {
      reason = 'ALREADY_MEMBER';
      joinable = false;
    } else if (memberCount >= sharedStreak.maxMembers) {
      reason = 'STREAK_FULL';
      joinable = false;
    }

    res.json({
      success: true,
      data: {
        sharedStreak: {
          id: sharedStreak._id,
          title: sharedStreak.title,
          goalDays: sharedStreak.goalDays,
          currentDay: sharedStreak.currentDay,
          startDate: sharedStreak.startDate,
          endDate: sharedStreak.endDate,
          status: sharedStreak.status,
          creatorName,
          memberCount,
          maxMembers: sharedStreak.maxMembers,
        },
        inviteCode: sharedStreak.inviteCode,
        viewerMembership,
        isCreator,
        joinable,
        reason,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const revokeInvite = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { id } = req.params;

    const sharedStreak = await SharedStreak.findById(id);
    if (!sharedStreak) return fail(res, 404, 'NOT_FOUND', 'Streak not found');
    if (String(sharedStreak.creatorId) !== user.id) {
      return fail(res, 403, 'OWNER_ONLY', 'Only the creator can revoke invites');
    }

    sharedStreak.isRevoked = true;
    sharedStreak.inviteCode = uuidv4().slice(0, 8).toUpperCase(); // rotate code
    await sharedStreak.save();

    res.json({ success: true, data: { inviteCode: sharedStreak.inviteCode } });
  } catch (error) {
    next(error);
  }
};

export const shareStreak = async (req, res, next) => {
  try {
    const user = await resolveUser(req);
    const { id } = req.params;

    const sharedStreak = await SharedStreak.findById(id).populate('creatorId', 'displayName name');
    if (!sharedStreak) return fail(res, 404, 'NOT_FOUND', 'Streak not found');

    const member = await StreakMember.findOne({ streakId: id, userId: user.id, status: 'active' });
    const isCreator = String(sharedStreak.creatorId._id || sharedStreak.creatorId) === user.id;
    if (!member && !isCreator) {
      return fail(res, 403, 'NOT_MEMBER', 'You are not a member of this streak');
    }

    const creatorName = sharedStreak.creatorId?.displayName || sharedStreak.creatorId?.name || 'Someone';
    const inviteUrl = process.env.APP_URL || 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';

    res.json({
      success: true,
      data: {
        inviteCode: sharedStreak.inviteCode,
        inviteUrl,
        shareText: `${creatorName} invited you to join a ${sharedStreak.goalDays}-Day Salah Streak. Pray together and stay consistent! Use invite code: ${sharedStreak.inviteCode}`,
      },
    });
  } catch (error) {
    next(error);
  }
};
