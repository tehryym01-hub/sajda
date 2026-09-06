import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import './config/env.js';
import connectDB, { dbConnected } from './config/db.js';
import errorHandler from './middleware/errorHandler.js';
import { authenticateToken } from './middleware/auth.js';

import prayerRoutes from './routes/prayerRoutes.js';
import qiblaRoutes from './routes/qiblaRoutes.js';
import eventRoutes from './routes/eventRoutes.js';
import duaRoutes from './routes/duaRoutes.js';
import wazifaRoutes from './routes/wazifaRoutes.js';
import hijriRoutes from './routes/hijriRoutes.js';
import authRoutes from './routes/auth.js';
import streakRoutes from './routes/streakRoutes.js';
import streakV2Routes from './routes/streakV2Routes.js';
import quranRoutes from './routes/quranRoutes.js';

dotenv.config({ path: join(dirname(fileURLToPath(import.meta.url)), '..', '.env') });

const app = express();
const PORT = process.env.PORT || 5000;
const __dirname = dirname(fileURLToPath(import.meta.url));

// Render sits behind exactly one reverse proxy. Without this, req.ip is the
// proxy's internal IP for EVERY client, which collapses the rate limiter
// into one global bucket shared by all users ("Too many requests" for
// everyone after a few app opens).
app.set('trust proxy', 1);



const checkDBConnection = (req, res, next) => {
  if (!dbConnected) {
    return res.status(503).json({ message: 'Database unavailable. Please try again later.' });
  }
  next();
};

app.use(helmet({
  crossOriginResourcePolicy: false,
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "https:"],
      imgSrc: ["'self'", "data:", "https:", "blob:"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      connectSrc: ["'self'", "https://fonts.googleapis.com", "https://fonts.gstatic.com", "https:"],
      frameSrc: ["'self'", "https:"],
      workerSrc: ["'self'", "blob:"],
    },
  },
}));
app.use(compression());
// Request logging is a dev tool — at 20k users it burns CPU and memory for
// nothing. Only enabled when explicitly running in development.
if (process.env.NODE_ENV === 'development') app.use(morgan('dev'));
app.use(cors({
  origin: ['https://sajda-privacy.onrender.com'],
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve built frontend (for production deployment on Render)
const distPath = join(__dirname, '..', 'dist');
app.use(express.static(distPath));

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Sajda API is running' });
});

app.use('/api/prayers', checkDBConnection, prayerRoutes);
app.use('/api/qibla', checkDBConnection, qiblaRoutes);
app.use('/api/events', checkDBConnection, eventRoutes);
app.use('/api/duas', checkDBConnection, duaRoutes);
app.use('/api/wazifas', checkDBConnection, wazifaRoutes);
app.use('/api/hijri', checkDBConnection, hijriRoutes);
app.use('/api/auth', checkDBConnection, authRoutes);
app.use('/api/streak', authenticateToken, checkDBConnection, streakRoutes);
// v2 streak system (Solo + Friends & Family groups). The v1 router above
// has no route matching `v2/...`, so requests fall through to this mount.
// v1 stays mounted for older app versions until they are retired.
app.use('/api/streak/v2', authenticateToken, checkDBConnection, streakV2Routes);
app.use('/api/quran', checkDBConnection, quranRoutes);

// Fallback: serve index.html for any non-API route (SPA)
app.get('*', (req, res) => {
  res.sendFile(join(distPath, 'index.html'));
});

app.use(errorHandler);

function startKeepAlive() {
  const RENDER_URL = process.env.RENDER_EXTERNAL_URL;
  if (!RENDER_URL) return;
  setInterval(async () => {
    try {
      const res = await fetch(`${RENDER_URL}/api/health`);
      console.log(`[KeepAlive] Ping - ${res.status} @ ${new Date().toISOString()}`);
    } catch (err) {
      console.error(`[KeepAlive] Failed: ${err.message}`);
    }
  }, 10 * 60 * 1000);
  console.log('[KeepAlive] Started - will ping every 10 min');
}

connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Sajda server running on port ${PORT}`);
    startKeepAlive();
  });
}).catch((err) => {
  console.error('Failed to start server:', err.message);
  app.listen(PORT, () => {
    console.log(`Sajda server running on port ${PORT} (without database)`);
    startKeepAlive();
  });
});

export default app;


