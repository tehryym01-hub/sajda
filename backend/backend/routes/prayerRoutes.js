import { Router } from 'express';
import { getPrayerTimes, getNextPrayer } from '../controllers/prayerController.js';
import { cacheMiddleware } from '../middleware/cache.js';
import { generalLimiter } from '../middleware/rateLimiter.js';

const router = Router();

router.use(generalLimiter);

router.get('/times', cacheMiddleware(3600), getPrayerTimes);
router.get('/next-prayer', cacheMiddleware(300), getNextPrayer);

export default router;
