import { Router } from 'express';
import { getTodayEvents, getMonthEvents, getUpcomingEvents } from '../controllers/eventController.js';
import { cacheMiddleware } from '../middleware/cache.js';

const router = Router();

router.get('/today', cacheMiddleware(86400), getTodayEvents);
router.get('/month/:monthName', cacheMiddleware(86400), getMonthEvents);
router.get('/upcoming', cacheMiddleware(3600), getUpcomingEvents);

export default router;
