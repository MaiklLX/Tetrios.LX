# Checkpoint 352 — desktop arena centering and collision-free fit (2026-11-03)

## User-reported issues after checkpoint 351
- Bottom 3–5 rows of the board were clipped.
- The bottom controls/instructions block overlapped the arena.
- Resizing the browser caused the board and nearby modules to collide, compress or distort.
- The arena looked attached to the right-side information rail instead of centered on the page.

## Implemented
- Added a final desktop-only layout override with a symmetric three-column play area. The arena occupies the center column; equal flexible gutters keep its visual centerline stable.
- Moved the information rail into the right gutter as a compact overlay rail, so it no longer steals width from or pushes the arena.
- Explicitly set the board frame and canvas to fill the available play-area height while preserving the 10:23 aspect ratio and native 300×690 drawing buffer.
- Removed the desktop bottom control/instruction row from layout to eliminate overlap with the arena. Keyboard gameplay remains unchanged.
- Rebalanced the page around the available viewport height and added a compact short-window mode.
- Increased CSS selector specificity so the new board-frame sizing supersedes legacy inline stylesheet rules.
- Bumped desktop CSS cache key to v9.

## Preservation
- CSS changes are scoped to min-width: 901px.
- No game JS, input handling, game state, save data, scoring, game modes, renderer implementation, mobile/tablet CSS or cosmic background changed.

## Static checks
- CSS braces balanced: 394/394.
- v9 cache key present.
- Desktop-only override present.
- Browser visual verification and deployment still need confirmation.

## Resume phrase
TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 352. ИСПРАВЛЕНА КОМПОНОВКА ПК-АРЕНЫ: ПОЛЕ СТРОГО ПО ЦЕНТРУ СТРАНИЦЫ, СИММЕТРИЧНЫЕ БОКОВЫЕ ПРОСТРАНСТВА, ИНФОПАНЕЛЬ В ПРАВОМ РЕЗЕРВЕ НЕ СДВИГАЕТ АРЕНУ. CANVAS И РАМКА ЗАНИМАЮТ ДОСТУПНУЮ ВЫСОТУ С ПРОПОРЦИЕЙ 10:23; НИЖНЯЯ СТРОКА УПРАВЛЕНИЯ/ПОДСКАЗКИ УБРАНА С ПК-ЭКРАНА, ЧТОБЫ НЕ ПЕРЕКРЫВАТЬ ПОЛЕ. CSS CACHE KEY v9. PR #27. ПРОВЕРИТЬ В РАЗНЫХ РАЗМЕРАХ ОКНА И РЕЖИМАХ. МОБИЛЬНУЮ ВЕРСИЮ, ФОН И ЛОГИКУ НЕ ТРОГАТЬ.
