import { getPrayerTimesFromAPI, getNextPrayer as getNextPrayerService } from '../services/prayerService.js';

export const getPrayerTimes = async (req, res, next) => {
  try {
    const { city = 'Karachi', country = 'Pakistan' } = req.query;
    const data = await getPrayerTimesFromAPI(city, country);
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getNextPrayer = async (req, res, next) => {
  try {
    const { city = 'Karachi', country = 'Pakistan' } = req.query;
    const data = await getPrayerTimesFromAPI(city, country);
    const nextPrayer = getNextPrayerService(data.prayers);

    res.json({
      success: true,
      data: {
        currentTime: new Date().toLocaleTimeString(),
        nextPrayer,
        allPrayers: data.prayers,
        hijri: data.hijri,
      },
    });
  } catch (error) {
    next(error);
  }
};
