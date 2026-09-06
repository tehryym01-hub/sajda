import rateLimit from 'express-rate-limit';

// AUTH limiter — per IP on register/login only (brute-force protection).
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  message: { success: false, message: 'Too many attempts, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

// WRITE limiter — keyed per USER (falls back to IP before auth runs).
// CGNAT users share one public IP, so per-IP limits punish whole
// neighbourhoods; per-user keys never do. Normal usage is a handful of
// writes a day — 300/15min is far beyond anything a real user generates.
const writeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  keyGenerator: (req) => String(req.user?.id || req.user?._id || req.ip),
  message: { success: false, message: 'Too many requests, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

// READ flood-guard — only for legacy v1 routes still mounted with a blanket
// limiter. High enough that no real user ever notices it.
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  message: { success: false, message: 'Too many requests, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

export { authLimiter, writeLimiter, generalLimiter };
