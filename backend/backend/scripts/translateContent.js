// ============================================================================
// translateContent.js — automated multi-language batch translation
//
// Populates the translations object (ar / ur / en / hi / id) for:
//   1. Ayat of the Day  → collection `ayat_translations` (one doc per ayah)
//      Arabic + official human translations fetched from AlQuran Cloud
//      (quran-uthmani, ur.jalandhry, en.sahih, hi.hindi, id.indonesian).
//      No AI needed — sources are official editions.
//   2. Adhkar           → collection `adhkar_categories` (Hisnul Muslim)
//      Parsed from the bundled Flutter dataset (lib/data/azkar_data.dart)
//      and machine-translated with Gemini or OpenAI (whichever key is set).
//
// Usage (run from D:\sajda_app\backend):
//   node backend/scripts/translateContent.js                 # everything
//   node backend/scripts/translateContent.js --only=ayat     # no AI needed
//   node backend/scripts/translateContent.js --only=adhkar   # needs AI key
//   node backend/scripts/translateContent.js --dry-run       # plan only
//   node backend/scripts/translateContent.js --limit=20      # first N docs
//   node backend/scripts/translateContent.js --force         # re-translate
//
// Env (backend/.env): MONGODB_URI + GEMINI_API_KEY or OPENAI_API_KEY
// Resumable: adhkar items that already have a translation are skipped,
// progress is saved after every category, so a partial run can just rerun.
// ============================================================================

import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';
import '../config/env.js';
import connectDB from '../config/db.js';
import AyatTranslation from '../models/AyatTranslation.js';
import AdhkarCategory from '../models/AdhkarCategory.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..', '..');
const AZKAR_DATA_PATH =
  process.env.AZKAR_DATA_PATH ||
  path.join(REPO_ROOT, 'lib', 'data', 'azkar_data.dart');

const args = process.argv.slice(2);
const opt = (name, def = null) => {
  const hit = args.find((a) => a === `--${name}` || a.startsWith(`--${name}=`));
  if (!hit) return def;
  const idx = hit.indexOf('=');
  return idx === -1 ? true : hit.slice(idx + 1);
};
const DRY_RUN = !!opt('dry-run');
const FORCE = !!opt('force');
const ONLY = opt('only'); // 'ayat' | 'adhkar' | null (both)
const LIMIT = parseInt(opt('limit', '0'), 10) || 0;
const DELAY_MS = parseInt(opt('delay', '1200'), 10);
const AI_BATCH = parseInt(opt('batch', '8'), 10); // items per AI call

// Which output languages to produce (default: all four). e.g. --langs=en
const TARGETS = (opt('langs', 'ur,en,hi,id') || 'ur,en,hi,id')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

const LANG_NAMES = { ur: 'Urdu', en: 'English', hi: 'Hindi', id: 'Indonesian' };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (...m) => console.log(...m);

// ---------------------------------------------------------------------------
// Phase 1 — Ayat of the Day (official AlQuran Cloud editions)
// ---------------------------------------------------------------------------

const AYAT_EDITIONS = {
  ar: 'quran-uthmani',
  ur: 'ur.jalandhry',
  en: 'en.sahih',
  hi: 'hi.hindi',
  id: 'id.indonesian',
};

