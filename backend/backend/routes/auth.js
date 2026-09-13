import { Router } from 'express';
import { register, login, getProfile, updateProfile, deleteAccount, linkDevice, firebaseVerify } from '../controllers/authController.js';
import { authenticateToken } from '../middleware/auth.js';
import { authLimiter } from '../middleware/rateLimiter.js';

const router = Router();

router.post('/register', authLimiter, register);
router.post('/login', authLimiter, login);
router.post('/firebase-verify', authLimiter, firebaseVerify);
router.post('/link-device', authenticateToken, linkDevice);
router.get('/profile', authenticateToken, getProfile);
router.put('/profile', authenticateToken, updateProfile);
router.post('/profile', authenticateToken, updateProfile);
router.delete('/account', authenticateToken, deleteAccount);

export default router;
