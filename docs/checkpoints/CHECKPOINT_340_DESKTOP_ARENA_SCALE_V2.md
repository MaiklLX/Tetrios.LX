# CHECKPOINT 340 — Desktop Arena Scale & Composition v2

Date: 2026-11-02
Base: `main` at `772b262d43f3f7c47c1c6be795fba9052702061b`
Branch: `desktop/arena-layout-v2`

## Goal
Continue the planned PC web experience after isolating legacy desktop CSS. Improve the desktop arena's use of widescreen space while keeping the game screen centered and readable.

## Changes
- Reduced the desktop game screen maximum width from 1480px to 1220px so the arena does not spread excessively across ultrawide displays.
- Increased the right information column from 270–330px to 280–340px.
- Increased the playfield height target from 67dvh / 720px to 74dvh / 780px, with a revised viewport-height safety cap.
- Adjusted short-height desktop sizing to preserve more usable board height.
- Slightly widened the side panel at 901–1120px desktop widths.

## Preserved
- All changes remain inside desktop-only media rules (`min-width: 901px`).
- No HTML markup, JavaScript, game mechanics, canvas dimensions, input handlers, save data, or progression changed.
- Campaign, Block-run, and Daily mode buttons remain untouched.
- Mobile CSS and layouts remain untouched.

## Static verification
- Branch is one commit ahead of main, no divergence.
- Only `site/desktop-shell.css` changed (6 additions, 6 deletions).
- CSS braces balanced (156 opening / 156 closing).
- Game screen remains guarded by `:not([hidden])`.
- No browser visual verification performed.

## Next
Continue the desktop roadmap: refine the main menu's information hierarchy and the campaign atlas / daily calendar surfaces, then review settings and dialogs. Keep changes isolated to desktop presentation and validate Pages deployment after merge.
