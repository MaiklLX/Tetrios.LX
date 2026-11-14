# KT-491 — Bright casual-cartoon visual pilot

Date: 2026-11-08  
Status: visual direction pilot; draft review only.

## Accepted visual direction

The user supplied a visual reference and approved it as the target direction for Block Buddies:

- Friendly, colorful, dimensional casual mobile-game presentation.
- Saturated blue/cyan foundation with gold/orange and playful violet accents.
- Rounded, layered panels with soft shadows and glossy highlights.
- Readable game board; visual richness must never obscure the 10×23 playfield.
- Buddy is a prominent expressive toy-like cube mascot, not a tiny pixel decoration.
- Russian UI, portrait-first mobile layout, no permanent on-screen gameplay buttons.

## Pilot implementation

- Replaced the near-black starfield with a brighter fantasy-blue atmosphere, soft color glows, drifting particles and distant landscape shapes.
- Added reusable rounded panel/pill drawing helpers using native Godot StyleBoxFlat.
- Restyled mode cards, header controls, HUD, previews, board frame, tetromino cells and pause control.
- Replaced the procedural pixel Buddy drawing with a rounded dimensional mascot, face expressions, cheeks, gloss, soft shadow and floating star.
- All artwork is procedural/native Godot drawing. No generated or third-party images/assets were used.

## Guardrails

- This checkpoint changes presentation only. Game model, mode logic, Block Run, scoring, goals, abilities, input, save/migration and economy are not intentionally changed.
- Do not merge, publish, deploy or build/release an APK without explicit user approval.
- Existing KT-490 baseline and PR #77 remain untouched.
- Save/migration work remains deferred until visual and gameplay completion.

## Validation still required

- Godot 4.4.1 import and script parse.
- Existing model/session/live integration suite.
- Visual screenshot captures at 720×1280 and 360×800.
- Inspect actual screenshots before calling the visual pilot successful.
- CI viewport captures are not physical Android/iPhone tests.

## Next decision

Review the captured screens against the user's supplied reference. Adjust the pilot before extending the art direction to every remaining screen. If the visual result cannot be brought close enough within Godot, compare a return to the proven HTML/CSS/JavaScript PWA + Android packaging path before adopting another engine.
