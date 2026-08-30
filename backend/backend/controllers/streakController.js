import Streak from '../models/Streak.js';
import SharedStreak from '../models/SharedStreak.js';
import StreakMember from '../models/StreakMember.js';
import PrayerCompletion from '../models/PrayerCompletion.js';
import { v4 as uuidv4 } from 'uuid';

const PRAYERS = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

// Helper to get today's date string in user's timezone
const getTodayDateString = (timezone) => {
  const now = new Date();
  const formatter = new Intl.DateTimeFormat('en-CA', { 
    timeZone: timezone, 
    year: 'numeric', 
    month: '2-digit', 
    day: '2-digit' 
  });
  return formatter.format(now);
};

// Helper to calculate streak from completions
const calculateStreak = async (userId, timezone) => {
  let currentStreak = 0;
  let longestStreak = 0;
  
  const completions = await PrayerCompletion.find({ userId })
    .sort({ date: -1 })
    .lean();
  
  if (completions.length === 0) return { currentStreak: 0, longestStreak: 0 };
  
  const today = getTodayDateString(timezone);
  const yesterday = getPreviousDate(today);
  let checkDate = today;
  
  const todayCompletion = completions.find(c => c.date === today);
  if (!todayCompletion || !todayCompletion.isComplete) {
    const yesterdayCompletion = completions.find(c => c.date === yesterday);
    if (yesterdayCompletion && yesterdayCompletion.isComplete) {
      checkDate = yesterday;
    } else {
      return { currentStreak: 0, longestStreak: 0 };
    }
  }
  
  for (const completion of completions) {
    if (completion.date === checkDate && completion.isComplete) {
      currentStreak++;
      checkDate = getPreviousDate(checkDate);
    } else if (completion.date < checkDate) {
      break;
    }
  }
  
  let tempStreak = 0;
  let prevDate = null;
  
  for (const completion of completions.reverse()) {
    if (completion.isComplete) {
      if (prevDate && getPreviousDate(prevDate) === completion.date) {
        tempStreak++;
      } else {
        tempStreak = 1;
      }
      longestStreak = Math.max(longestStreak, tempStreak);
    } else {
      tempStreak = 0;
    }
    prevDate = completion.date;
  }
  
  return { currentStreak, longestStreak };
};

const getPreviousDate = (dateStr) => {
  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year, month - 1, day);
  date.setDate(date.getDate() - 1);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
};

// ============================================
// PERSONAL STREAK ENDPOINTS
// ============================================

export const getMyStreak = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const timezone = req.user?.timezone || 'Asia/Karachi';
    
    let streak = await Streak.findOne({ userId, status: { $in: ['active', 'paused'] } })
      .sort({ createdAt: -1 });
    
    if (!streak) {
      return res.json({ 
        success: true, 
        data: { 
          streak: null,
          todayProgress: { fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false },
          stats: { currentStreak: 0, longestStreak: 0, completionRate: 0 }
        } 
      });
    }
    
    // Get today's prayer completion
    const today = getTodayDateString(timezone);
    const todayCompletion = await PrayerCompletion.findOne({ userId, date: today });
    
    // Calculate stats
    const { currentStreak, longestStreak } = await calculateStreak(userId, timezone);
    
    // Update streak document if needed
    if (streak.currentStreak !== currentStreak || streak.longestStreak !== longestStreak) {
      streak.currentStreak = currentStreak;
      streak.longestStreak = Math.max(streak.longestStreak, longestStreak);
      await streak.save();
    }
    
    const todayProgress = todayCompletion ? {
      fajr: todayCompletion.fajr,
      dhuhr: todayCompletion.dhuhr,
      asr: todayCompletion.asr,
      maghrib: todayCompletion.maghrib,
      isha: todayCompletion.isha,
    } : { fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false };
    
    const totalDays = streak.streakHistory?.length || 0;
    const completedDays = streak.streakHistory?.filter(d => d.isComplete).length || 0;
    const completionRate = totalDays > 0 ? Math.round((completedDays / totalDays) * 100) : 0;
    
    res.json({ 
      success: true, 
      data: { 
        streak: {
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
        },
        todayProgress,
        stats: { currentStreak, longestStreak, completionRate }
      } 
    });
  } catch (error) {
    next(error);
  }
};

export const createPersonalStreak = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const { goalDays } = req.body;
    
    if (!goalDays || goalDays < 3 || goalDays > 365) {
      return res.status(400).json({ success: false, message: 'Goal days must be between 3 and 365' });
    }
    
    // Check for existing active streak
    const existing = await Streak.findOne({ userId, status: { $in: ['active', 'paused'] } });
    if (existing) {
      return res.status(400).json({ success: false, message: 'You already have an active streak. Complete or pause it first.' });
    }
    
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + goalDays);
    
    const streak = new Streak({
      userId,
      goalDays,
      startDate,
      endDate,
      status: 'active',
    });
    
    await streak.save();
    
    res.status(201).json({ success: true, data: { streak } });
  } catch (error) {
    next(error);
  }
};

