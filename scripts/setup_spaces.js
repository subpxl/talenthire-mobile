#!/usr/bin/env node

import {
  SPACES_BUCKET,
  SPACES_REGION,
  SPACES_CDN_BASE,
  applyBucketCors,
  createSpacesClient,
  verifyBucket,
} from './lib/spaces.js';

async function main() {
  const client = createSpacesClient();
  console.log(`Verifying bucket ${SPACES_BUCKET} (${SPACES_REGION})...`);
  await verifyBucket(client);
  console.log('Bucket reachable.');

  console.log('Applying CORS policy...');
  await applyBucketCors(client);
  console.log('CORS applied (GET, PUT, HEAD, DELETE).');

  console.log('\nSpaces setup complete.');
  console.log(`Origin : https://${SPACES_BUCKET}.${SPACES_REGION}.digitaloceanspaces.com`);
  console.log(`CDN    : ${SPACES_CDN_BASE}`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
