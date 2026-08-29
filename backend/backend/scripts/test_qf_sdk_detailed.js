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
    console.log('=== byKey 1:1 ===');
    const v = await c.content.v4.verses.byKey('1:1');
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byKey error:', e.message);
  }

  try {
    console.log('\n=== byKey with translations param ===');
    const v = await c.content.v4.verses.byKey('1:1', { translations: 'en-haleem' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 800));
  } catch (e) {
    console.error('byKey translations error:', e.message);
  }

  try {
    console.log('\n=== byKey with tafsirs param ===');
    const v = await c.content.v4.verses.byKey('1:1', { tafsirs: 'en-tafisr-ibn-kathir' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 800));
  } catch (e) {
    console.error('byKey tafsirs error:', e.message);
  }

  try {
    console.log('\n=== resources.translations list ===');
    const t = await c.content.v4.resources.translations.list();
    console.log('count:', t.translations?.length || t.length || 'N/A');
  } catch (e) {
    console.error('translations error:', e.message);
  }

  try {
    console.log('\n=== resources.tafsirs list ===');
    const t = await c.content.v4.resources.tafsirs.list();
    console.log('count:', t.tafsirs?.length || t.length || 'N/A');
  } catch (e) {
    console.error('tafsirs error:', e.message);
  }
}

main().catch(e => console.error('Fatal:', e.message));
