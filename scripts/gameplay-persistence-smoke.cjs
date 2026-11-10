const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    reducedMotion: 'reduce'
  });
  const page = await context.newPage();
  page.setDefaultTimeout(15000);
  const pageErrors = [];
  page.on('pageerror', error => pageErrors.push(error.stack || String(error)));

  try {
    await page.goto('http://127.0.0.1:4173/index.html?qaVisual=1', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });
    await page.locator('button.mode[data-mode="rogue"]').waitFor({ state: 'visible' });
    await page.locator('button.mode[data-mode="rogue"]').click();
    await page.locator('#bbConfirmStartHero').waitFor({ state: 'visible' });
    await page.locator('#bbConfirmStartHero').evaluate(element => element.click());
    await page.locator('#game:not([hidden])').waitFor({ state: 'visible' });
    await page.locator('#game .boardframe').waitFor({ state: 'visible' });

    const result = await page.evaluate(() =>
      window.__TETRIOS_QA__?.finishRunForPersistenceSmoke?.() || null
    );
    if (!result) throw new Error('QA game-over hook is missing');
    if (!result.gameOver) throw new Error('Real endGame() did not set gameOver');
    if (result.after.runs !== result.before.runs + 1) {
      throw new Error('Run counter did not increment: ' + JSON.stringify(result));
    }
    if (result.after.coins <= result.before.coins) {
      throw new Error('Coin reward was not earned: ' + JSON.stringify(result));
    }
    if (result.after.xp <= result.before.xp) {
      throw new Error('Hero XP reward was not earned: ' + JSON.stringify(result));
    }
    if (!result.rewardLine.includes('Награда:')) {
      throw new Error('Game-over reward summary is missing: ' + result.rewardLine);
    }

    await page.reload({ waitUntil: 'domcontentloaded' });
    const persisted = await page.evaluate(() => ({
      runs: Number(localStorage.getItem('nrRuns') || 0),
      coins: Number(JSON.parse(localStorage.getItem('bb_coins') || '0')),
      xp: Number(JSON.parse(localStorage.getItem('bb_xp_plush') || '0'))
    }));
    if (JSON.stringify(persisted) !== JSON.stringify(result.after)) {
      throw new Error('Profile reward did not survive reload: ' +
        JSON.stringify({ expected: result.after, actual: persisted }));
    }
    if (pageErrors.length) throw new Error('Page errors: ' + pageErrors.join(' | '));

    console.log('KT-588 GAMEPLAY PERSISTENCE SMOKE PASSED');
    console.log(JSON.stringify({ result, persisted, pageErrors }, null, 2));
  } finally {
    await context.close();
    await browser.close();
  }
})().catch(error => {
  console.error(error.stack || String(error));
  process.exit(1);
});
