import rateLimit from 'express-rate-limit';

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  // Per REAL client IP (requires app.set('trust proxy', 1) on Render).
  // 300 is headroom for users behind CGNAT (mobile networks share one
  // public IP across many people) while still blocking abuse.
  max: 300,
  message: { success: false, message: 'Too many requests, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

export { generalLimiter };
