#!/usr/bin/env node
/**
 * Tetrios.LX mascot asset gate.
 * Run from repository root: node site/characters/validate-manifest.mjs
 *
 * This intentionally validates local, reviewed assets only. It does not download
 * remote models, and an empty manifest is valid while procedural mascots are used.
 */
import { readFile, stat } from 'node:fs/promises';
import { dirname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const manifestPath = resolve(here, 'manifest.json');
const root = resolve(here, '..', '..');
const errors = [];
const warnings = [];
const requiredCharacters = ['plush', 'prism', 'blip', 'pixel', 'spark'];

function fail(message) { errors.push(message); }
function warn(message) { warnings.push(message); }

let manifest;
try {
  manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
} catch (error) {
  console.error(`FAIL: cannot read valid JSON at ${manifestPath}: ${error.message}`);
  process.exit(1);
}

if (manifest.schemaVersion !== 1) fail('schemaVersion must be 1');
if (manifest.coordinateSystem !== 'Y-up') fail('coordinateSystem must be "Y-up"');
if (!Number.isFinite(manifest.targetHeight) || manifest.targetHeight <= 0) {
  fail('targetHeight must be a positive number');
}
if (!manifest.characters || typeof manifest.characters !== 'object') {
  fail('characters must be an object');
} else {
  for (const id of requiredCharacters) {
    if (!Object.hasOwn(manifest.characters, id)) fail(`missing character entry: ${id}`);
  }

  for (const [id, entry] of Object.entries(manifest.characters)) {
    if (!entry || typeof entry !== 'object') {
      fail(`${id}: entry must be an object`);
      continue;
    }
    if (entry.model == null) {
      if (entry.license != null) warn(`${id}: license is set but model is null`);
      console.log(`FALLBACK ${id}: no GLB configured; procedural mascot will be used`);
      continue;
    }
    if (typeof entry.model !== 'string' || !entry.model.toLowerCase().endsWith('.glb')) {
      fail(`${id}: model must be a relative .glb path`);
      continue;
    }
    if (/^(?:https?:)?\/\//i.test(entry.model) || entry.model.includes('..') || entry.model.startsWith('/')) {
      fail(`${id}: model must be a safe relative path inside site/characters`);
      continue;
    }
    if (!entry.license || typeof entry.license !== 'object' ||
        typeof entry.license.name !== 'string' || !entry.license.name.trim() ||
        typeof entry.license.source !== 'string' || !/^https:\/\//.test(entry.license.source)) {
      fail(`${id}: model requires license.name and an HTTPS license.source URL`);
    }
    const modelPath = resolve(root, entry.model.replace(/^\.\//, ''));
    if (!modelPath.startsWith(root + sep)) {
      fail(`${id}: resolved model path escapes the site directory`);
      continue;
    }
    try {
      const info = await stat(modelPath);
      if (!info.isFile()) {
        fail(`${id}: model path is not a file: ${entry.model}`);
        continue;
      }
      if (info.size < 20) {
        fail(`${id}: GLB file is suspiciously small (${info.size} bytes)`);
        continue;
      }
      const header = Buffer.alloc(12);
      const { open } = await import('node:fs/promises');
      const handle = await open(modelPath, 'r');
      try { await handle.read(header, 0, header.length, 0); } finally { await handle.close(); }
      if (header.toString('ascii', 0, 4) !== 'glTF') fail(`${id}: invalid GLB magic header`);
      if (header.readUInt32LE(4) !== 2) fail(`${id}: only GLB version 2 is supported`);
      if (header.readUInt32LE(8) !== info.size) fail(`${id}: GLB header length does not match file size`);
      console.log(`ASSET ${id}: ${entry.model} (${info.size} bytes; GLB v2 header valid)`);
    } catch {
      fail(`${id}: model file does not exist: ${entry.model}`);
    }
    if (entry.animations != null && typeof entry.animations !== 'object') {
      fail(`${id}: animations must be an object when provided`);
    }
  }
}

if (warnings.length) {
  console.warn('\nWarnings:');
  for (const message of warnings) console.warn(`- ${message}`);
}
if (errors.length) {
  console.error('\nAsset validation failed:');
  for (const message of errors) console.error(`- ${message}`);
  process.exit(1);
}
console.log(`\nPASS: manifest schema valid. ${requiredCharacters.length} mascot entries checked.`);
