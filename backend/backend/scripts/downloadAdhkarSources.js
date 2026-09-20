// Downloads the official Hisnul Muslim dataset from hisnmuslim.com (the
// exact source the Flutter app's bundled data was built from) for the
// languages they publish (ar + en) and saves it locally under backend/data/.
//
//   node backend/scripts/downloadAdhkarSources.js
//
// Output:
//   backend/data/adhkar_source_ar.json  [{ id, title, items: [{id, ar, repeat}] }]
//   backend/data/adhkar_source_en.json  [{ id, title, items: [{id, ar, en, repeat}] }]

import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.resolve(__dirname, '..', '..', 'data');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function getJson(url, attempt = 0) {
  try {
    const res = await fetch(url, { headers: { 'User-Agent': 'SajdaApp/1.0' } });
    if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
    const text = await res.text();
    // Some source files contain raw control characters inside strings —
    // replace them with spaces (valid JSON, harmless content).
    let sanitized = text.replace(/[\u0000-\u001F\u007F]+/g, ' ');
    // en/126.json is malformed upstream: the object key is missing its closing quote.
    sanitized = sanitized.replace(
      /"What to say when you feel frightened:\s*\[/,
      '"What to say when you feel frightened": ['
    );
    return JSON.parse(sanitized);
  } catch (err) {
    if (attempt < 3) {
      await sleep(1500 * (attempt + 1));
      return getJson(url, attempt + 1);
    }
    throw err;
  }
}

async function downloadLanguage(lang) {
  const list = await getJson(`https://www.hisnmuslim.com/api/${lang}/husn_${lang}.json`);
  const entries = Object.values(list)[0];
  if (!Array.isArray(entries)) throw new Error(`Unexpected list payload for ${lang}`);

  const categories = [];
  const failures = [];
  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];
    const id = entry.ID;
    let arr = null;
    try {
      const itemsRaw = await getJson(`https://www.hisnmuslim.com/api/${lang}/${id}.json`);
      arr = Object.values(itemsRaw)[0];
      if (!Array.isArray(arr)) throw new Error('not an array');
    } catch (err) {
      failures.push(id);
      console.warn(`\n  WARN ${lang}/${id}.json failed: ${err.message}`);
      arr = [];
    }
    categories.push({
      id,
      title: entry.TITLE || '',
      items: arr.map((it) => ({
        id: it.ID,
        ar: it.ARABIC_TEXT || '',
        en: lang === 'en' ? it.TRANSLATED_TEXT || '' : undefined,
        repeat: it.REPEAT ?? 1,
      })),
    });
    process.stdout.write(`\r  ${lang}: ${i + 1}/${entries.length} categories`);
    await sleep(250);
  }
  if (failures.length) {
    console.warn(`\n  ${lang} failed categories (empty items kept): ${failures.join(', ')}`);
  }
  process.stdout.write('\n');
  return categories;
}

async function main() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  for (const lang of ['ar', 'en']) {
    const outPath = path.join(DATA_DIR, `adhkar_source_${lang}.json`);
    if (fs.existsSync(outPath)) {
      console.log(`${lang}: already downloaded (${outPath}) — delete to refetch`);
      continue;
    }
    console.log(`Downloading ${lang}…`);
    const categories = await downloadLanguage(lang);
    fs.writeFileSync(outPath, JSON.stringify(categories, null, 1), 'utf8');
    console.log(`  saved ${categories.length} categories → ${outPath}`);
  }
  console.log('Done.');
}

main().catch((err) => {
  console.error('FATAL:', err.message);
  process.exit(1);
});
