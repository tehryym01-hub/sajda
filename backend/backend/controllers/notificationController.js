import { getPrayerTimesFromAPI } from '../services/prayerService.js';
import Wazifa from '../models/Wazifa.js';

export const getSchedule = async (req, res, next) => {
  try {
    const { city = 'Karachi', country = 'Pakistan' } = req.query;
    const schedule = await buildSchedule(city, country);
    res.json({ success: true, data: schedule });
  } catch (error) {
    next(error);
  }
};

export const getPrayerTimesForNotification = async (req, res, next) => {
  try {
    const { city = 'Karachi', country = 'Pakistan' } = req.query;
    const schedule = await buildPrayerOnly(city, country);
    res.json({ success: true, data: schedule });
  } catch (error) {
    next(error);
  }
};

export async function buildSchedule(city = 'Karachi', country = 'Pakistan') {
  const prayerData = await getPrayerTimesFromAPI(city, country);
  const dayOfYear = getDayOfYear();

  const prayerNotifications = prayerData.prayers.filter(p => p.name !== 'Sunrise').map((prayer) => {
    return {
      prayer: prayer.name,
      time: prayer.time,
    };
  });

  const wazifa = await Wazifa.findOne({ dayOfYear }).lean();

  return {
    date: prayerData.date,
    hijri: prayerData.hijri,
    prayers: prayerNotifications.filter(Boolean),
    wazifa: wazifa ? {
      title: wazifa.title,
      arabic: wazifa.arabic,
      urdu: wazifa.urdu,
      english: wazifa.english,
      transliteration: wazifa.transliteration,
      count: wazifa.count,
      type: wazifa.type,
      benefit: wazifa.benefit,
    } : null,
  };
}

export async function buildPrayerOnly(city = 'Karachi', country = 'Pakistan') {
  const data = await getPrayerTimesFromAPI(city, country);
  const prayers = data.prayers.filter(p => p.name !== 'Sunrise');
  return { date: data.date, hijri: data.hijri, prayers };
}

const getDayOfYear = () => {
  const now = new Date();
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Karachi', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(now);
  const get = (t) => parts.find(p => p.type === t)?.value;
  const pktDate = new Date(`${get('year')}-${get('month')}-${get('day')}T00:00:00`);
  const start = new Date(pktDate.getFullYear(), 0, 0);
  return Math.floor((pktDate - start) / (1000 * 60 * 60 * 24));
};
