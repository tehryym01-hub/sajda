import { Router } from 'express';
import { getAdhkar } from '../controllers/adhkarController.js';
import { cacheMiddleware } from '../middleware/cache.js';

const router = Router();

router.get('/', cacheMiddleware(86400), getAdhkar);

export default router;
