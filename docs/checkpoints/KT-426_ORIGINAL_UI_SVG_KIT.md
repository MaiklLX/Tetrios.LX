# KT-426 — Original Block Buddies SVG visual kit

Date: 2026-11-07
Status: visual prototype, not wired into gameplay.

## Deliverables
Five independent SVG files in `site/assets/ui/block-buddies-kit/`:
1. Drop control surface (thumb-first visual treatment)
2. Reusable action button surface
3. HUD panel
4. Vertical Roguelike card frame
5. Sample block tile

## Why original assets first
They give the project a coherent starting style without importing mismatched art or adding external runtime dependencies. CC0 packs remain candidates for later comparison and selective import.

## Visual direction
Graphite/deep-space surfaces, turquoise interactive accents, restrained gold reward details, cool slate outlines. Keep all critical labels and game interactions as live accessible controls.

## Verification before integration
- Preview assets at native and scaled sizes.
- Check alpha/transparency and crisp edges.
- Test button backgrounds with focus/pressed/disabled states.
- Check card frame at phone viewport scale.
- Compare block tile against current game palette and color-blind contrast.
- Never flatten controls or cards into screenshots.

## Non-goals
No live CSS integration, gameplay changes, save changes, merge, deployment or APK release.
