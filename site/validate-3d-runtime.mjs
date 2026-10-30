#!/usr/bin/env node
/**
 * Verifies that the pinned Three.js runtime is bundled locally for web and WebView.
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

const [index, arena, visual, packageJson] = await Promise.all([
  read('site/index.html'),
  read('site/arena-3d.js'),
  read('site/visual-3d.js'),
  read('site/vendor/three/package.json')
]);
const imports = index.match(/<script type="importmap">\\s*([\\s\\S]*?)\\s*<\\/script>/)?.[1];
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
]) if (!await exists(path)) fail(`missing bundled runtime file: ${path}`);
if (!arena.includes('./vendor/three/build/three.module.js')) fail('arena-3d.js does not load local Three.js');
if (!visual.includes('./vendor/three/build/three.module.js')) fail('visual-3d.js does not load local Three.js');
if (!visual.includes('three/addons/loaders/GLTFLoader.js')) fail('visual-3d.js does not load the local GLTFLoader');
if (/cdn\\.jsdelivr\\.net\\/npm\\/three@/.test(arena + visual)) fail('a Three.js CDN dependency remains in runtime modules');
if (index.indexOf('type="importmap"') > index.indexOf('src="./visual-3d.js"')) {
  fail('import map must be declared before module scripts');
}
if (process.exitCode) process.exit(process.exitCode);
console.log('PASS: Three.js 0.180.0 and GLTFLoader are bundled locally; no Three.js CDN dependency remains.');
