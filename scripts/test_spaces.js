#!/usr/bin/env node

import {
  createPresignedUploadUrl,
  createSpacesClient,
  listAllObjects,
  publicObjectUrl,
} from './lib/spaces.js';

async function testCdnGet(objectPath) {
  const url = publicObjectUrl(objectPath);
  const res = await fetch(url, { method: 'GET' });
  return { url, status: res.status, ok: res.ok, bytes: res.headers.get('content-length') };
}

async function testCorsPreflight(cdnUrl) {
  const origin = 'https://talenthire-d86a1.web.app';
  const res = await fetch(cdnUrl, {
    method: 'OPTIONS',
    headers: {
      Origin: origin,
      'Access-Control-Request-Method': 'PUT',
      'Access-Control-Request-Headers': 'content-type',
    },
  });
  return {
    status: res.status,
    allowOrigin: res.headers.get('access-control-allow-origin'),
    allowMethods: res.headers.get('access-control-allow-methods'),
    allowHeaders: res.headers.get('access-control-allow-headers'),
  };
}

async function testPresignedPut() {
  const objectPath = `_migration_test/cors-put-${Date.now()}.txt`;
  const { uploadUrl, publicUrl } = await createPresignedUploadUrl(objectPath, 'text/plain');
  const putRes = await fetch(uploadUrl, {
    method: 'PUT',
    headers: {
      'Content-Type': 'text/plain',
      'x-amz-acl': 'public-read',
    },
    body: 'spaces migration test',
  });
  const getRes = await testCdnGet(objectPath);
  return {
    putStatus: putRes.status,
    putOk: putRes.ok,
    publicUrl,
    get: getRes,
  };
}

async function main() {
  const client = createSpacesClient();
  const keys = await listAllObjects(client);
  console.log(`Objects in bucket: ${keys.length}`);

  const samplePath = keys.find((k) => k.startsWith('job-images/')) || keys[0];
  let get = { ok: false };
  if (samplePath) {
    get = await testCdnGet(samplePath);
    console.log('\nCDN GET test');
    console.log(JSON.stringify(get, null, 2));
    const cors = await testCorsPreflight(get.url);
    console.log('\nCORS preflight (browser PUT simulation)');
    console.log(JSON.stringify(cors, null, 2));
  }

  console.log('\nPresigned PUT test');
  const put = await testPresignedPut();
  console.log(JSON.stringify(put, null, 2));

  const passed = (samplePath ? get.ok : true) && put.putOk && put.get.ok;

  console.log(`\nOverall: ${passed ? 'PASS' : 'FAIL'}`);
  process.exitCode = passed ? 0 : 1;
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
