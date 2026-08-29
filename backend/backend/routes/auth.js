import { Router } from 'express';
import { register, login, getProfile, updateProfile, deleteAccount } from '../controllers/authController.js';
import { authenticateToken } from '../middleware/auth.js';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.get('/profile', authenticateToken, getProfile);
router.put('/profile', authenticateToken, updateProfile);
router.post('/profile', authenticateToken, updateProfile);
router.delete('/account', authenticateToken, deleteAccount);

export default router;
