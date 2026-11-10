# KT-581 — browser home composition rebuilt from Godot KT-549

**Repository:** `MaiklLX/Tetrios.LX`  
**PR:** #85 — Draft only  
**Branch:** `web/kt550-browser-return-2026-11-09`  
**Implementation commits:** `a8f9babadc45c84a51b4a7e4f29b70c5d66c5c18`, `ab8eb9a6baf2475fda113061a91f968352d01687`

## Why this stage exists
KT-580 changed the palette, but the resulting screenshots still showed the old browser layout. That was not sufficient visual parity. KT-581 begins translating the actual Godot visual composition rather than only recoloring existing browser cards.

## Implemented
- Rebuilt the browser home screen into a responsive cockpit-style composition: large cosmic hero panel, pilot-profile panel, prominent mode selection, daily quests and visit-streak panels.
- Added layered navy/blue-glass surfaces, cyan edge lighting, restrained gold reward accents, orbital rings and block-mark styling.
- Improved hierarchy, spacing, card proportions, borders, depth and hover feedback.
- Reused existing DOM nodes and IDs; mode buttons, profile, quests, streak, settings and progression data hooks remain intact.
- Mobile layout collapses cleanly into a single-column flow.

## Explicitly unchanged
- No gameplay, controls, collision, piece colors, board size, modes, campaign progression, reward economy or save schema changes.
- Godot KT-549 remains the visual source of truth and is not modified.
- `main`, public Pages and APK are untouched. No merge, deployment or APK build.

## Validation state
- Mobile Arena #415 on prior KT-580 head passed; this is not validation of the KT-581 home redesign.
- Cross-platform #641 was still running on the prior head when KT-581 began.
- Fresh preview runs on the KT-581 head are required. Do not mark this stage passed until the new desktop Chromium and iOS WebKit captures are inspected, and the mobile preview completes.
- Physical-device testing remains outstanding.
