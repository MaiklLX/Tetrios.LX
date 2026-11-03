# Checkpoint 353 — restore native desktop layout and arena cell proportions (2026-11-03)

## User-reported regression after checkpoint 352
- Arena was pushed against the right edge.
- HUD and surrounding elements appeared detached/floating over the page.
- Board cells were horizontally distorted.

## Root cause
The checkpoint 351/352 CSS layers overrode the established two-column `.playlayout` contract with a three-track grid, then positioned `.sidecol` absolutely. The board canvas was also forced to `width:100%; height:100%` inside a padded aspect-ratio frame, allowing its rendered rectangle to diverge from the native 10:23 ratio. This contradicted the prior CSS conflict audit's instruction not to globally override `.playlayout`.

## Implemented
- Removed the entire accumulated checkpoint 350/351/352 override tail from `site/desktop-shell.css`.
- Restored the established desktop two-column playlayout and normal-flow side rail from the pre-350 stylesheet rules.
- Added a concise checkpoint 353 desktop-only rule set that targets the board frame and board canvas only; it does not rewrite `.playlayout`, reposition the side rail, or change app/body layout.
- The 2D canvas now receives a single CSS height with `width:auto` and the native `10:23` aspect ratio; it is never stretched independently in both dimensions.
- The 3D overlay continues to measure the real 2D canvas bounds through the existing ResizeObserver; no 3D/game JS was changed.
- Removed the duplicate desktop touch-control strip while keeping the keyboard hint in normal document flow.
- Updated desktop CSS cache key to v10.

## Preservation
- All new rules are scoped to desktop `min-width:901px`.
- Mobile/tablet rules, game logic, input handlers, board drawing, save data, scoring, modes, 3D renderer code and cosmic background are unchanged.

## Static validation
- CSS braces balanced: 274/274.
- Checkpoint 351/352 override layers absent.
- Absolute side-rail positioning absent from the new desktop rules.
- Independent 100% canvas width/height stretching absent from the new desktop rules.
- Cache key v10 present.
- Browser visual verification and Pages deployment still require user confirmation.

## Resume phrase
TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 353. ОТКАЧЕНЫ КОНФЛИКТУЮЩИЕ СЛОИ 350–352, ВОССТАНОВЛЕНА ШТАТНАЯ ДВУХКОЛОНОЧНАЯ DESKTOP-КОМПОНОВКА: АРЕНА СЛЕВА, ИНФОПАНЕЛЬ СПРАВА В ОБЫЧНОМ ПОТОКЕ. БОЛЬШЕ НЕТ ABSOLUTE SIDE RAIL И ТРЁХКОЛОНОЧНОГО PLAYLAYOUT. CANVAS ЗАДАЁТСЯ ПО ВЫСОТЕ, WIDTH AUTO, ASPECT-RATIO 10:23 — ГОРИЗОНТАЛЬНОЕ СЖАТИЕ НЕ ДОЛЖНО ВОЗНИКАТЬ. ПРАВИЛА ТОЛЬКО ДЛЯ ПК, CSS CACHE KEY v10. ПРОВЕРИТЬ НА ПК И В РАЗНЫХ РАЗМЕРАХ ОКНА. МОБИЛЬНУЮ ВЕРСИЮ, КОСМИЧЕСКИЙ ФОН И ИГРОВУЮ ЛОГИКУ НЕ ТРОГАТЬ.
