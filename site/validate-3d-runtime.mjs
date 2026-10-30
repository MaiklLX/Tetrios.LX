#!/usr/bin/env node
/**
 * Verifies the pinned local Three.js runtime and offline-safe 3D asset references.
 * Run from the repository root after preparing site/vendor/three.
 */
import { readFile, stat } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = process.cwd();
const read = path => readFile(resolve(root, path), 'utf8');
const exists = async path => {
  try { return (await stat(resolve(root, path))).isFile(); }
  catch { return false; }
};
const fail = message => { console.error(`FAIL: ${message}`); process.exitCode = 1; };

const [index, arena, visual, packageJson, manifestText, audioCredits] = await Promise.all([
  read('site/index.html'),
  read('site/arena-3d.js'),
  read('site/visual-3d.js'),
  read('site/vendor/three/package.json'),
  read('site/characters/manifest.json'),
  read('site/audio/README.txt')
]);

const imports = index.match(/<script type="importmap">\s*([\s\S]*?)\s*<\/script>/)?.[1];
let map;
try { map = JSON.parse(imports); }
catch { fail('index.html must contain a valid JSON import map before module scripts'); }

if (map?.imports?.three !== './vendor/three/build/three.module.js') {
  fail('import map must resolve "three" to the bundled local runtime');
}
if (map?.imports?.['three/addons/'] !== './vendor/three/examples/jsm/') {
  fail('import map must resolve "three/addons/" to the bundled examples modules');
}
if (packageJson.version !== '0.180.0') fail(`expected Three.js 0.180.0, got ${packageJson.version}`);

for (const path of [
  'site/vendor/three/build/three.module.js',
  'site/vendor/three/build/three.core.js',
  'site/vendor/three/examples/jsm/loaders/GLTFLoader.js'
]) {
  if (!await exists(path)) fail(`missing bundled runtime file: ${path}`);
}

if (!arena.includes('./vendor/three/build/three.module.js')) fail('arena-3d.js does not load local Three.js');
if (!visual.includes('./vendor/three/build/three.module.js')) fail('visual-3d.js does not load local Three.js');
if (!visual.includes('three/addons/loaders/GLTFLoader.js')) fail('visual-3d.js does not load the local GLTFLoader');
if (/https?:\/\//i.test(arena + visual)) fail('a remote HTTP(S) dependency remains in a 3D runtime module');
if (/cdn\.jsdelivr\.net\/npm\/three@/i.test(index)) fail('index.html contains a Three.js CDN reference');
if (!index.includes('src="./audio/chills.mp3"')) fail('index.html must use the bundled local soundtrack');
if (!audioCredits.includes('CC0') || !audioCredits.includes('Holizna')) fail('soundtrack attribution must document the author and CC0 license');
if (!await exists('site/audio/chills.mp3')) fail('bundled offline soundtrack is missing: site/audio/chills.mp3');

const importMapPosition = index.indexOf('<script type="importmap">');
for (const modulePath of ['./visual-3d.js', './arena-3d.js']) {
  const modulePosition = index.indexOf(`src="${modulePath}"`);
  if (importMapPosition < 0 || modulePosition < 0 || importMapPosition > modulePosition) {
    fail(`import map must be declared before ${modulePath}`);
  }
}

let manifest;
try { manifest = JSON.parse(manifestText); }
catch { fail('characters/manifest.json must be valid JSON'); }

const requiredCharacters = ['plush', 'prism', 'blip', 'pixel', 'spark'];
for (const id of requiredCharacters) {
  const entry = manifest?.characters?.[id];
  if (!entry || typeof entry !== 'object') {
    fail(`character manifest is missing the "${id}" entry`);
    continue;
  }
  if (entry.model == null) continue; // Procedural fallback remains supported until a licensed GLB is supplied.
  if (typeof entry.model !== 'string' || /^(?:[a-z]+:|\/)/i.test(entry.model) || entry.model.split('/').includes('..')) {
    fail(`character "${id}" must use a safe, relative, in-app model path`);
    continue;
  }
  if (typeof entry.license !== 'string' || !entry.license.trim()) {
    fail(`character "${id}" has a model but no recorded license`);
  }
  const modelPath = `site/${entry.model.replace(/^\.\//, '')}`;
  if (!await exists(modelPath)) fail(`character "${id}" model file is missing: ${modelPath}`);
}

if (process.exitCode) process.exit(process.exitCode);
console.log('PASS: Three.js 0.180.0, GLTFLoader, import-map order and character asset references are valid.');
