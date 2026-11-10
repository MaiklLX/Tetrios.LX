const { chromium, webkit } = require('playwright');
const fs = require('fs');

const outputDir = 'cross-platform-preview-artifacts';
fs.mkdirSync(outputDir, { recursive: true });

// Five representative device profiles keep the full interaction suite within the
// 25-minute Actions budget while retaining desktop, iOS, Android, portrait and landscape coverage.
const targets = [
  { engine: 'chromium', name: 'desktop-1440x900', width: 1440, height: 900, mobile: false },
  { engine: 'webkit', name: 'ios-webkit-390x844', width: 390, height: 844, mobile: true },
  { engine: 'webkit', name: 'ios-webkit-landscape-844x390', width: 844, height: 390, mobile: true },
  { engine: 'chromium', name: 'android-chromium-393x873', width: 393, height: 873, mobile: true },
  { engine: 'chromium', name: 'android-tablet-chromium-768x1024', width: 768, height: 1024, mobile: true },
  { engine: 'chromium', name: 'android-chromium-landscape-873x393', width: 873, height: 393, mobile: true }
];

(async () => {
  const report = [];
  const failures = [];

  for (const target of targets) {
    console.log('[target:start] ' + target.name + ' (' + target.engine + ', ' + target.width + 'x' + target.height + ')');
    const targetWatchdog = setTimeout(() => {
      console.error('[target:timeout] ' + target.name + ' exceeded 150000ms; stopping preview process');
      process.exit(1);
    }, 210000);
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

    const browser = await browserType.launch({ ...launchOptions, timeout: 30000 });
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
    const consoleErrors = [];
    const failedRequests = [];
    page.on('pageerror', error => pageErrors.push(error.stack || String(error)));
    page.on('console', message => { if (message.type() === 'error') consoleErrors.push(message.text()); });
    page.on('requestfailed', request => failedRequests.push({url:request.url(),failure:request.failure()?.errorText||'unknown'}));

    console.log('[stage:menu] ' + target.name);
    await page.goto('http://127.0.0.1:4173/index.html?qaVisual=1', { waitUntil: 'domcontentloaded', timeout: 20000 });
    await page.locator('button.mode[data-mode="rogue"]').waitFor({ state: 'visible', timeout: 10000 });
    await page.waitForTimeout(250);
    // KT-569.1: assert the Godot home-hub wordmark and themed mode panels.
    const homeVisualState = await page.evaluate(() => {
      const title = document.querySelector('#menu .hero h1');
      const campaign = document.querySelector('#menu button.mode[data-mode="campaign"]');
      const rogue = document.querySelector('#menu button.mode[data-mode="rogue"]');
      const campaignStyle = campaign ? getComputedStyle(campaign) : null;
      const rogueStyle = rogue ? getComputedStyle(rogue) : null;
      return {
        title: title?.textContent?.replace(/\s+/g, ' ').trim() || '',
        campaignBorder: campaignStyle?.borderTopColor || '',
        campaignPlanet: campaign ? getComputedStyle(campaign, '::after').backgroundImage : '',
        rogueBorder: rogueStyle?.borderTopColor || '',
        roguePlanet: rogue ? getComputedStyle(rogue, '::after').backgroundImage : ''
      };
    });
    const homeBorderColorsSupported = await page.evaluate(state =>
      CSS.supports('color', state.campaignBorder) &&
      CSS.supports('color', state.rogueBorder) &&
      state.campaignBorder !== 'rgba(0, 0, 0, 0)' &&
      state.rogueBorder !== 'rgba(0, 0, 0, 0)', homeVisualState);
    if (homeVisualState.title !== 'BLOCK BUDDIES' ||
        !homeBorderColorsSupported ||
        !homeVisualState.campaignPlanet.includes('radial-gradient') ||
        !homeVisualState.roguePlanet.includes('radial-gradient')) {
      failures.push(target.name + ': KT-569.1 Godot home-hub visual mapping is incomplete (' + JSON.stringify(homeVisualState) + ')');
    }
    // KT-571: selected Buddy, actual hero level and wallet are rendered from live game state.
    const pilotProfileState=await page.evaluate(()=>{
      const profile=document.querySelector('#bbHomeProfile');
      const wallet=profile?.querySelector('.bb-home-profile-wallet strong')?.textContent?.trim()||'';
      const currentCoins=document.querySelector('#coins')?.textContent?.trim()||'';
      return {
        visible:!!profile&&getComputedStyle(profile).display!=='none'&&profile.getBoundingClientRect().height>=50,
        hasHeroEmblem:!!profile?.querySelector('.bb-home-profile-avatar svg'),
        hasPilotName:!!profile?.querySelector('.bb-home-profile-copy strong')?.textContent?.trim(),
        hasLevel:/УРОВЕНЬ \d+/.test(profile?.innerText||''),
        walletMatches:wallet===currentCoins
      };
    });
    if(!pilotProfileState.visible||!pilotProfileState.hasHeroEmblem||!pilotProfileState.hasPilotName||
       !pilotProfileState.hasLevel||!pilotProfileState.walletMatches){
      failures.push(target.name+': KT-571 live Buddy pilot profile mismatch ('+JSON.stringify(pilotProfileState)+')');
    }
    const modeCardVisualState=await page.evaluate(()=>{
      const cards=[...document.querySelectorAll('#menu .modes .mode')];
      return {
        count:cards.length,
        cards:cards.map(card=>{
          const style=getComputedStyle(card),icon=card.querySelector('.modeicon');
          const iconStyle=icon?getComputedStyle(icon):null;
          return {
            radius:parseFloat(style.borderTopLeftRadius)||0,
            borderWidth:parseFloat(style.borderTopWidth)||0,
            background:style.backgroundImage||'',
            accent:style.getPropertyValue('--glow').trim(),
            iconWidth:icon?.getBoundingClientRect().width||0,
            iconBorder:iconStyle?.borderTopColor||'',
            titleColor:getComputedStyle(card.querySelector('.modetitle')).color
          };
        })
      };
    });
    if(modeCardVisualState.count!==3||modeCardVisualState.cards.some(card=>
      card.radius<16||card.borderWidth<1||!card.background.includes('radial-gradient')||
      !card.background.includes('linear-gradient')||!card.accent||card.iconWidth<40||
      card.iconBorder==='rgba(0, 0, 0, 0)')){
      failures.push(target.name+': KT-577 Godot home mode-card styling mismatch ('+JSON.stringify(modeCardVisualState)+')');
    }
    // KT-581: verify the actual Godot home-hub hierarchy, not only card colors.
    const homeHubLayoutState=await page.evaluate(()=>{
      const rect=selector=>{
        const el=document.querySelector(selector),r=el?.getBoundingClientRect();
        return r?{top:r.top,bottom:r.bottom,width:r.width,height:r.height}:null;
      };
      return {
        viewport:{width:innerWidth,height:innerHeight},
        menu:rect('#menu'),title:rect('#menu .hero h1'),profile:rect('#bbHomeProfile'),
        campaign:rect('#menu button.mode[data-mode="campaign"]'),
        blockRun:rect('#menu button.mode[data-mode="rogue"]'),
        daily:rect('#menu button.mode[data-mode="daily"]'),
        quests:rect('#dailyQuestsPanel')
      };
    });
    const orderedHomePanels=['title','profile','campaign','blockRun','daily','quests'];
    const homePanelsOrdered=orderedHomePanels.every((key,index,all)=>{
      const current=homeHubLayoutState[key],previous=index?homeHubLayoutState[all[index-1]]:null;
      return !!current&&current.width>0&&current.height>0&&(!previous||current.top>=previous.bottom-2);
    });
    if(!homePanelsOrdered||
       homeHubLayoutState.profile.width<homeHubLayoutState.menu.width*.55||
       homeHubLayoutState.campaign.width<homeHubLayoutState.menu.width*.78||
       homeHubLayoutState.blockRun.width<homeHubLayoutState.menu.width*.78){
      failures.push(target.name+': KT-581 Godot home-hub composition/order/width mismatch ('+JSON.stringify(homeHubLayoutState)+')');
    }
    await page.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-menu.png', fullPage: false });

    // KT-418: landscape phone view is intentionally blocked before the menu
    // can be used. Verify the orientation guard here instead of trying to
    // interact with controls underneath the full-screen guard.
    const phoneLandscape = target.mobile && target.width > target.height &&
      target.width <= 960 && target.height <= 650;
    if (phoneLandscape) {
      const guardState = await page.evaluate(() => {
        const guard = document.querySelector('#bbPhoneLandscapeGuard');
        const style = guard ? getComputedStyle(guard) : null;
        const rect = guard?.getBoundingClientRect();
        return {
          found: !!guard,
          visible: !!guard && style.display !== 'none' &&
            style.visibility !== 'hidden' && Number(style.opacity) > 0 &&
            !!rect && rect.width >= innerWidth - 2 && rect.height >= innerHeight - 2,
          text: guard?.innerText?.replace(/\s+/g, ' ').trim() || ''
        };
      });
      if (!guardState.visible || !guardState.text.includes('Поверни телефон') ||
          !guardState.text.includes('портретном режиме')) {
        failures.push(target.name + ': phone landscape orientation guard is missing or not visible (' + JSON.stringify(guardState) + ')');
      }
      await page.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-orientation-guard.png', fullPage: false });
      report.push({ target: target.name, engine: target.engine, orientationGuard: guardState, pageErrors, consoleErrors, failedRequests });
      await context.close();
      await browser.close();
      clearTimeout(targetWatchdog);
      console.log('[target:orientation-guard-verified] ' + target.name);
      continue;
    }

    // KT-553: capture the actual pressed state on a real menu control. Remove
    // the held control before mouseup so the visual probe cannot start a game.
    const pressTarget = page.locator('button.mode[data-mode="rogue"]');
    const pressBox = await pressTarget.boundingBox();
    if (!pressBox) {
      failures.push(target.name + ': KT-553 press target has no visible geometry');
    } else {
      await page.mouse.move(pressBox.x + pressBox.width / 2, pressBox.y + pressBox.height / 2);
      await page.mouse.down();
      await page.waitForTimeout(90);
      const pressState = await pressTarget.evaluate(el => {
        const s = getComputedStyle(el);
        return {outlineStyle:s.outlineStyle,outlineColor:s.outlineColor,boxShadow:s.boxShadow,transform:s.transform,filter:s.filter};
      });
      if (pressState.outlineStyle !== 'solid' || pressState.boxShadow === 'none') {
        failures.push(target.name + ': KT-553 visible gold/cyan pressed feedback is incomplete (' + JSON.stringify(pressState) + ')');
      }
      await page.screenshot({timeout:45000,path:outputDir+'/'+target.name+'-menu-press-feedback.png',fullPage:false});
      // Release outside the control: preserve the real menu DOM and avoid
      // dispatching a click that would launch the mode under test.
      await page.mouse.move(Math.max(1, pressBox.x - 12), Math.max(1, pressBox.y - 12));
      await page.mouse.up();
    }

    console.log('[stage:card-library] ' + target.name);
    // The complete card archive must be available before starting a run on every platform.
    await page.locator('#bbOpenCardLibrary').click();
    await page.locator('#bbCardLibraryList article').first().waitFor({ state: 'visible' });
    const allCards = await page.locator('#bbCardLibraryList article').count();
    if (allCards !== 35) failures.push(target.name + ': expected 35 catalog cards, got ' + allCards);
    // The live archive uses thematic category tabs; every card is Block Run-only.
    const libraryHeading = await page.locator('.bb-library-heading').innerText();
    if (!libraryHeading.includes('Все карты относятся к рогалик-системе и работают только в режиме Block Run')) {
      failures.push(target.name + ': Block Run-only archive scope is not explained in the library');
    }
    const libraryLayout = await page.locator('#modal.bb-upgrade-library-modal').evaluate(modal => {
      const grid=modal.querySelector('.bb-library-grid'),cards=[...modal.querySelectorAll('.bb-library-card')];
      const r=grid?.getBoundingClientRect(),first=cards[0]?.getBoundingClientRect(),styles=grid?getComputedStyle(grid):null;
      return {visible:!!r&&r.width>0&&r.height>0,columns:styles?.gridTemplateColumns||'',scrollable:!!grid&&grid.scrollHeight>=grid.clientHeight,cardCount:cards.length,cardWidth:first?.width||0,cardHeight:first?.height||0};
    });
    if(!libraryLayout.visible||libraryLayout.cardCount!==35||libraryLayout.cardWidth<90||libraryLayout.cardHeight<150||!libraryLayout.scrollable){
      failures.push(target.name+': library catalogue layout is not calibrated ('+JSON.stringify(libraryLayout)+')');
    }
    const pageBackdrop=await page.locator('body .app').evaluate(el=>getComputedStyle(el).backgroundImage);
    const pageSurface=await page.locator('body').evaluate(el=>getComputedStyle(el).backgroundColor);
    if(!pageBackdrop.includes('linear-gradient')||!pageBackdrop.includes('radial-gradient')||pageSurface==='rgb(255, 255, 255)') failures.push(target.name+': friendly teal page backdrop is missing or washed out ('+JSON.stringify({pageBackdrop,pageSurface})+')');
    await page.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-card-library.png', fullPage: false });
    await page.locator('[data-bb-lib-filter="all"]').click();
    const allFilteredCards = await page.locator('#bbCardLibraryList article').count();
    if (allFilteredCards !== 35) failures.push(target.name + ': the All category must retain all 35 cards, got ' + allFilteredCards);
    const categoryCounts={};
    for (const [filter,expected] of [['attack',12],['defense',7],['control',11],['anomaly',5]]) {
      await page.locator('[data-bb-lib-filter="'+filter+'"]').click();
      const count=await page.locator('#bbCardLibraryList article').count();
      categoryCounts[filter]=count;
      if(count!==expected) failures.push(target.name+': '+filter+' archive should contain '+expected+' unique cards, got '+count);
    }
    await page.locator('[data-bb-lib-filter="all"]').click();
    await page.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-card-library-all.png', fullPage: false });
    if (await page.locator('[data-bb-card-filter="standard"], [data-bb-lib-filter="standard"]').count() !== 0) {
      failures.push(target.name + ': shared/standard card filter must not exist');
    }
    await page.locator('#bbCloseCardLibrary').click();

    console.log('[stage:campaign-atlas] ' + target.name);
    // Campaign is a standard ruleset: show its own mission objectives, never card picks.
    // Use a separate page so WebKit reload quirks cannot interrupt the Rogue preview.
    const campaignPage = await context.newPage();
    campaignPage.setDefaultTimeout(15000);
    campaignPage.setDefaultNavigationTimeout(30000);
    campaignPage.on('pageerror', error => pageErrors.push('campaign: ' + (error.stack || String(error))));
    campaignPage.on('console', message => { if (message.type() === 'error') consoleErrors.push('campaign: '+message.text()); });
    campaignPage.on('requestfailed', request => failedRequests.push({url:request.url(),failure:request.failure()?.errorText||'unknown',page:'campaign'}));
    await campaignPage.goto('http://127.0.0.1:4173/index.html', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await campaignPage.locator('button.mode[data-mode="campaign"]').click();
    await campaignPage.locator('#campaignStart').waitFor({ state: 'visible', timeout: 15000 });
    await campaignPage.locator('#campaign .bb-galaxy-card').first().waitFor({state:'visible',timeout:10000});
    // KT-574: classic horizontal universe carousel with Godot's cosmic art direction.
    const atlasCarouselState=await campaignPage.locator('#campaign .bb-galaxy-viewport').evaluate(viewport=>{
      const track=viewport.querySelector('.bb-galaxy-track');
      const cards=track?[...track.querySelectorAll('.bb-galaxy-card')]:[];
      const first=cards[0],art=first?.querySelector('.bb-galaxy-art');
      const rect=first?.getBoundingClientRect(),artRect=art?.getBoundingClientRect();
      return {
        cardCount:cards.length,
        display:track?getComputedStyle(track).display:'',
        flexDirection:track?getComputedStyle(track).flexDirection:'',
        horizontalOverflow:!!track&&track.scrollWidth>viewport.clientWidth+2,
        verticalOverflow:viewport.scrollHeight>viewport.clientHeight+2,
        overflowX:getComputedStyle(viewport).overflowX,
        overflowY:getComputedStyle(viewport).overflowY,
        cardWidth:rect?Math.round(rect.width):0,
        cardHeight:rect?Math.round(rect.height):0,
        artWidth:artRect?Math.round(artRect.width):0,
        artVisible:!!art&&artRect.width>100
      };
    });
    if(atlasCarouselState.cardCount!==12||atlasCarouselState.display!=='flex'||
       atlasCarouselState.flexDirection!=='row'||!atlasCarouselState.horizontalOverflow||
       atlasCarouselState.verticalOverflow||atlasCarouselState.overflowX!=='auto'||
       atlasCarouselState.overflowY!=='hidden'||atlasCarouselState.cardWidth<210||
       atlasCarouselState.cardHeight<290||atlasCarouselState.artWidth<150||
       !atlasCarouselState.artVisible){
      failures.push(target.name+': KT-574 horizontal Godot atlas carousel mismatch ('+JSON.stringify(atlasCarouselState)+')');
    }
    // Verify the visible controls actually move the horizontal rail in both directions.
    const atlasTouchAction=await campaignPage.locator('#campaign .bb-galaxy-viewport').evaluate(el=>getComputedStyle(el).touchAction);
    const atlasViewport=campaignPage.locator('#campaign .bb-galaxy-viewport');
    // Let the initial selected-universe centering finish before measuring controls.
    await campaignPage.waitForTimeout(900);
    await atlasViewport.evaluate(el=>{el.style.scrollSnapType='none';el.style.scrollBehavior='auto';el.scrollLeft=0;});
    const atlasBefore=await atlasViewport.evaluate(el=>el.scrollLeft);
    const waitForAtlasScrollSettle=()=>atlasViewport.evaluate(el=>new Promise(resolve=>{
      let last=el.scrollLeft,stable=0,frames=0;
      const tick=()=>{
        frames++;
        if(Math.abs(el.scrollLeft-last)<0.5)stable++;else stable=0;
        last=el.scrollLeft;
        if(stable>=8||frames>=180)resolve(el.scrollLeft);else requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    }));
    await campaignPage.locator('#campaign .bb-atlas-controls button[aria-label="Следующая вселенная"]').click();
    const atlasAfterNext=await waitForAtlasScrollSettle();
    await campaignPage.locator('#campaign .bb-atlas-controls button[aria-label="Предыдущая вселенная"]').click();
    const atlasAfterPrevious=await waitForAtlasScrollSettle();
    if(atlasTouchAction!=='pan-x'||atlasAfterNext<=atlasBefore+8||atlasAfterPrevious>=atlasAfterNext-8){
      failures.push(target.name+': KT-574 horizontal swipe/arrow navigation mismatch ('+JSON.stringify({atlasTouchAction,atlasBefore,atlasAfterNext,atlasAfterPrevious})+')');
    }
    const atlasInputState=await atlasViewport.evaluate(el=>({
      tabIndex:el.tabIndex,role:el.getAttribute('role'),
      label:el.getAttribute('aria-label')
    }));
    await atlasViewport.evaluate(el=>{el.scrollLeft=0;});
    await atlasViewport.focus();
    await atlasViewport.evaluate(el=>el.dispatchEvent(new WheelEvent('wheel',{deltaY:Math.max(120,el.clientWidth*.55),bubbles:true,cancelable:true})));
    await campaignPage.waitForFunction(()=>{const el=document.querySelector('#campaign .bb-galaxy-viewport');return !!el&&el.scrollLeft>8;},{timeout:2000});
    const atlasAfterWheel=await atlasViewport.evaluate(el=>el.scrollLeft);
    await atlasViewport.evaluate(el=>{
      el.style.setProperty('scroll-snap-type','none','important');
      el.style.setProperty('scroll-behavior','auto','important');
      el.scrollLeft=0;
    });
    await campaignPage.waitForFunction(()=>{
      const el=document.querySelector('#campaign .bb-galaxy-viewport');
      return !!el&&el.scrollLeft<=1;
    },{timeout:2000});
    const keyboardBefore=await atlasViewport.evaluate(el=>el.scrollLeft);
    await atlasViewport.focus();
    await atlasViewport.evaluate(el=>{
      el.dataset.kt575KeyPrevented='false';
      el.addEventListener('keydown',event=>{
        if(event.key==='ArrowRight')el.dataset.kt575KeyPrevented=String(event.defaultPrevented);
      },{once:true});
    });
    await atlasViewport.press('ArrowRight');
    const keyboardEventState=await atlasViewport.evaluate(el=>({
      prevented:el.dataset.kt575KeyPrevented==='true',
      focused:document.activeElement===el
    }));
    await campaignPage.waitForFunction(before=>{
      const el=document.querySelector('#campaign .bb-galaxy-viewport');
      return !!el&&el.scrollLeft>before+8;
    },keyboardBefore,{timeout:3000});
    const atlasAfterKeyboard=await waitForAtlasScrollSettle();
    if(atlasInputState.tabIndex!==0||atlasInputState.role!=='region'||
       !atlasInputState.label||atlasAfterWheel<=8||
       !keyboardEventState.prevented||!keyboardEventState.focused||
       atlasAfterKeyboard<=keyboardBefore+8){
      failures.push(target.name+': KT-575 atlas mousewheel/keyboard access mismatch ('+JSON.stringify({atlasInputState,atlasAfterWheel,keyboardBefore,atlasAfterKeyboard,keyboardEventState})+')');
    }
    await campaignPage.waitForTimeout(3000);
    // KT-554: verify the browser reward shelf reproduces the 49-item Godot
    // collection without changing the existing 360-node campaign progression.
    await campaignPage.locator('#bbOpenCampaignCollection').waitFor({state:'visible',timeout:10000});
    await campaignPage.locator('#bbOpenCampaignCollection').click();
    const shelfModal=campaignPage.locator('.bb-collection-modal');
    const emblemState=await shelfModal.evaluate(rail=>({
      cardCount:rail.querySelectorAll('.bb-shelf-item').length,
      vectorCount:rail.querySelectorAll('.bb-shelf-item .bb-shelf-art svg').length,
      detailVectorCount:rail.querySelectorAll('.bb-shelf-detail-art svg').length,
      shelfRows:rail.querySelectorAll('.bb-real-shelf-row').length
    }));
    if(emblemState.cardCount!==9||emblemState.vectorCount!==9||emblemState.detailVectorCount!==1||emblemState.shelfRows!==3){
      failures.push(target.name+': KT-555.2 paged shelf SVG/row rendering mismatch ('+JSON.stringify(emblemState)+')');
    }
    const collectionCount=await shelfModal.locator('[data-bb-collection-id]').count();
    if(collectionCount!==9) failures.push(target.name+': KT-554 expected 9 visible reward cards per shelf page, got '+collectionCount);
    // The current shelf is paginated 3×3 (49 total), not one long 49-card rail.
    for(let page=1;page<6;page++) await campaignPage.locator('#bbShelfNext').click();
    const lastPageCount=await shelfModal.locator('[data-bb-collection-id]').count();
    if(lastPageCount!==4||!(await campaignPage.locator('#bbShelfNext').isDisabled())){
      failures.push(target.name+': KT-554 final reward shelf page should contain 4 cards and disable Next, got '+lastPageCount);
    }
    const collectionFinal=shelfModal.locator('[data-bb-collection-id="campaign_crown"]');
    await collectionFinal.click();
    const collectionDetail=await shelfModal.locator('.bb-shelf-detail').innerText();
    if(!collectionDetail.includes('Корона дальнего пути')||!collectionDetail.includes('ЕЩЁ ВПЕРЕДИ')) failures.push(target.name+': KT-554 final crown detail or locked state is incorrect ('+collectionDetail+')');
    await campaignPage.screenshot({timeout:45000,path:outputDir+'/'+target.name+'-campaign-reward-shelf.png',fullPage:false});
    await campaignPage.locator('#bbCampaignCollectionClose').click();
    const campaignAtlasState = await campaignPage.evaluate(() => {
      const root=document.querySelector('#campaign'),style=root?getComputedStyle(root):null,rect=root?.getBoundingClientRect();
      return {
        slots: document.querySelectorAll('#campaign [data-universe-model]').length,
        proceduralModels: document.querySelectorAll('#campaign [data-universe-model].is-model-fallback').length,
        loadedModels: document.querySelectorAll('#campaign [data-universe-model].is-loaded').length,
        visibleFallbacks: Array.from(document.querySelectorAll('#campaign [data-universe-model].is-model-fallback')).filter(node => {
          const r=node.getBoundingClientRect(); return r.width>0&&r.height>0&&r.bottom>0&&r.top<innerHeight;
        }).length,
        root: rect?{x:rect.x,y:rect.y,width:rect.width,height:rect.height,opacity:style.opacity,display:style.display}:null,
        cards: document.querySelectorAll('#campaign .bb-galaxy-card').length
      };
    });
    await campaignPage.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-campaign-atlas.png', fullPage: false });
    if (campaignAtlasState.slots > 0 && campaignAtlasState.visibleFallbacks < 1) {
      failures.push(target.name + ': campaign atlas has model slots but no visible procedural fallback (' + JSON.stringify(campaignAtlasState) + ')');
    }
    // KT-555: verify the Godot-style vertical, bottom-to-top route without
    // changing the existing 30 planets per universe or their node identities.
    await campaignPage.locator('#campaign .bb-galaxy-card').first().click();
    await campaignPage.locator('#campaign .bb-planet-node').first().waitFor({state:'visible',timeout:10000});
    await campaignPage.waitForTimeout(350);
    const routeState=await campaignPage.evaluate(()=>{
      const track=document.querySelector('#campaign .bb-planet-track');
      const viewport=document.querySelector('#campaign .bb-planet-viewport');
      const nodes=Array.from(document.querySelectorAll('#campaign .bb-planet-node'));
      const heading=document.querySelector('#campaign .bb-planet-heading');
      const headingOrb=heading?getComputedStyle(heading,'::after'):null;
      const viewportStyle=viewport?getComputedStyle(viewport):null;
      const y=nodes.map(node=>Number.parseFloat(node.style.top)||0);
      return {
        orientation:track?.dataset.routeOrientation||'',
        headingOrbWidth:headingOrb?parseFloat(headingOrb.width):0,
        headingOrbBackground:headingOrb?.backgroundImage||'',
        routePanelBorder:viewportStyle?.borderTopColor||'',
        nodeCount:nodes.length,
        bossCount:nodes.filter(node=>node.classList.contains('is-boss')).length,
        verticalOverflow:!!viewport&&viewport.scrollHeight>viewport.clientHeight,
        firstAtBottom:y.length>1&&y[0]>y[y.length-1],
        currentVisible:(()=>{const active=nodes.find(node=>node.classList.contains('is-current'));if(!active||!viewport)return false;const a=active.getBoundingClientRect(),v=viewport.getBoundingClientRect();return a.bottom>v.top&&a.top<v.bottom})(),
        scrollTop:viewport?.scrollTop||0,
        bossNumbers:nodes.filter(node=>node.classList.contains('is-boss')).map(node=>node.dataset.planetNumber),
        trackDisplay:track?getComputedStyle(track).display:null,
        nodePosition:nodes[0]?getComputedStyle(nodes[0]).position:null,
        nodeSpread:(()=>{const xs=nodes.map(node=>node.getBoundingClientRect().left);return xs.length?Math.round(Math.max(...xs)-Math.min(...xs)):0})(),
        viewportOverflowY:viewport?getComputedStyle(viewport).overflowY:null,
        viewportClientHeight:viewport?.clientHeight||0,
        viewportClientWidth:viewport?.clientWidth||0,
        viewportScrollHeight:viewport?.scrollHeight||0,
        alignmentStatus:viewport?.dataset.routeAlign||'not-run',
        alignmentTop:viewport?.dataset.routeAlignTop||null,
        alignmentNode:viewport?.dataset.routeAlignNode||null,
        trackOffsetHeight:track?.offsetHeight||0,
        currentOffsetTop:(()=>{const active=nodes.find(node=>node.classList.contains('is-current'));return active?.offsetTop??null})(),
        currentRect:(()=>{const active=nodes.find(node=>node.classList.contains('is-current'));if(!active)return null;const r=active.getBoundingClientRect();return {top:Math.round(r.top),bottom:Math.round(r.bottom),left:Math.round(r.left),right:Math.round(r.right),height:Math.round(r.height)}})()
      };
    });
    if(routeState.orientation!=='vertical'||routeState.nodeCount!==30||routeState.bossCount!==3||!routeState.verticalOverflow||!routeState.firstAtBottom||!routeState.currentVisible||routeState.alignmentStatus!=='applied'||routeState.headingOrbWidth<60||!routeState.headingOrbBackground.includes('radial-gradient')||routeState.routePanelBorder==='rgba(0, 0, 0, 0)'||routeState.nodeSpread<routeState.viewportClientWidth*0.4){
      failures.push(target.name+': KT-555 vertical campaign route geometry/progression mismatch ('+JSON.stringify(routeState)+')');
    }
    await campaignPage.screenshot({timeout:45000,path:outputDir+'/'+target.name+'-campaign-vertical-route.png',fullPage:false});
    // Reload the isolated preview so the following mission test starts from
    // the same clean atlas state on Chromium and WebKit.
    await campaignPage.reload({waitUntil:'domcontentloaded'});
    await campaignPage.locator('button.mode[data-mode="campaign"]').waitFor({state:'visible',timeout:15000});
    await campaignPage.locator('button.mode[data-mode="campaign"]').click();
    await campaignPage.locator('#campaignStart').waitFor({state:'visible',timeout:15000});
    // The campaign start button can keep shifting while the 3D atlas model settles;
    // visibility/enabled are asserted above, so dispatch its native DOM click after scrolling.
    await campaignPage.locator('#campaignStart').scrollIntoViewIfNeeded();
    await campaignPage.locator('#campaignStart').evaluate(button => button.click());
    await campaignPage.locator('#bbStartHeroList [data-start-hero]').first().waitFor({state:'visible',timeout:10000});
    await campaignPage.locator('#bbStartHeroList [data-start-hero]').first().click();
    try {
      await campaignPage.locator('#bbStartHeroChoose').waitFor({state:'visible',timeout:10000});
    } catch (error) {
      const heroDiagnostic=await campaignPage.evaluate(()=>({
        modalVisible:!!document.querySelector('#modal.show'),
        modalText:document.querySelector('#modal')?.innerText?.slice(0,1200)||'',
        heroListCount:document.querySelectorAll('#bbStartHeroList [data-start-hero]').length,
        chooseButton:!!document.querySelector('#bbStartHeroChoose'),
        confirmButton:!!document.querySelector('#bbConfirmStartHero')
      }));
      failures.push(target.name+': campaign hero detail did not open ('+JSON.stringify({heroDiagnostic,pageErrors:pageErrors.slice(-5)})+')');
      await campaignPage.screenshot({timeout:45000,path:outputDir+'/'+target.name+'-campaign-hero-diagnostic.png',fullPage:false});
      await campaignPage.close();
      continue;
    }
    await campaignPage.locator('#bbStartHeroChoose').click();
    await campaignPage.locator('#game #campaignGoals').waitFor({ state: 'visible', timeout: 15000 });
    await campaignPage.waitForTimeout(900);
    const campaignMissionState = await campaignPage.evaluate(() => {
      const goals = document.querySelector('#campaignGoals');
      return {
        objectiveRows: Math.max(0, goals ? Array.from(goals.children).filter(node => node.tagName === 'DIV').length - 1 : 0),
        boostLabel: document.querySelector('#boostName')?.textContent || '',
        cardChoices: document.querySelectorAll('#modal [data-up]').length,
        missionBottom: goals ? goals.getBoundingClientRect().bottom : 0,
        viewportHeight: innerHeight,
        proceduralModels: document.querySelectorAll('#campaign [data-universe-model].is-model-fallback').length,
        loadedModels: document.querySelectorAll('#campaign [data-universe-model].is-loaded').length
      };
    });
    if (campaignMissionState.proceduralModels < 1) failures.push(target.name + ': campaign has no visible procedural 3D fallback models');
    if (campaignMissionState.objectiveRows < 2) failures.push(target.name + ': campaign must show at least two mission objectives');
    if (campaignMissionState.boostLabel !== 'Только в Block Run') failures.push(target.name + ': campaign HUD must not expose upgrade cards');
    if (campaignMissionState.cardChoices !== 0) failures.push(target.name + ': campaign must not open card choices');
    if (target.mobile && campaignMissionState.missionBottom > campaignMissionState.viewportHeight + 2) failures.push(target.name + ': campaign mission rail extends beyond the viewport');
    await campaignPage.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-campaign-missions.png', fullPage: false });
    console.log('[stage:campaign-missions] ' + target.name);
    await campaignPage.close();

    {
      // KT-591: run the same daily-challenge entry and objective checks on
      // desktop, iOS WebKit, and Android Chromium — not desktop only.
      console.log('[stage:daily-challenge] ' + target.name);
      // Daily challenge objective must remain visible after the player enters the arena.
      const dailyPage = await context.newPage();
      dailyPage.setDefaultTimeout(15000);
      dailyPage.setDefaultNavigationTimeout(30000);
      dailyPage.on('pageerror', error => pageErrors.push('daily: ' + (error.stack || String(error))));
      dailyPage.on('console', message => { if (message.type() === 'error') consoleErrors.push('daily: '+message.text()); });
      dailyPage.on('requestfailed', request => failedRequests.push({url:request.url(),failure:request.failure()?.errorText||'unknown',page:'daily'}));
      await dailyPage.goto('http://127.0.0.1:4173/index.html', { waitUntil: 'domcontentloaded', timeout: 30000 });
      await dailyPage.locator('button.mode[data-mode="daily"]').click();
      await dailyPage.locator('#dailyStart:not([disabled])').click();
      await dailyPage.locator('#bbStartHeroList [data-start-hero]').first().evaluate(element => element.click());
      await dailyPage.locator('#bbStartHeroChoose').waitFor({ state: 'visible', timeout: 15000 });
      await dailyPage.locator('#bbStartHeroChoose').evaluate(element => element.click());
      await dailyPage.locator('#game #dailyMissionGoal:not([hidden])').waitFor({ state: 'visible', timeout: 15000 });
      await dailyPage.waitForTimeout(1200);
      const dailyGoalState = await dailyPage.evaluate(() => {
        const panel=document.querySelector('#game #dailyMissionGoal');
        const rect=panel?.getBoundingClientRect();
        return {
          visible:!!panel&&getComputedStyle(panel).display!=='none'&&getComputedStyle(panel).visibility!=='hidden'&&rect.width>0&&rect.height>0,
          text:panel?.innerText?.replace(/\s+/g,' ').trim()||'',
          parentId:panel?.parentElement?.id||'',
          parentClass:typeof panel?.parentElement?.className==='string'?panel.parentElement.className:'',
          gameOpacity:panel?getComputedStyle(panel.closest('#game')).opacity:null,
          panelOpacity:panel?getComputedStyle(panel).opacity:null,
          valueFontSize:panel?.querySelector('strong')?getComputedStyle(panel.querySelector('strong')).fontSize:null,
          labelFontSize:panel?.querySelector('.daily-mission-label')?getComputedStyle(panel.querySelector('.daily-mission-label')).fontSize:null,
          rect:rect?{x:rect.x,y:rect.y,width:rect.width,height:rect.height}:null
        };
      });
      if (!dailyGoalState.visible) failures.push(target.name + ': daily challenge objective is not visible inside the arena');
      if (!dailyGoalState.text.includes('ЦЕЛЬ ИСПЫТАНИЯ')) failures.push(target.name + ': daily objective label is missing');
      if (!dailyGoalState.text.match(/\d+\s*(?:линий|линии|линия|очков|секунд)/i)) failures.push(target.name + ': daily objective value is missing (' + dailyGoalState.text + ')');
      if (!target.mobile && !dailyGoalState.parentClass.includes('game-heading-copy')) failures.push(target.name + ': desktop daily objective is not attached to the arena heading');
      if (target.mobile && dailyGoalState.parentId !== 'game') failures.push(target.name + ': mobile daily objective was moved out of its original layout');
      await dailyPage.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-daily-challenge-arena.png', fullPage: false });
      await dailyPage.close();

    }

    console.log('[stage:block-run-start] ' + target.name);
    await page.locator('button.mode[data-mode="rogue"]').click();
    await page.locator('#bbConfirmStartHero').waitFor({ state: 'visible', timeout: 15000 });
    await page.locator('#bbConfirmStartHero').evaluate(element => element.click());
    await page.locator('#game:not([hidden])').waitFor({ state: 'visible', timeout: 15000 });
    await page.locator('#game .boardframe').waitFor({ state: 'visible', timeout: 10000 });
    await page.waitForTimeout(900);

    console.log('[stage:gameplay-ready] ' + target.name);

    // KT-576: pause and result overlays must use the Godot cosmic panel language.
    const pauseButton = page.locator('#pauseBtn');
    await pauseButton.waitFor({ state: 'visible', timeout: 10000 });
    // Mobile WebKit may scroll the fixed HUD button while Playwright is trying
    // to synthesize a pointer click. Trigger the real DOM click handler directly;
    // the following overlay assertion still verifies that the control works.
    await pauseButton.evaluate(element => element.click());
    await page.locator('#overlay.show #resume').waitFor({state:'visible',timeout:8000});
    const pauseOverlayState=await page.evaluate(()=>{
      const root=document.querySelector('#overlay'),modal=document.querySelector('#modal');
      const action=modal?.querySelector('#resume'),wallet=modal?.querySelector('.bb-pause-wallet');
      const css=getComputedStyle(modal),button=action?getComputedStyle(action):null;
      return {
        variant:root?.classList.contains('bb-godot-pause-overlay'),
        borderRadius:parseFloat(css.borderTopLeftRadius)||0,
        borderColor:css.borderTopColor,
        background:css.backgroundImage,
        wallet:!!wallet,
        buttonBackground:button?.backgroundImage||'',
        buttonBorder:button?.borderTopColor||''
      };
    });
    if(!pauseOverlayState.variant||pauseOverlayState.borderRadius<16||
       !pauseOverlayState.borderColor.includes('85')&&!pauseOverlayState.borderColor.includes('rgb')||
       !pauseOverlayState.background.includes('radial-gradient')||!pauseOverlayState.wallet||
       !pauseOverlayState.buttonBackground.includes('linear-gradient')){
      failures.push(target.name+': KT-576 Godot pause overlay styling mismatch ('+JSON.stringify(pauseOverlayState)+')');
    }
    const resultStyleState=await page.evaluate(()=>{
      const root=document.querySelector('#overlay'),modal=document.querySelector('#modal');
      root.classList.remove('bb-godot-pause-overlay');
      root.classList.add('bb-godot-result-overlay');
      const css=getComputedStyle(modal);
      const stat=document.createElement('div');stat.className='bottomstats';stat.innerHTML='<div class="stat"><strong>12</strong><span>ЛИНИИ</span></div>';modal.append(stat);
      const statColor=getComputedStyle(stat.querySelector('strong')).color;
      stat.remove();
      return {variant:root.classList.contains('bb-godot-result-overlay'),borderRadius:parseFloat(css.borderTopLeftRadius)||0,statColor};
    });
    if(!resultStyleState.variant||resultStyleState.borderRadius<16){
      failures.push(target.name+': KT-576 Godot result overlay styling mismatch ('+JSON.stringify(resultStyleState)+')');
    }
    await page.locator('#resume').click();
    await page.waitForTimeout(120);

    // Exercise KT-418 during a live run: rotate to phone landscape, confirm
    // the game pauses and the guard covers the viewport, then return to
    // portrait and confirm the same run resumes automatically.
    if (target.name === 'ios-webkit-390x844') {
      await page.setViewportSize({ width: 844, height: 390 });
      await page.waitForTimeout(180);
      const landscapeState = await page.evaluate(() => {
        const guard = document.querySelector('#bbPhoneLandscapeGuard');
        const piece = window.__TETRIOS_QA__?.getPieceState?.();
        return {
          guardVisible: !!guard && getComputedStyle(guard).display !== 'none',
          paused: !!piece?.paused,
          started: !!piece?.started,
          gameOver: !!piece?.gameOver
        };
      });
      if (!landscapeState.guardVisible || !landscapeState.paused ||
          !landscapeState.started || landscapeState.gameOver) {
        failures.push('KT-418: live phone landscape did not show the guard and pause the active run (' + JSON.stringify(landscapeState) + ')');
      }
      await page.setViewportSize({ width: 390, height: 844 });
      await page.waitForTimeout(180);
      const portraitState = await page.evaluate(() => {
        const guard = document.querySelector('#bbPhoneLandscapeGuard');
        const piece = window.__TETRIOS_QA__?.getPieceState?.();
        return {
          guardHidden: !!guard && getComputedStyle(guard).display === 'none',
          resumed: !!piece?.started && !piece?.paused && !piece?.gameOver
        };
      });
      if (!portraitState.guardHidden || !portraitState.resumed) {
        failures.push('KT-418: returning to portrait did not hide the guard and resume the same run (' + JSON.stringify(portraitState) + ')');
      }
    }
    // Exercise real board touch listeners in WebKit/Chromium, not only screenshots.
    if (target.mobile) {
      const gestureResult = await page.evaluate(() => {
        const board=document.querySelector('#game #board');
        const surface=document.querySelector('#game .gamehud');
        const qa=window.__TETRIOS_QA__;
        if(!board||!surface||!qa?.getPieceState) return {supported:false,reason:'board, non-board gesture surface, or QA state hook missing'};
        const prepared=qa.prepareGestureTest?.();
        if(!prepared?.ready) return {supported:false,reason:'deterministic test piece could not be prepared'};
        const rect=board.getBoundingClientRect();
        const surfaceRect=surface.getBoundingClientRect();
        const centerX=surfaceRect.left+surfaceRect.width*.5,centerY=surfaceRect.top+surfaceRect.height*.5;
        let identifier=71;
        const send=(type,x,y,target=surface)=>{
          // Start on the HUD, outside #board, then move/release on body. This
          // verifies document-level pointer tracking beyond the original hit
          // target and across the arena boundary.
          const event=new PointerEvent(type,{
            bubbles:true,cancelable:true,pointerId:identifier,
            pointerType:'touch',isPrimary:true,clientX:x,clientY:y,
            width:8,height:8,pressure:type==='pointerup'?0:.5
          });
          target.dispatchEvent(event);
        };
        const state=()=>qa.getPieceState().piece;
        const swipe=(dx,dy)=>{
          const x=centerX,y=centerY;
          identifier++;
          send('pointerdown',x,y,surface);
          send('pointermove',x+dx,y+dy,document.body);
          send('pointerup',x+dx,y+dy,document.body);
        };
        const before=state();
        const horizontalStep=Math.max(28,rect.width*.14);
        const diagonalDistance=Math.max(36,Math.min(horizontalStep,rect.height*.06));
        swipe(diagonalDistance,-diagonalDistance);
        const afterDiagonal=state();
        const diagonalRejected=!!before&&!!afterDiagonal&&JSON.stringify(before)===JSON.stringify(afterDiagonal);
        swipe(horizontalStep,0);
        const afterRight=state();
        // Repeat immediately, without waiting for a cooldown timer.
        swipe(horizontalStep,0);
        const afterRightRepeat=state();
        swipe(-horizontalStep,0);
        const afterLeft=state();
        const rotationSwipe=-Math.max(40,rect.height*.06);
        swipe(0,rotationSwipe);
        const afterRotate=state();
        // A second fast rotation must not be throttled by the hard-drop guard.
        swipe(0,rotationSwipe);
        const afterRotateRepeat=state();
        swipe(0,Math.min(70,Math.max(20,rect.height*.10)));
        const afterDown=state();
        // A touch Hard Drop must not leave a shared cooldown that delays the next
        // deliberate horizontal move or rotation.
        const touchDrop=qa.triggerTouchDrop?.();
        const postDropProbe=qa.preparePostDropGestureProbe?.();
        const afterTouchDrop=state();
        const afterTouchDropX=afterTouchDrop?.x;
        swipe(horizontalStep,0);
        const afterDropMove=state();
        const afterDropMoveX=afterDropMove?.x;
        const afterDropMoveShape=afterDropMove?JSON.stringify(afterDropMove.shape):null;
        swipe(0,rotationSwipe);
        const afterDropRotate=state();
        const afterDropRotateShape=afterDropRotate?JSON.stringify(afterDropRotate.shape):null;
        return {
          supported:true,
          before,afterDiagonal,afterRight,afterRightRepeat,afterLeft,afterRotate,afterRotateRepeat,afterDown,
          afterTouchDrop,afterDropMove,afterDropRotate,touchDrop,postDropProbe,
          diagonalRejected,
          movedRight:!!before&&!!afterRight&&afterRight.x>before.x,
          repeatedRight:!!afterRight&&!!afterRightRepeat&&afterRightRepeat.x>afterRight.x,
          movedLeft:!!afterRightRepeat&&!!afterLeft&&afterLeft.x<afterRightRepeat.x,
          rotated:!!afterLeft&&!!afterRotate&&JSON.stringify(afterLeft)!==JSON.stringify(afterRotate),
          repeatedRotation:!!afterRotate&&!!afterRotateRepeat&&JSON.stringify(afterRotate)!==JSON.stringify(afterRotateRepeat),
          softDropped:!!afterRotateRepeat&&!!afterDown&&afterDown.y>=afterRotateRepeat.y,
          movedImmediatelyAfterDrop:Number.isFinite(afterTouchDropX)&&Number.isFinite(afterDropMoveX)&&afterDropMoveX!==afterTouchDropX,
          rotatedImmediatelyAfterDrop:!!afterDropMoveShape&&!!afterDropRotateShape&&afterDropMoveShape!==afterDropRotateShape
        };
      });
      if (!gestureResult.supported || !gestureResult.diagonalRejected || !gestureResult.movedRight || !gestureResult.repeatedRight || !gestureResult.movedLeft || !gestureResult.rotated || !gestureResult.repeatedRotation || !gestureResult.softDropped || !gestureResult.movedImmediatelyAfterDrop || !gestureResult.rotatedImmediatelyAfterDrop) {
        failures.push(target.name + ': mobile full-screen gesture interaction failed (' + JSON.stringify(gestureResult) + ')');
      }
    }

    const visualBoostState = await page.evaluate(() => window.__TETRIOS_QA__?.activatePrismAura?.() || null);
    if (!visualBoostState || !visualBoostState.activePiece || !visualBoostState.boosts.includes('prism') || !visualBoostState.auraOwned) {
      failures.push(target.name + ': Prism/Aura QA activation failed (' + JSON.stringify(visualBoostState) + ')');
    }
    if (visualBoostState && (!visualBoostState.prismColor || !/^#[0-9a-f]{6}$/i.test(visualBoostState.prismColor))) {
      failures.push(target.name + ': Prism did not produce a valid spectral color');
    }
    const voidState = await page.evaluate(() => window.__TETRIOS_QA__?.testVoidCompression?.() || null);
    if (!voidState || !voidState.firstActivation || voidState.secondActivation || voidState.rowCount !== 23 || voidState.blocksBefore !== voidState.blocksAfter || !voidState.topSpawnRowsEmpty) {
      failures.push(target.name + ': Void compression invariants failed (' + JSON.stringify(voidState) + ')');
    }
    await page.waitForTimeout(180);

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
      const game = document.querySelector('#game');
      const leftRail = document.querySelector('#game .gameleftcol');
      const controlRow = document.querySelector('#game .controls');
      const hint = document.querySelector('#game>.hint');
      return {
        viewport: { width: innerWidth, height: innerHeight },
        typography: (() => {
          const sample = selector => { const el=document.querySelector(selector); if(!el)return null; const cs=getComputedStyle(el); return {fontSize:cs.fontSize,lineHeight:cs.lineHeight,letterSpacing:cs.letterSpacing,scrollWidth:el.scrollWidth,clientWidth:el.clientWidth,scrollHeight:el.scrollHeight,clientHeight:el.clientHeight}; };
          return {hudLabel:sample('#game .gamehud .hudbox span'),sideLabel:sample('#game .sidecol .sidecard label'),boostName:sample('#game .sidecol .boostname'),goals:sample('#game #rogueGoals'),dailyGoal:sample('#game #dailyMissionGoal .daily-mission-label')};
        })(),
        document: {
          width: document.documentElement.scrollWidth,
          height: document.documentElement.scrollHeight
        },
        frame: rect(frame),
        playfield: rect(document.querySelector('#game #board')),
        leftRail: rect(leftRail),
        controlRow: rect(controlRow),
        controlVisibility: controlRow ? {display:getComputedStyle(controlRow).display,visibility:getComputedStyle(controlRow).visibility,pointerEvents:getComputedStyle(controlRow).pointerEvents,buttons:Array.from(controlRow.querySelectorAll('.control')).map(node=>rect(node))} : null,
        hint: rect(hint),
        side: rect(side),
        gameGrid: game ? { gridTemplateRows: getComputedStyle(game).gridTemplateRows, gridTemplateColumns: getComputedStyle(game).gridTemplateColumns, rowGap: getComputedStyle(game).rowGap } : null,
        sideScroll: side ? {
          overflowY: getComputedStyle(side).overflowY,
          scrollHeight: side.scrollHeight,
          clientHeight: side.clientHeight,
          maxScroll: Math.max(0, side.scrollHeight - side.clientHeight)
        } : null,
        heroSkillDiagnostic: (() => {
          const card=document.querySelector('#bbHeroSkillCard');
          const copy=card?.querySelector('.bb-hero-skill-copy');
          const art=card?.querySelector('.bb-hero-skill-art');
          const style=document.querySelector('#bb-mobile-hero-skill-final-override-kt40716');
          const cr=card?.getBoundingClientRect();
          return {
            media520:matchMedia('(max-width:520px)').matches,
            mediaPortrait:matchMedia('(orientation:portrait)').matches,
            cardFound:!!card,
            gameAncestor:!!card?.closest('#game'),
            parentChain:card?(()=>{const chain=[];let node=card;while(node&&chain.length<6){chain.push({tag:node.tagName,id:node.id||'',className:typeof node.className==='string'?node.className:''});node=node.parentElement;}return chain;})():[],
            intendedSelectorMatches:!!card?.matches('#game.unified-game-layout>.playlayout>.sidecol>#bbHeroSkillCard'),
            cardInline:card?.getAttribute('style')||null,
            cardComputed:card?{height:getComputedStyle(card).height,minHeight:getComputedStyle(card).minHeight,padding:getComputedStyle(card).padding,gap:getComputedStyle(card).gap,display:getComputedStyle(card).display}:null,
            copyDisplay:copy?getComputedStyle(copy).display:null,
            artDisplay:art?getComputedStyle(art).display:null,
            overrideStyleFound:!!style,
            overrideRuleCount:style?.sheet?.cssRules?.length??null,
            rect:cr?{width:cr.width,height:cr.height}:null
          };
        })(),
        utilityCards: side ? Array.from(side.querySelectorAll('.sidecard, .bb-hero-skill-slot')).filter(node => {
          const r = node.getBoundingClientRect();
          return r.width > 0 && r.height > 0;
        }).map(node => {
          const r = node.getBoundingClientRect();
          return { id: node.id || node.className, top: Math.round(r.top*100)/100, bottom: Math.round(r.bottom*100)/100, height: Math.round(r.height*100)/100 };
        }) : [],
        utilityCardsFit: side ? Array.from(side.querySelectorAll('.sidecard, .bb-hero-skill-slot')).filter(node => {
          const r = node.getBoundingClientRect();
          return r.width > 0 && r.height > 0;
        }).every(node => {
          const r = node.getBoundingClientRect(), sr = side.getBoundingClientRect();
          return r.top >= sr.top - 1 && r.bottom <= sr.bottom + 1;
        }) : false,
        drop: rect(drop),
        hold: rect(hold),
        goals: rect(goals),
        playlayout: rect(playlayout),
        playfieldRatio: (() => { const board=document.querySelector('#game #board'),r=board?.getBoundingClientRect(); return r&&r.height>0?r.width/r.height:0; })()
      };
    });

    const ratio = geometry.playfieldRatio;
    if (!geometry.frame || ratio < 0.42 || ratio > 0.45) {
      failures.push(target.name + ': arena frame ratio is outside the 10:23 tolerance (' + ratio + ')');
    }
    if (geometry.document.width > target.width + 2) {
      failures.push(target.name + ': horizontal document overflow (' + geometry.document.width + 'px)');
    }
    let sideScrollCheck = null;
    if (target.mobile) {
      // KT-412 intentionally replaces the bottom movement/rotation deck with
      // board gestures. Assert the old deck is absent and the board is the
      // active touch surface; do not fail because legacy buttons are hidden.
      if (geometry.controlRow && geometry.controlVisibility &&
          (geometry.controlVisibility.display !== 'none' ||
           geometry.controlVisibility.visibility === 'visible' ||
           geometry.controlVisibility.pointerEvents !== 'none' ||
           geometry.controlRow.width > 1 || geometry.controlRow.height > 1)) {
        failures.push(target.name + ': complete bottom movement deck must be removed from mobile layout (' + JSON.stringify(geometry.controlVisibility) + ')');
      }
      const boardGestureState = await page.evaluate(() => {
        const board = document.querySelector('#game #board');
        const frame = document.querySelector('#game .boardframe');
        const style = board ? getComputedStyle(board) : null;
        const rect = board?.getBoundingClientRect();
        return {
          boardFound: !!board,
          frameFound: !!frame,
          boardVisible: !!rect && rect.width > 0 && rect.height > 0 &&
            style.display !== 'none' && style.visibility !== 'hidden',
          touchAction: style?.touchAction || '',
          frameRatio: frame ? frame.getBoundingClientRect().width / frame.getBoundingClientRect().height : 0
        };
      });
      if (!boardGestureState.boardFound || !boardGestureState.boardVisible || boardGestureState.touchAction !== 'none') {
        failures.push(target.name + ': gesture-first board touch surface is missing or does not suppress browser gestures (' + JSON.stringify(boardGestureState) + ')');
      }
      if (!geometry.drop || geometry.drop.width < 40 || geometry.drop.height < 36) {
        failures.push(target.name + ': Hard Drop control is missing or too small');
      }
      if (!geometry.hold || geometry.hold.width < 30 || geometry.hold.height < 24) {
        failures.push(target.name + ': Hold control is missing or too small');
      }
      if (geometry.goals && geometry.goals.bottom > target.height + 2) {
        failures.push(target.name + ': Block Run goals extend beyond the viewport');
      }
      if (geometry.frame && geometry.goals) {
        const overlapsHorizontally = geometry.goals.x < geometry.frame.right && geometry.goals.right > geometry.frame.x;
        const overlapsVertically = geometry.goals.y < geometry.frame.bottom + 3 && geometry.goals.bottom > geometry.frame.y;
        if (overlapsHorizontally && overlapsVertically) {
          failures.push(target.name + ': goals overlap the 10:23 arena cabinet');
        }
      }
      if (geometry.sideScroll && geometry.sideScroll.maxScroll > 2) {
        failures.push(target.name + ': utility HUD requires scrolling (' + geometry.sideScroll.maxScroll + 'px overflow)');
      }
      if (!geometry.utilityCardsFit) {
        failures.push(target.name + ': one or more utility HUD cards are clipped outside the rail');
      }
      if (geometry.drop && geometry.side && (geometry.drop.bottom > geometry.side.bottom + 1 || geometry.drop.top < geometry.side.top - 1)) {
        failures.push(target.name + ': Hard Drop control is clipped by the utility rail');
      }
      if (geometry.hold && geometry.side && (geometry.hold.bottom > geometry.side.bottom + 1 || geometry.hold.top < geometry.side.top - 1)) {
        failures.push(target.name + ': Hold control is clipped by the utility rail');
      }
      if (geometry.frame && geometry.frame.right > target.width + 2) {
        failures.push(target.name + ': arena extends beyond the right viewport edge');
      }
      if (target.mobile && target.width < 600 && target.height > 600 &&
          geometry.playfield && geometry.playfield.width < target.width * 0.53) {
        failures.push(target.name + ': KT-552 portrait board did not reach the expanded 53vw minimum (' + geometry.playfield.width + 'px)');
      }
    } else if (geometry.frame && (geometry.frame.y < -2 || geometry.frame.bottom > target.height + 2)) {
      failures.push(target.name + ': desktop arena is not contained by the viewport');
    }

    await page.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-arena-2d.png', fullPage: false });
    await page.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-arena-prism-aura.png', fullPage: false });
    console.log('Captured 2D arena and Prism/Aura state: ' + target.name);

    const arenaModeState = await page.evaluate(() => ({
      toggleCount: document.querySelectorAll('#game .boardframe .bb-arena-toggle').length,
      overlayCanvasCount: document.querySelectorAll('#game .boardframe .bb-arena-canvas').length,
      boardVisible: (() => { const board=document.querySelector('#game #board'); if(!board)return false; const style=getComputedStyle(board),rect=board.getBoundingClientRect(); return style.display!=='none'&&style.visibility!=='hidden'&&Number(style.opacity)>0&&rect.width>0&&rect.height>0; })()
    }));
    if (arenaModeState.toggleCount !== 0 || arenaModeState.overlayCanvasCount !== 0 || !arenaModeState.boardVisible) {
      failures.push(target.name + ': expected the single-renderer 2D arena with no 3D toggle or overlay (' + JSON.stringify(arenaModeState) + ')');
    }
    await page.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-arena-2d-final.png', fullPage: false });
    if (target.mobile && target.width < 600 && target.height > 600) {
      await page.screenshot({ timeout:45000, path: outputDir + '/' + target.name + '-kt552-tall-phone-arena.png', fullPage: false });
    }
    console.log('[stage:final-arena-verified] ' + target.name);

    report.push({ target: target.name, engine: target.engine, geometry, sideScrollCheck, arenaModeState, visualBoostState, voidState, campaignAtlasState, campaignMissionState, pageErrors, consoleErrors, failedRequests });
    await context.close();
    await browser.close();
    clearTimeout(targetWatchdog);
    console.log('[target:complete] ' + target.name);
  }

  fs.writeFileSync(outputDir + '/report.json', JSON.stringify({ report, failures }, null, 2));
  console.log(JSON.stringify({ report, failures }, null, 2));
  if (failures.length) throw new Error(failures.join('\n'));
})().catch(error => {
  console.error(error);
  process.exit(1);
});
