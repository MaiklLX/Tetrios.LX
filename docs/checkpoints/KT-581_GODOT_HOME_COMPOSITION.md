# KT-581 — browser home composition rebuilt from Godot KT-549

**Repository:** `MaiklLX/Tetrios.LX`  
**PR:** #85 — Draft only  
**Branch:** `web/kt550-browser-return-2026-11-09`  
**Implementation commits:** `a8f9babadc45c84a51b4a7e4f29b70c5d66c5c18`, `ab8eb9a6baf2475fda113061a91f968352d01687`, `cf863b255027c74e375d825ece19e2eef2e6ea94`, `dd25057d42689f04d65570401572518a5999d34`, `b765bcdb5921bcc520cab5e6e1f2102fb263fb3a`

## Why this stage exists
KT-580 changed the palette, but the resulting screenshots still showed the old browser layout. That was not sufficient visual parity. KT-581 begins translating the actual Godot visual composition rather than only recoloring existing browser cards.

## Implemented
- Rebuilt the browser home screen to follow Godot ` _draw_home_hub()` hierarchy: compact title/brand, full-width pilot profile, two large featured adventure panels, secondary daily challenge, daily tasks, visit streak and supporting sections.
- Added layered navy/blue-glass surfaces, cyan edge lighting, restrained gold reward accents, rounded soft-panel treatment and distinct blue campaign / violet Block Run panels.
- Improved hierarchy, spacing, card proportions, borders, depth and hover feedback.
- Reused existing DOM nodes and IDs; mode buttons, profile, quests, streak, settings and progression data hooks remain intact.\n- Added a cross-platform browser regression assertion for the home-hub vertical order and full-width profile / campaign / Block Run panels; existing menu screenshots are captured on Chromium and WebKit.
- Mobile layout follows the same single-column hierarchy as Godot; daily quest rows collapse to a readable vertical list.

## Explicitly unchanged
- No gameplay, controls, collision, piece colors, board size, modes, campaign progression, reward economy or save schema changes.
- Godot KT-549 remains the visual source of truth and is not modified.
- `main`, public Pages and APK are untouched. No merge, deployment or APK build.

## Validation state
- Mobile Arena #415 on prior KT-580 head passed; this is not validation of the KT-581 home redesign.
- Cross-platform #641 was still running on the prior head when KT-581 began.
- Fresh preview runs on the KT-581 head are required. Do not mark this stage passed until the new desktop Chromium and iOS WebKit captures are inspected, and the mobile preview completes.
- Physical-device testing remains outstanding.
\n\n## Current implementation head\n`2cf52f36dbc5451f96ca9d43bc055c655808e903` — latest implementation and layout-regression test. Fresh automated previews for this exact head are required; earlier run results from intermediate commits are not evidence for this revision.\n