import fs from 'node:fs';

const html = fs.readFileSync(new URL('./index.html', import.meta.url), 'utf8');
const failures = [];

function requireMatch(label, pattern) {
  if (!pattern.test(html)) failures.push(label);
}

requireMatch(
  'Every upgrade card must be classified as Block Run-only',
  /const bbRogueOnlyUpgradeIds\s*=\s*new Set\(upgrades\.map\(upgrade=>upgrade\[3\]\)\)/
);
requireMatch(
  'Only Block Run may receive an upgrade-card pool',
  /function bbGetModeUpgradePool\(targetMode=mode\)\{return targetMode==='rogue'\?upgrades\.slice\(\):\[\];\}/
);
requireMatch(
  'Upgrade selection must exit immediately outside Block Run',
  /function showUpgrade\(\)\{\s*if\(mode!=='rogue'\)\{paused=false;restartDrop\(\);return;\}/
);
requireMatch(
  'Only Block Run level-ups may open card selection',
  /function levelUp\(\)[\s\S]*?if\(mode==='rogue'\)\{paused=true;showUpgrade\(\)\}[\s\S]*?else\{paused=false;/
);
requireMatch(
  'Blip random card starter must be Block Run-only',
  /if\(mode==='rogue'&&bbSelectedHero==='blip'&&upgrades\.length\)/
);
requireMatch(
  'Rogue card ranks must be inactive outside Block Run',
  /function bbGetRogueCardRank\(id\)\{return mode==='rogue'\?/
);
requireMatch(
  'Monster encounter UI must be hidden outside Block Run',
  /function bbRogueRenderEncounter\(\)\{\s*if\(mode!=='rogue'\)return ''/
);
requireMatch(
  'Monster attacks must be guarded to Block Run',
  /function bbRogueEnemyAttack\(\)\{\s*if\(mode!=='rogue'\|\|!started\|\|paused\|\|gameOver\)return/
);
requireMatch(
  'Monster attack timer must tick only in Block Run',
  /if\(mode==='rogue'\)\{if\(bbRogueEncounter\.hp>0\)/
);
requireMatch(
  'Monster attacks must expose distinct telegraphed profiles',
  /function bbRogueGetAttackProfile\(\)[\s\S]*?breach:[\s\S]*?crossfire:[\s\S]*?siege:/
);
requireMatch(
  'Normal encounters and bosses must use different attack cycles',
  /const cycle=e\.boss\?\['siege','crossfire'\]:\['breach','crossfire'\]/
);
requireMatch(
  'Monster attack patterns must be deterministic from room and attack index',
  /function bbRogueBuildGarbageRow\(profile,rowIndex\)[\s\S]*?const seed=\(e\.room\*3\+e\.attackIndex\*5\+rowIndex\*2\)%W/
);
requireMatch(
  'Monster encounter warning must activate at five seconds or less',
  /warning=e\.nextAttack<=5/
);
requireMatch(
  'Monster encounter UI must show the selected next attack and countdown',
  /attack\.label[\s\S]*?АТАКА ЧЕРЕЗ/
);
requireMatch(
  'Gear must award points once per fifth locked piece while active',
  /if\(boosts\.includes\('gear'\)\)\{bbGearMoveCount\+\+;if\(bbGearMoveCount%5===0\)\{const bonus=25\*bbGetUpgradeRank\('gear'\);score\+=bonus/
);
requireMatch(
  'Plasma must reset the next fall delay only after a line clear',
  /if\(cleared&&boosts\.includes\('plasma'\)\)\{\s*if\(mode==='rogue'\)dropLastStepAt=performance\.now\(\);\s*else restartDrop\(\);\s*\}/
);
requireMatch(
  'Short mobile Block Run objective rail must use compact spacing below 380px',
  /@media\(max-width:380px\) and \(orientation:portrait\)\{\s*#game \.gameleftcol #rogueGoals\{gap:3px!important\}/
);
requireMatch(
  'Aura must draw a glow around the active piece only while the card is owned',
  /if\(piece&&!gameOver\)\{\s*const activeColor=boosts\.includes\('prism'\)\?bbPrismColor\(piece\.t\):bbDailyGlitchColor\(piece\.t\);\s*if\(boosts\.includes\('aura'\)\)\{\s*ctx\.save\(\);ctx\.globalAlpha=\.72;ctx\.shadowColor=activeColor/
);
requireMatch(
  'Shift must award rank-scaled points only after a successful rotation',
  /if\(boosts\.includes\('shift'\)&&Math\.random\(\)<0\.25\)\{score\+=25\*bbGetUpgradeRank\('shift'\);updateHud\(\)\}/
);
requireMatch(
  'Stable upgrade must extend deterministic rotation wall-kicks only in Block Run',
  /const rank=mode==='rogue'\?bbGetRogueCardRank\('stable'\):0,maxKick=rank\?Math\.min\(4,1\+rank\):1/
);
requireMatch(
  'Reserve must consume and block one fully telegraphed attack',
  /bbRogueReserveCharges--;e\.attackIndex\+\+;[\s\S]*?РЕЗЕРВ ПОГЛОТИЛ АТАКУ/
);
requireMatch(
  'Monster attack resolution must apply the selected profile row count',
  /for\(let n=0;n<attack\.rows;n\+\+\)[\s\S]*?bbRogueBuildGarbageRow\(attack,n\)/
);
requireMatch(
  'Daily challenge rules must remain independently gated',
  /mode\s*===\s*'daily'[\s\S]{0,160}bbIsDailyMechanic/
);


requireMatch(
  'Campaign mission pool must include tactical and skill-based objectives',
  /function bbGetNodeGoals\(node\)[\s\S]*?id:'rotations'[\s\S]*?id:'hold'[\s\S]*?id:'doubles'[\s\S]*?id:'noHardDrop'[\s\S]*?id:'streak'/
);
requireMatch(
  'Campaign missions must reset independent counters at run start',
  /bbCampaignRun=\{maxClear:0,piecesPlaced:0,rotations:0,holdUses:0,hardDrops:0,singleClears:0,doubleClears:0,tripleClears:0,tetrisClears:0,maxCombo:0\}/
);
requireMatch(
  'Campaign placement, rotation, hold, and clear events must update mission counters',
  /function lockPiece\(\)\{if\(!piece\)return;if\(mode==='campaign'\)bbCampaignRun\.piecesPlaced\+\+;[\s\S]*?if\(mode==='campaign'\)\{if\(cleared===1\)bbCampaignRun\.singleClears\+\+;if\(cleared===2\)bbCampaignRun\.doubleClears\+\+/
);
requireMatch(
  'Campaign Scout perk must not inject a Block Run card',
  /mode==='campaign'&&bbHasCampaignPerk\('scout'\)\?2:1/
);
requireMatch(
  'Inventory card-like consumables must only apply in Block Run',
  /if\(!started\|\|gameOver\|\|!Array\.isArray\(board\)\|\|board\.length!==H\|\|mode!=='rogue'\)return;\s*if\(bbInventory\.quick>0\)/
);
requireMatch(
  'Campaign and daily level-ups must continue without opening card selection',
  /function levelUp\(\)[\s\S]*?if\(mode==='rogue'\)\{paused=true;showUpgrade\(\)\}[\s\S]*?else\{paused=false;if\(mode==='campaign'\)/
);


requireMatch(
  'Campaign mission selection must avoid contradictory Hold and no-Hold objectives',
  /if\(goals\.some\(goal=>goal\.id==='hold'\)&&goals\.some\(goal=>goal\.id==='noHold'\)\)goals\.splice\(goals\.findIndex\(goal=>goal\.id==='noHold'\),1\)/
);
requireMatch(
  'Campaign rotation and Hold objectives must refresh progress immediately',
  /if\(mode==='campaign'\)bbRenderGoals\(\)/
);
requireMatch(
  'Upgrade ranks must be inactive outside Block Run',
  /function bbGetUpgradeRank\(id\)\{return mode==='rogue'\?Math\.max\(1,bbGetRogueCardRank\(id\)\):0;\}/
);
requireMatch(
  'The card archive must not advertise shared or standard cards',
  /Все карты относятся к рогалик-системе и работают только в режиме Block Run/
);

requireMatch(
  'Prism must animate only the active/preview piece without changing board cells',
  /function bbPrismColor\(index,now=performance\.now\(\)\)[\s\S]*?if\(!boosts\.includes\('prism'\)/
);
requireMatch(
  'Prism render loop must stop when paused, over, or reduced motion is requested',
  /function bbSchedulePrismAnimation\(\)[\s\S]*?!started\|\|paused\|\|gameOver[\s\S]*?prefers-reduced-motion/
);
requireMatch(
  'Prism color must also reach the next-piece preview',
  /function drawNext\(\)[\s\S]*?const s=shapes\[nextType\],color=bbPrismColor\(nextType\)/
);
requireMatch(
  'Prism animation must be scheduled by the 2D renderer',
  /bbSchedulePrismAnimation\(\);\s*\}\s*window\.bbGet3DBoardState/
);
requireMatch(
  '3D board state must expose Prism color and Aura ownership for the active piece',
  /pieceColor:active\?\(boosts\.includes\('prism'\)\?bbPrismColor\(active\.t\):bbDailyGlitchColor\(active\.t\)\):null,aura:!!\(active&&boosts\.includes\('aura'\)\)/
);


requireMatch(
  'Void compresses one fully empty internal row while preserving board dimensions and every occupied cell',
  /function bbBuildVoidCompressedBoard\(source\)[\s\S]*?compressed\.splice\(y,1\);[\s\S]*?compressed\.unshift\(Array\(W\)\.fill\(0\)\)/
);
requireMatch(
  'Void compression is once per level, Block Run-only, and guarded against active-piece collision',
  /function bbApplyVoidCompression\(\)[\s\S]*?mode!=='rogue'[\s\S]*?bbVoidLastAppliedLevel===level[\s\S]*?if\(piece&&collides\(piece\)\)/
);

requireMatch(
  'Void is invoked from the real level-up flow only when its card is owned',
  /function levelUp\(\)[\s\S]*?if\(boosts\.includes\('void'\)\)bbApplyVoidCompression\(\)/
);

if (failures.length) {
  console.error('Gameplay mode validation failed:\n- ' + failures.join('\n- '));
  process.exit(1);
}

console.log('Gameplay mode validation passed: roguelike card ranks, monster encounters and random starter cards are isolated to Block Run; standard reward and daily-rule paths remain present.');
