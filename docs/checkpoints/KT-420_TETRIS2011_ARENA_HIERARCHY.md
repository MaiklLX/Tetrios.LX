# KT-420 — Tetris 2011-inspired mobile arena hierarchy

**Date:** 2026-11-07  
**Base:** `main` at `a9fce851a7c7b319c55642e490a39766736e10b6`  
**Branch:** `design/kt420-tetris2011-arena-first-2026-11-07`

## Reference

Use the user-provided EA Tetris 2011 v3.1.01 APK as the mobile UX reference. The KT-416 audit found a board-first composition with compact Hold/Cycle utility modules and secondary information kept from competing with the playfield. Tutorial assets establish hierarchy and utility relationships, not exact live-game dimensions.

## First implementation slice

- Keep the playfield and its stable 10×23 silhouette as the primary anchor.
- Keep the immediate Next, Hold, and Drop actions directly visible.
- Move level charge, active boost, Chrono Rift, and hero ability into one keyboard-accessible native disclosure drawer labelled “ЕЩЁ”.
- Preserve all existing element IDs, gameplay callbacks, progression data, and hero ability activation.
- No gameplay rules, scoring, saves, assets, or desktop layout changed.

## Validation

- Mobile previews at 375×812 and 412×915; compare against KT-419 baseline.
- Verify Next/Hold/Drop remain visible and functional.
- Open/close “ЕЩЁ”; verify charge, boost, Chrono Rift, and hero ability remain available.
- Verify Campaign, Block Run, Daily, pause/resume, and desktop Golden Baseline.
- Follow-up: compact lower objective/room rail and audit full menu/navigation graph.

No merge, Pages deployment, or APK release in this checkpoint.
