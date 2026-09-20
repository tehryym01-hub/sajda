import AyatTranslation from '../models/AyatTranslation.js';

const VERSE_COUNTS = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
  111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
  54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
  49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
  44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
  26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3,
  6, 3, 5, 4, 5, 6,
];

// Mirrors the Flutter client (QuranService.ayahForDay) so every device and
// the server agree on which ayah belongs to a given day of the year.
export function ayahForDay(dayOfYear) {
  const total = 6236;
  let remaining = ((dayOfYear % total) + total) % total;
  for (let s = 1; s <= 114; s++) {
    const count = VERSE_COUNTS[s - 1];
    if (remaining < count) return { surah: s, ayah: remaining + 1 };
    remaining -= count;
  }
  return { surah: 1, ayah: 1 };
}

export const getAyatToday = async (req, res) => {
  const now = new Date();
  const start = Date.UTC(now.getUTCFullYear(), 0, 0);
  const dayOfYear = Math.floor((now.getTime() - start) / 86400000);
  const { surah, ayah } = ayahForDay(dayOfYear);
  const doc = await AyatTranslation.findOne({ surah, ayah }).lean();
  if (!doc) {
    return res.json({ success: true, data: null, message: 'Ayat translations are not seeded yet' });
  }
  return res.json({ success: true, data: doc });
};

export const getAyatTranslations = async (req, res) => {
  const surah = parseInt(req.params.surah, 10);
  const ayah = parseInt(req.params.ayah, 10);
  if (!Number.isInteger(surah) || surah < 1 || surah > 114 ||
      !Number.isInteger(ayah) || ayah < 1) {
    return res.status(400).json({ success: false, message: 'Invalid surah/ayah' });
  }
  const doc = await AyatTranslation.findOne({ surah, ayah }).lean();
  if (!doc) {
    return res.status(404).json({ success: false, message: 'No translations found for this ayah' });
  }
  return res.json({ success: true, data: doc });
};
