// Print logs of a deployment (crash diagnosis ke liye).
// Usage:  node scripts/railway/logs.mjs <deploymentId>
//         (id ke pehle 8 letters bhi chalenge — poori id se match karte hain)
//
// GOTCHA: deploymentLogs returns a FLAT list of Log nodes
//         ({ message, severity, timestamp }) — NOT { edges { node { ... } } }.
import { gql } from './common.mjs';

const arg = process.argv[2];
if (!arg) {
  console.error('Usage: node scripts/railway/logs.mjs <deploymentId>');
  process.exit(1);
}

// resolve short id -> full id via environment deployments
let depId = arg;
if (arg.length < 36) {
  const { IDS } = await import('./common.mjs');
  const r = await gql(`{
    environment(id: "${IDS.environment}") {
      deployments { edges { node { id } } }
    }
  }`);
  const all = (r.data?.environment?.deployments?.edges ?? []).map((e) => e.node.id);
  const found = all.find((id) => id.startsWith(arg));
  if (!found) {
    console.error('Short id not matched. Pehle status.mjs chalayein.');
    process.exit(1);
  }
  depId = found;
}

const r = await gql(`{
  deploymentLogs(deploymentId: "${depId}", limit: 100) {
    message severity timestamp
  }
}`);
if (r.errors) {
  console.error(JSON.stringify(r.errors, null, 2));
  process.exit(1);
}
for (const e of r.data.deploymentLogs) {
  console.log(`[${e.severity ?? 'info'}] ${e.message}`);
}
