# KT-548 — Godot Web Preview Preparation

Date: 2026-11-09

## Recovery and release safety
- The pre-release public web version on `main` is preserved unchanged.
- Recovery branch: `backup/main-before-block-buddies-web-release-2026-11-09`.
- Recovery commit: `a9fce851a7c7b319c55642e490a39766736e10b6`.
- PR #81 remains Draft and unmerged; it targets `godot/kt491-cartoon-visual-pilot-2026-11-08`, not `main`.
- No APK build/release is authorized.

## Development continuation point
- Validated Godot source baseline: `aee0d710d25a380e07eb5a464bf858fd61632edd` (KT-547.15).
- Baseline CI: Godot Native Project Check #42591587500 passed.
- Work continues on `godot/kt548-web-preview-prep-2026-11-09`.
- KT-547.11–KT-547.15 collection work is complete: adaptive grid, persistent reveal queue, narrow-screen column counts, selection auto-scroll, selection clarity/scrollbar.

## KT-548 scope
Prepare a separate browser build of the Godot game without replacing the existing public website:
1. Add a reproducible Godot 4.4.1 Web export preset.
2. Add CI export and static artifact validation.
3. Validate browser boot, touch input, viewport scaling, and save persistence.
4. Package the exported build as an isolated preview under a separate site path only after CI and runtime checks pass.
5. Keep the existing `site/` web game untouched and available as fallback.
6. Do not merge PR #81, change `main`, publish the preview, or release an APK without a separate explicit release approval.

## Return point after preview publication
After the separate browser preview is published and handed over for user testing, return to the exact development stage at KT-547.15 / KT-548:
- continue Godot gameplay and UI polish on a development branch;
- keep the public legacy web version intact;
- incorporate user testing observations into the Godot preview;
- do not treat web preview publication as final release or APK authorization.

## Important limitations
A successful headless export/CI is not equivalent to real browser/device verification. Desktop browser and physical Android/iOS touch testing remain explicit acceptance steps.
