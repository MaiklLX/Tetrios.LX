# TETRIOS LX — Checkpoint 345
## Desktop stylesheet cache-bust v2

**Base:** `main` at `ee694b46e692d518e4c8b4a01270195a0e7f5e23`  
**Branch:** `desktop/stylesheet-cache-bust-v2`

### Change
- Updated the desktop stylesheet query version in `site/index.html` from `20261102-desktop-shell-v1` to `20261102-desktop-shell-v2`.
- This forces browsers and CDN caches to request the current `desktop-shell.css` instead of reusing a previously cached response.

### Safety
- Only the stylesheet cache key and this checkpoint document are changed.
- No page markup, JavaScript, game logic, assets, mobile styles, saves, or progression changed.

### Validation
- Confirmed the previous cache key existed exactly once before update.
- Confirmed the new key is present in the updated HTML.
