// Watch deployment status for the production environment.
// Usage:  node scripts/railway/status.mjs          -> list latest 5 deployments
//         node scripts/railway/status.mjs --watch  -> poll until the newest one finishes
//
// GOTCHAS (learned the hard way):
//  - deployments list must come from environment(id) { deployments }, NOT the
//    Query.deployments field (that returned [] with this token).
//  - Deployment.meta is a SCALAR (no subfields!) — query it plain, not meta { ... }.
import { gql, IDS } from './common.mjs';

const watch = process.argv.includes('--watch');
const DONE = ['SUCCESS', 'FAILED', 'CRASHED', 'ERROR'];

function short(meta) {
  try {
    const m = typeof meta === 'string' ? JSON.parse(meta) : meta;
    return `${(m?.commitHash ?? '').slice(0, 7)} ${(m?.commitMessage ?? '').slice(0, 48)}`;
  } catch {
    return '';
  }
}

const fetchOnce = async () => {
  const r = await gql(`{
    environment(id: "${IDS.environment}") {
      deployments { edges { node { id status createdAt meta } } }
    }
  }`);
  return (r.data?.environment?.deployments?.edges ?? []).map((e) => e.node);
};

const list = await fetchOnce();
if (list.length === 0) {
  console.log('No deployments listed.');
  process.exit(1);
}

for (const d of list.slice(0, 5)) {
  console.log(`${d.status.padEnd(9)} ${d.id.slice(0, 8)}  ${d.createdAt}  ${short(d.meta)}`);
}

if (watch) {
  const target = list[0];
  console.log(`\nWatching ${target.id.slice(0, 8)} (current: ${target.status}) ...`);
  let last = target.status;
  for (let i = 0; i < 20; i++) {
    await new Promise((r) => setTimeout(r, 40000));
    const nodes = await fetchOnce();
    const cur = nodes.find((n) => n.id === target.id) ?? target;
    if (cur.status !== last) {
      console.log(`[${new Date().toLocaleTimeString('en-GB')}] ${cur.status}`);
      last = cur.status;
    }
    if (DONE.includes(cur.status)) {
      console.log('FINAL:', cur.status);
      process.exit(cur.status === 'SUCCESS' ? 0 : 1);
    }
  }
  console.log('TIMEOUT (~13 min)');
  process.exit(2);
}
