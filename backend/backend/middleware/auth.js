import jwt from 'jsonwebtoken';

export const getJwtSecret = () =>
  process.env.JWT_SECRET || 'sajda-secret-key-change-in-production';

export const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Authentication required' });
  }

  jwt.verify(token, getJwtSecret(), (err, user) => {
    if (err) {
      if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({ success: false, message: 'Invalid token' });
      }
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ success: false, message: 'Token expired' });
      }
      return res.status(401).json({ success: false, message: 'Token invalid' });
    }
    req.user = user;
    next();
  });
};

