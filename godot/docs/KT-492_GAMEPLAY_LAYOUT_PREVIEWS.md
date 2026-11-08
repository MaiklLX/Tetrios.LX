# KT-492 — Gameplay layout and preview emphasis

Date: 2026-11-08
Status: implementation checkpoint; Draft review only.

## User feedback addressed

- Hide the large BLOCK BUDDIES and mode-name title banner during active gameplay.
- Keep compact mode-switch and pause affordances at the top.
- Move the score/progress HUD upward to reclaim vertical space.
- Move the arena's minimum top position upward so the playfield can use more of the portrait viewport.
- Increase HOLD/NEXT preview cards from 46px to 60px and enlarge the displayed piece cells.

## Layout targets

- Portrait 720×1280: larger playfield while preserving top HUD, previews and touch-safe spacing.
- Portrait 360×800: score HUD, Block Run goals, preview cards and arena remain separated without overlap.
- No permanent on-screen directional control strip is introduced.

## Drop control discrepancy

The current Godot scene has no visible DROP button: hard drop is performed by a fast downward swipe (and Enter on keyboard); slower downward swipes soft-drop. The user mentioned making the DROP button more prominent. Before adding a persistent touch button, compare the exact screen/reference they mean with the current Godot and Web/PWA builds. Do not silently add a control that could conflict with the previously approved gesture-first layout.

## Scope and guardrails

- Presentation/layout only; no gameplay rules, scoring, mode progression, Block Run logic, economy, or save/migration changes.
- No generated/third-party artwork.
- Do not merge, publish, deploy, or release APK without explicit user approval.
- PR remains Draft. Main/public build unchanged.

## Validation

- Godot import/parse and existing gameplay/integration tests.
- Capture and inspect 720×1280 and 360×800 screenshots.
- CI screenshots are not physical Android/iPhone device tests.

## Next visual screens

After the user reviews the gameplay layout, prepare dedicated concept screens for the main menu, shop, hero roster/detail, upgrades and Block Run hub/results. These sections must be designed as real navigable UI before connecting them to persistent profile/economy data.
