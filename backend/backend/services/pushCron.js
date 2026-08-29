import cron from 'node-cron';
import { sendPushToAll, sendPushWazifa } from './push.js';
import { buildSchedule } from '../controllers/notificationController.js';

const TIMEZONE = 'Asia/Karachi';

const PRAYER_DAY_MAP = {
  Fajr: 0, Dhuhr: 1, Asr: 2, Maghrib: 3, Isha: 4,
};

let sentPrayers = new Set();
let sentWazifa = false;
let lastDate = '';

function getPktDate() {
  const now = new Date();
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: TIMEZONE, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(now);
  const get = (t) => parts.find(p => p.type === t)?.value;
  return `${get('year')}-${get('month')}-${get('day')}`;
}

function getTodayKey() {
  return getPktDate();
}

function getCurrentMinutes() {
  const now = new Date();
  const parts = new Intl.DateTimeFormat('en-US', { timeZone: TIMEZONE, hour: '2-digit', minute: '2-digit', hour12: false }).formatToParts(now);
  const h = parseInt(parts.find(p => p.type === 'hour')?.value || '0');
  const m = parseInt(parts.find(p => p.type === 'minute')?.value || '0');
  return h * 60 + m;
}

function isFriday() {
  const day = new Intl.DateTimeFormat('en-US', { timeZone: TIMEZONE, weekday: 'long' }).format(new Date());
  return day === 'Friday';
}

export function startPushCron() {
  console.log('Push cron started — checks every 30 seconds');

  cron.schedule('*/30 * * * * *', async () => {
    const todayKey = getTodayKey();
    if (lastDate !== todayKey) {
      sentPrayers = new Set();
      sentWazifa = false;
      lastDate = todayKey;
    }

    const currentMinutes = getCurrentMinutes();

    try {
      const schedule = await buildSchedule('Karachi', 'Pakistan');
      if (!schedule) return;

      // Check each prayer (skip Sunrise)
      for (const prayer of schedule.prayers) {
        const [h, m] = prayer.time.split(':').map(Number);
        const prayerMinutes = h * 60 + m;
        const diff = currentMinutes - prayerMinutes;

        if (diff >= 0 && diff <= 2 && !sentPrayers.has(prayer.prayer)) {
          sentPrayers.add(prayer.prayer);

          // On Friday, send "Jummah" instead of "Dhuhr"
          let prayerName = prayer.prayer;
          if (isFriday() && prayer.prayer === 'Dhuhr') {
            prayerName = 'Jummah';
          }

          console.log(`Pushing prayer notification: ${prayerName}`);
          const title = `🕌 ${prayerName} Time Has Come`;
          const body = `It's time for ${prayerName} prayer.`;
          await sendPushToAll(title, body, `push-${prayerName}`, 10);
        }
      }

      // Wazifa between Fajr and Dhuhr
      if (schedule.prayers.length > 0) {
        const fajrTime = schedule.prayers.find(p => p.prayer === 'Fajr')?.time || '05:00';
        const dhuhrTime = schedule.prayers.find(p => p.prayer === 'Dhuhr')?.time || '12:30';
        const [fh, fm] = fajrTime.split(':').map(Number);
        const [dh, dm] = dhuhrTime.split(':').map(Number);
        const fajrMinutes = fh * 60 + fm;
        const dhuhrMinutes = dh * 60 + dm;
        // Send wazifa in the middle of Fajr-Dhuhr window
        const wazifaWindowStart = fajrMinutes + 30;
        const wazifaWindowEnd = dhuhrMinutes - 30;

        if (!sentWazifa && currentMinutes >= wazifaWindowStart && currentMinutes <= wazifaWindowEnd && schedule.wazifa) {
          sentWazifa = true;
          console.log('Pushing wazifa notification');
          await sendPushWazifa(schedule.wazifa);
        }
      }
    } catch (err) {
      console.error('Push cron error:', err.message);
    }
  });

  // Self-ping every 10 minutes to prevent Render free tier sleep
  cron.schedule('*/10 * * * *', async () => {
    const baseUrl = process.env.RENDER_EXTERNAL_URL || process.env.FRONTEND_URL || 'https://sajdadailyathan\.site';
    try {
      const response = await fetch(`${baseUrl}/api/health`, { timeout: 10000 });
      if (response.ok) console.log('Keep-alive ping OK');
    } catch (err) {
      console.log('Keep-alive ping failed:', err.message);
    }
  });
}

