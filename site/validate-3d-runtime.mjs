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

const [index, arena, visual, packageJsonText, manifestText, audioCredits, mobileCss] = await Promise.all([
  read('site/index.html'),
  read('site/arena-3d.js'),
  read('site/visual-3d.js'),
  read('site/vendor/three/package.json'),
  read('site/characters/manifest.json'),
  read('site/audio/README.txt'),
  read('site/visual-overhaul.css')
]);

let packageJson;
try { packageJson = JSON.parse(packageJsonText); }
catch { fail('Three.js package.json must be valid JSON'); }

const imports = index.match(/<script type="importmap">\s*([\s\S]*?)\s*<\/script>/)?.[1];
let map;
try { map = JSON.parse(imports); }
catch { fail('index.html must contain a valid JSON import map before module scripts'); }

const inlineScriptStart = index.indexOf('<script>');
const inlineScriptEnd = index.indexOf('</script>', inlineScriptStart);
const inlineGameScript = inlineScriptStart >= 0 && inlineScriptEnd > inlineScriptStart
  ? index.slice(inlineScriptStart + 8, inlineScriptEnd)
  : '';
if (!inlineGameScript) fail('index.html must contain the main inline gameplay script');
else {
  try { new Function(inlineGameScript); }
  catch (error) { fail('main inline gameplay script has a syntax error: ' + error.message); }
}

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

