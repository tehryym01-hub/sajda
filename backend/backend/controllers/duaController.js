import Dua from '../models/Dua.js';
import { fetchVersesBySurah } from '../services/quranApiService.js';

const DUAS_SURAH_MAP = {
  morning: [1, 2, 18, 36, 67, 112, 113, 114],
  evening: [1, 2, 18, 36, 67, 112, 113, 114],
  sleep: [1, 2, 18, 36, 67, 112, 113, 114],
  food: [1, 2],
  travel: [1, 2],
  hardship: [1, 2, 18, 36, 67, 112, 113, 114],
  forgiveness: [1, 2, 3, 18, 36, 39, 67, 112, 113, 114],
  protection: [1, 2, 112, 113, 114],
  ramadan: [1, 2, 36, 67, 112, 113, 114],
};

async function fetchQuranicDuas(category) {
  const surahs = category ? (DUAS_SURAH_MAP[category] || [1, 2, 112, 113, 114]) : [1, 2, 112, 113, 114];
  const allVerses = [];
  
  for (const surah of surahs) {
    const verses = await fetchVersesBySurah(surah);
    allVerses.push(...verses);
  }
  
  return allVerses.slice(0, 50);
}

export const getDuasByCategory = async (req, res, next) => {
  try {
    const { category } = req.query;
    const filter = {};
    if (category) {
      filter.category = category;
    }
    const duas = await Dua.find(filter).sort({ _id: 1 }).lean();
    
    if (duas.length > 0) {
      return res.json({ success: true, data: duas, count: duas.length });
    }
    
    const quranicDuas = await fetchQuranicDuas(category);
    if (quranicDuas.length > 0) {
      return res.json({ success: true, data: quranicDuas, count: quranicDuas.length });
    }
    
    return res.json({ success: true, data: [], count: 0, message: 'No duas available' });
  } catch (error) {
    next(error);
  }
};

export const getDailyDua = async (req, res, next) => {
  try {
    const dayOfYear = Math.floor((Date.now() - new Date(new Date().getFullYear(), 0, 0)) / 86400000);
    const count = await Dua.countDocuments();
    if (count > 0) {
      const skip = dayOfYear % count;
      const dua = await Dua.findOne().skip(skip).lean();
      if (dua) {
        return res.json({ success: true, data: dua });
      }
    }
    
    const quranicDuas = await fetchQuranicDuas('all');
    if (quranicDuas.length > 0) {
      const index = dayOfYear % quranicDuas.length;
      return res.json({ success: true, data: quranicDuas[index] });
    }
    
    return res.json({ success: true, data: null, message: 'No duas available' });
  } catch (error) {
    next(error);
  }
};

export const getDuaById = async (req, res, next) => {
  try {
    const dua = await Dua.findById(req.params.id).lean();
    if (!dua) {
      res.status(404);
      throw new Error('Dua not found');
    }
    res.json({ success: true, data: dua });
  } catch (error) {
    next(error);
  }
};
