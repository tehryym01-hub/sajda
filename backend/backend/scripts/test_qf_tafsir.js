import dotenv from 'dotenv';

dotenv.config({ path: '.env' });

const QF_CLIENT_ID = process.env.QF_CLIENT_ID;
const QF_CLIENT_SECRET = process.env.QF_CLIENT_SECRET;

async function getToken() {
  const res = await fetch('https://prelive-oauth2.quran.foundation/oauth2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic ' + Buffer.from(`${QF_CLIENT_ID}:${QF_CLIENT_SECRET}`).toString('base64'),
    },
    body: new URLSearchParams({ grant_type: 'client_credentials', scope: 'content' }),
  });
  const data = await res.json();
  return data.access_token;
}

async function testEndpoint(token, path, label) {
  const res = await fetch(`https://apis-prelive.quran.foundation${path}`, {
    headers: { 'x-auth-token': token, 'x-client-id': QF_CLIENT_ID },
  });
  console.log(`\n${label}: ${path} -> ${res.status}`);
  if (res.ok) {
    const text = await res.text();
    console.log('Body:', text.substring(0, 500));
  }
}

async function main() {
  const token = await getToken();
  console.log('Token obtained\n');

  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?tafsirs=169&tafsir_fields=text,resource_name', 'tafsir_by_id');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?tafsirs=en-tafisr-ibn-kathir&tafsir_fields=text,resource_name', 'tafsir_by_slug');
  await testEndpoint(token, '/content/api/v4/verses/by_key/2:255?fields=text_uthmani&translations=85&tafsirs=169', 'ayah_255_full');
}

main().catch(e => console.error('Fatal:', e.message));
