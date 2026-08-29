import { Router } from 'express';
import { getDailyWazifa, getWazifaByDay } from '../controllers/wazifaController.js';
import { cacheMiddleware } from '../middleware/cache.js';

const router = Router();

router.get('/daily', cacheMiddleware(86400), getDailyWazifa);
router.get('/day/:day', cacheMiddleware(86400), getWazifaByDay);

export default router;
