# CHECKPOINT 326 — Desktop layout reset

Date: 2026-11-02

## Purpose
Recover the desktop web layout after repeated CSS patches caused overlapping dashboard elements and a distorted game arena.

## Backup
Created branch:
- `backup/pre-desktop-layout-reset-2026-11-02`
- Base commit: `0cddd3da7de8867b17b934e911c33379fddd0286`

## Implementation
Updated `site/index.html` on `main`.

Implementation commit:
- `8b6acfdd0432e582b7b976fb50fb3ae7de370d9e`

Removed seven competing desktop-only style blocks:
- `bb-desktop-restoration-v1`
- `bb-desktop-arena-restoration-v2`
- `bb-desktop-arena-hidden-guard-v1`
- `bb-desktop-home-dashboard-v2`
- `bb-desktop-layout-correction-v3`
- `bb-desktop-single-viewport-v1`
- `bb-desktop-overlap-correction-v2`

Replaced them with one authoritative desktop stylesheet:
- `bb-desktop-layout-unified-v1`

The new stylesheet is desktop-only (`min-width: 901px`) and defines:
- one explicit dashboard grid matching the actual DOM;
- campaign / block-run / daily challenge cards in one visible row;
- streak, hero selection and currency in a dedicated information row;
- daily quests across the full dashboard width;
- reset, shop (inside `#rpgPanel`) and stats in the footer row;
- a two-column game layout: board plus information rail;
- a 10:23 board frame based on the canvas's actual 300×690 ratio;
- a two-column side rail with bounded rows and a full-width hero skill slot;
- independently scrollable secondary screens (shop, heroes, campaign, daily).

No gameplay JavaScript, canvas drawing logic, mobile CSS, or Android project files were changed.

## Structural verification
Fetched the resulting `site/index.html` from `main` and confirmed:
- new desktop stylesheet occurs exactly once;
- all seven superseded desktop styles are absent;
- campaign button markup and label remain present;
- JavaScript shop relocation code remains present;
- all six primary screen sections remain present;
- board canvas markup remains present;
- HTML closes correctly;
- stylesheet braces are balanced at authoring time.

## Important limitation
A rendered browser inspection was attempted but the live Pages URL was not accessible from the current execution environment (network/DNS fetch unavailable). Therefore this checkpoint records a source/structure correction, **not a visually verified result**. Do not claim that overlap is visually resolved until the deployed page is checked at:
- 1920×1080
- 1366×768
- 1280×650
- 901–1100 px wide

Check both the main menu and active game screen. Also check shop, heroes, campaign and daily screens for clipping/scroll behavior.

## Continuation phrase
TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 326. DESKTOP LAYOUT RESET: УДАЛЕНЫ СЕМЬ КОНКУРИРУЮЩИХ DESKTOP CSS-ПАТЧЕЙ, ВВЕДЁН ЕДИНЫЙ bb-desktop-layout-unified-v1. ПРОВЕРИТЬ ПОСЛЕ ПУБЛИКАЦИИ ГЛАВНОЕ МЕНЮ, КАМПАНИЮ, МАГАЗИН, ГЕРОЕВ, ЕЖЕДНЕВНОЕ ИСПЫТАНИЕ И АРЕНУ НА 1920×1080, 1366×768, 1280×650 И 901–1100 PX. ОСОБО ПРОВЕРИТЬ, ЧТО ИГРОВОЕ ПОЛЕ 10:23 НЕ СЖАТО, БОКОВЫЕ КАРТОЧКИ НЕ НАЛЕЗАЮТ ДРУГ НА ДРУГА, А КНОПКА КАМПАНИЯ ВИДНА. МОБИЛЬНУЮ ВЁРСТКУ И ИГРОВУЮ ЛОГИКУ НЕ МЕНЯТЬ.
