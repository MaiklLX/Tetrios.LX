# Checkpoint 355 — explicit desktop arena frame ratio (2026-11-03)

## User feedback
After checkpoint 354 the right half of the arena was clipped, the whole composition was pulled to the right, and the page had no scroll.

## Root cause found in CSS sizing contract
The 354 layout assigned `.boardframe` `display:block; width:auto` inside a flex container and also set a height/aspect ratio. A block/flex child with auto cross-size can stretch to its available container width; aspect-ratio was not being used as a reliable explicit frame width. The board canvas and 3D overlay then inherited a mismatched frame/viewport geometry. Previous changes also tried to derive width implicitly rather than defining one exact frame rectangle.

## Implemented
- Replaced the checkpoint 354 block with a single checkpoint 355 desktop layout.
- The board frame now owns an explicit viewport-derived width, capped by available height and 430px maximum, and a fixed 10:23 aspect ratio.
- The 2D canvas fills the exact frame rectangle (100% × 100%); because the frame itself has a fixed 10:23 ratio, cells remain square and the 3D renderer's measured canvas rectangle matches it.
- The arena sits in the auto-sized center track of a symmetric three-column grid. Flexible left and right gutters remain equal; side modules stay in the right track in normal flow.
- Kept desktop page height locked to one viewport and retained compact HUD/side modules.
- Bumped CSS cache key to v12.

## Preservation
Desktop-only min-width 901px. No game JS, canvas drawing buffer (300×690), 3D camera/renderer, controls, scoring, saves, modes, mobile/tablet styles, or cosmic background changed.

## Static checks
- CSS braces balanced: 260/260.
- Old checkpoint 354 block removed.
- Explicit frame width and 10:23 aspect ratio present.
- Canvas fills the fixed-ratio frame.
- Symmetric center grid and normal-flow side rail present.
- Cache key v12 present.
- Browser visual verification and deployment still require confirmation.

## Resume phrase
TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 355. ИСПРАВЛЕНА ПЕРВОПРИЧИНА ОБРЕЗАНИЯ АРЕНЫ: BOARD FRAME БОЛЬШЕ НЕ ПОЛАГАЕТСЯ НА AUTO-WIDTH FLEX STRETCH. РАМКА ПОЛУЧАЕТ ЯВНУЮ ШИРИНУ И VIEWPORT-ОГРАНИЧЕНИЕ, СТРОГОЕ ASPECT-RATIO 10:23; CANVAS ЗАПОЛНЯЕТ ЭТУ РАМКУ 100%×100%. АРЕНА В ЦЕНТРАЛЬНОЙ КОЛОНКЕ С РАВНЫМИ БОКОВЫМИ GUTTERS, ИНФОПАНЕЛЬ СПРАВА В ОБЫЧНОМ ПОТОКЕ. CSS CACHE KEY v12. PR #31. ПРОВЕРИТЬ ПОЛНОТУ ПОЛЯ, КВАДРАТНЫЕ КЛЕТКИ, ЦЕНТРИРОВАНИЕ И ОТСУТСТВИЕ ПРОКРУТКИ. МОБИЛЬНУЮ ВЕРСИЮ, КОСМИЧЕСКИЙ ФОН И ЛОГИКУ НЕ ТРОГАТЬ.
