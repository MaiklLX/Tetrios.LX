# TETRIOS LX — Checkpoint #394
Date: 2026-11-03

## Branch and safety
- Branch: `feature/gameplay-evolution-389-2026-11-03`
- PR #50 remains open/draft; no merge or production deployment.
- Current work continues from #393.
- No APK build.

## Completed: Shift (Сдвиг измерений)
- A valid successful rotation triggers a 25% chance to award +25 points.
- In Block Run the reward scales as +25 × card rank.
- Failed rotations do not trigger the chance or award points.
- Catalog description now matches the real effect.
- Added a static validator assertion.
- This is a shared card effect; it does not modify campaign/daily rules or the rotation geometry.

## Luck (Артефакт удачи) — audited, not implemented
- Current `randomType()` uses a seven-piece bag: each of the seven shapes appears exactly once per bag, shuffled.
- There is no existing rare-piece category. Assigning rarity to an arbitrary shape or weighting the bag would change core piece fairness.
- Keep Luck inactive until the rarity rule is explicitly designed: rare shapes, frequency, and reward formula.

## Validation and known limits
- Source and validator changes are committed to the PR branch.
- Static validator has an assertion for Shift, but a successful CI run on this new head is not yet confirmed.
- Cross-platform Chromium/WebKit visual acceptance remains pending.
- No real-device iPhone Safari test performed.

## Next
1. Run/confirm gameplay validation and cross-platform preview on the current head.
2. Decide a principled rarity model for Luck before implementation.
3. Continue auditing `void`, `aura`, and `prism` without inventing effects.
4. Preserve Golden Desktop Baseline #372 and the 10:23 mobile arena.
5. Keep main unchanged; do not merge PR #50 without explicit approval.
