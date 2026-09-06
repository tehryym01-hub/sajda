import { Router } from 'express';
import {
  getMyStreak,
  createPersonalStreak,
  updatePrayerCompletion,
  confirmPrayerFromNotification,
  pauseStreak,
  resumeStreak,
  extendStreak,
  cancelStreak,
  getStreakHistory,
  getPastStreaks,
  getStreakCalendar,
  createSharedStreak,
  getSharedStreak,
  joinSharedStreak,
  leaveSharedStreak,
  endSharedStreak,
  getSharedStreakInvite,
  revokeInvite,
  shareStreak,
} from '../controllers/streakController.js';
import { writeLimiter } from '../middleware/rateLimiter.js';

const router = Router();

// NOTE: this router is mounted at /api/streak, which by Express prefix
// matching ALSO sees every /api/streak/v2/* request. Never mount a blanket
// limiter here — v2 reads must stay unlimited. Writes carry the per-user
// limiter only.
const W = writeLimiter;

// Personal Streak
router.get('/my-streak', getMyStreak);
router.post('/personal', W, createPersonalStreak);
router.post('/completion', W, updatePrayerCompletion);
router.post('/confirm-prayer', W, confirmPrayerFromNotification);
router.post('/pause', W, pauseStreak);
router.post('/resume', W, resumeStreak);
router.post('/extend', W, extendStreak);
router.post('/cancel', W, cancelStreak);
router.get('/history', getStreakHistory);
router.get('/past', getPastStreaks);
router.get('/calendar', getStreakCalendar);

// Shared Streak
router.post('/shared', W, createSharedStreak);
router.get('/shared/:id', getSharedStreak);
router.post('/shared/join', W, joinSharedStreak);
router.post('/shared/:id/leave', W, leaveSharedStreak);
router.post('/shared/:id/end', W, endSharedStreak);
router.get('/invite/:code', getSharedStreakInvite);
router.post('/shared/:id/revoke-invite', W, revokeInvite);
router.get('/shared/:id/share', shareStreak);

export default router;