const markPrayerComplete = async (userId, prayer, completed, timezone, date) => {
  if (!PRAYERS.includes(prayer)) {
    throw new Error('Invalid prayer name');
  }
  const targetDate = date || getTodayDateString(timezone || 'Asia/Karachi');
  const tz = timezone || 'Asia/Karachi';
  let completion = await PrayerCompletion.findOne({ userId, date: targetDate });
  if (!completion) {
    completion = new PrayerCompletion({ userId, date: targetDate, timezone: tz, completedAt: new Map() });
  }
  completion[prayer] = completed;
  if (completed) { completion.completedAt.set(prayer, new Date()); } else { completion.completedAt.delete(prayer); }
  completion.isComplete = PRAYERS.every(p => completion[p]);
  await completion.save();
  const today = getTodayDateString(tz);
  if (targetDate === today) { await updateStreakProgress(userId, tz); }
  return completion;
};

export const confirmPrayerFromNotification = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { prayer, timezone } = req.body || {};
    if (!prayer || !timezone) {
      return res.status(400).json({ success: false, message: 'Prayer and timezone are required' });
    }
    const completion = await markPrayerComplete(userId, prayer, true, timezone);
    res.json({ success: true, message: 'Prayer marked as complete', data: { completion } });
  } catch (error) {
    next(error);
  }
};

export const updatePrayerCompletion = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const { prayer, completed, date, timezone } = req.body;
    if (!PRAYERS.includes(prayer)) {
      return res.status(400).json({ success: false, message: 'Invalid prayer name' });
    }
    const completion = await markPrayerComplete(userId, prayer, completed, timezone, date);
    res.json({ success: true, data: { completion } });
  } catch (error) {
    next(error);
  }
};

const updateStreakProgress = async (userId, timezone) => {
  const today = getTodayDateString(timezone);
  const completion = await PrayerCompletion.findOne({ userId, date: today });
  
  if (!completion || !completion.isComplete) return;
  
  let streak = await Streak.findOne({ userId, status: { $in: ['active', 'paused'] } });
  
  if (!streak) return;
  
  // Check if already counted today
  const alreadyCounted = streak.streakHistory?.some(d => d.date === today && d.isComplete);
  if (alreadyCounted) return;
  
  streak.currentDay = (streak.currentDay || 0) + 1;
  streak.currentStreak = (streak.currentStreak || 0) + 1;
  streak.longestStreak = Math.max(streak.longestStreak, streak.currentStreak);
  streak.lastCompletedDate = today;
  
  streak.streakHistory = streak.streakHistory || [];
  streak.streakHistory.push({
    date: today,
    isComplete: true,
    prayerCounts: 5
  });
  
  // Check if goal reached
  if (streak.currentDay >= streak.goalDays) {
    streak.status = 'completed';
    streak.endDate = new Date();
  }
  
  await streak.save();
  
  // If shared streak, update member progress too
  if (streak.isShared && streak.sharedStreakId) {
    await SharedStreak.findByIdAndUpdate(streak.sharedStreakId, { $inc: { currentDay: 1 } });
    await StreakMember.findOneAndUpdate(
      { streakId: streak.sharedStreakId, userId },
      { $inc: { currentDay: 1 }, lastCompletedDate: today }
    );
  }
};

export const pauseStreak = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const streak = await Streak.findOne({ userId, status: 'active' });
    
    if (!streak) {
      return res.status(404).json({ success: false, message: 'No active streak found' });
    }
    
    streak.status = 'paused';
    await streak.save();
    
    res.json({ success: true, data: { streak } });
  } catch (error) {
    next(error);
  }
};

export const resumeStreak = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const streak = await Streak.findOne({ userId, status: 'paused' });
    
    if (!streak) {
      return res.status(404).json({ success: false, message: 'No paused streak found' });
    }
    
    streak.status = 'active';
    await streak.save();
    
    res.json({ success: true, data: { streak } });
  } catch (error) {
    next(error);
  }
};

export const getStreakHistory = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const streak = await Streak.findOne({ userId }).sort({ createdAt: -1 });
    
    if (!streak) {
      return res.json({ success: true, data: { history: [] } });
    }
    
    res.json({ success: true, data: { history: streak.streakHistory || [] } });
  } catch (error) {
    next(error);
  }
};

