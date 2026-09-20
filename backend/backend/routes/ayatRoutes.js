import { Router } from 'express';
import { getAyatToday, getAyatTranslations } from '../controllers/ayatController.js';
import { cacheMiddleware } from '../middleware/cache.js';

const router = Router();

router.get('/today', cacheMiddleware(3600), getAyatToday);
router.get('/:surah/:ayah', cacheMiddleware(86400), getAyatTranslations);

export default router;
