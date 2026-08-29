import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import { v4 as uuidv4 } from 'uuid';
import { getJwtSecret } from '../middleware/auth.js';

const JWT_EXPIRY = '30d';

const generateToken = (user) => {
  return jwt.sign(
    { id: user._id, displayName: user.displayName, timezone: user.timezone },
    getJwtSecret(),
    { expiresIn: JWT_EXPIRY }
  );
};

export const register = async (req, res, next) => {
  try {
    const { displayName, deviceId } = req.body;

    if (!displayName || displayName.trim().length < 1) {
      return res.status(400).json({ success: false, message: 'Display name is required' });
    }

    let user;
    if (deviceId) {
      user = await User.findOne({ deviceId });
      if (user) {
        user.displayName = displayName.trim();
        await user.save();
        const token = generateToken(user);
        return res.status(200).json({ success: true, data: { user, token, isNew: false } });
      }
    }

    user = new User({
      displayName: displayName.trim(),
      deviceId: deviceId || uuidv4(),
    });
    await user.save();

    const token = generateToken(user);
    res.status(201).json({ success: true, data: { user, token, isNew: true } });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'User already exists' });
    }
    next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const { deviceId } = req.body;

    if (!deviceId) {
      return res.status(400).json({ success: false, message: 'Device ID is required' });
    }

    const user = await User.findOne({ deviceId });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found. Please register first.' });
    }

    const token = generateToken(user);
    res.json({ success: true, data: { user, token, isNew: false } });
  } catch (error) {
    next(error);
  }
};

export const getProfile = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const user = await User.findById(userId).select('-__v');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, data: { user } });
  } catch (error) {
    next(error);
  }
};

export const deleteAccount = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const deviceId = user.deviceId;

    await user.deleteOne();

    const Streak = (await import('../models/Streak.js')).default;
    const SharedStreak = (await import('../models/SharedStreak.js')).default;
    const StreakMember = (await import('../models/StreakMember.js')).default;
    const PrayerCompletion = (await import('../models/PrayerCompletion.js')).default;

    await Promise.all([
      Streak.deleteMany({ userId }),
      SharedStreak.deleteMany({ creatorId: userId }),
      StreakMember.deleteMany({ userId }),
      PrayerCompletion.deleteMany({ userId }),
    ]);

    res.json({ success: true, message: 'Account and all associated data deleted successfully' });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const { displayName, timezone, city, country } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (displayName !== undefined) user.displayName = displayName.trim();
    if (timezone !== undefined) user.timezone = timezone;
    if (city !== undefined) user.city = city;
    if (country !== undefined) user.country = country;

    await user.save();
    res.json({ success: true, data: { user } });
  } catch (error) {
    next(error);
  }
};
