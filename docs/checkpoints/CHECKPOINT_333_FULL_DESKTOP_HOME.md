# CHECKPOINT 333 — Full desktop home dashboard parity
Date: 2026-11-02

## Starting point
- Continued from checkpoint #332.
- User requested that the desktop web home page restore every section from the mobile home page, using mobile as the content/order reference.

## Root cause found
- In `site/index.html`, the home-menu markup contained two extra closing `</div>` tags immediately after the currency panel.
- Those tags prematurely closed the outer application wrapper before the remaining home sections. The reset action, daily quests, shop wrapper and stats were therefore no longer children of the main app container.
- The desktop layout also had no explicit placement for the live shop button container `#rpgPanel`; the shop button is moved into this container by the existing `bbApplyHero()` function. The old static `.shopbuttons` wrapper is intentionally hidden to avoid showing a duplicate.

## Changes
- `site/index.html`:
  - Removed exactly two stray closing div tags after the currency panel.
  - Verified the menu's div opening/closing counts balance.
  - Bumped CSS cache key to `20261102-desktop-menu-2`.
- `site/visual-overhaul.css`:
  - Added the full desktop dashboard layout at `min-width:901px`.
  - Preserved all mobile breakpoints and the existing menu markup/handlers.
  - Kept the brand hero and APK download at the top, the three game modes in one full-width row, then placed visit streak, hero bay, live shop, currency, daily quests, stats and reset in dedicated grid areas.
  - The live `#openShop` button remains the same DOM node moved by existing `bbApplyHero()`; no duplicate shop action was introduced.
  - Explicit grid row count now matches all seven dashboard rows.

## Commits
- HTML wrapper + cache key: `0df9783c7a4d021483ad95758502e888b5752606`
- Desktop section layout: `ebeb2c358069d0782692dcbaacca0b27038e1968`
- Grid row-track correction: `3c69bf7bc7513eaf4b662e51e6d163f9a56a22bc`

## Source verification
- Main menu div tags balance.
- Confirmed the original `campaign`, `rogue`, and `daily` data-mode hooks remain.
- Confirmed required sections remain present: visit streak, hero bay, RPG/shop panel, currency panel, daily quests, reset, best score, runs and relic stats.
- Confirmed the shop button is still moved into `#rpgPanel` by existing JavaScript.
- CSS brace balance passed.
- No game logic, data, save format, gameplay controls, or mobile CSS was changed.

## Remaining checks
- GitHub combined status returned no status entries at check time; deployment success is not confirmed here.
- After Web Deploy completes, hard-refresh the desktop site and visually verify all seven areas, especially the live shop button and daily quests.
- Perform a mobile regression check to confirm the source mobile layout remains unchanged.
- User visual confirmation is required before calling this complete.

## Continuation phrase
`TETRIOS LX — контрольная точка 333: восстановлена полная главная страница ПК по составу мобильной версии. Удалены две лишние закрывающие div после панели валют, из-за которых преждевременно закрывался app-контейнер. На ПК отдельные зоны: бренд и APK, три режима, серия посещений, отсек героев, магазин, ресурсы, ежедневные задания, статистика и сброс. Коммиты 0df9783, ebeb2c3, 3c69bf7. Проверить Web Deploy, визуально проверить ПК после Ctrl+F5 и не затронуть мобильную версию.`
