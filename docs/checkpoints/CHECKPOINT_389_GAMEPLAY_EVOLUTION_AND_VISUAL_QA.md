# TETRIOS LX — CHECKPOINT #389
## Gameplay evolution architecture audit and cross-platform visual QA

**Date:** 2026-11-03  
**Feature branch:** `feature/gameplay-evolution-389-2026-11-03`  
**Branch base:** `6b1b6afb4bba62571a4b78990728ac8814e10e98` — checkpoint #388 / verified APK #799  
**Protected mobile source PR:** #48 — open, not merged  
**Protected desktop baseline:** #372 — `3e7387f667e9420f04f62e327ef854b703c68297`  
**Production deploy:** not performed  
**APK:** not requested or built for this checkpoint

## Verified starting point

- The correct #388 continuation is the head of PR #48, branch `mobile/golden-arena-adaptation-2026-11-03`, head SHA `6b1b6afb4bba62571a4b78990728ac8814e10e98`.
- The #388 checkpoint file records the universe duplicate/ghost removal, seven procedural planet silhouette families, incremental soft-drop, preserved hard-drop, and future hero placement exclusively in the hero roster.
- PR #48 contains mobile arena and control work; it explicitly preserves desktop Golden Baseline #372 and is not merged.
- The new feature branch is created from the exact #388 head, not from stale `main`.
- Existing visual workflow: `.github/workflows/mobile-arena-preview.yml`. It runs Playwright Chromium for 375×812 and 412×915, captures 2D and 3D screenshots, checks arena ratio/overflow/overlay alignment, and uploads `tetrios-mobile-arena-preview`.
- The mobile preview artifact from run `41632096050` is `13227409865`. The artifact can be downloaded and inspected as a ZIP; this is a proven route for visual review of CI screenshots.

## Architecture findings from current game source

- Modes currently exposed: `campaign`, `rogue` (Block Run), and `daily`.
- Roguelike upgrade definitions live in the shared `upgrades` array (35 entries), while rank state and several card synergies are guarded by `mode === 'rogue'`.
- The current level-up flow still offers non-rogue relic choices in campaign/daily. This is distinct from roguelike card drafting and must not be removed blindly.
- The monster encounter object, monster HP and timed attacks are currently specific to Block Run. `bbRogueEnemyAttack()` currently inserts garbage rows (two for bosses); this is the attack behavior to expand into readable, telegraphed attack patterns.
- Hero active abilities already exist for five heroes and unlock at hero level 5 with a 45-second cooldown. The existing standard-mode and Block Run behaviors differ. Preserve hero identity, unlock progression, cooldown, and the already working abilities while deepening their effects.
- A dedicated active-boost viewer exists in the HUD. It can become an entry point to a permanent pre-game card library, but the library must not grant cards or alter balance simply by being opened.

## Scope for #389 and following checkpoints

1. **Mode boundaries:** keep roguelike drafting, ranks, synergies, escalating room/floor state, and monster encounter timers exclusively in Block Run. Preserve campaign progression/relic choices and daily challenge modifiers as separate systems. Do not disable standard hero abilities.
2. **Card library:** add a persistent reference/catalog view for all cards with clear effect, trigger, rank behavior, rarity, and counterplay. In Block Run, preserve draft/evolution loop. Add pre-run strategy/loadout only after the rules and balance are specified and tested; no accidental card ownership economy.
3. **Card effects:** route gameplay effects through explicit events (line clear, combo, timer tick, incoming attack, level-up, monster defeat) with deterministic stacking/caps and tests. Audit all 35 current upgrade implementations before adding new ones.
4. **Monster attacks:** introduce attack telegraphs and distinct counterable patterns (gravity pulse, temporary rotation lock, cryo slow, drone interference, spatial shift, marked-cell hazard). Keep a visible warning window and fair response; never create an unavoidable loss from a hidden instant effect.
5. **Heroes:** deepen the five existing heroes (Captain Plush, Prism, Blip, Pixel, Spark) without replacing their current active/passive mechanics. Each should have a distinct tactical role and readable feedback.
6. **Equal platforms:** every player-facing feature and UI must work in desktop web and mobile web. Preserve Golden Desktop Baseline #372; preserve mobile 10:23 arena and touch controls. Do not treat desktop as a secondary target.
7. **Build policy:** no APK build unless native Android WebView validation is specifically needed. For iOS, use automated Mobile Safari/WebKit emulation plus manual real-iPhone Safari checks for platform-specific behavior.

## Visual inspection and test pipeline

