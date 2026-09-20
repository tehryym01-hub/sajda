// One-time content auto-seed.
//
// Production DBs start EMPTY (adhkar categories + ayat-of-the-day
// translations), which left those features dead until someone manually ran
// the seeder against the right database. This runs on boot: if either
// collection is empty, it inserts the bundled snapshot
// (backend/data/content_seed.json.gz — exported from the seeded local DB).
//
// - Idempotent: only fires when a collection is empty.
// - Never blocks or breaks boot: every failure is swallowed and logged.
import { readFileSync, existsSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

import AdhkarCategory from '../models/AdhkarCategory.js';
import AyatTranslation from '../models/AyatTranslation.js';

const SEED_FILE = join(
  dirname(fileURLToPath(import.meta.url)),
  '..',
  'data',
  'content_seed.json.gz',
);

export async function autoSeedContent() {
  try {
    const [adhkarCount, ayatCount] = await Promise.all([
      AdhkarCategory.estimatedDocumentCount(),
      AyatTranslation.estimatedDocumentCount(),
    ]);
    if (adhkarCount > 0 && ayatCount > 0) return;

    if (!existsSync(SEED_FILE)) {
      console.warn('[autoSeed] content_seed.json.gz missing — skipping');
      return;
    }
    const seed = JSON.parse(gunzipSync(readFileSync(SEED_FILE)));

    if (adhkarCount === 0 && Array.isArray(seed.adhkarcategories) && seed.adhkarcategories.length) {
      await AdhkarCategory.insertMany(seed.adhkarcategories, { ordered: false });
      console.log(`[autoSeed] adhkarcategories seeded: ${seed.adhkarcategories.length}`);
    }
    if (ayatCount === 0 && Array.isArray(seed.ayattranslations) && seed.ayattranslations.length) {
      const rows = seed.ayattranslations;
      for (let i = 0; i < rows.length; i += 500) {
        await AyatTranslation.insertMany(rows.slice(i, i + 500), { ordered: false });
      }
      console.log(`[autoSeed] ayattranslations seeded: ${rows.length}`);
    }
  } catch (e) {
    console.warn('[autoSeed] skipped:', e?.message || e);
  }
}
