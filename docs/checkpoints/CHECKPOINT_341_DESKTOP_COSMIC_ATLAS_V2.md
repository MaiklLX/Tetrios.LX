# CHECKPOINT 341 — Desktop Cosmic Atlas v2

Date: 2026-11-02
Base: `main` at `a8e1989175c979e0e27e74c8bde8d3712a040d02`
Branch: `desktop/cosmic-atlas-v2`

## Goal
Advance the PC web experience from the arena to the campaign's cosmic atlas. The existing atlas already has galaxy carousel cards, 3D model overlays, a horizontal planet route, progress states, and locked/cleared states. This pass improves how that existing experience uses desktop width.

## Changes
- Increased desktop galaxy card width responsively to 310–360px.
- Increased card height and internal spacing for clearer planet/universe artwork, title, biome summary, progress and status.
- Reworked the atlas intro into a desktop heading/description + status legend row.
- Expanded the horizontal galaxy viewport to the full campaign content width.
- Improved desktop atlas controls and hover feedback.
- Expanded planet map viewport to the full desktop content width and refined its heading/back control.

## Preserved
- All changes are in `site/desktop-shell.css` under `@media (min-width: 901px)`.
- No HTML, JavaScript, canvas geometry, model loading, campaign progression, saved data, or interaction handlers changed.
- Existing galaxy/planet carousel behavior and scroll snapping remain.
- Planet-node and treasure-trail geometry remain untouched to avoid breaking SVG path alignment.
- Mobile CSS is untouched.

## Static verification
- CSS braces balanced.
- New rules are desktop-only.
- No mobile media queries added.
- Galaxy cards remain horizontally scrollable.
- Planet node/trail geometry is unchanged.
- Browser visual verification has not been performed.

## Next
After deployment, continue with the daily challenge/calendar surface, then polish the remaining desktop shop and hero dossier views. Verify at 1920×1080, 1366×768, and 1280×650; preserve mobile and game logic.
