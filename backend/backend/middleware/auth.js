import jwt from 'jsonwebtoken';

export const getJwtSecret = () =>
  process.env.JWT_SECRET || 'sajda-secret-key-change-in-production';

export const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, code: 'UNAUTHORIZED', message: 'Authentication required' });
  }

  jwt.verify(token, getJwtSecret(), (err, user) => {
    if (err) {
      if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({ success: false, code: 'INVALID_TOKEN', message: 'Invalid token' });
      }
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ success: false, code: 'TOKEN_EXPIRED', message: 'Token expired' });
      }
      return res.status(401).json({ success: false, code: 'INVALID_TOKEN', message: 'Token invalid' });
    }
    req.user = user;
    next();
  });
};