async function fetchEdition(edition) {
  const url = `https://api.alquran.cloud/v1/quran/${edition}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`AlQuran Cloud ${edition} failed: HTTP ${res.status}`);
  const json = await res.json();
  const surahs = json?.data?.surahs;
  if (!Array.isArray(surahs)) throw new Error(`AlQuran Cloud ${edition}: unexpected payload`);
  const map = new Map();
  for (const surah of surahs) {
    for (const ayah of surah.ayahs) {
      map.set(`${surah.number}:${ayah.numberInSurah}`, ayah.text);
    }
  }
  log(`  fetched ${edition}: ${map.size} ayahs`);
  return map;
}

async function translateAyat() {
  log('\n── Phase 1: Ayat of the Day (AlQuran Cloud official editions) ──');

  const existing = await AyatTranslation.estimatedDocumentCount();
  if (!FORCE && existing >= 6236) {
    log(`  already seeded (${existing} docs). Use --force to refresh. Skipping.`);
    return;
  }
  if (DRY_RUN) {
    log(`  [dry-run] would fetch 5 editions and upsert ~6236 docs (currently ${existing}).`);
    return;
  }

  const maps = {};
  for (const [lang, edition] of Object.entries(AYAT_EDITIONS)) {
    maps[lang] = await fetchEdition(edition);
    await sleep(400);
  }

  const ops = [];
  for (let s = 1; s <= 114; s++) {
    for (let a = 1; a <= 999; a++) {
      const key = `${s}:${a}`;
      const arabic = maps.ar.get(key);
      if (!arabic) break;
      const translations = { ar: arabic };
      for (const lang of TARGETS) translations[lang] = maps[lang].get(key) || '';
      ops.push({
        updateOne: {
          filter: { surah: s, ayah: a },
          update: {
            $set: { arabic, translations, source: 'alquran.cloud' },
          },
          upsert: true,
        },
      });
      if (LIMIT && ops.length >= LIMIT) break;
    }
    if (LIMIT && ops.length >= LIMIT) break;
  }

  for (let i = 0; i < ops.length; i += 500) {
    const chunk = ops.slice(i, i + 500);
    await AyatTranslation.bulkWrite(chunk, { ordered: false });
    log(`  upserted ${Math.min(i + 500, ops.length)}/${ops.length}`);
  }
  log(`  ✔ ayat_translations seeded: ${ops.length} docs`);
}

// ---------------------------------------------------------------------------
// Phase 2 — Adhkar (AI translation: Gemini or OpenAI)
// ---------------------------------------------------------------------------

function aiProvider() {
  if (process.env.GEMINI_API_KEY) return 'gemini';
  if (process.env.OPENAI_API_KEY) return 'openai';
  return null;
}

const systemPrompt = () => [
  'You are an expert translator of Islamic supplications (adhkar / duas) from Classical Arabic.',
  `Translate each Arabic dhikr into ${TARGETS.map((l) => LANG_NAMES[l] || l).join(', ')} (codes: ${TARGETS.join(', ')}).`,
  'Keep the meaning accurate and respectful; use standard Islamic terminology',
  '(e.g. "Rabb", "اللہ" as "Allah"), natural sentence flow, and conventional du\u2019a wording.',
  'Do not transliterate the whole text; produce a real translation in each language.',
  'Return ONLY valid JSON with exactly this shape:',
  `{"name":{${TARGETS.map((l) => `"${l}":"..."`).join(',')}},"items":[{"i":<int>,${TARGETS.map((l) => `"${l}":"..."`).join(',')}}]}`,
  'Every item index "i" from the input must appear exactly once in the output.',
].join(' ');

function extractJson(text) {
  const trimmed = text.trim().replace(/^```(?:json)?/i, '').replace(/```$/, '');
  return JSON.parse(trimmed);
}

async function callGemini(userPayload, key) {
  // New-style Google keys (AQ.… ) only work via the x-goog-api-key header.
  // flash-lite has a larger free-tier quota than flash.
  const model = process.env.GEMINI_MODEL || 'gemini-flash-lite-latest';
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt() }] },
        contents: [{ role: 'user', parts: [{ text: userPayload }] }],
        generationConfig: { temperature: 0.2, responseMimeType: 'application/json', maxOutputTokens: 8192 },
      }),
    }
  );
  if (!res.ok) throw Object.assign(new Error(`Gemini HTTP ${res.status}`), { status: res.status });
  const json = await res.json();
  const text = json?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('');
  if (!text) throw new Error('Gemini returned no content');
  return extractJson(text);
}

async function callOpenAI(userPayload, key) {
  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${key}` },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      temperature: 0.2,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: systemPrompt() },
        { role: 'user', content: userPayload },
      ],
    }),
  });
  if (!res.ok) throw Object.assign(new Error(`OpenAI HTTP ${res.status}`), { status: res.status });
  const json = await res.json();
  return extractJson(json?.choices?.[0]?.message?.content || '');
}

