// Shared config for Railway deploy scripts.
// Token priority: RAILWAY_TOKEN env var -> ../../.railway_token file (gitignored).
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));

export const GRAPHQL = 'https://backboard.railway.app/graphql/v2'; // plain /graphql = 404!

export const IDS = {
  workspace: 'ea6d93be-f71f-4f4d-aafd-2edfd30b0cb1',
  project: 'b9aafb99-a3b1-487c-bbe5-556f016536d9', // sajda-prod
  environment: '7034f999-8ac3-4c5b-b079-f59a5b582f64', // production
  service: 'a0c5e65a-849c-4eba-b7d4-6f7b38ac84f2', // backend
};

export function getToken() {
  if (process.env.RAILWAY_TOKEN) return process.env.RAILWAY_TOKEN.trim();
  try {
    return readFileSync(join(here, '..', '..', '.railway_token'), 'utf8').trim();
  } catch {
    console.error('Token not found. Put it in .railway_token (repo root) or set RAILWAY_TOKEN.');
    process.exit(1);
  }
}

export async function gql(query, variables) {
  const res = await fetch(GRAPHQL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${getToken()}`,
    },
    body: JSON.stringify({ query, variables }),
  });
  return await res.json();
}
