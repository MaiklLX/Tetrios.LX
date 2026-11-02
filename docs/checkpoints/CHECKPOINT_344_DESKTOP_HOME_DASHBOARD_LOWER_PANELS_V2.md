# TETRIOS LX — Checkpoint 344
## Desktop home dashboard: shop/profile row and stats consolidation

**Base:** `main` at `dd3ccb79dd5d2a37820c0403ad09c187911951bf`  
**Branch:** `desktop/home-dashboard-lower-panels-v2`

### Changes
- Corrected the desktop home-dashboard grid to match the actual runtime DOM.
- `bbApplyHero()` moves the existing `#openShop` button into `#rpgPanel`; the old `.shopbuttons` wrapper is therefore empty and hidden by runtime code. The previous desktop grid still reserved a separate `shop` cell for that empty wrapper.
- Removed that empty desktop grid cell and let the hero/roster action and shop action occupy the intended fourth row.
- Styled the actual moved shop button as a full-width desktop action inside `#rpgPanel`.
- Moved the three bottom statistics into a full-width row, preserving all statistic values and their existing update logic.
- Reset-progress action remains in its own final row.

### Safety
- Only `site/desktop-shell.css` changed in this checkpoint.
- No HTML, JavaScript, gameplay, handlers, saves, localStorage keys, campaign, rewards, or progression changed.
- All affected rules are inside the existing `@media (min-width: 901px)` desktop scope.
- Mobile/tablet styles remain untouched.

### Validation
- Static source inspection confirmed `bbApplyHero()` appends `#openShop` to `#rpgPanel` and hides `.shopbuttons`.
- CSS brace balance and desktop media-scope checks to be recorded with PR validation.
- Browser visual verification has not been performed in this checkpoint.
