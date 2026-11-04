# TETRIOS LX — Checkpoint #393
Date: 2026-11-03

## Branch and safety
- Branch: `feature/gameplay-evolution-389-2026-11-03`
- PR #50 remains open/draft; no merge or production deployment.
- Gameplay commit: `7c4fd0d719d4181f593741558383644dd8cdaf49`
- Validator commit: `30485797dde31382d089ed8db57cc264143b6ae4`
- No APK build.

## Completed: Gear (Механизм повторения)
- Added a run-local counter for locked/placed pieces.
- Counter advances exactly once in `lockPiece()`, regardless of whether the piece arrived by gravity, soft drop, or hard drop.
- Failed horizontal/vertical movement and rotations do not count.
- While Gear is active, every fifth locked piece awards +25 points; in Block Run the bonus scales with the card rank.
- Counter resets at the start of every run and begins counting only while Gear is owned.
- Card library description now reflects the actual trigger.
- Added a static validator assertion.

## Completed earlier
- #391: Stable rank-scaled wall-kicks in Block Run only; mobile preview #94 passed.
- #392: Plasma resets the next fall delay after line clears without altering the Block Run gravity ramp.

## Outstanding
- Remaining unaudited IDs: `prism`, `luck`, `void`, `shift`, `aura`.
- Cross-platform Chromium/WebKit visual acceptance still pending; earlier attempts were cancelled due to overlapping workflow concurrency.
- Static validator changes have not yet been confirmed by a successful CI run on the latest head.

## Next
1. Re-run the gameplay validator and visual QA on the current PR head.
2. Audit `shift` (rotation score) and `luck` (rare-piece score) against the actual shape selection / rotation flows.
3. Keep campaign and daily challenge behavior unchanged unless a card is intentionally shared.
4. Preserve Golden Desktop Baseline #372 and the 10:23 mobile arena.
