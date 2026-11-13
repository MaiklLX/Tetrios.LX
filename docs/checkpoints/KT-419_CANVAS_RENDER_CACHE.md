# KT-419 — Canvas rendering performance pass

**Date:** 2026-11-07  
**Base:** `main` at `a9fce851a7c7b319c55642e490a39766736e10b6` (KT-418)  
**Branch:** `perf/kt419-canvas-cell-cache-2026-11-07`  
**Scope:** isolated rendering optimization; no gameplay rules, scoring, board geometry, save data, controls, or release configuration changed.

## Reference and design direction

Continue from the KT-416 audit of the user-provided EA Tetris 2011 APK (3.1.01): board-first hierarchy, compact utility modules, stable board silhouette, and clear touch ergonomics. Keep Tetrios' own neon/cosmic identity and original assets. Do not copy EA branding, art, code, music, or proprietary assets.

The current Block Buddies Android baseline previously inspected was `Block-Buddies-KT403.2.apk` (debug build; SHA-256 `afdbd8270c063e09031e35c3a4f0b04dffcef88b4fe4e9e88b161efe260b55e8`). It remains a comparison point, not a release artifact.

## Finding

The arena background and next-piece preview already have caches. However, every board redraw still rebuilds each settled/active block face using rounded paths, multiple gradients, strokes, and shadow operations. During frequent redraws this repeats static work for unchanged block styles and can contribute to slowdown, especially when effects request additional frames.

## Change in this checkpoint

- Added a bounded cache (maximum 96 entries) for rendered block sprites, keyed by color, cell size, and solid/ghost state.
- Reused cached sprites via `drawImage` instead of reconstructing gradients and paths on every render.
- Kept the existing block artwork recipe, board dimensions, ghost treatment, and game state unchanged.
- No APK build/release and no production deployment.

## Required validation

1. Run mobile arena and cross-platform visual previews.
2. Compare screenshots at 375, 390, 412, and 430 px, plus desktop Golden Baseline.
3. Verify Campaign, Block Run, Daily, active piece, ghost, prism/glitch colors, line-clear animation, and pause/resume.
4. Check the cache stays bounded while colors/cell sizes change; no visual seams, clipped glow, or stale color sprites.
5. Only after review proceed to compact mobile HUD/RIFT/TIME/DROP composition, then main-menu/navigation adaptation.

## Guardrails

- Work on this branch and through a reviewable PR; keep `main` untouched until explicit approval.
- Preserve Golden Desktop Baseline and existing game rules.
- Orientation guard remains a separate follow-up; it must not block this work.
- No APK release.
