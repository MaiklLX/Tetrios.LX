# TETRIOS LX — Checkpoint 346
## Fresh Pages deployment trigger and desktop stylesheet cache key v3

**Base:** `main` at `8ae806cd3fc3ec4202d7cd86a39f0fe71fd0b748`  
**Branch:** `desktop/stylesheet-cache-redeploy-v3`

### Context
- Checkpoint #345 passed source audit and merged.
- The first Pages deployment attempt uploaded the site artifact but GitHub Pages returned HTTP 500 while creating the deployment.
- Retrying the same workflow run created a second artifact with the same name, so the deploy action correctly refused to choose between duplicate artifacts.

### Change
- Advance the desktop stylesheet cache key from `20261102-desktop-shell-v2` to `20261102-desktop-shell-v3`.
- This creates a clean new push-triggered Pages workflow run with exactly one Pages artifact and ensures the browser requests the current CSS.

### Safety
- Cache-key-only HTML change plus this checkpoint.
- No page structure, JavaScript, gameplay, assets, mobile styles, saves, or progression changed.

### Validation
- The v2 key was confirmed in main before replacement.
- A fresh workflow run will be used; the failed workflow run will not be retried again.
