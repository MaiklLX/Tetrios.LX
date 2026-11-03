# Checkpoint 354 — centered desktop arena and single-viewport composition (2026-11-03)

## User feedback after checkpoint 353
- Vertical page scrolling returned.
- Arena remained distorted.
- Placement improved, but too much unused space remained to the left of the arena.
- Request: center the arena on the browser viewport, make it larger and more substantial, fit the gameplay screen on one page, and audit legacy styles.

## Audit findings
- `desktop-shell.css` contained an old desktop arena v1 block (7.8 KB) with a separate grid and fixed minimum side-card heights.
- Checkpoint 353 then added another board-only sizing layer at the end.
- The global desktop shell kept `.app` at `min-height:100dvh` with generous top/bottom padding and header margins, which could make the visible game page exceed the viewport.
- The prior two-column layout centered the board only within the left column, not at the viewport center.
- `visual-overhaul.css` contains presentation-only 3D frame effects; it does not establish the desktop gameplay grid. These effects were retained.

## Implemented
- Removed the obsolete desktop arena v1 layout block and the checkpoint 353 override layer. There is now one authoritative desktop gameplay layout definition.
- Locked the active desktop gameplay shell to exactly one viewport height and disabled page-level scrolling only while `#game` is visible.
- Compressed the top bar and gameplay header/HUD to reserve the available height for the arena.
- Rebuilt the play area as a symmetric three-column grid: flexible left gutter, intrinsic-width centered arena, flexible right gutter. The board centerline now matches the browser viewport center.
- Kept the information rail in the right grid track in normal document flow; no absolute positioning or overlay over the board.
- Enlarged the board to use the full available play-area height. Only the canvas height is controlled; width remains automatic and follows the intrinsic 300×690 (10:23) ratio.
- Kept the existing 3D overlay and cosmetic styling; no renderer or gameplay JavaScript changes.
- Hid the redundant desktop bottom touch-control row and swipe hint.
- Reduced side-module heights and spacing so the right rail can fit alongside the larger arena.
- Bumped desktop CSS cache key to v11.

## Preservation
- Desktop-only rules at min-width 901px.
- Mobile/tablet layouts, gameplay logic, scoring, save data, game modes, keyboard/touch handlers, 2D drawing buffer, 3D renderer and cosmic background remain unchanged.
- The `visual-overhaul.css` presentation effects were retained.

## Static verification
- CSS braces balanced: 262/262.
- Legacy desktop arena v1 block removed.
- Checkpoint 353 duplicate override removed.
- One symmetric center grid confirmed.
- Side rail remains in normal flow.
- Canvas width remains automatic; height alone is controlled.
- Cache key v11 present.
- Browser visual verification and GitHub Pages deployment still require confirmation.

## Resume phrase
TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 354. ПРОВЕДЕНА РЕВИЗИЯ СТАРЫХ СТИЛЕЙ: УДАЛЕН УСТАРЕВШИЙ DESKTOP ARENA V1 И ДУБЛИРУЮЩИЙ СЛОЙ 353. СОЗДАНА ЕДИНАЯ КОМПОНОВКА ПК-ИГРОВОГО ЭКРАНА НА ОДНУ ВЫСОТУ VIEWPORT БЕЗ ПРОКРУТКИ. АРЕНА В ЦЕНТРАЛЬНОЙ КОЛОНКЕ СИММЕТРИЧНОЙ 3-КОЛОНОЧНОЙ СЕТКИ; ПРАВАЯ ПАНЕЛЬ В ОБЫЧНОМ ПОТОКЕ. CANVAS МАСШТАБИРУЕТСЯ ПО ВЫСОТЕ, WIDTH AUTO, СОХРАНЯЕТСЯ НАТИВНАЯ ПРОПОРЦИЯ 10:23. CSS CACHE KEY v11. PR #30. ПРОВЕРИТЬ НА МОНИТОРАХ РАЗНОЙ ШИРИНЫ/ВЫСОТЫ, ВСЕ РЕЖИМЫ УРОВНЕЙ. МОБИЛЬНУЮ ВЕРСИЮ, КОСМИЧЕСКИЙ ФОН И ЛОГИКУ НЕ ТРОГАТЬ.
