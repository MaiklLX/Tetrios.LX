# KT-423 — Visible arena controls and thumb-first Drop

Date: 2026-11-07  
Branch: `design/kt423-visible-controls-drop-access-2026-11-07`  
Base: KT-422 draft branch  
Status: first implementation prepared; visual and interaction verification pending

## User feedback
- Drop is not in a comfortable position for fast thumb access.
- Active-play elements should not be hidden in the “ЕЩЁ” drawer.

## Changes
- Removed the active-play “ЕЩЁ” drawer.
- Restored charge, boost, chrono, and hero skill to the visible side rail.
- Kept Next and Hold visible.
- Made Drop the last/bottom-most side-rail action with a larger 50–52px touch target and stronger visual separation.
- Reorders existing DOM elements; does not recreate controls or change game logic, timers, rewards, or save data.

## Verification required
- Mobile visual preview at 375x812 and 412x915.
- Confirm all active-play controls remain visible without clipping or overlap.
- Confirm Drop is the lowest and easiest-to-reach target on the right rail.
- Confirm Drop, Hold, Next, charge, boost, chrono, and hero skill retain their existing handlers.
- Cross-platform desktop/iOS preview and landscape guard checks.
- Do not merge, deploy, or produce an APK without explicit user approval.
