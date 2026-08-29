import { Router } from 'express';
import { getQiblaDirection } from '../controllers/qiblaController.js';
import { cacheMiddleware } from '../middleware/cache.js';

const router = Router();

router.get('/direction', cacheMiddleware(86400), getQiblaDirection);

export default router;