async function translateWithRetry(userPayload) {
  const provider = aiProvider();
  const key = provider === 'gemini' ? process.env.GEMINI_API_KEY : process.env.OPENAI_API_KEY;
  let lastErr;
  for (let attempt = 0; attempt < 4; attempt++) {
    try {
      return provider === 'gemini'
        ? await callGemini(userPayload, key)
        : await callOpenAI(userPayload, key);
    } catch (err) {
      lastErr = err;
      const retriable =
        [429, 500, 502, 503].includes(err.status) ||
        /fetch|network|no content/i.test(err.message);
      if (!retriable) throw err;
      await sleep(2000 * 2 ** attempt);
    }
  }
  throw lastErr;
}

function loadBundledAdhkar() {
  const raw = fs.readFileSync(AZKAR_DATA_PATH, 'utf8');
  const start = raw.indexOf('List azkar =');
  if (start === -1) throw new Error(`azkar_data.dart: "List azkar =" not found`);
  const arrStart = raw.indexOf('[', start);
  const arrEnd = raw.lastIndexOf(']');
  let body = raw.slice(arrStart, arrEnd + 1);
  try {
    return JSON.parse(body);
  } catch (_) {
    // Tolerate Dart-isms like trailing commas before a retry.
    body = body.replace(/,(\s*[}\]])/g, '$1');
    return JSON.parse(body);
  }
}

function missingLangs(obj) {
  if (FORCE) return TARGETS;
  return TARGETS.filter((l) => !obj?.translations?.[l]);
}

// ---------------------------------------------------------------------------
// Phase 2 helper — official English overlay from locally downloaded sources
// (backend/data/adhkar_source_*.json, fetched by downloadAdhkarSources.js
// from hisnmuslim.com — the site the bundled dataset originates from).
// ---------------------------------------------------------------------------

const SOURCE_DIR = path.resolve(__dirname, '..', '..', 'data');

function normalizeArabic(text) {
  return (text || '')
    .replace(/[\u064B-\u0652\u0670\u0640]/g, '') // harakat, dagger alif, tatweel
    .replace(/[^\u0621-\u064A]/g, '') // keep Arabic letters only
    .replace(/[\u0622\u0623\u0625]/g, '\u0627') // unify alef forms
    .replace(/\u0649/g, '\u064A') // ى → ي
    .replace(/\u0629/g, '\u0647') // ة → ه
    .trim();
}

async function ensureDoc(cat) {
  const items = cat.array || [];
  let doc = await AdhkarCategory.findOne({ categoryId: cat.id });
  if (!doc) {
    doc = await AdhkarCategory.create({
      categoryId: cat.id,
      category: cat.category || '',
      audio: cat.audio || '',
      items: items.map((it) => ({
        itemId: it.id ?? 0, // a few bundled items lack "id"; Flutter defaults them to 0
        text: it.text || '',
        count: it.count ?? 1,
        audio: it.audio || '',
      })),
    });
  }
  return doc;
}

