# TETRIOS LX — Checkpoint #397
Date: 2026-11-03

## Branch and safety
- Branch: `feature/gameplay-evolution-389-2026-11-03`
- PR #50 remains open and draft; no merge or deployment.
- Main remains unchanged. No APK build was started.
- Desktop Golden Baseline #372 and the mobile 10:23 arena were not intentionally altered.

## Strict mode separation — all 35 upgrade cards
- All 35 upgrade cards are now classified as Block Run-only.
- `bbGetModeUpgradePool()` returns the card pool only for `mode === 'rogue'`; campaign and daily modes receive an empty pool.
- Level-up card selection is opened only in Block Run. Campaign and daily level-ups continue automatically without card-choice overlays.
- Rogue card ranks and rank scaling return inactive/zero outside Block Run.
- The card library now labels every card “ТОЛЬКО BLOCK RUN”; the misleading “ОБЩИЕ” filter was removed.
- Campaign Scout no longer injects the Shield card. It now grants a separate campaign perk: a second hold use per node.
- Plush's non-rogue active skill now performs a direct board rescue instead of adding the Shield card.
- Inventory items that previously injected card-like boosts are consumed only in Block Run.

## Campaign mission expansion
Campaign node objectives now draw from a larger deterministic pool:
1. Clear a target number of lines.
2. Reach a score target.
3. Reach a level.
4. Survive for a target duration.
5. Clear multiple lines in one placement.
6. Place a target number of pieces.
7. Rotate pieces a target number of times.
8. Use Hold.
9. Perform double clears.
10. On boss nodes, perform a triple clear.
11. On boss nodes, clear four lines in one placement.
12. Place eight pieces without using Hard Drop.
13. Place eight pieces without using Hold.
14. Build a streak of consecutive line-clearing placements.

- Mission count grows from 2 to 5 as the campaign advances.
- Campaign-only counters track placements, successful rotations, Hold uses, Hard Drops, double/triple/Tetris clears, and best clear streak.
- Rotation and Hold progress refresh immediately.
- Mutually exclusive Hold / no-Hold objectives cannot be selected together.
- Failed challenge conditions are visibly marked as “УСЛОВИЕ НАРУШЕНО”.
- These missions use standard gameplay and do not grant or activate roguelike cards.

## Separate progression retained
- Campaign perks remain campaign-specific. Scout is now an extra Hold use, Guardian remains its emergency rescue, and Tactician remains its campaign score bonus.
- Hero abilities remain distinct from upgrade cards.
- Daily challenge modifiers remain in their own daily-mode system.

## Validation
- Updated static assertions cover all-card isolation, non-rogue level-up behavior, campaign mission counters, Scout separation, and Block Run-only inventory injection.
- The rotation/haptic validator was updated to allow campaign mission progress refresh after a successful rotation.
- The latest Chromium/WebKit and mobile visual preview runs are still being checked; do not mark the new mission UI visually accepted until they complete.
- No real-device test has been performed in this checkpoint.

## Next
1. Confirm latest CI runs complete successfully.
2. Inspect screenshots for any campaign mission rail overflow on desktop and mobile.
3. If mission rail needs compacting, adjust only its presentation; do not alter Golden Desktop Baseline #372 or mobile board ratio.
4. Continue with the remaining upgrade audit only after the campaign mode separation is verified.
