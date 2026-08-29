import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

dotenv.config({ path: join(dirname(fileURLToPath(import.meta.url)), '..', '..', '.env') });

const QF_CLIENT_ID = process.env.QF_CLIENT_ID;
const QF_CLIENT_SECRET = process.env.QF_CLIENT_SECRET;
const QF_ENV = process.env.QF_ENV || 'prelive';

const OAUTH_URL =
  QF_ENV === 'production'
    ? 'https://oauth2.quran.foundation'
    : 'https://prelive-oauth2.quran.foundation';

const BASE_URL =
  QF_ENV === 'production'
    ? 'https://apis.quran.foundation'
    : 'https://apis-prelive.quran.foundation';

console.log('QF_CLIENT_ID:', QF_CLIENT_ID);
console.log('QF_ENV:', QF_ENV);
console.log('OAUTH_URL:', OAUTH_URL);
console.log('BASE_URL:', BASE_URL);

async function getAccessToken() {
  const credentials = Buffer.from(`${QF_CLIENT_ID}:${QF_CLIENT_SECRET}`).toString('base64');
  const response = await fetch(`${OAUTH_URL}/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': `Basic ${credentials}`,
    },
    body: new URLSearchParams({
      grant_type: 'client_credentials',
      scope: 'content',
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OAuth2 failed: ${response.status} ${text}`);
  }

  const data = await response.json();
  return data.access_token;
}

async function testChapters(token) {
  const res = await fetch(`${BASE_URL}/content/api/v4/chapters?page=1&limit=20`, {
    headers: {
      'x-auth-token': token,
      'x-client-id': QF_CLIENT_ID,
    },
  });
  if (!res.ok) throw new Error(`Chapters failed: ${res.status}`);
  const data = await res.json();
  console.log('Chapters response keys:', Object.keys(data));
  console.log('Chapters count:', data.chapters?.length || data.data?.length || 'N/A');
  return data;
}

async function testVerse(token) {
  const res = await fetch(`${BASE_URL}/content/api/v4/verses/by_key/2:255?fields=text`, {
    headers: {
      'x-auth-token': token,
      'x-client-id': QF_CLIENT_ID,
    },
  });
  if (!res.ok) throw new Error(`Verse failed: ${res.status}`);
  const data = await res.json();
  console.log('Verse full response keys:', Object.keys(data));
  console.log('Verse keys:', Object.keys(data.verse || {}));
  console.log('Verse text field:', data.verse?.text);
  return data;
}

async function testTranslations(token) {
  const endpoints = [
    `${BASE_URL}/content/api/v4/verses/by_key/2:255/translations?language=english`,
    `${BASE_URL}/content/api/v4/verses/2:255/translations?language=english`,
    `${BASE_URL}/content/api/v4/translations/2:255?language=english`,
  ];
  
  for (const url of endpoints) {
    console.log(`Trying: ${url.replace(BASE_URL, '')}`);
    const res = await fetch(url, {
      headers: {
        'x-auth-token': token,
        'x-client-id': QF_CLIENT_ID,
      },
    });
    console.log(`Status: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log('✅ Translations:', data.translations?.length || data.translation?.length || 'N/A');
      return data;
    }
  }
  throw new Error('All translation endpoints failed');
}

async function testTafsir(token) {
  const endpoints = [
    `${BASE_URL}/content/api/v4/verses/by_key/2:255/tafsirs`,
    `${BASE_URL}/content/api/v4/verses/2:255/tafsirs`,
    `${BASE_URL}/content/api/v4/tafsirs/2:255`,
  ];
  
  for (const url of endpoints) {
    console.log(`Trying: ${url.replace(BASE_URL, '')}`);
    const res = await fetch(url, {
      headers: {
        'x-auth-token': token,
        'x-client-id': QF_CLIENT_ID,
      },
    });
    console.log(`Status: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log('✅ Tafsirs:', data.tafsirs?.length || data.tafsir?.length || 'N/A');
      return data;
    }
  }
  throw new Error('All tafsir endpoints failed');
}

async function testAudio(token) {
  const endpoints = [
    `${BASE_URL}/content/api/v4/verses/by_surah/1/audio?reciter=ar.alafasy`,
    `${BASE_URL}/content/api/v4/audio/1?reciter=ar.alafasy`,
  ];
  
  for (const url of endpoints) {
    console.log(`Trying: ${url.replace(BASE_URL, '')}`);
    const res = await fetch(url, {
      headers: {
        'x-auth-token': token,
        'x-client-id': QF_CLIENT_ID,
      },
    });
    console.log(`Status: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log('✅ Audio:', data.audio?.length || data.verses?.length || 'N/A');
      return data;
    }
  }
  throw new Error('All audio endpoints failed');
}

async function main() {
  console.log('\n=== Testing OAuth2 Client Credentials ===');
  const token = await getAccessToken();
  console.log('✅ Access token obtained');

  console.log('\n=== Testing /chapters ===');
  const chapters = await testChapters(token);
  console.log('✅ Chapters count:', chapters.chapters?.length || 'N/A');
  console.log('Chapters sample:', JSON.stringify(chapters.chapters?.slice(0, 2)).substring(0, 200));

  console.log('\n=== Testing /verses/by_key/2:255 ===');
  const verse = await testVerse(token);
  console.log('✅ Verse text:', verse.verse?.text?.madani?.substring(0, 50) || 'N/A');
  console.log('Verse keys:', Object.keys(verse.verse || {}));

  console.log('\n=== Testing /translations ===');
  const translations = await testTranslations(token);
  console.log('✅ Translations:', translations.translations?.length || 0);

  console.log('\n=== Testing /tafsirs ===');
  const tafsir = await testTafsir(token);
  console.log('✅ Tafsirs:', tafsir.tafsirs?.length || 0);

  console.log('\n=== Testing /audio ===');
  const audio = await testAudio(token);
  console.log('✅ Audio:', audio.audio?.length || 0);
}

main().catch(err => {
  console.error('❌ Test failed:', err.message);
  process.exit(1);
});
