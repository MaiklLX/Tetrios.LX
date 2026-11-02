# CHECKPOINT 328 — Desktop screen visibility hotfix

Date: 2026-11-02

## Problem
On desktop, the main menu, secondary screens, and game arena appeared simultaneously. The mobile-first desktop CSS assigned explicit `display:block !important` / `display:flex !important` values to screen sections, overriding the browser's normal `[hidden]` behavior used by the app's screen navigation.

## Fix
- Updated `site/index.html` only.
- Added `.screen[hidden] { display:none !important; }` inside the existing `@media (min-width: 901px)` block `bb-desktop-mobile-layout-v1`.
- This restores the visibility contract for menu, shop, heroes, campaign, daily challenge, and game screens.
- No JavaScript, game logic, mobile CSS, or layout structure changed.

## Implementation
- Commit: `3ef0fcfe206e952e23bce2a66c5337e54e5f8696`
- Previous desktop baseline: checkpoint #327 / commit `1eb765d45564fbbb48b68ad47e374140d5f04178`

## Verification
- Source check confirms the override is present inside the desktop media query.
- Web deployment run: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41453070443
- Debug APK run: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41453070333
- Release APK run: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41453070669
- At checkpoint creation these runs were queued/in progress; deployment is not yet confirmed.
- Browser visual verification has not been performed. After deployment, verify that only the home menu is visible on initial load and that Campaign, Heroes, Shop, Daily, and Game each open alone and return correctly.

## Continuation phrase
TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 328. DESKTOP SCREEN VISIBILITY HOTFIX: В bb-desktop-mobile-layout-v1 ДОБАВЛЕНО `.screen[hidden]{display:none!important}`, ЧТОБЫ DESKTOP DISPLAY ПРАВИЛА НЕ ПОКАЗЫВАЛИ ВСЕ ЭКРАНЫ ОДНОВРЕМЕННО. Коммит 3ef0fcfe206e952e23bce2a66c5337e54e5f8696. Проверить публикацию и отдельно проверить главное меню, кампанию, героев, магазин, ежедневный вызов и арену. Не менять мобильную вёрстку и игровую логику.