async function applyOfficialOverlay(bundled) {
  const arPath = path.join(SOURCE_DIR, 'adhkar_source_ar.json');
  const enPath = path.join(SOURCE_DIR, 'adhkar_source_en.json');
  if (!fs.existsSync(arPath) || !fs.existsSync(enPath)) {
    log('  ⚠ adhkar_source_ar/en.json missing in backend/data — run downloadAdhkarSources.js first');
    return;
  }
  // Match on the Arabic dataset (titles + item texts); English values are
  // looked up from the en dataset via the shared hisnmuslim.com IDs.
  const arCats = JSON.parse(fs.readFileSync(arPath, 'utf8'));
  const enCats = JSON.parse(fs.readFileSync(enPath, 'utf8'));
  const enById = new Map(enCats.map((c) => [c.id, c]));
  const byTitle = new Map();
  for (const c of arCats) {
    const key = normalizeArabic(c.title);
    if (key && !byTitle.has(key)) byTitle.set(key, c);
  }
  // Global text index — bundled items sometimes live in a different
  // hisnmuslim category than their bundled one.
  const globalIndex = new Map();
  for (const c of arCats) {
    for (const it of c.items || []) {
      const n = normalizeArabic(it.ar);
      if (n && !globalIndex.has(n)) {
        const enText = enById.get(c.id)?.items?.find((e) => e.id === it.id)?.en;
        if (enText) globalIndex.set(n, { en: enText, ar: it.ar });
      }
    }
  }
  const globalNorms = [...globalIndex.entries()];

  let matchedCats = 0;
  let matchedItems = 0;
  let unmatchedItems = 0;

  for (const cat of bundled) {
    const src = byTitle.get(normalizeArabic(cat.category));
    const doc = await ensureDoc(cat);
    let dirty = false;
    const enCat = src && enById.get(src.id);

    if ((FORCE || !doc.translations?.en) && enCat?.title) {
      doc.translations = { ...(doc.translations || {}), en: enCat.title };
      dirty = true;
    }

    // Resolve doc items positionally when bundled ids collide (the bundled
    // dataset reuses id 17 for every item of some categories).
    const bundledItems = cat.array || [];
    const positional = bundledItems.length === doc.items.length;
    const resolveDocItem = (idx, item) =>
      positional ? doc.items[idx] : doc.items.find((i) => i.itemId === item.id);

    bundledItems.forEach((item, idx) => {
      const docItem = resolveDocItem(idx, item);
      if (!docItem) return;
      if (!FORCE && docItem.translations?.en) return;
      const n = normalizeArabic(item.text);
      let hit = globalIndex.get(n);
      if (!hit) {
        // containment fallback for slightly edited texts
        for (const [sn, entry] of globalNorms) {
          const min = Math.min(sn.length, n.length);
          const max = Math.max(sn.length, n.length);
          if (min > 0 && (sn.includes(n) || n.includes(sn)) && min / max > 0.85) {
            hit = entry;
            break;
          }
        }
      }
      if (hit?.en) {
        docItem.translations = { ...(docItem.translations || {}), en: hit.en };
        matchedItems++;
        dirty = true;
      } else {
        unmatchedItems++;
      }
    });

    if (dirty) {
      doc.markModified('items');
      doc.markModified('translations');
      await doc.save();
      matchedCats++;
    }
  }
  log(
    `  ✔ official English overlay: ${matchedCats} categories, ${matchedItems} items matched` +
      (unmatchedItems ? `, ${unmatchedItems} left for AI` : '')
  );
}

