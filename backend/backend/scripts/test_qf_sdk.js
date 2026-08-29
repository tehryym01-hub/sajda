import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

dotenv.config({ path: join(dirname(fileURLToPath(import.meta.url)), '..', '..', '.env') });

import { createServerClient } from '@quranjs/api/server';

const QF_CLIENT_ID = process.env.QF_CLIENT_ID || '';
const QF_CLIENT_SECRET = process.env.QF_CLIENT_SECRET || '';
const QF_ENV = process.env.QF_ENV || 'prelive';

console.log('QF_CLIENT_ID:', QF_CLIENT_ID);
console.log('QF_ENV:', QF_ENV);

const qfClient = createServerClient({
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

async function main() {
  try {
    console.log('\n=== Testing getChapters ===');
    const chapters = await qfClient.content.v4.chapters.list();
    console.log('Chapters type:', typeof chapters);
    console.log('Chapters isArray:', Array.isArray(chapters));
    console.log('Chapters count:', chapters.length || 'N/A');
    console.log('Chapters sample:', JSON.stringify(chapters.slice(0, 2)).substring(0, 300));
  } catch (err) {
    console.error('getChapters error:', err.message);
  }

  try {
    console.log('\n=== Testing byKey (verse) ===');
    const verse = await qfClient.content.v4.verses.byKey('2:255', { fields: 'text' });
    console.log('Verse type:', typeof verse);
    console.log('Verse keys:', Object.keys(verse));
    console.log('Verse text:', verse.text);
  } catch (err) {
    console.error('byKey error:', err.message);
  }

  try {
    console.log('\n=== Testing translations ===');
    const result = await qfClient.content.v4.verses.byKey('2:255', { translations: 'english' });
    console.log('Translations result keys:', Object.keys(result));
    console.log('Translations:', result.translations?.length || 'N/A');
  } catch (err) {
    console.error('translations error:', err.message);
  }

  try {
    console.log('\n=== Testing tafsir ===');
    const result = await qfClient.content.v4.verses.byKey('2:255', { tafsirs: true });
    console.log('Tafsir result keys:', Object.keys(result));
    console.log('Tafsirs:', result.tafsirs?.length || 'N/A');
  } catch (err) {
    console.error('tafsir error:', err.message);
  }

  try {
    console.log('\n=== Testing audio ===');
    const audio = await qfClient.content.v4.audio.chapterRecitation('1', { reciter: 'ar.alafasy' });
    console.log('Audio type:', typeof audio);
    console.log('Audio keys:', Object.keys(audio));
    console.log('Audio:', JSON.stringify(audio).substring(0, 300));
  } catch (err) {
    console.error('audio error:', err.message);
  }
}

main().catch(err => {
  console.error('Fatal:', err.message);
  process.exit(1);
});
