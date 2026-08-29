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
    console.log('=== byKey with text param ===');
    const v = await c.content.v4.verses.byKey('1:1', { text: true });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byKey text error:', e.message);
  }

  try {
    console.log('\n=== byKey with fields param ===');
    const v = await c.content.v4.verses.byKey('1:1', { fields: 'text' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byKey fields error:', e.message);
  }

  try {
    console.log('\n=== byKey with tafsirs ar-tafsir-jalalayn ===');
    const v = await c.content.v4.verses.byKey('1:1', { tafsirs: 'ar-tafsir-jalalayn' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byKey tafsirs error:', e.message);
  }

  try {
    console.log('\n=== byKey with multiple params ===');
    const v = await c.content.v4.verses.byKey('1:1', { text: true, translations: 'en-haleem', tafsirs: 'ar-tafsir-jalalayn' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 1000));
  } catch (e) {
    console.error('byKey multiple error:', e.message);
  }
}

main().catch(e => console.error('Fatal:', e.message));
