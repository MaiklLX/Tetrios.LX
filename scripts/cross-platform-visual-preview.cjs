const { chromium, webkit } = require('playwright');
const fs = require('fs');

const outputDir = 'cross-platform-preview-artifacts';
fs.mkdirSync(outputDir, { recursive: true });

const targets = [
  { engine: 'chromium', name: 'desktop-1440x900', width: 1440, height: 900, mobile: false },
  { engine: 'chromium', name: 'desktop-1920x1080', width: 1920, height: 1080, mobile: false },
  { engine: 'webkit', name: 'ios-webkit-390x844', width: 390, height: 844, mobile: true },
  { engine: 'webkit', name: 'ios-webkit-430x932', width: 430, height: 932, mobile: true }
];

(async () => {
  const report = [];
  const failures = [];

  for (const target of targets) {
    const browserType = target.engine === 'webkit' ? webkit : chromium;
    const launchOptions = { headless: true };
    if (target.engine === 'chromium') {
      launchOptions.args = [
        '--enable-webgl',
        '--ignore-gpu-blocklist',
        '--use-gl=angle',
        '--use-angle=swiftshader'
      ];
    }

    const browser = await browserType.launch(launchOptions);
    const context = await browser.newContext({
      viewport: { width: target.width, height: target.height },
      deviceScaleFactor: target.mobile ? 3 : 1,
      isMobile: target.mobile,
      hasTouch: target.mobile
    });
    const page = await context.newPage();
    page.setDefaultTimeout(15000);
    page.setDefaultNavigationTimeout(25000);
    const pageErrors = [];
    page.on('pageerror', error => pageErrors.push(error.stack || String(error)));

    console.log('Starting visual capture: ' + target.name + ' (' + target.engine + ')');
    await page.goto('http://127.0.0.1:4173/index.html', { waitUntil: 'domcontentloaded', timeout: 20000 });
    await page.locator('button.mode[data-mode="rogue"]').waitFor({ state: 'visible', timeout: 10000 });
    await page.waitForTimeout(250);
    await page.screenshot({ path: outputDir + '/' + target.name + '-menu.png', fullPage: false });

    // The complete card archive must be available before starting a run on every platform.
    await page.locator('#bbOpenCardLibrary').click();
    await page.locator('#bbCardLibraryList article').first().waitFor({ state: 'visible' });
    const allCards = await page.locator('#bbCardLibraryList article').count();
    if (allCards !== 35) failures.push(target.name + ': expected 35 catalog cards, got ' + allCards);
    // Capture the default archive before switching filters so the primary visual
    // artifact represents the complete 35-card library, not the 4-card Block Run subset.
    await page.screenshot({ path: outputDir + '/' + target.name + '-card-library.png', fullPage: false });
    await page.locator('[data-bb-card-filter="rogue"]').click();
    const rogueCards = await page.locator('#bbCardLibraryList article').count();
    if (rogueCards !== 4) failures.push(target.name + ': expected 4 Block Run-only cards, got ' + rogueCards);
    await page.screenshot({ path: outputDir + '/' + target.name + '-card-library-block-run.png', fullPage: false });
    await page.locator('[data-bb-card-filter="standard"]').click();
    const standardCards = await page.locator('#bbCardLibraryList article').count();
    if (standardCards !== 31) failures.push(target.name + ': expected 31 shared cards, got ' + standardCards);
    await page.screenshot({ path: outputDir + '/' + target.name + '-card-library-shared.png', fullPage: false });
    await page.locator('#bbCloseCardLibrary').click();

    await page.locator('button.mode[data-mode="rogue"]').click();
    await page.locator('#bbConfirmStartHero').waitFor({ state: 'visible', timeout: 15000 });
    await page.locator('#bbConfirmStartHero').click();
    await page.locator('#game:not([hidden])').waitFor({ state: 'visible', timeout: 15000 });
    await page.locator('#game .boardframe').waitFor({ state: 'visible', timeout: 10000 });
    await page.waitForTimeout(900);

    const geometry = await page.evaluate(() => {
      const rect = element => {
        if (!element) return null;
        const r = element.getBoundingClientRect();
        return {
          x: Math.round(r.x * 100) / 100,
          y: Math.round(r.y * 100) / 100,
          width: Math.round(r.width * 100) / 100,
          height: Math.round(r.height * 100) / 100,
          right: Math.round(r.right * 100) / 100,
          bottom: Math.round(r.bottom * 100) / 100
        };
      };
      const frame = document.querySelector('#game .boardframe');
      const side = document.querySelector('#game .sidecol');
      const drop = document.querySelector('#game .side-drop');
      const hold = document.querySelector('#game #holdBtn');
      const goals = document.querySelector('#game #rogueGoals');
      const playlayout = document.querySelector('#game .playlayout');
      return {
        viewport: { width: innerWidth, height: innerHeight },
        document: {
          width: document.documentElement.scrollWidth,
          height: document.documentElement.scrollHeight
        },
        frame: rect(frame),
        side: rect(side),
        drop: rect(drop),
        hold: rect(hold),
        goals: rect(goals),
        playlayout: rect(playlayout),
        frameRatio: frame ? frame.getBoundingClientRect().width / frame.getBoundingClientRect().height : 0
      };
    });

    const ratio = geometry.frameRatio;
    if (!geometry.frame || ratio < 0.42 || ratio > 0.45) {
      failures.push(target.name + ': arena frame ratio is outside the 10:23 tolerance (' + ratio + ')');
    }
    if (geometry.document.width > target.width + 2) {
      failures.push(target.name + ': horizontal document overflow (' + geometry.document.width + 'px)');
    }
    if (target.mobile) {
      if (!geometry.drop || geometry.drop.width < 40 || geometry.drop.height < 36) {
        failures.push(target.name + ': Hard Drop control is missing or too small');
      }
      if (!geometry.hold || geometry.hold.width < 30 || geometry.hold.height < 24) {
        failures.push(target.name + ': Hold control is missing or too small');
      }
      if (geometry.goals && geometry.goals.bottom > target.height + 2) {
        failures.push(target.name + ': Block Run goals extend beyond the viewport');
      }
      if (geometry.frame && geometry.frame.right > target.width + 2) {
        failures.push(target.name + ': arena extends beyond the right viewport edge');
      }
    } else if (geometry.frame && (geometry.frame.y < -2 || geometry.frame.bottom > target.height + 2)) {
      failures.push(target.name + ': desktop arena is not contained by the viewport');
    }

    await page.screenshot({ path: outputDir + '/' + target.name + '-arena-2d.png', fullPage: false });
    console.log('Captured 2D arena: ' + target.name);

    let threeD = null;
    if (target.engine === 'chromium') {
      const toggle = page.locator('#game .boardframe .bb-arena-toggle');
      await toggle.waitFor({ state: 'visible', timeout: 10000 });
      await toggle.click();
      await page.locator('#game .boardframe.bb-3d-arena-active').waitFor({ state: 'attached', timeout: 15000 });
      await page.waitForTimeout(1200);
      threeD = await page.evaluate(() => {
        const board = document.querySelector('#game #board')?.getBoundingClientRect();
        const canvas = document.querySelector('#game .bb-arena-canvas')?.getBoundingClientRect();
        if (!board || !canvas) return null;
        return {
          board: { x: board.x, y: board.y, width: board.width, height: board.height },
          canvas: { x: canvas.x, y: canvas.y, width: canvas.width, height: canvas.height },
          delta: Math.max(
            Math.abs(canvas.x - board.x),
            Math.abs(canvas.y - board.y),
            Math.abs(canvas.width - board.width),
            Math.abs(canvas.height - board.height)
          )
        };
      });
      if (!threeD || threeD.delta > 3) {
        failures.push(target.name + ': 3D overlay is missing or misaligned (' + JSON.stringify(threeD) + ')');
      }
      await page.screenshot({ path: outputDir + '/' + target.name + '-arena-3d.png', fullPage: false });
      console.log('Captured 3D arena: ' + target.name);
    }

    report.push({ target: target.name, engine: target.engine, geometry, threeD, pageErrors });
    await context.close();
    await browser.close();
  }

  fs.writeFileSync(outputDir + '/report.json', JSON.stringify({ report, failures }, null, 2));
  console.log(JSON.stringify({ report, failures }, null, 2));
  if (failures.length) throw new Error(failures.join('\n'));
})().catch(error => {
  console.error(error);
  process.exit(1);
});
