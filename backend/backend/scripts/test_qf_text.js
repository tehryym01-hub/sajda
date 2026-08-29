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

async function main() {
  try {
    console.log('=== byChapter 1 ===');
    const v = await c.content.v4.verses.byChapter(1);
    console.log('type:', typeof v);
    console.log('keys:', Array.isArray(v) ? 'array' : Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byChapter error:', e.message);
  }

  try {
    console.log('\n=== byKey with tafsirs slug ===');
    const t = await c.content.v4.resources.tafsirs.list();
    console.log('tafsirs:', JSON.stringify(t).substring(0, 800));
  } catch (e) {
    console.error('tafsirs error:', e.message);
  }

  try {
    console.log('\n=== byKey with tafsirs en-tafisr-ibn-kathir ===');
    const v = await c.content.v4.verses.byKey('1:1', { tafsirs: 'en-tafisr-ibn-kathir' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byKey tafsirs error:', e.message);
  }
}

main().catch(e => console.error('Fatal:', e.message));
