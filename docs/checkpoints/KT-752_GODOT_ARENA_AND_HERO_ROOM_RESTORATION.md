# KT-752 — Godot-era arena restoration and hero-room render fix

**Date:** 2026-11-20  
**Branch:** `restore/kt752-godot-arena-heroes-2026-11-20`  
**Base main:** `62e9234f4aa7c1edb9393a94e7191fcc18f2e36b`  
**Status:** implementation branch; visual verification pending.

## Why

The fixed home dock opens the Heroes screen through the shared `show('heroes')` navigation function. The roster was only rendered by a click listener attached to the old home-menu button, so dock navigation could reveal an empty screen. Rendering now belongs to screen activation, which also covers back-stack restoration and any future entry point.

## Godot arena reference

Restore the Godot-era composition as a web presentation/layout, not an engine rewrite:

- Keep the current web 2D canvas as the authoritative board and preserve gameplay/input/save systems.
- Preserve the canonical 10×23 board ratio.
- Re-establish the Godot visual hierarchy: compact score/progress HUD, clear glowing board frame, readable utility rail, goals separated from the board, large reachable controls, deep blue/cyan cosmic backdrop.
- On desktop, use a balanced three-zone composition when mission/monster information exists: left goals/status, centered arena, right utility modules.
- On portrait mobile, keep the board and utility rail side by side; move mission goals below the board rather than letting them steal board width. Keep the board fully visible and the hard-drop/hold actions reachable.
- Do not change gameplay rules, hero abilities, scoring, rewards, progression or stored data in this layout checkpoint.

## Code changes in this checkpoint

- The shared screen navigation now renders the Heroes roster whenever `heroes` becomes active.
- Removed the old home-button-only render hook to avoid relying on one entry path.
- Added a Godot-inspired arena presentation layer scoped to `#game.bb-godot-arena`.
- Extended cross-platform preview assertions to require all five playable hero cards when the dock opens the Heroes screen.

## Verification gate

Fresh Cross-platform and Mobile Arena previews must run on this branch. Inspect desktop Chromium and mobile portrait screenshots, including the actual 10×23 frame, side-rail alignment, visible HOLD/DROP controls, and goals placement. A green workflow alone is not visual acceptance.

No merge, main update, Pages deployment or APK build/release is performed from this branch.

## KT-752.3 — portrait layout correction

The first visual run exposed that the runtime layout function was explicitly pinning the objectives rail above the board and hiding both HOLD and hard-drop controls with inline `!important` styles. The follow-up changes the portrait grid to two rows: board + utility rail in row one, objectives across the full width in row two. The utility rail now retains visible HOLD and DROP actions. Desktop three-zone placement remains unchanged. Fresh mobile and cross-platform visual runs are required before acceptance.


## KT-754 — compact mobile HOLD and hero utility cards

The KT-752 mobile screenshots exposed clipping inside the right utility rail: the HOLD card's preview/action/timer exceeded its fixed portrait height, and the Buddy skill art was clipped by its 42px slot.

- Compact the HOLD card to a 56px portrait slot with an 18px preview and a 22px action button.
- Hide the duplicate elapsed-run timer inside HOLD on portrait phones; the mode HUD remains the timer/status surface.
- Resize Buddy skill art to 32px and give its slot 50px so the complete icon remains visible.
- Keep the 10×23 board, objectives ribbon, gameplay actions, and desktop layout unchanged.

**Validation gate:** rerun Mobile Arena Visual Preview at 375×812 and 412×915, inspect screenshots for zero overlap/clipping and working HOLD/DROP taps, then rerun Cross-platform Visual Preview. This follow-up is not accepted until both fresh runs pass and screenshots are inspected.
