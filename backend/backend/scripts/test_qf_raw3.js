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
    console.log('Body:', text.substring(0, 400));
  }
}

async function main() {
  const token = await getToken();
  console.log('Token obtained\n');

  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?fields=text_uthmani', 'text_uthmani');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?fields=text_imlaei', 'text_imlaei');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?fields=text_uthmani,text_imlaei', 'text_both');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?include=words&word_fields=text_uthmani', 'words_include');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?include=text', 'include_text');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1?include=translations&translations=85', 'translations_by_id');
  await testEndpoint(token, '/content/api/v4/verses/by_key/1:1/translations/85', 'translation_direct');
}

main().catch(e => console.error('Fatal:', e.message));