export const getStreakCalendar = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const { year, month } = req.query; // month 1-12
    
    const completions = await PrayerCompletion.find({ userId })
      .sort({ date: 1 })
      .lean();
    
    // Filter by year/month if provided
    let filtered = completions;
    if (year && month) {
      const start = `${year}-${String(month).padStart(2, '0')}-01`;
      const endDate = new Date(year, month, 0);
      const end = `${year}-${String(month).padStart(2, '0')}-${String(endDate.getDate()).padStart(2, '0')}`;
      filtered = completions.filter(c => c.date >= start && c.date <= end);
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
    const userId = req.user?.id || req.user?._id;
    const userName = req.user?.displayName || req.user?.name || 'Anonymous';
    const { goalDays, title } = req.body;
    
    if (!goalDays || goalDays < 3 || goalDays > 365) {
      return res.status(400).json({ success: false, message: 'Goal days must be between 3 and 365' });
    }
    
    const inviteCode = uuidv4().slice(0, 8).toUpperCase();
    
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + goalDays);
    
    const sharedStreak = new SharedStreak({
      creatorId: userId,
      title: title || `${goalDays}-Day Salah Streak`,
      goalDays,
      startDate,
      endDate,
      status: 'active',
      inviteCode,
    });
    
    await sharedStreak.save();
    
    const member = new StreakMember({
      streakId: sharedStreak._id,
      userId,
      displayName: userName,
      status: 'active',
    });
    await member.save();
    
    const existingPersonal = await Streak.findOne({ userId, status: { $in: ['active', 'paused'] } });
    if (existingPersonal) {
      return res.status(400).json({ success: false, message: 'You already have an active streak. Complete or pause it first.' });
    }
    
    const personalStreak = new Streak({
      userId,
      goalDays,
      startDate,
      endDate,
      status: 'active',
      isShared: true,
      sharedStreakId: sharedStreak._id,
    });
    await personalStreak.save();
    
    res.status(201).json({ 
      success: true, 
      data: { 
        sharedStreak: {
          id: sharedStreak._id,
          title: sharedStreak.title,
          goalDays: sharedStreak.goalDays,
          currentDay: sharedStreak.currentDay,
          startDate: sharedStreak.startDate,
          endDate: sharedStreak.endDate,
          inviteCode: sharedStreak.inviteCode,
        },
        personalStreakId: personalStreak._id,
      } 
    });
  } catch (error) {
    next(error);
  }
};

export const getSharedStreak = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id || req.user?._id;
    
    const sharedStreak = await SharedStreak.findById(id);
    if (!sharedStreak) {
      return res.status(404).json({ success: false, message: 'Streak not found' });
    }
    
    const members = await StreakMember.find({ streakId: id, status: 'active' })
      .select('displayName userId currentDay lastCompletedDate')
      .lean();
    
    const isMember = members.some(m => m.userId.toString() === userId.toString());
    const isCreator = sharedStreak.creatorId.toString() === userId.toString();
    
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
          inviteCode: isMember || isCreator ? sharedStreak.inviteCode : null,
        },
        members: members.map(m => ({
          displayName: m.displayName,
          currentDay: m.currentDay,
          lastCompletedDate: m.lastCompletedDate,
          isCurrentUser: m.userId.toString() === userId.toString(),
        })),
        isMember,
        isCreator,
      } 
    });
  } catch (error) {
    next(error);
  }
};

export const joinSharedStreak = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const userName = req.user?.displayName || req.user?.name || 'Anonymous';
    const { inviteCode } = req.body;
    
    const sharedStreak = await SharedStreak.findOne({ inviteCode, isRevoked: false });
    if (!sharedStreak) {
      return res.status(404).json({ success: false, message: 'Invalid or expired invite code' });
    }
    
    if (sharedStreak.status !== 'active') {
      return res.status(400).json({ success: false, message: 'This streak is no longer active' });
    }
    
    // Check if already a member
    const existing = await StreakMember.findOne({ streakId: sharedStreak._id, userId });
    if (existing) {
      if (existing.status === 'active') {
        return res.status(400).json({ success: false, message: 'You are already a member of this streak' });
      }
      // Reactivate if left
      existing.status = 'active';
      existing.displayName = userName;
      await existing.save();
    } else {
      // Check member limit
      const memberCount = await StreakMember.countDocuments({ streakId: sharedStreak._id, status: 'active' });
      if (memberCount >= sharedStreak.maxMembers) {
        return res.status(400).json({ success: false, message: 'This streak has reached its member limit' });
      }
      
      const member = new StreakMember({
        streakId: sharedStreak._id,
        userId,
        displayName: userName,
      });
      await member.save();
    }
    
    // Check if user already has an active or paused personal streak
    const activeStreak = await Streak.findOne({ userId, status: { $in: ['active', 'paused'] } });
    if (activeStreak) {
      return res.status(400).json({ success: false, message: 'You already have an active streak. Complete or pause it first.' });
    }
    
    // Create or reactivate personal streak linked to shared
    const existingStreak = await Streak.findOne({ userId, sharedStreakId: sharedStreak._id });
    if (existingStreak) {
      if (existingStreak.status === 'expired' || existingStreak.status === 'completed') {
        existingStreak.status = 'active';
        existingStreak.startDate = new Date();
        const newEnd = new Date();
        newEnd.setDate(newEnd.getDate() + sharedStreak.goalDays);
        existingStreak.endDate = newEnd;
        existingStreak.currentDay = 0;
        existingStreak.currentStreak = 0;
        existingStreak.longestStreak = existingStreak.longestStreak;
        existingStreak.streakHistory = [];
        await existingStreak.save();
      }
    } else {
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + sharedStreak.goalDays);
      
      const streak = new Streak({
        userId,
        goalDays: sharedStreak.goalDays,
        startDate,
        endDate,
        status: 'active',
        isShared: true,
        sharedStreakId: sharedStreak._id,
      });
      await streak.save();
    }
    
    res.json({ 
      success: true, 
      data: { 
        sharedStreak: {
          id: sharedStreak._id,
          title: sharedStreak.title,
          goalDays: sharedStreak.goalDays,
        },
        message: 'Successfully joined the streak!'
      } 
    });
  } catch (error) {
    next(error);
  }
};

