// Trigger a Railway deployment.
// Usage:  node scripts/railway/deploy.mjs [commitSha]
//   - with commitSha: deploys that exact commit
//   - without:        deploys latest commit (latestCommit: true)
// NOTE: right after a git push, Railway's git sync can lag a few seconds —
// if it redeploys an OLD commit ("reason: redeploy"), pass the explicit sha.
import { gql, IDS } from './common.mjs';

const sha = process.argv[2];

let query, variables;
if (sha) {
  query = `mutation Deploy($serviceId: String!, $environmentId: String!, $commitSha: String!) {
    serviceInstanceDeploy(serviceId: $serviceId, environmentId: $environmentId, commitSha: $commitSha)
  }`;
  variables = { serviceId: IDS.service, environmentId: IDS.environment, commitSha: sha };
} else {
  query = `mutation Deploy($serviceId: String!, $environmentId: String!) {
    serviceInstanceDeploy(serviceId: $serviceId, environmentId: $environmentId, latestCommit: true)
  }`;
  variables = { serviceId: IDS.service, environmentId: IDS.environment };
}

const r = await gql(query, variables);
if (r.errors) {
  console.error('TRIGGER FAILED:', JSON.stringify(r.errors, null, 2));
  process.exit(1);
}
console.log('TRIGGERED:', r.data.serviceInstanceDeploy === true ? 'OK' : r.data);
console.log('Ab status dekhein:  node scripts/railway/status.mjs');
