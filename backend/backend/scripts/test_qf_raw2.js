import dotenv from 'dotenv';
import { createServerClient } from '@quranjs/api/server';

dotenv.config({ path: '.env' });

const c = createServerClient({
  clientId: process.env.QF_CLIENT_ID,
  clientSecret: process.env.QF_CLIENT_SECRET,
  services: {
    gatewayUrl: 'https://apis-prelive.quran.foundation',
    oauth2BaseUrl: 'https://prelive-oauth2.quran.foundation',
  },
});

async function testRaw(path, label) {
  const token = await c.content.v4.chapters.list().then(() => 'dummy'); // force token
  // We'll use raw HTTP for these tests
  return { path, label };
}

async function main() {
  const QF_CLIENT_ID = process.env.QF_CLIENT_ID;
  const QF_CLIENT_SECRET = process.env.QF_CLIENT_SECRET;
  
  const tokenRes = await fetch('https://prelive-oauth2.quran.foundation/oauth2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic ' + Buffer.from(`${QF_CLIENT_ID}:${QF_CLIENT_SECRET}`).toString('base64'),
    },
    body: new URLSearchParams({ grant_type: 'client_credentials', scope: 'content' }),
  });
  const tokenData = await tokenRes.json();
  const token = tokenData.access_token;

  const endpoints = [
    '/content/api/v4/verses/by_key/1:1/tafsirs',
    '/content/api/v4/verses/by_key/1:1/tafsirs/169',
    '/content/api/v4/tafsirs/169/verses/1:1',
    '/content/api/v4/verses/by_key/1:1/text',
    '/content/api/v4/verses/by_key/1:1/text.madani',
    '/content/api/v4/text/1:1',
    '/content/api/v4/verses/1:1',
    '/content/api/v4/verses/1:1?include=text',
  ];

  for (const path of endpoints) {
    const res = await fetch(`https://apis-prelive.quran.foundation${path}`, {
      headers: { 'x-auth-token': token, 'x-client-id': QF_CLIENT_ID },
    });
    console.log(`${path} -> ${res.status}`);
    if (res.ok) {
      const body = await res.text();
      console.log('Body:', body.substring(0, 300));
    }
  }
}

main().catch(e => console.error('Fatal:', e.message));
