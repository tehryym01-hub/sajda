import { Router } from 'express';
import { getDuasByCategory, getDailyDua, getDuaById } from '../controllers/duaController.js';
import { cacheMiddleware } from '../middleware/cache.js';

const router = Router();

router.get('/', cacheMiddleware(86400), getDuasByCategory);
router.get('/daily', cacheMiddleware(86400), getDailyDua);
router.get('/:id', cacheMiddleware(86400), getDuaById);

export default router;
