import axios from 'axios';
import { createServerClient } from '@quranjs/api/server';

const QF_CLIENT_ID = process.env.QF_CLIENT_ID || '';
const QF_CLIENT_SECRET = process.env.QF_CLIENT_SECRET || '';
const QF_ENV = process.env.QF_ENV || 'prelive';

if (!QF_CLIENT_ID || !QF_CLIENT_SECRET) {
  console.warn('Warning: Quran Foundation credentials not configured. Quran features will be limited.');
}

const BASE_URL =
  QF_ENV === 'production'
    ? 'https://apis.quran.foundation'
    : 'https://apis-prelive.quran.foundation';

const OAUTH_URL =
  QF_ENV === 'production'
    ? 'https://oauth2.quran.foundation'
    : 'https://prelive-oauth2.quran.foundation';

let cachedToken = null;
let tokenExpiresAt = 0;

async function getAccessToken() {
  if (cachedToken && Date.now() < tokenExpiresAt - 60000) {
    return cachedToken;
  }

  const response = await axios.post(
    `${OAUTH_URL}/oauth2/token`,
    new URLSearchParams({
      grant_type: 'client_credentials',
      scope: 'content',
    }),
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      auth: {
        username: QF_CLIENT_ID,
        password: QF_CLIENT_SECRET,
      },
    }
  );

  cachedToken = response.data.access_token;
  tokenExpiresAt = Date.now() + (response.data.expires_in || 3600) * 1000;
  return cachedToken;
}

async function qfGet(path, params = {}) {
  const token = await getAccessToken();
  const response = await axios.get(`${BASE_URL}${path}`, {
    params,
    headers: {
      'x-auth-token': token,
      'x-client-id': QF_CLIENT_ID,
    },
  });
  return response.data;
}

export const qfClient = createServerClient({
  clientId: QF_CLIENT_ID,
  clientSecret: QF_CLIENT_SECRET,
  services: {
    gatewayUrl: QF_ENV === 'production'
      ? 'https://apis.quran.foundation'
      : 'https://apis-prelive.quran.foundation',
    oauth2BaseUrl: QF_ENV === 'production'
      ? 'https://oauth2.quran.foundation'
      : 'https://prelive-oauth2.quran.foundation',
  },
});

export async function getChapters() {
  return qfClient.content.v4.chapters.list();
}

export async function getChapter(surahNumber) {
  return qfClient.content.v4.chapters.retrieve(surahNumber);
}

export async function getVerse(surahNumber, verseNumber, options = {}) {
  const params = { fields: 'text_uthmani,text_imlaei' };
  if (options.translations) {
    params.translations = options.translations;
    params.translation_fields = 'text,resource_name';
  }
  if (options.tafsirs) {
    params.tafsirs = options.tafsirs;
    params.tafsir_fields = 'text,resource_name';
  }
  return qfGet(`/content/api/v4/verses/by_key/${surahNumber}:${verseNumber}`, params);
}

export async function getVerseTranslations(surahNumber, verseNumber, translationId = 85) {
  return qfGet(`/content/api/v4/verses/by_key/${surahNumber}:${verseNumber}`, {
    translations: String(translationId),
    translation_fields: 'text,resource_name',
  });
}

export async function getVerseTafsir(surahNumber, verseNumber, tafsirId = 169) {
  return qfGet(`/content/api/v4/verses/by_key/${surahNumber}:${verseNumber}`, {
    tafsirs: String(tafsirId),
    tafsir_fields: 'text,resource_name',
  });
}

export async function getSurahAudio(surahNumber, reciter = 'ar.alafasy') {
  const all = await qfClient.content.v4.audio.chapterRecitation.list(Number(surahNumber), { reciter });
  const filtered = all.filter(item => item.chapterId === Number(surahNumber));
  return filtered.length > 0 ? filtered : all;
}

export async function searchQuran(query) {
  return qfClient.content.v4.search.list({ query });
}

export async function getJuz(juzNumber) {
  return qfClient.content.v4.juzs.retrieve(juzNumber);
}

export async function getPage(pageNumber) {
  return qfClient.content.v4.pages.quran(pageNumber);
}

export async function getSurahWithTranslations(surahNumber, translationId = 85) {
  return qfClient.content.v4.verses.byChapter(Number(surahNumber), {
    translations: String(translationId),
    translation_fields: 'text,resource_name',
  });
}

export async function getSurahWithTafsir(surahNumber, tafsirId = 169) {
  return qfClient.content.v4.verses.byChapter(Number(surahNumber), {
    tafsirs: String(tafsirId),
    tafsir_fields: 'text,resource_name',
  });
}
