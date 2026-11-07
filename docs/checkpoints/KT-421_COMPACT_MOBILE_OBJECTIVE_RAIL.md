# KT-421 — Compact mobile room and objective rail

Date: 2026-11-07  
Branch: `design/kt421-compact-objective-rail-2026-11-07`  
Base: KT-420 draft branch  
Status: implementation prepared; visual verification pending

## Goal
Reduce the vertical weight of the lower room/mission panel on phone portrait screens, following the EA Tetris 2011 principle that the playfield remains the primary visual anchor.

## Changes
- Tightened the Block Run encounter header spacing and typography.
- Kept room/floor, enemy HP, HP bar, attack label, attack countdown, attack description, and hero-skill level visible.
- Reduced spacing around the three Block Run objective rows while retaining each label, live progress, and coin reward.
- Applied a compact two-column presentation to campaign objectives while preserving the node title, completion count, each objective, and progress bar.
- Scoped changes to phone/tablet portrait widths; desktop layout is untouched.
- No game logic, objective values, reward rules, combat timing, or board dimensions changed.

## Verification required
- Mobile visual preview at 375x812 and 412x915.
- Cross-platform preview including desktop Chromium, iOS WebKit, Android Chromium, and landscape orientation guard checks.
- Inspect screenshots for clipping, unreadable labels, overlap, and loss of objective/encounter telemetry.
- Do not merge to `main`, deploy, or produce an APK without explicit user approval.
