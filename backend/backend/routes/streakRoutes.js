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
import { generalLimiter } from '../middleware/rateLimiter.js';

const router = Router();

router.use(generalLimiter);

// Personal Streak
router.get('/my-streak', getMyStreak);
router.post('/personal', createPersonalStreak);
router.post('/completion', updatePrayerCompletion);
router.post('/confirm-prayer', confirmPrayerFromNotification);
router.post('/pause', pauseStreak);
router.post('/resume', resumeStreak);
router.post('/extend', extendStreak);
router.post('/cancel', cancelStreak);
router.get('/history', getStreakHistory);
router.get('/past', getPastStreaks);
router.get('/calendar', getStreakCalendar);

// Shared Streak
router.post('/shared', createSharedStreak);
router.get('/shared/:id', getSharedStreak);
router.post('/shared/join', joinSharedStreak);
router.post('/shared/:id/leave', leaveSharedStreak);
router.post('/shared/:id/end', endSharedStreak);
router.get('/invite/:code', getSharedStreakInvite);
router.post('/shared/:id/revoke-invite', revokeInvite);
router.get('/shared/:id/share', shareStreak);

export default router;
