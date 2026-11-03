import fs from 'node:fs';

const html = fs.readFileSync(new URL('./index.html', import.meta.url), 'utf8');
const failures = [];

function requireMatch(label, pattern) {
  if (!pattern.test(html)) failures.push(label);
}

requireMatch(
  'Roguelike-only card IDs must be explicitly classified',
  /const bbRogueOnlyUpgradeIds\s*=\s*new Set\(\['burst','rift','reserve','hunter'\]\)/
);
requireMatch(
  'Standard modes must receive a filtered upgrade pool',
  /function bbGetModeUpgradePool\(targetMode=mode\)[\s\S]*?upgrades\.filter\(upgrade=>!bbRogueOnlyUpgradeIds\.has\(upgrade\[3\]\)\)/
);
requireMatch(
  'Level-up reward selection must use the mode-specific pool',
  /function showUpgrade\(\)[\s\S]*?let pool=rogue\?bbGetModeUpgradePool\('rogue'\):bbGetModeUpgradePool\(mode\)\.filter/
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
  'Daily challenge rules must remain independently gated',
  /mode\s*===\s*'daily'[\s\S]{0,160}bbIsDailyMechanic/
);

if (failures.length) {
  console.error('Gameplay mode validation failed:\n- ' + failures.join('\n- '));
  process.exit(1);
}

console.log('Gameplay mode validation passed: roguelike card ranks, monster encounters and random starter cards are isolated to Block Run; standard reward and daily-rule paths remain present.');