- Extend the existing Playwright visual-preview workflow rather than introducing a second, duplicate harness.
- Add desktop viewport captures at wide and short heights (at minimum 1440×900 and 1280×720), preserving the existing mobile captures.
- Add Playwright WebKit project with iPhone device profile for Mobile Safari-style coverage. This is WebKit emulation, not proof of behavior in Apple's branded Safari; retain a manual real-device check for iOS-specific issues.
- Upload desktop Chromium and mobile WebKit screenshots as separate named artifacts, plus the existing Android WebView source audit. Keep screenshot artifacts available for direct visual review.
- Add game-flow smoke tests for campaign, Block Run, daily challenge, each hero ability, card catalog, monster telegraphs, pause/resume, and responsive desktop/mobile viewports.
- Record exact commit, workflow run, artifact ID, test outcome, and screenshot review status at each checkpoint.

## Acceptance gates

- No regression to desktop Golden Baseline #372.
- No regression to mobile arena proportions, hard-drop/hold controls, or incremental soft-drop.
- Campaign and daily do not receive roguelike card ranks, synergies, room timers, or monster attacks.
- Block Run retains its roguelike progression.
- Five heroes remain distinct and usable in both desktop and mobile web.
- Desktop Chromium and mobile WebKit screenshot artifacts are uploaded and inspected before visual acceptance.
- No production deploy or main-branch merge without explicit approval.

## Continuation phrase

`TETRIOS LX — продолжаем с #389: ветка feature/gameplay-evolution-389-2026-11-03 от точного #388 / APK #799. Сохраняем Golden Desktop Baseline #372 и мобильную арену. Roguelike — только Block Run; каталог карт и стратегии; новые телеграфированные атаки монстров; уникальные способности пяти героев. ПК и мобильная веб-версия равноправны. Визуальные тесты: Chromium desktop + mobile WebKit/iPhone, скриншоты из CI artifacts. APK не собираем без необходимости. Контрольные точки обязательны.`

## Implementation update — 2026-11-03

- Added a pre-run **Библиотека усилений** entry to the main menu.
- The archive renders all 35 existing upgrade cards with their current effect descriptions.
- Added filters: all cards, Block Run-only cards, and shared cards.
- The four current Block Run-only IDs are `burst`, `rift`, `reserve`, and `hunter`; 31 cards are currently shared.
- The archive is read-only: opening it does not award cards, alter a run, or modify progression.
- Extended `scripts/cross-platform-visual-preview.cjs` to assert 35 / 4 / 31 catalog counts and capture the archive at desktop Chromium and iOS WebKit viewports.
- Implementation commit: `caf47005e51689e18540ea8954db93a2540a4398`.
- Visual test commit: `a844403b009f0cbd5911b4a79734c859e2d2e65a`.
- Draft PR #50: https://github.com/MaiklLX/Tetrios.LX/pull/50. It is not merged and no production deployment has been requested.
- CI runs at the time of this update are still in progress; screenshots and assertions are not yet accepted.

## Automation note

Opening draft PR #50 triggered the repository's existing pull-request workflows, including its pre-existing Android APK build workflow. That APK workflow was not manually requested. Going forward, the PR workflow configuration must be adjusted so visual/code review does not trigger native APK builds unless explicitly needed.


## Visual QA follow-up — 2026-11-03

- Cross-platform visual preview on the pre-adjustment test commit `076bf9740c291c2a15cb27791c7f5e2a6413786b` completed successfully: run `41662895309`, artifact `13242464580`.
- Mobile Arena Visual Preview on the updated test commit `f2620d2b3abc19864e9e49d041b571f4ff81b927` completed successfully: run `41664481652`, artifact `13246030477`.
- Android WebView source audit on `f2620d2b3abc19864e9e49d041b571f4ff81b927` completed successfully: run `41664482048`.
- Screenshot review confirmed the library layout renders on desktop Chromium and iPhone-sized WebKit viewports; the list itself is scrollable. The first artifact's primary library screenshot showed the 4-card Block Run filter because the test captured after changing filters, not the default all-cards view.
- Corrected the visual test to capture the default 35-card view first, then separate Block Run (4) and shared (31) filter screenshots. Test-only commit: `f2620d2b3abc19864e9e49d041b571f4ff81b927`.
- Latest cross-platform preview runs `41664481743` and `41664479828` were still running at checkpoint update; the mobile preview and Android source audit were green. Do not mark screenshot acceptance complete until the latest cross-platform artifact is uploaded and inspected.
- APK workflow configuration on this branch was verified to trigger only on `workflow_dispatch` or pushes to `main`; it no longer has a `pull_request` trigger. The earlier APK run caused by the pre-existing PR trigger remains an acknowledged incident.
- PR #50 remains draft/open, base `main`, head `f2620d2b3abc19864e9e49d041b571f4ff81b927`; no merge or production deploy.
- Initial gameplay audit: Block Run currently has a single generic garbage-row monster attack (two rows for bosses) with a countdown but no distinct attack telegraph/counterplay. The existing upgrade pool has 35 entries and the selection/rank system is present, but implementation is distributed across line-clear, timer, level-up, hold, death, and monster-defeat code. Build an event/trigger map before refactoring; do not infer that an upgrade is missing solely from a lack of `boosts.includes` (some are implemented through dedicated state or rendering paths).
