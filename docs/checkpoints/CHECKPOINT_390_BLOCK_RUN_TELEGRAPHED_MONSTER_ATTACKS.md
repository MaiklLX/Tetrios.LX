# TETRIOS LX — CHECKPOINT #390
## Block Run: telegraphed monster attack patterns
Date: 2026-11-03

### Base and scope
- Repository: `MaiklLX/Tetrios.LX`
- Working branch: `feature/gameplay-evolution-389-2026-11-03`
- Base gameplay and card-library work: checkpoint #389.
- This increment changes Block Run monster encounters only. Campaign, Daily Challenge, desktop arena baseline #372 and mobile arena layout are out of scope and must remain unchanged.
- No merge to `main`, no production deployment, no APK build requested.

### Implemented
- Added three explicit attack profiles:
  - `breach`: one garbage row with one open cell.
  - `crossfire`: two garbage rows with two offset openings per row.
  - `siege`: boss-only two-row attack with one narrow opening per row.
- Normal encounters cycle through breach and crossfire; bosses cycle through siege and crossfire.
- Encounter panel now names the upcoming attack, describes its shape and shows a stronger warning treatment when five seconds or less remain.
- Attack row openings are deterministic from room, attack index and row index; the same encounter sequence can be reproduced in tests.
- Reserve still blocks a complete attack, consumes one charge and advances to the next telegraphed pattern.
- Existing counterplay remains: clear lines to damage the monster, use Reserve to absorb an attack, and Blip's active ability delays the attack timer.
- All attack logic remains guarded to `mode==='rogue'`.

### Automated checks added
- `site/validate-gameplay-modes.mjs` now asserts:
  - distinct attack profiles and boss/normal cycles;
  - deterministic row construction;
  - attack label and <=5-second warning in the encounter panel;
  - Reserve consumption and attack profile row resolution;
  - existing Block Run-only mode guards.
- Validation is awaiting the GitHub Actions runs below. Do not mark as green until completed.

### Commits
- Attack implementation: `815cd906ea2a92bfdd60f232ab26450d98b19939`
- Gameplay validation: `d5592098cd3926a3a0013afdb743d7c6b18263c1`

### CI at checkpoint creation
- Android WebView source audit run: `41665678315` — in progress.
- Cross-platform visual preview run: `41665678736` — pending.
- Mobile Arena Visual Preview run: `41665678933` — pending.
- No APK workflow was triggered by these commits; APK workflow remains configured without a `pull_request` trigger. The earlier legacy PR-triggered APK run is documented in checkpoint #389.

### Manual review still required
- Inspect desktop Chromium and iPhone-sized WebKit screenshots after CI.
- Verify the warning text fits the monster panel at mobile widths.
- Play an actual Block Run encounter to confirm the cadence feels readable and fair; WebKit automation is not a substitute for real iPhone Safari.
- Confirm that campaign and daily modes never render or process these attacks.
- Do not merge PR #50 until the user explicitly approves after review.

### Next
1. Complete and inspect CI artifacts for #390.
2. Add focused gameplay tests for attack resolution and counterplay if the test harness permits deterministic board fixtures.
3. Audit all 35 upgrades against their real trigger paths; distinguish active effects, descriptive-only cards and effects that are implemented through dedicated state.
4. Only then begin a unified upgrade event layer. Preserve the existing 35-card pool until that audit is complete.

### Continuation phrase
`TETRIOS LX — продолжаем с контрольной точки #390. Ветка feature/gameplay-evolution-389-2026-11-03, commits 815cd90 (телеграфированные атаки Block Run) и d559209 (проверки режимов). Добавлены breach/crossfire/siege, предупреждение атаки и детерминированные ряды; Reserve блокирует атаку и переводит цикл дальше. CI runs 41665678315 / 41665678736 / 41665678933 проверить и изучить скриншоты. PR #50 не сливать, main не менять. Затем аудит реальных триггеров всех 35 карт. Сохранить Golden Desktop Baseline #372 и mobile baseline; APK без необходимости не собирать.`


### Follow-up audit
- Added `docs/audits/UPGRADE_TRIGGER_AUDIT_390.md`.
- The source audit found eight catalogue cards with no card-owned gameplay trigger in the current code: `prism`, `stable`, `luck`, `void`, `gear`, `shift`, `aura`, `plasma`.
- It also found rank/description mismatches for `mult`, `glow`, `comet`, `flash`, and `neuron`; dedicated paths for `shield`, `armor`, `hold`, `reserve`, `nova`, and `hunter` are documented separately.
- This is a static source audit, not a claim that all cards have been dynamically tested. The 35-card pool is unchanged; no card has been removed or silently rebalanced.

### Latest branch state
- Audit document commit: `6e376069151cb8e674e0248dfefc7274cd784a1a`.
- PR #50 head at audit update: `6e376069151cb8e674e0248dfefc7274cd784a1a`.
- Run `41665678315` (Android WebView source audit) remained in progress.
- Runs `41665678736` (cross-platform visual preview) and `41665678933` (mobile arena preview) had not yet exposed job results; screenshot acceptance remains pending.
- Next implementation should repair the eight inactive cards and align rank formulas/descriptions, with tests and mode gating. Do not change the 35-card count without approval.


### Automation correction — Android audit workflow
- Inspection of the actual `.github/workflows/android-webview-audit.yml` revealed that this separate workflow also compiled and uploaded a debug APK on every PR to `main`; this was broader than the earlier `build-apk.yml` fix.
- Run `41665678315` was already executing its `Compile debug APK without publishing` step when this was discovered. It was an automatic PR-triggered audit run, not a user-requested APK build. It may complete and upload its test artifact; no release signing or deployment is involved.
- Updated the audit workflow's `pull_request.paths` filter so it only runs when Android WebView patching, Android project archive, 3D runtime/character assets or related 3D source files change. Ordinary gameplay/card-library changes no longer request an Android APK build.
- This workflow change is on the feature branch and will not be merged/deployed automatically.


- Follow-up found the scoped `pull_request.paths` filter still matched the full PR #50 diff because the branch also contains earlier 3D/Android-related file changes. A second automatic run `41666284649` therefore started before the final correction.
- Final correction: removed the `pull_request` trigger from `.github/workflows/android-webview-audit.yml` entirely and added `workflow_dispatch`. The existing explicit push triggers for the dedicated 3D maintenance branches remain. Android WebView/APK audit is now manual for PR-based gameplay work.
- The already-started automatic audit run `41666284649` is not retroactively cancelled; it may finish. Run `41665678315` completed successfully and included a debug APK artifact, despite no release signing or deployment.
