import express from 'express';
import {
  getChapters,
  getChapter,
  getVerse,
  getVerseTranslations,
  getVerseTafsir,
  getSurahWithTranslations,
  getSurahWithTafsir,
  getSurahAudio,
  searchQuran,
  getJuz,
  getPage,
} from '../services/quranFoundationService.js';

const router = express.Router();

router.get('/chapters', async (req, res) => {
  try {
    const data = await getChapters();
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch chapters' });
  }
});

router.get('/chapters/:surah', async (req, res) => {
  try {
    const surah = parseInt(req.params.surah);
    if (isNaN(surah) || surah < 1 || surah > 114) {
      return res.status(400).json({ success: false, message: 'Invalid surah number' });
    }
    const data = await getChapter(surah);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch chapter' });
  }
});

router.get('/verses/:surah/:ayah', async (req, res) => {
  try {
    const surah = parseInt(req.params.surah);
    const ayah = parseInt(req.params.ayah);
    if (isNaN(surah) || isNaN(ayah)) {
      return res.status(400).json({ success: false, message: 'Invalid verse parameters' });
    }
    const data = await getVerse(surah, ayah);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch verse' });
  }
});

router.get('/verses/:surah/:ayah/translations', async (req, res) => {
  try {
    const surah = parseInt(req.params.surah);
    const ayah = parseInt(req.params.ayah);
    if (isNaN(surah) || isNaN(ayah)) {
      return res.status(400).json({ success: false, message: 'Invalid verse parameters' });
    }
    const data = await getVerseTranslations(surah, ayah);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch translation' });
  }
});

router.get('/verses/:surah/:ayah/tafsir', async (req, res) => {
  try {
    const surah = parseInt(req.params.surah);
    const ayah = parseInt(req.params.ayah);
    if (isNaN(surah) || isNaN(ayah)) {
      return res.status(400).json({ success: false, message: 'Invalid verse parameters' });
    }
    const data = await getVerseTafsir(surah, ayah);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch tafsir' });
  }
});

router.get('/audio/surah/:surah', async (req, res) => {
  try {
    const surah = parseInt(req.params.surah);
    const reciter = req.query.reciter || 'ar.alafasy';
    if (isNaN(surah)) {
      return res.status(400).json({ success: false, message: 'Invalid surah number' });
    }
    const data = await getSurahAudio(surah, reciter);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch audio' });
  }
});

router.get('/search', async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) {
      return res.status(400).json({ success: false, message: 'Query parameter required' });
    }
    const data = await searchQuran(query);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to search' });
  }
});

router.get('/juz/:juz', async (req, res) => {
  try {
    const juz = parseInt(req.params.juz);
    if (isNaN(juz) || juz < 1 || juz > 30) {
      return res.status(400).json({ success: false, message: 'Invalid juz number' });
    }
    const data = await getJuz(juz);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch juz' });
  }
});

router.get('/page/:page', async (req, res) => {
  try {
    const page = parseInt(req.params.page);
    if (isNaN(page) || page < 1 || page > 604) {
      return res.status(400).json({ success: false, message: 'Invalid page number' });
    }
    const data = await getPage(page);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch page' });
  }
});

router.get('/surah/:surah/translations', async (req, res) => {
  try {
    const surah = parseInt(req.params.surah);
    if (isNaN(surah) || surah < 1 || surah > 114) {
      return res.status(400).json({ success: false, message: 'Invalid surah number' });
    }
    const data = await getSurahWithTranslations(surah);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch translations' });
  }
});

router.get('/surah/:surah/tafsir', async (req, res) => {
  try {
    const surah = parseInt(req.params.surah);
    if (isNaN(surah) || surah < 1 || surah > 114) {
      return res.status(400).json({ success: false, message: 'Invalid surah number' });
    }
    const data = await getSurahWithTafsir(surah);
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message || 'Failed to fetch tafsir' });
  }
});

export default router;
