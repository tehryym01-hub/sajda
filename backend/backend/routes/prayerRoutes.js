import { Router } from 'express';
import { getPrayerTimes, getNextPrayer } from '../controllers/prayerController.js';
import { cacheMiddleware } from '../middleware/cache.js';

const router = Router();

// Read-only endpoints served from cache — no app-level rate limiting
// (limiting reads only hurts shared-IP users; abuse is handled upstream).

router.get('/times', cacheMiddleware(3600), getPrayerTimes);
router.get('/next-prayer', cacheMiddleware(300), getNextPrayer);

export default router;
