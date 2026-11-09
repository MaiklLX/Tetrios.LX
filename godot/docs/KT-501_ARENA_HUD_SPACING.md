# KT-501 — Arena HUD spacing and Block Run goal strip

## Scope
Refine the active gameplay HUD without changing game rules, controls, board dimensions, campaign data, or save behavior.

## Changes
- Rebalanced score and progress cards to equal-width columns with 18px outer gutters and a 10px gap.
- Reduced the stat-card height to 52px and aligned labels, values, and progress tracks to a consistent baseline.
- Rebuilt the three Block Run objective indicators as 32px rounded cards.
- Each objective now has a dedicated label/progress line, a separate progress bar, and a reward value in its own lower-right area.
- Kept objective cards between the stats row and HOLD/NEXT/hero-skill previews, avoiding text outside card bounds.

## Layout targets
- Stats row: y=56, height=52.
- Objective strip: board top minus 108px, height=32px.
- Piece preview row: board top minus 68px, height=60px.
- Intended vertical separation: 8px from stats to goals (at the minimum board top) and 8px from goals to previews.

## Validation
Run the existing Godot import, parse, model, Block Run integration, visual screenshot, and scene smoke tests. Inspect both 720x1280 and 360x800 captures, paying special attention to goal labels, reward labels, score cards, previews, and board frame clearances.

## Safety
Draft PR only. No merge, public deployment, APK build, or persistent economy/save migration.
