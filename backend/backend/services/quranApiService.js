// Quran text services backed ONLY by free, public APIs with
// copyright-safe (public domain / freely distributable) resources:
//
//  - Translations (quran.com public API, no auth):
//      22  Abdullah Yusuf Ali (EN)   – public domain (d. 1953, 1934 text)
//      19  Marmaduke Pickthall (EN)  – public domain (d. 1936)
//      234 Fateh Muhammad Jalandhari (UR) – public domain (d. 1938)
//      54  Muhammad Junagarhi (UR)   – public domain (d. 1949)
//  - Tafsir (alquran.cloud public API):
//      ar.muyassar — Tafsir Al-Muyassar, King Fahd Glorious Quran
//      Printing Complex (free distribution permitted)
//
// NOTE: Never switch to copyrighted resources (e.g. The Clear Quran 85/131,
// Abdel Haleem, Taqi Usmani EN, Tafsir Ibn Kathir Darussalam 169, Bayan-ul-
// Quran 158/159, Wahiduddin Khan 818/819) — that would expose the app to
// Play Store copyright complaints.

const QURAN_COM = 'https://api.quran.com/api/v4';
const ALQURAN_CLOUD = 'https://api.alquran.cloud/v1';

const TRANSLATION_CHAIN = {
  en: [22, 19], // Yusuf Ali -> Pickthall (both public domain)
  ur: [234, 54], // Jalandhari -> Junagarhi (both public domain)
};

const TRANSLATION_NAMES = {
  22: 'Abdullah Yusuf Ali',
  19: 'Marmaduke Pickthall',
  234: 'Fateh Muhammad Jalandhari',
  54: 'Muhammad Junagarhi',
};

const TAFSIR_EDITION = 'ar.muyassar';
const TAFSIR_NAME = 'Tafsir Al-Muyassar (King Fahad Quran Complex)';

const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // Quran text never changes.
const cache = new Map(); // key -> { expiresAt, data }

function cacheGet(key) {
  const hit = cache.get(key);
  if (hit && hit.expiresAt > Date.now()) return hit.data;
  if (hit) cache.delete(key);
  return undefined;
}

function cacheSet(key, data) {
  cache.set(key, { expiresAt: Date.now() + CACHE_TTL_MS, data });
}

async function fetchJson(url, timeoutMs = 12000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      signal: controller.signal,
      headers: { Accept: 'application/json' },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } finally {
    clearTimeout(timer);
  }
}

/// quran.com wraps foot-note refs in markup like <sup foot_note=123>1</sup>.
function stripHtml(text) {
  return String(text || '')
    .replace(/<sup[^>]*>.*?<\/sup>/gi, '')
    .replace(/<[^>]+>/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

/// Whole-surah translation from quran.com. Tries the chain of public-domain
/// translators in order; returns the shape the Flutter client expects:
/// { verses: [{ verse_number, translations: [{ text, resource_name }] }] }
export async function fetchSurahTranslations(surahNumber, lang = 'ur') {
  const surah = Number(surahNumber);
  const language = lang === 'en' ? 'en' : 'ur';
  const ids = TRANSLATION_CHAIN[language] || TRANSLATION_CHAIN.ur;
  const cacheKey = `tr:${surah}:${language}`;

  const cached = cacheGet(cacheKey);
  if (cached) return cached;

  let lastError = null;
  for (const id of ids) {
    try {
      const json = await fetchJson(
        `${QURAN_COM}/quran/translations/${id}?chapter_number=${surah}`
      );
      const rows = Array.isArray(json.translations) ? json.translations : [];
      // Rows are returned in verse order for the whole chapter and the
      // endpoint does not expose verse_key — index + 1 is the verse number.
      const verses = rows
        .map((t, i) => {
          const text = stripHtml(t.text);
          if (!text) return null;
          return {
            verse_number: i + 1,
            translations: [
              {
                text,
                resource_name: TRANSLATION_NAMES[id] || `Translation ${id}`,
              },
            ],
          };
        })
        .filter(Boolean);
      if (verses.length === 0) throw new Error('empty translation payload');
      const data = {
        verses,
        translation_name: TRANSLATION_NAMES[id],
        language,
        source: 'quran.com (public domain)',
      };
      cacheSet(cacheKey, data);
      return data;
    } catch (err) {
      lastError = err;
    }
  }
  throw lastError || new Error('Translation service unavailable');
}

/// Single-verse translation (same public-domain chain).
export async function fetchVerseTranslation(surahNumber, ayahNumber, lang = 'ur') {
  const surah = Number(surahNumber);
  const ayah = Number(ayahNumber);
  const language = lang === 'en' ? 'en' : 'ur';
  const ids = TRANSLATION_CHAIN[language] || TRANSLATION_CHAIN.ur;
  const cacheKey = `trv:${surah}:${ayah}:${language}`;

  const cached = cacheGet(cacheKey);
  if (cached) return cached;

  let lastError = null;
  for (const id of ids) {
    try {
      const json = await fetchJson(
        `${QURAN_COM}/quran/translations/${id}?verse_key=${surah}:${ayah}`
      );
      const rows = Array.isArray(json.translations) ? json.translations : [];
      const text = stripHtml(rows[0]?.text);
      if (!text) throw new Error('empty translation payload');
      const data = {
        verse: {
          verse_number: ayah,
          translations: [
            {
              text,
              resource_name: TRANSLATION_NAMES[id] || `Translation ${id}`,
            },
          ],
        },
        translation_name: TRANSLATION_NAMES[id],
        language,
        source: 'quran.com (public domain)',
      };
      cacheSet(cacheKey, data);
      return data;
    } catch (err) {
      lastError = err;
    }
  }
  throw lastError || new Error('Translation service unavailable');
}

/// Whole-surah tafsir from alquran.cloud (Tafsir Al-Muyassar, Arabic —
/// produced by the King Fahad Complex, distributed freely).
export async function fetchSurahTafsir(surahNumber) {
  const surah = Number(surahNumber);
  const cacheKey = `tf:${surah}`;

  const cached = cacheGet(cacheKey);
  if (cached) return cached;

  const json = await fetchJson(`${ALQURAN_CLOUD}/surah/${surah}/${TAFSIR_EDITION}`);
  if (json.code !== 200 || !Array.isArray(json.data?.ayahs)) {
    throw new Error('Tafsir service unavailable');
  }
  const verses = json.data.ayahs
    .map((a) => ({
      verse_number: a.numberInSurah,
      tafsirs: [{ text: stripHtml(a.text), resource_name: TAFSIR_NAME }],
    }))
    .filter((v) => v.tafsirs[0].text);
  if (verses.length === 0) throw new Error('empty tafsir payload');

  const data = {
    verses,
    tafsir_name: TAFSIR_NAME,
    source: 'alquran.cloud (King Fahad Complex)',
  };
  cacheSet(cacheKey, data);
  return data;
}

/// Single-verse tafsir.
export async function fetchVerseTafsir(surahNumber, ayahNumber) {
  const surahData = await fetchSurahTafsir(surahNumber);
  const ayah = Number(ayahNumber);
  const verse = surahData.verses.find((v) => v.verse_number === ayah);
  if (!verse) throw new Error('Tafsir not found for this verse');
  return {
    verse,
    tafsir_name: surahData.tafsir_name,
    source: surahData.source,
  };
}
