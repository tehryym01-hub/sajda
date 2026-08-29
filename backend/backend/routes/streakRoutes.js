import { Router } from 'express';
import {
  getMyStreak,
  createPersonalStreak,
  updatePrayerCompletion,
  confirmPrayerFromNotification,
  pauseStreak,
  resumeStreak,
  getStreakHistory,
  getStreakCalendar,
  createSharedStreak,
  getSharedStreak,
  joinSharedStreak,
  leaveSharedStreak,
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
router.get('/history', getStreakHistory);
router.get('/calendar', getStreakCalendar);

// Shared Streak
router.post('/shared', createSharedStreak);
router.get('/shared/:id', getSharedStreak);
router.post('/shared/join', joinSharedStreak);
router.post('/shared/:id/leave', leaveSharedStreak);
router.get('/invite/:code', getSharedStreakInvite);
router.post('/shared/:id/revoke-invite', revokeInvite);
router.get('/shared/:id/share', shareStreak);

export default router;