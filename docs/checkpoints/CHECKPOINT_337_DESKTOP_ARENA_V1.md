# CHECKPOINT 337 — Desktop game arena v1

Date: 2026-11-02

## Branch and base
- Working branch: `rebuild/desktop-web-v1`
- Base: `main` at `7eb934c3331ef6920a57e7e22141b4b72c980cef`
- This work remains isolated from `main`; it has not been deployed or merged.

## Implemented
- Added a desktop-only game arena layout in `site/desktop-shell.css`.
- Game HUD is arranged as four equal metric panels.
- The board is centered in a dedicated arena surface and given a viewport-aware desktop height.
- The side HUD is reorganized into a two-column grid for charge, next piece, boost, timer, music/drop, chrono state, and hero skill.
- Pause control receives a compact cyan desktop treatment.
- Movement controls are centered beneath the playfield.
- Added compact desktop adjustments for shorter screens and narrower desktop widths.

## Preserved
- No gameplay JavaScript, event handlers, canvas drawing code, storage, progression, or assets were changed.
- Existing board canvas, pause button, and three mode entry hooks remain in `site/index.html`.
- The desktop stylesheet remains linked exactly once.
- All new arena rules are scoped under `@media (min-width: 901px)`; mobile styles are not edited.

## Static verification
- CSS braces: 113 opening / 113 closing.
- Arena selectors present for game shell, playlayout, board, controls, and pause.
- HTML still contains the board canvas, pause button, and campaign/rogue/daily mode hooks.
- Browser visual testing has not yet been performed. Layout should be checked in a real desktop browser at wide and short viewport sizes before merging.

## Next
1. Inspect the arena visually in the public test preview/branch deployment if available.
2. Tune board scale and side-panel density from a screenshot.
3. Continue with the remaining desktop pages only after the arena is accepted.
4. Do not merge to `main` until the desktop review passes.
