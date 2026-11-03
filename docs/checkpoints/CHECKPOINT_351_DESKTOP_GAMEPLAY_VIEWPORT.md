# Checkpoint 351 — desktop gameplay viewport composition (2026-11-03)

## Goal
Rebuild the PC browser gameplay screen so the complete board, counters, pause control, mission goal and side modules fit inside one visible browser viewport without page scrolling.

## Implemented
- Reworked the desktop-only gameplay screen into a viewport-bounded composition.
- The page shell and main content contract to the available browser height while the game screen uses a minmax(0, 1fr) play area.
- HUD counters stay in a compact horizontal strip; the 10×23 board fills the available arena height while preserving its native aspect ratio.
- The right rail is a compact two-column module grid for charge, next piece, boost, timer, music/drop and hero skill; chrono remains full-width when active.
- Removed the redundant desktop touch-control row; retained the gameplay hint and keyboard-first interaction.
- Added a short-window desktop density mode and a narrower desktop rail for 901–1120px layouts.
- Bumped the desktop stylesheet cache key to v8.

## Preservation
- Changes are limited to desktop CSS and the stylesheet cache key.
- No gameplay JavaScript, scoring, board state, save data, keyboard handlers, 2D/3D renderer logic, game mechanics, mobile/tablet styles or cosmic background were changed.
- The 2D canvas remains the authoritative game/input surface; the 3D overlay continues to align to its rendered bounds.
- The CSS remains scoped to min-width: 901px.

## Static verification
- CSS brace balance: 339/339.
- Desktop v8 cache key present.
- Browser visual verification and GitHub Pages deployment are not yet confirmed.

## Resume phrase
TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 351. ПЕРЕСТРОЕНА ПК-ВЕРСИЯ ИГРОВОГО ЭКРАНА ПОД ОДНО ОКНО БРАУЗЕРА: HUD СВЕРХУ, ПОЛЕ 10×23 ЗАНИМАЕТ ДОСТУПНУЮ ВЫСОТУ БЕЗ ИСКАЖЕНИЯ ПРОПОРЦИЙ, СПРАВА КОМПАКТНАЯ СЕТКА ИГРОВЫХ МОДУЛЕЙ, УБРАНА ЛИШНЯЯ СТРОКА СЕНСОРНЫХ КНОПОК. CSS CACHE KEY v8. ПРОВЕРИТЬ НА ШИРОКОМ И НИЗКОМ ОКНЕ, ВО ВСЕХ РЕЖИМАХ ИГРЫ. МОБИЛЬНУЮ ВЕРСИЮ, КОСМИЧЕСКИЙ ФОН И ИГРОВУЮ ЛОГИКУ НЕ ТРОГАТЬ.
