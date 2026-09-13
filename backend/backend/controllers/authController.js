import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import { v4 as uuidv4 } from 'uuid';
import { getJwtSecret } from '../middleware/auth.js';
import { verifyFirebaseIdToken, FirebaseTokenError } from '../services/firebaseAuth.js';

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

/// Firebase passwordless (magic link) sign-in exchange.
///
/// Client sends the Firebase IDToken it obtained via signInWithEmailLink.
/// The server VERIFIES it cryptographically, then resolves the account:
///   1. by firebaseUid (returning magic-link user)
///   2. by verified email (re-verification on a new Firebase uid)
///   3. by deviceId claim (existing device account adopts the email —
///      streaks/groups survive the upgrade to authenticated identity)
///   4. otherwise creates a new account
/// Issues the app's normal 30d JWT on success.
export const firebaseVerify = async (req, res, next) => {
  try {
    const { idToken, displayName, deviceId } = req.body;
    if (!idToken) {
      return res.status(400).json({ success: false, code: 'MISSING_ID_TOKEN', message: 'idToken is required' });
    }

    let claims;
    try {
      claims = await verifyFirebaseIdToken(idToken);
    } catch (e) {
      if (e instanceof FirebaseTokenError) {
        return res.status(401).json({ success: false, code: e.code, message: 'Invalid Firebase ID token' });
      }
      return res.status(502).json({ success: false, code: 'FIREBASE_UNAVAILABLE', message: 'Could not verify token' });
    }

    const { uid: firebaseUid, email } = claims;
    if (!email) {
      return res.status(400).json({ success: false, code: 'EMAIL_MISSING', message: 'Firebase account has no email' });
    }
    // Anti-spoofing: only trust identities whose email Firebase has VERIFIED
    // (magic-link sign-ins are always verified). A password sign-up with an
    // unverified email must never be able to claim someone's streaks.
    if (!claims.emailVerified) {
      return res.status(403).json({ success: false, code: 'EMAIL_NOT_VERIFIED', message: 'Email not verified' });
    }

    let user = await User.findOne({ firebaseUid });
    let isNew = false;
    let claimed = false;

    if (!user && claims.emailVerified) {
      user = await User.findOne({ email });
    }

    // Claim an existing device-only account on THIS device so its solo
    // streak, groups and history are preserved under the verified identity.
    if (!user && deviceId) {
      const deviceUser = await User.findOne({ deviceId });
      if (deviceUser && !deviceUser.firebaseUid && !deviceUser.email) {
        deviceUser.firebaseUid = firebaseUid;
        deviceUser.email = email;
        if (displayName && displayName.trim()) deviceUser.displayName = displayName.trim();
        await deviceUser.save();
        user = deviceUser;
        claimed = true;
      }
    }

    if (!user) {
      user = new User({
        displayName: displayName && displayName.trim() ? displayName.trim() : email.split('@')[0],
        email,
        firebaseUid,
        deviceId: deviceId || undefined,
      });
      isNew = true;
      try {
        await user.save();
      } catch (error) {
        if (error.code === 11000) {
          // Race: the email/uid got registered concurrently — re-resolve.
          user = (await User.findOne({ firebaseUid })) || (await User.findOne({ email }));
          if (!user) return res.status(409).json({ success: false, code: 'ACCOUNT_CONFLICT', message: 'Account conflict' });
          isNew = false;
        } else {
          throw error;
        }
      }
    } else {
      // Ensure the verified identity is fully linked.
      let dirty = false;
      if (!user.firebaseUid) { user.firebaseUid = firebaseUid; dirty = true; }
      if (!user.email) { user.email = email; dirty = true; }
      if (dirty) await user.save();
    }

    const token = generateToken(user);
    res.json({ success: true, data: { user, token, isNew, claimed } });
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

export const linkDevice = async (req, res, next) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const deviceId = String(req.body?.deviceId || '').trim();
    if (!deviceId) {
      return res.status(400).json({ success: false, message: 'Device ID is required' });
    }
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    // If another account already holds this deviceId (e.g. an abandoned
    // account created after a reinstall), release it first — deviceId must
    // map to exactly one account for login to be deterministic.
    await User.updateOne(
      { deviceId, _id: { $ne: user._id } },
      { $set: { deviceId: `unlinked_${uuidv4()}` } },
    );
    user.deviceId = deviceId;
    await user.save();
    res.json({ success: true, data: { linked: true } });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (req, res, next) => {  try {
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
