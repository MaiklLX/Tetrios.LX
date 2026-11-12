# TETRIOS LX — Checkpoint #396
Date: 2026-11-03

## Branch and safety
- Branch: `feature/gameplay-evolution-389-2026-11-03`
- PR #50 remains open/draft; no merge, deployment, or APK build.
- Aura implementation and narrow-mobile layout fix are on the PR branch.
- Main and Golden Desktop Baseline #372 remain untouched.

## Completed: Aura (Живой кристалл)
- While the Aura card is owned, the active falling piece receives a soft glow in its own palette color.
- Glow is drawn behind the active piece cells; settled blocks, ghost-piece logic, collision, score, and board geometry are unchanged.
- Catalog description now accurately describes the active-piece aura.
- Static gameplay validator checks the card-gated render path.

## Mobile regression caught and fixed
- A variable-length Block Run objective label could wrap at 375×812 and push the objective rail 1.5px below the viewport.
- Added compact spacing only under 380px portrait width; did not alter the board or side rail.
- Mobile Arena Visual Preview run #109 (`41671558940`) passed on source `00c68881b835e45c30417f363b97d0644af0201a`.
  - 375×812: goals rail bottom 799.91px of 812px.
  - 412×915: goals rail bottom 874.09px of 915px.
  - Board ratio remains approximately 0.43479 (10:23).
  - No page errors.

## Cross-platform QA
- Runs #91 and #92 (`41671559073`, `41671560083`) are still in progress at checkpoint creation.
- Prior successful cross-platform run #80 passed for the pre-Aura source.
- Do not mark Aura cross-platform acceptance complete until one current-head run passes.

## Upgrade audit state
- Implemented since the original audit: Stable (#391), Plasma (#392), Gear (#393), Shift (#394), Aura (#396).
- Luck remains deferred because the current seven-piece bag has no rarity tier.
- Prism and Void remain catalogue-only; their effects need a precise visual/gameplay design before implementation.

## Next
1. Confirm a successful Chromium/WebKit preview on the Aura source.
2. Audit/define Prism's color treatment without altering piece fairness or desktop baseline.
3. Keep Void deferred until a safe, deterministic field-compression rule is designed.
4. Preserve mobile 10:23 geometry and the desktop Golden Baseline.
5. Keep PR #50 draft/open; do not merge without explicit approval.
