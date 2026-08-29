import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

dotenv.config({ path: join(dirname(fileURLToPath(import.meta.url)), '..', '..', '.env') });

const QF_CLIENT_ID = process.env.QF_CLIENT_ID || '';
const QF_CLIENT_SECRET = process.env.QF_CLIENT_SECRET || '';
const BASE_URL = 'https://apis-prelive.quran.foundation';
const OAUTH_URL = 'https://prelive-oauth2.quran.foundation';

async function getToken() {
  const res = await fetch(`${OAUTH_URL}/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic ' + Buffer.from(`${QF_CLIENT_ID}:${QF_CLIENT_SECRET}`).toString('base64'),
    },
    body: new URLSearchParams({ grant_type: 'client_credentials', scope: 'content' }),
  });
  if (!res.ok) throw new Error(`Token failed: ${res.status}`);
  const data = await res.json();
  return data.access_token;
}

async function testEndpoint(token, path, label) {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'x-auth-token': token, 'x-client-id': QF_CLIENT_ID },
  });
  console.log(`${label}: ${path} -> ${res.status}`);
  if (res.ok) {
    const text = await res.text();
    console.log('Body:', text.substring(0, 400));
  }
}

async function main() {
  const token = await getToken();
  console.log('Token obtained\n');

  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?include=text', 'by_key include=text');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?include=translations', 'by_key include=translations');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?include=tafsirs', 'by_key include=tafsirs');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?include=text,translations,tafsirs', 'by_key include=all');
  await testEndpoint(token, '/content/api/v4/verses/by_surah/1', 'by_surah default');
  await testEndpoint(token, '/content/api/v4/verses/by_surah/1?include=text', 'by_surah include=text');
  await testEndpoint(token, '/content/api/v4/verses/by_surah/1?include=translations', 'by_surah include=translations');
  await testEndpoint(token, '/content/api/v4/verses/by_surah/1?include=tafsirs', 'by_surah include=tafsirs');
  await testEndpoint(token, '/content/api/v4/audio/1?reciter=ar.alafasy', 'audio direct');
  await testEndpoint(token, '/content/api/v4/recitations/1?reciter=ar.alafasy', 'recitations direct');
}

main().catch(e => console.error('Fatal:', e.message));