export const leaveSharedStreak = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const { id } = req.params;
    
    const member = await StreakMember.findOne({ streakId: id, userId });
    if (!member) {
      return res.status(404).json({ success: false, message: 'You are not a member of this streak' });
    }
    
    member.status = 'left';
    await member.save();
    
    // Update personal streak status
    const personalStreak = await Streak.findOne({ userId, sharedStreakId: id });
    if (personalStreak) {
      personalStreak.status = 'expired';
      await personalStreak.save();
    }
    
    res.json({ success: true, data: { message: 'Left the streak' } });
  } catch (error) {
    next(error);
  }
};

export const getSharedStreakInvite = async (req, res, next) => {
  try {
    const { code } = req.params;
    
    const sharedStreak = await SharedStreak.findOne({ inviteCode: code, isRevoked: false })
      .populate('creatorId', 'displayName name');
    
    if (!sharedStreak) {
      return res.status(404).json({ success: false, message: 'Invalid or expired invite code' });
    }
    
    if (sharedStreak.status !== 'active') {
      return res.status(400).json({ success: false, message: 'This streak is no longer active' });
    }
    
    const memberCount = await StreakMember.countDocuments({ 
      streakId: sharedStreak._id, 
      status: 'active' 
    });
    
    res.json({ 
      success: true, 
      data: { 
        sharedStreak: {
          id: sharedStreak._id,
          title: sharedStreak.title,
          goalDays: sharedStreak.goalDays,
          currentDay: sharedStreak.currentDay,
          creatorName: sharedStreak.creatorId?.displayName || sharedStreak.creatorId?.name || 'Someone',
          memberCount,
          maxMembers: sharedStreak.maxMembers,
        },
        inviteCode: sharedStreak.inviteCode,
      } 
    });
  } catch (error) {
    next(error);
  }
};

export const revokeInvite = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const { id } = req.params;
    
    const sharedStreak = await SharedStreak.findById(id);
    if (!sharedStreak) {
      return res.status(404).json({ success: false, message: 'Streak not found' });
    }
    
    if (sharedStreak.creatorId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Only the creator can revoke invites' });
    }
    
    sharedStreak.isRevoked = true;
    sharedStreak.inviteCode = uuidv4().slice(0, 8).toUpperCase(); // Generate new code
    await sharedStreak.save();
    
    res.json({ success: true, data: { inviteCode: sharedStreak.inviteCode } });
  } catch (error) {
    next(error);
  }
};

export const shareStreak = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const { id } = req.params;
    
    const sharedStreak = await SharedStreak.findById(id);
    if (!sharedStreak) {
      return res.status(404).json({ success: false, message: 'Streak not found' });
    }
    
    // Check if user is member
    const member = await StreakMember.findOne({ streakId: id, userId, status: 'active' });
    if (!member) {
      return res.status(403).json({ success: false, message: 'You are not a member of this streak' });
    }
    
    const inviteUrl = process.env.APP_URL || 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';
    
    res.json({ 
      success: true, 
      data: { 
        inviteCode: sharedStreak.inviteCode,
        inviteUrl,
        shareText: `${sharedStreak.creatorId?.displayName || 'Someone'} invited you to join a ${sharedStreak.goalDays}-Day Salah Streak. Pray together and stay consistent!`
      } 
    });
  } catch (error) {
    next(error);
  }
};
