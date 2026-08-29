import { Router } from 'express';
import { cacheMiddleware } from '../middleware/cache.js';

const router = Router();

router.get('/calendar', cacheMiddleware(86400), async (req, res, next) => {
  try {
    const month = parseInt(req.query.month) || (new Date().getMonth() + 1);
    const year = parseInt(req.query.year) || new Date().getFullYear();
    const url = `https://api.aladhan.com/v1/gToHCalendar/${month}/${year}`;
    const response = await fetch(url);
    const data = await response.json();
    if (data.code === 200 && data.data) {
      const hijriData = data.data.map(day => ({
        gregorian: day.gregorian.date,
        hijri: {
          day: day.hijri.day,
          month: day.hijri.month.en,
          monthNumber: day.hijri.month.number,
          year: day.hijri.year,
          designation: day.hijri.designation.abbreviated,
        },
      }));
      res.json({ success: true, data: hijriData });
    } else {
      res.status(500).json({ success: false, message: 'Failed to fetch Hijri calendar' });
    }
  } catch (error) {
    next(error);
  }
});

router.get('/today', cacheMiddleware(3600), async (req, res, next) => {
  try {
    const now = new Date();
    const parts = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Karachi', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(now);
    const get = (t) => parts.find(p => p.type === t)?.value;
    // Use method 1 (University of Islamic Sciences, Karachi) for Pakistan-aligned dates
    const url = `https://api.aladhan.com/v1/timingsByCity?city=Karachi&country=Pakistan&method=1&date=${get('day')}-${get('month')}-${get('year')}`;
    const response = await fetch(url);
    const data = await response.json();
    if (data.code === 200 && data.data) {
      const h = data.data.date.hijri;
      res.json({
        success: true,
        data: {
          day: h.day,
          month: h.month.en,
          monthNumber: h.month.number,
          year: h.year,
          full: `${h.day} ${h.month.en} ${h.year} ${h.designation.abbreviated}`,
          fullAr: `${h.day} ${h.month.ar} ${h.year} ${h.designation.abbreviated}`,
        },
      });
    } else {
      res.status(500).json({ success: false, message: 'Failed to fetch Hijri date' });
    }
  } catch (error) {
    next(error);
  }
});

router.get('/date', cacheMiddleware(86400), async (req, res, next) => {
  try {
    const day = String(parseInt(req.query.day) || new Date().getDate()).padStart(2, '0');
    const month = String(parseInt(req.query.month) || (new Date().getMonth() + 1)).padStart(2, '0');
    const year = parseInt(req.query.year) || new Date().getFullYear();
    const url = `https://api.aladhan.com/v1/gToH?date=${day}-${month}-${year}`;
    const response = await fetch(url);
    const data = await response.json();
    if (data.code === 200 && data.data) {
      const h = data.data.hijri;
      res.json({
        success: true,
        data: {
          gregorian: { day, month, year },
          hijri: {
            day: h.day,
            month: h.month.en,
            monthAr: h.month.ar,
            monthNumber: h.month.number,
            year: h.year,
            full: `${h.day} ${h.month.en} ${h.year} ${h.designation.abbreviated}`,
          },
        },
      });
    } else {
      res.status(500).json({ success: false, message: 'Failed to fetch Hijri date' });
    }
  } catch (error) {
    next(error);
  }
});

export default router;