async function translateAdhkar() {
  log('\n── Phase 2: Adhkar (Hisnul Muslim) ──');

  const provider = aiProvider();
  if (!provider) {
    log('  ⚠ No GEMINI_API_KEY / OPENAI_API_KEY found in environment.');
    log('    Set one in backend/.env and rerun with --only=adhkar');
  }
  if (DRY_RUN) {
    let cats = 0;
    let items = 0;
    try {
      const bundled = loadBundledAdhkar();
      const existing = await AdhkarCategory.find({}).lean();
      const byId = new Map(existing.map((c) => [c.categoryId, c]));
      for (const cat of bundled) {
        const doc = byId.get(cat.id);
        if (missingLangs(doc).length || missingLangs(cat).length) cats++;
        for (const item of cat.array || []) {
          const docItem = doc?.items?.find((i) => i.id === item.id);
          if (missingLangs(docItem).length || missingLangs(item).length) items++;
        }
      }
    } catch (err) {
      log(`  could not build plan: ${err.message}`);
      return;
    }
    log(`  [dry-run] provider=${provider || 'NONE'} | categories to translate: ${cats} | items: ${items}`);
    return;
  }
  if (!provider) return;

  const bundled = loadBundledAdhkar();
  const totalCats = bundled.length;
  let doneItems = 0;
  let failedCats = 0;

  // Step 1: fill English from the official hisnmuslim.com dataset where possible.
  await applyOfficialOverlay(bundled);

  for (let ci = 0; ci < totalCats; ci++) {
    const cat = bundled[ci];
    if (LIMIT && ci >= LIMIT) break;
    const items = cat.array || [];
    const doc = await ensureDoc(cat);

    const catLangs = missingLangs(doc);
    // Positional resolution when bundled ids collide (some bundled categories
    // reuse the same id for every item).
    const positional = items.length === doc.items.length;
    const pendingItems = items
      .map((it, idx) => {
        const docItem = positional
          ? doc.items[idx]
          : doc.items.find((i) => i.itemId === it.id);
        const langs = missingLangs(docItem);
        return { it, docItem, langs };
      })
      .filter((p) => p.langs.length > 0);

    if (!catLangs.length && !pendingItems.length) continue;

    process.stdout.write(
      `  [${ci + 1}/${totalCats}] "${(cat.category || '').slice(0, 32)}" — ${pendingItems.length} items…\n`
    );

    try {
      if (!pendingItems.length && catLangs.length) {
        // All items done, only the category name needs translating.
        const out = await translateWithRetry(
          JSON.stringify({ name: cat.category, items: [] })
        );
        if (out.name) {
          const mergedCat = { ...(doc.translations || {}) };
          for (const lang of catLangs) {
            if (typeof out.name[lang] === 'string' && out.name[lang].trim()) {
              mergedCat[lang] = out.name[lang].trim();
            }
          }
          doc.translations = mergedCat;
          doc.markModified('translations');
          await doc.save();
        }
        continue;
      }
      // Translate items in chunks of AI_BATCH.
      for (let start = 0; start < pendingItems.length; start += AI_BATCH) {
        const chunk = pendingItems.slice(start, start + AI_BATCH);
        const payload = JSON.stringify({
          name: catLangs.length ? cat.category : undefined,
          items: chunk.map((p, idx) => ({ i: idx, text: p.it.text })),
        });
        const out = await translateWithRetry(payload);
        const byIndex = new Map((out.items || []).map((o) => [parseInt(o.i, 10), o]));

        chunk.forEach((p, idx) => {
          const tr = byIndex.get(idx);
          if (!tr || !p.docItem) return;
          const merged = { ...(p.docItem.translations || {}) };
          for (const lang of p.langs) {
            if (typeof tr[lang] === 'string' && tr[lang].trim()) merged[lang] = tr[lang].trim();
          }
          p.docItem.translations = merged;
          doneItems++;
        });

        if (catLangs.length && start === 0 && out.name) {
          const mergedCat = { ...(doc.translations || {}) };
          for (const lang of catLangs) {
            if (typeof out.name[lang] === 'string' && out.name[lang].trim()) {
              mergedCat[lang] = out.name[lang].trim();
            }
          }
          doc.translations = mergedCat;
        }
        await sleep(DELAY_MS);
      }
      // Mark remaining category langs as translated even if the name came in
      // a later chunk (name is sent with the first chunk only).
      doc.markModified('items');
      doc.markModified('translations');
      await doc.save();
    } catch (err) {
      failedCats++;
      log(`    ✖ failed (will retry on next run): ${err.message}`);
      try {
        doc.markModified('items');
        await doc.save(); // persist whatever partial progress we have
      } catch (_) { /* ignore */ }
    }
  }

  log(`  ✔ adhkar done: ${doneItems} item translations, ${failedCats} failed categories`);
}

// ---------------------------------------------------------------------------

async function main() {
  const t0 = Date.now();
  log(`translateContent — dry-run=${DRY_RUN} only=${ONLY || 'all'} limit=${LIMIT || '∞'} force=${FORCE}`);
  await connectDB();
  if (!mongoose.connection.db) throw new Error('MongoDB connection failed (check MONGODB_URI)');

  if (!ONLY || ONLY === 'ayat') await translateAyat();
  if (!ONLY || ONLY === 'adhkar') await translateAdhkar();

  log(`\nDone in ${((Date.now() - t0) / 1000).toFixed(1)}s`);
  await mongoose.disconnect();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('\nFATAL:', err.message);
  try { await mongoose.disconnect(); } catch (_) { /* ignore */ }
  process.exit(1);
});
