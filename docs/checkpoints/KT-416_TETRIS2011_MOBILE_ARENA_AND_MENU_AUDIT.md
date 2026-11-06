# KT-416 — Tetris 2011 mobile arena and navigation reference audit

**Date:** 2026-11-06  
**Base:** `main` at `7ceee9aa326b65a1d57829b1d4b4e8bff5e32df8` (KT-415 merged and Pages deploy successful)  
**Branch:** `design/kt416-mobile-arena-ux-audit-2026-11-06`  
**Scope:** research and design direction only. No gameplay code, CSS, assets, save data, or production deployment changed.

## User priority

The first priority is to evaluate and adapt the *mobile arena composition* of EA Tetris 2011 (version 3.1.01): board size and proportions, available play area, side modules, hierarchy, and touch ergonomics. The second priority is to audit the main menu, mode selection, pause/results/settings windows, and submenu navigation. Campaign/Galaxy and new power-ups come after the arena and navigation foundation.

## Source material inspected

- User-provided APK: `zzsunset-tetri_-2011_3.1.01.apk` (64 MB).
- APK archive listing and assets; eight embedded tutorial videos (528×544, 30 fps) and eight tutorial illustration assets.
- Tutorial topics include Hold, Cycle, Score, Marathon, Objective, Tetrimino, Galaxy, and Explorers.
- The tutorial assets show a tall, narrow, visually isolated playfield; Hold and Cycle are compact utility modules beside the board; instructional focus stays on the board and the current action.
- Important limitation: the APK's embedded tutorial videos are instructional animations, not full live gameplay captures. They establish the visual grammar and relationships of the board/modules, but do not prove exact live HUD dimensions or the full menu flow. Do not present tutorial-derived dimensions as confirmed runtime measurements.

## Current Block Buddies / Tetrios baseline inspected

Latest mobile visual preview artifact: run `42224024454`, artifact `13504548549`. Cross-platform preview: run `42224024364`, artifact `13505791239`.

At 375×812 mobile viewport, the current geometry report records:
- Board frame: 215.1×494.8 px; inner board: 211.1×490.8 px; grid ratio 10:23.
- Side rail: 113.9 px wide with charge, next piece, boost, hold, hero skill, and drop modules.
- A separate bottom panel occupies about 144 px and contains Block Run room/HP/monster status and three goals.
- The board itself is prominent and readable, but the screen carries several simultaneous information groups: top title/HUD, tall board, side rail, and a dense bottom mission panel.
- In the 393×873 cross-platform capture, the same hierarchy remains: the board dominates the center-left, while the right rail and bottom room/goal panel compete for attention.

Existing main menu baseline:
- Strong, recognizable Tetrios branding and large mode cards.
- The home screen is a long vertical dashboard: hero/brand panel, mode cards, daily tasks and additional progression panels. This is visually rich but requires substantial vertical scrolling on a phone.
- Existing screens are not to be discarded; the redesign should improve information hierarchy and navigation while preserving the characters, neon/space identity, modes, progression and established user expectations.

## Reference principles to adapt (not copy)

1. **Board-first composition.** The playfield must be the primary visual anchor. HUD and secondary systems should frame it rather than compete with it.
2. **A stable, legible board silhouette.** Preserve the native 10-column grid and avoid perspective/rotation that harms cell recognition. Test the board against short and tall phone viewports, safe areas and browser chrome.
3. **Compact utility zones.** Keep only the most frequently needed contextual modules visible during play. Secondary systems can open in compact drawers, overlays or pause panels rather than permanently consuming board width/height.
4. **Consistent spatial grammar.** Hold, next piece, objective/progress, and pause should retain predictable positions between modes. A mode may add one unique module without rearranging the entire arena.
5. **Touch-first controls.** Large, separated touch targets; no overlap with the board's gesture surface; drop must be visually distinct; movement/rotation controls should remain reachable one-handed. Keep keyboard and desktop behavior intact.
6. **Readable hierarchy.** Score/lines/level are glanceable; mission/monster information is secondary; detailed explanations live in dedicated panels.
7. **Menu navigation by task.** Main menu should answer “what can I play now?” first. Campaign, Block Run and Daily remain clear primary destinations; progression, heroes, collection, store and settings are grouped into understandable secondary destinations.
8. **Purposeful overlays.** Pause, settings, help, restart confirmation and results should use a consistent modal/panel system, clear primary action, and safe back/close behavior. Avoid stacked modal dead ends.
9. **Responsive behavior by orientation.** Portrait is the primary phone composition; landscape gets a deliberate arena layout, not merely a squeezed portrait layout. Desktop remains separately optimized.
10. **Preserve identity.** Recreate the ergonomic logic, not EA's art, assets, text, branding, or proprietary implementation. Tetrios keeps its own characters, neon cosmic setting, and 3D block treatment.

## Proposed order of work

### Phase A — Arena research and layout specification (first)
- Inspect all current mobile arena modes: Campaign, Block Run and Daily, including pause, game-over, level-up, skill/boost states.
- Compare current 375×812, 393×873, 412×915, 430×932 and short-device viewports.
- Establish a compact mobile HUD, board sizing rules, side-module priority, bottom-panel behavior, touch target map, safe-area rules and landscape fallback.
- Define explicit acceptance criteria for no clipping, no overlap, readable cells, reachable controls and minimal scrolling during active play.

### Phase B — Mobile arena prototype
- Implement only behind a dedicated branch/PR.
- Preserve 2D canvas as authoritative game/input surface and keep the optional 3D overlay aligned to its bounds.
- Do not change scoring, physics, gesture timing, save data, mode rules or hero abilities as part of a layout-only pass.
- Run visual previews and interaction tests across all modes and viewports; compare screenshots before/after.

### Phase C — Menus and submenus
- Map the current screen/navigation graph before redesigning.
- Consolidate secondary destinations into a coherent navigation layer; shorten the phone home-screen scroll.
- Standardize mode selection, pause, settings, help, results, restart and exit flows.
- Test back navigation, state preservation, modal stacking and accessibility/touch target sizes.

### Phase D — New content
- Only after arena and navigation are stable, proceed to the Galaxy-inspired campaign map, staged challenges and character-linked abilities/power-ups.

## Guardrails

- Do not change `main` directly for the redesign; use branch + PR and checkpoint.
- Do not remove or replace the existing golden desktop baseline.
- No production deployment until the user reviews the visual direction and the PR's CI passes.
- Keep current game modes, progression, heroes, save data, controls and desktop experience working.
- No EA assets, code, names, logos, music, or extracted proprietary content will be reused. Implement original Tetrios visuals and behavior inspired by general usability patterns.

## Resume phrase

**TETRIOS LX — KT-416 ARENA-FIRST DESIGN AUDIT.** Base `main` at `7ceee9aa`; branch `design/kt416-mobile-arena-ux-audit-2026-11-06`. First redesign the mobile playfield composition and touch ergonomics using Tetris 2011 as a usability reference, then menu/pause/settings/results navigation. Current 10×23 board and 113.9px side rail at 375×812 were measured from the current Playwright artifact. Tetris APK tutorial assets show board-first hierarchy and compact side utilities, but do not include a full live gameplay capture; exact EA runtime layout remains unverified. No source code changed and no deployment performed.