if (!arena.includes('new THREE.OrthographicCamera(') || !arena.includes('camera.position.set(0,0,34)')) fail('3D arena camera must face the board head-on without a horizontal/vertical offset');
if (!arena.includes('boardCanvas.getBoundingClientRect()') || !arena.includes('boardRect.left-frameRect.left-frame.clientLeft') || !arena.includes('boardRect.top-frameRect.top-frame.clientTop')) fail('3D arena canvas must align to the exact visible 2D board bounds');
if (!arena.includes('viewHeight=Math.max(arenaHeight,arenaWidth/aspect)*1.025') || !arena.includes('camera.left=-viewWidth/2') || !arena.includes('camera.right=viewWidth/2')) fail('3D arena must fit the full board and rails to the exact board aspect ratio');
if (arena.includes('camera.position.x=3+') || arena.includes('camera.position.y=2+')) fail('3D arena must not reintroduce the off-centre camera drift that crops the board');
if (!arena.includes('./vendor/three/build/three.module.js')) fail('arena-3d.js does not load local Three.js');
if (!arena.includes('pieceOffsetX') || !arena.includes('pieceOffsetY')) fail('3D arena must interpolate horizontal and vertical active-piece movement');
if (!arena.includes('function rotateMatrix(matrix,direction)') || !arena.includes('rotationAngle=-direction*Math.PI/2')) fail('3D arena must animate quarter-turn piece rotations');
if (!arena.includes('activeGroup.rotation.z=rotationAngle')) fail('3D arena must apply the eased rotation to the active piece');
if (!arena.includes('new THREE.TorusGeometry(.78,.035,5,18,Math.PI*1.55)') || !arena.includes('rotationArc.userData.rotationArc=true') || !arena.includes('effect.userData.rotationArc')) fail('3D piece rotations must emit a short-lived, animated arc cue');
if (!arena.includes('rotationArc.userData.life=310') || !arena.includes('addEffect(rotationArc)')) fail('rotation feedback must use the capped and disposable transient-effects lifecycle');
const compactArena = arena.replace(/\\s+/g, '');
if (!compactArena.includes('rotationPivotX*(1-c)+rotationPivotY*sn')) fail('3D arena rotation must compensate around the piece centre');
if (!compactArena.includes('pieceOffsetX+rotationPivotX*(1-c)+rotationPivotY*sn')) fail('3D arena must apply interpolated piece offsets to the active group');
if (!arena.includes('impactStrength=Math.min(.32,.08+dropDistance*.025)')) fail('landing camera feedback must scale with drop distance');
if (!arena.includes("renderer.domElement.style.display='none'")) fail('WebGL context loss must hide the canvas so the 2D board remains visible');
if (!arena.includes('resumeAfterContextRestore=enabled') || !arena.includes("if(resumeAfterContextRestore)") || !arena.includes("lastBoardSignature='';lastPieceSignature='';previousState=null;")) fail('3D arena must resume and rebuild its scene after WebGL context restoration');
if (!arena.includes('const MAX_ARENA_EFFECTS=96') || !arena.includes('while(effectsGroup.children.length>MAX_ARENA_EFFECTS)')) fail('3D arena transient effects must have a hard memory-safe cap');
if (!arena.includes('function disposeEffect(effect)') || !arena.includes('disposeEffect(oldest)')) fail('3D arena must dispose geometry and materials when transient effects are removed');
if (!arena.includes('cell.scale.set(1,.78,1)') || !arena.includes('cell.userData.landAt')) fail('locked 3D blocks must use a brief landing compression');
if (!arena.includes('!reducedMotion.matches&&sameFallingPiece')) fail('piece movement interpolation must respect reduced-motion preferences');
if (!visual.includes('const USE_CURATED_GLB_HEROES=false') || !visual.includes('if(USE_CURATED_GLB_HEROES)tryLoadCharacterAsset(stage,char,item)')) fail('unmatched generic GLB models must not replace the five authored Tetrios hero identities');
if (!visual.includes("const HERO_IDS=['plush','prism','blip','pixel','spark']") || !visual.includes("HERO_IDS.includes(requestedId)?requestedId:'plush'")) fail('3D character previews must resolve to one of the five canonical hero identities');
if (!visual.includes('stage.dataset.bb3dHeroId') || !visual.includes('stage.dataset.bb3dRenderedHero=char.id') || !visual.includes('renderer.domElement.dataset.heroId=char.id')) fail('3D character previews must track the identity they actually rendered and rebuild on identity changes');
if (!visual.includes("stage.dataset.heroColor||''") || !visual.includes('parseInt(declaredColor.slice(1),16)')) fail('3D character preview must honor the selected roster color instead of stale model colors');
if (!visual.includes('plush:0x9b6845,prism:0x276c9e,blip:0x6846a0,pixel:0x2878c7,spark:0xffc84d')) fail('3D hero colors must follow the canonical roster palette');
if (!visual.includes('./vendor/three/build/three.module.js')) fail('visual-3d.js does not load local Three.js');
if (!visual.includes('three/addons/loaders/GLTFLoader.js')) fail('visual-3d.js does not load the local GLTFLoader');
if (!visual.includes("new IntersectionObserver(entries=>") || !visual.includes("rootMargin:'120px 0px'")) fail('character stages must observe viewport visibility with a small prefetch margin');
if (!visual.includes('item.isVisible===false') || !visual.includes('item.isVisible!==false')) fail('offscreen character stages must pause animation and rendering');
if (!visual.includes('item.visibilityObserver?.disconnect()')) fail('character visibility observers must disconnect when cards are disposed');
if (!visual.includes('item.mixer?.stopAllAction()') || !visual.includes('item.mixer.uncacheRoot(item.modelRoot)')) fail('character animation mixers must release actions and cached roots on disposal');
if (!visual.includes('item.renderer.domElement.remove()')) fail('disposed character stages must remove their WebGL canvas');
if (!visual.includes('const lowPowerDevice=(navigator.hardwareConcurrency||8)<=4||(navigator.deviceMemory||8)<=4')) fail('3D showcase must detect lower-memory and lower-core devices');
if (!visual.includes('antialias:!lowPowerDevice') || !visual.includes("powerPreference:lowPowerDevice?'low-power':'high-performance'")) fail('3D renderer must select an appropriate GPU profile for device capability');
if (!visual.includes('renderer.shadowMap.enabled=false') || visual.includes('key.castShadow=true')) fail('3D showcase must avoid allocating unused real-time shadow maps');
if (!visual.includes('velocityY:0,velocityX:0') || !visual.includes('controls.dragging=true')) fail('character drag controls must track pointer velocity and active dragging');
if (!visual.includes('const rotationEase=1-Math.exp(-10*delta)') || !visual.includes('const inertia=Math.exp(-6*delta)')) fail('character rotation must use frame-rate-independent easing and damped release inertia');
if (!visual.includes('controls.velocityY*=inertia') || !visual.includes('controls.velocityX*=inertia')) fail('character drag inertia must decay safely after release');
if (!visual.includes('const maxPixelRatio=lowPowerDevice?1:1.5') || !visual.includes('const frameInterval=lowPowerDevice?1000/30:1000/60')) fail('3D showcase must cap mobile pixel ratio and frame rate by device capability');
if (!visual.includes('window.matchMedia(\'(prefers-reduced-motion: reduce)\')') || !visual.includes('if(!reducedMotion.matches){') || !visual.includes('if(item.mixer)item.mixer.update(delta);')) fail('3D showcase must respect reduced-motion preferences for ambient and skeletal animation');
if (!visual.includes('now-lastFrameTime<frameInterval')) fail('3D showcase must throttle rendering to its device frame budget');
if (!visual.includes('const stageDetail=lowPowerDevice?32:48') || !visual.includes('const starCount=lowPowerDevice?72:120')) fail('3D showcase geometry and background particles must scale with device capability');
if (visual.includes('new THREE.PointLight(')) fail('3D showcase should avoid expensive per-pixel point lights');


