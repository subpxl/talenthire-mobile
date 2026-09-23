#!/usr/bin/env node
/**
 * Sync force-update defaults from pubspec.yaml to:
 * - mobile/remote_config.json (Firebase Remote Config template)
 * - mobile/lib/core/services/app_version_service.dart (client fallbacks)
 *
 * Usage:
 *   node sync_app_version.js           # dry-run (prints planned changes)
 *   node sync_app_version.js --apply   # write files
 *   node sync_app_version.js --apply --deploy   # write + firebase deploy remoteconfig
 */

import { readFile, writeFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const here = dirname(fileURLToPath(import.meta.url));
const mobileRoot = resolve(here, '..');
const pubspecPath = resolve(mobileRoot, 'pubspec.yaml');
const remoteConfigPath = resolve(mobileRoot, 'remote_config.json');
const versionServicePath = resolve(
  mobileRoot,
  'lib/core/services/app_version_service.dart',
);

function parsePubspecVersion(text) {
  const match = text.match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$/m);
  if (!match) {
    throw new Error(
      'Could not parse version from pubspec.yaml (expected format: 1.0.0+29)',
    );
  }
  return { versionName: match[1], buildNumber: Number(match[2], 10) };
}

function patchRemoteConfig(json, { versionName, buildNumber }) {
  const next = structuredClone(json);
  const desc =
    `Minimum build allowed to use the app. Synced from pubspec ${versionName}+${buildNumber}.`;
  next.parameters.min_android_build.defaultValue.value = String(buildNumber);
  next.parameters.min_android_build.description = desc.replace(
    'build',
    'Android versionCode',
  );
  next.parameters.min_ios_build.defaultValue.value = String(buildNumber);
  next.parameters.min_ios_build.description = desc.replace(
    'build',
    'iOS CFBundleVersion',
  );
  next.parameters.min_version.defaultValue.value = versionName;
  next.parameters.min_version.description =
    'Minimum marketing version shown on the force-update screen.';
  return next;
}

function patchVersionService(source, { versionName, buildNumber }) {
  let next = source;
  next = next.replace(
    /static const currentMinBuild = \d+;/,
    `static const currentMinBuild = ${buildNumber};`,
  );
  next = next.replace(
    /static const currentMinVersion = '[^']*';/,
    `static const currentMinVersion = '${versionName}';`,
  );
  next = next.replace(
    /\/\/\/ Current production APK[^\n]*\n/,
    `/// Synced from pubspec: versionName ${versionName}, build ${buildNumber}.\n`,
  );
  return next;
}

async function main() {
  const apply = process.argv.includes('--apply');
  const deploy = process.argv.includes('--deploy');

  const pubspec = await readFile(pubspecPath, 'utf8');
  const parsed = parsePubspecVersion(pubspec);
  const { versionName, buildNumber } = parsed;

  console.log(`Pubspec version: ${versionName}+${buildNumber}`);

  const remoteRaw = await readFile(remoteConfigPath, 'utf8');
  const remoteJson = JSON.parse(remoteRaw);
  const remoteNext = patchRemoteConfig(remoteJson, parsed);

  const serviceRaw = await readFile(versionServicePath, 'utf8');
  const serviceNext = patchVersionService(serviceRaw, parsed);

  const remoteOut = `${JSON.stringify(remoteNext, null, 2)}\n`;
  const remoteChanged = remoteOut !== remoteRaw.endsWith('\n')
    ? remoteOut !== remoteRaw
    : remoteOut !== remoteRaw;

  const serviceChanged = serviceNext !== serviceRaw;

  if (!remoteChanged && !serviceChanged) {
    console.log('All version targets already match pubspec.');
  } else {
    console.log('Planned updates:');
    if (remoteChanged) console.log('  - remote_config.json');
    if (serviceChanged) console.log('  - app_version_service.dart');
  }

  if (!apply) {
    if (remoteChanged || serviceChanged) {
      console.log('\nRe-run with --apply to write changes.');
    }
    return;
  }

  if (remoteChanged) {
    await writeFile(remoteConfigPath, remoteOut, 'utf8');
    console.log('Wrote remote_config.json');
  }
  if (serviceChanged) {
    await writeFile(versionServicePath, serviceNext, 'utf8');
    console.log('Wrote app_version_service.dart');
  }

  if (deploy) {
    console.log('\nDeploying Remote Config template to Firebase...');
    const result = spawnSync(
      'firebase',
      ['deploy', '--only', 'remoteconfig'],
      { cwd: mobileRoot, stdio: 'inherit', shell: true },
    );
    if (result.status !== 0) {
      process.exit(result.status ?? 1);
    }
    console.log('Remote Config deployed.');
  } else if (remoteChanged) {
    console.log(
      '\nDeploy when ready: cd mobile && firebase deploy --only remoteconfig',
    );
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
