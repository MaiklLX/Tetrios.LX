# KT-580 — Godot blue palette restoration

**Repository:** `MaiklLX/Tetrios.LX`  
**PR:** #85 — Draft only  
**Branch:** `web/kt550-browser-return-2026-11-09`  
**Commit:** `d8acc231dac5da2f32f826ae82ef3c19ba93a836`

## Goal
Bring the browser arena closer to the softer blue-glass palette of Godot KT-549. The earlier browser palette leaned too strongly toward green-cyan; Godot's visual language is clearer, cooler and more blue.

## Godot-to-browser mapping
- Godot panel fill `#102f68` / `#124b99` → browser HUD, side cards and objective panels use layered navy/blue gradients.
- Godot cyan edge `#55ddff` / `#4eaaff` → browser arena frame and HUD accents.
- Godot board interior `#071b45` with `#174276` grid/border → browser canvas board background and frame treatment.
- Godot pale-blue text `#c4edff` / `#d9edff` → browser supporting labels and objective copy.
- Godot gold `#ffd05a` → reserved for reward and primary drop-action accents.

## Scope and safety
- CSS-only visual change in `site/index.html`, appended as `bb-kt580-godot-blue-palette`.
- No JavaScript, Canvas piece colors, collision, gameplay, board dimensions, progression, saves or economy changes.
- Reduced-motion handling retained; ambient star animation is disabled when requested by the OS.
- `main`, public Pages, Godot Preview and APK are untouched. No merge or deployment.

## Validation
- Previous head `6b33500...`: Mobile Arena #413 Passed; Cross-platform #640 predecessor #639 Passed.
- New head `d8acc231...`: Mobile Arena #414 and Cross-platform #640 were triggered; results pending at checkpoint creation.
- Physical-device testing remains outstanding.
