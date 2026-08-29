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
    console.log('=== byKey with text_uthmani ===');
    const v = await c.content.v4.verses.byKey('1:1', { fields: 'text_uthmani' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byKey text_uthmani error:', e.message);
  }

  try {
    console.log('\n=== byKey with text_imlaei ===');
    const v = await c.content.v4.verses.byKey('1:1', { fields: 'text_imlaei' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byKey text_imlaei error:', e.message);
  }

  try {
    console.log('\n=== byKey with tafsirs param (correct slug) ===');
    const v = await c.content.v4.verses.byKey('1:1', { tafsirs: 'en-tafisr-ibn-kathir', tafsir_fields: 'text' });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 500));
  } catch (e) {
    console.error('byKey tafsirs error:', e.message);
  }

  try {
    console.log('\n=== byKey with all fields ===');
    const v = await c.content.v4.verses.byKey('1:1', { 
      fields: 'text_uthmani',
      translations: 'en-haleem',
      translation_fields: 'text,resource_name',
      tafsirs: 'en-tafisr-ibn-kathir',
      tafsir_fields: 'text,resource_name'
    });
    console.log('keys:', Object.keys(v));
    console.log('sample:', JSON.stringify(v).substring(0, 1000));
  } catch (e) {
    console.error('byKey all error:', e.message);
  }
}

main().catch(e => console.error('Fatal:', e.message));