if (/https?:\/\//i.test(arena + visual)) fail('a remote HTTP(S) dependency remains in a 3D runtime module');
if (/cdn\.jsdelivr\.net\/npm\/three@/i.test(index)) fail('index.html contains a Three.js CDN reference');
if (!index.includes("color: '#2878c7'") || !index.includes("color: '#ffc84d'")) fail('Pixel must remain blue and Spark must remain yellow in the hero roster');










if (!index.includes('@media (max-width: 520px)') || !index.includes('#game .playlayout')) fail('classic responsive gameplay layout must remain available on phones');
if (!index.includes('id="hapticBtn"') || !index.includes('function bbHaptic(pattern)') || !index.includes("typeof navigator.vibrate!=='function'")) fail('mobile haptic feedback must be optional and guarded for unsupported browsers');
if (!index.includes('bbHaptic(cleared>=4?[28,40,70]:cleared>=2?32:16)') || !index.includes('score+=dist*2;bbHaptic(16);lockPiece()')) fail('haptic feedback must respond to line clears and hard drops');
if (!index.includes('if(rotated){bbHaptic(9);chime();render()}')) fail('successful piece rotations must trigger a light haptic pulse without vibrating on blocked rotations');
if (!index.includes("localStorage.bb_haptics=hapticsOn?'1':'0'")) fail('haptic preference must persist between sessions');
if (!index.includes('function bbHandleVisibilityChange()') || !index.includes('if (document.hidden && started && !paused && !gameOver)') || !index.includes("document.addEventListener('visibilitychange', bbHandleVisibilityChange)")) fail('an active game must auto-pause when the app is backgrounded and require manual resume');
if (index.includes('bbSetupMobileGameHud') || index.includes('mobile-game-hud-trigger') || index.includes('bb-mobile-game-active')) fail('experimental immersive mobile HUD must remain removed');
if (mobileCss.includes('#game .sidecol{display:none!important}') || mobileCss.includes('position:fixed!important;inset:0!important')) fail('visual stylesheet must not force a fullscreen mobile board');
if (!arena.includes('new THREE.ExtrudeGeometry(shape,') || !arena.includes('bevelEnabled:true') || !arena.includes('clearcoat:ghost?0:.9')) fail('3D blocks must use beveled, premium physical surfaces');
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
  const licenseName = typeof entry.license === 'string' ? entry.license : entry.license?.name;
  const licenseSource = typeof entry.license === 'object' ? entry.license?.source : null;
  if (typeof licenseName !== 'string' || !licenseName.trim() ||
      (licenseSource != null && !/^https:\/\//.test(licenseSource))) {
    fail(`character "${id}" has a model but no valid recorded license`);
  }
  const modelPath = `site/${entry.model.replace(/^\.\//, '')}`;
  if (!await exists(modelPath)) fail(`character "${id}" model file is missing: ${modelPath}`);
}

if (process.exitCode) process.exit(process.exitCode);
console.log('PASS: Three.js 0.180.0, GLTFLoader, import-map order and character asset references are valid.');
