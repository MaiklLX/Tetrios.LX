# CHECKPOINT #400 — CROSS-PLATFORM VISUAL QA RESULTS AND LIMITATIONS

Date: 2026-11-03
Repository: MaiklLX/Tetrios.LX
Branch: feature/gameplay-evolution-389-2026-11-03
Base source commit: 5c3f115793177091c2472f10327aec4039cfec99

## Scope and safety

- Work remained on feature/gameplay-evolution-389-2026-11-03.
- main was not modified.
- PR #50 was not merged.
- Golden Desktop Baseline #372 was not changed.
- No APK was built.
- Nothing was deployed or published.
- This checkpoint records QA evidence; it does not change gameplay code.

## Cross-platform Visual Preview #171

- Workflow run: 41686955035
- Job: 126095457778
- Conclusion: SUCCESS
- Artifact: tetrios-cross-platform-visual-preview
- Artifact ID: 13256655405
- Artifact SHA-256: eb9e7b16a7c382bdedf6e04edc4ca43222ce64be58cd0628ff03c612692d2a79
- Tested source commit: 5c3f115793177091c2472f10327aec4039cfec99
- Captured targets:
  - Chromium desktop 1440×900
  - Chromium desktop 1920×1080
  - WebKit mobile 390×844
  - WebKit mobile 430×932

## Geometry results

- Desktop 1440×900: arena frame 319.26×734.31 px; ratio 0.43476882; 3D canvas alignment delta 2 px.
- Desktop 1920×1080: arena frame 356.29×819.49 px; ratio 0.43477517; 3D canvas alignment delta 2 px.
- WebKit 390×844: arena frame 256.91×590.88 px; ratio 0.43478951; frame and controls remain inside document bounds.
- WebKit 430×932: arena frame 283.69×652.47 px; ratio 0.43479094; frame and controls remain inside document bounds.
- The 10:23 arena ratio is preserved at all four tested viewports.
- Desktop 3D overlay alignment is within the 3 px harness tolerance.
- Mobile screenshots confirm the 2D arena and mobile control layout. The current harness intentionally captures 3D only on Chromium; mobile WebKit 3D parity is therefore NOT verified by this run.

## Visual inspection

- Inspected desktop 1440×900 2D and 3D screenshots.
- Inspected desktop 1920×1080 3D screenshot.
- Inspected iOS WebKit 390×844 2D arena and campaign mission screenshots.
- 2D arena layout and controls are coherent in the captured targets.
- Desktop 3D mode has aligned board/canvas geometry. The visual treatment still reads closer to a framed grid with dimensional block styling than a strongly volumetric arena; this is a separate visual-polish topic, not a geometry failure.
- Prism/Aura were not visually activated in these captures; their implementation and validators remain documented in #399 and are not declared visually accepted solely from these screenshots.

## Known QA caveats

- report.json contains WebKit campaign page errors for external planet GLB fetches from grab3d.com, blocked by CORS/access-control checks. These are asset-loading errors in the campaign preview path, not arena geometry failures.
- The workflow's failures array is empty and the job succeeded, but pageErrors records the external model fetch issue. Do not describe the entire run as error-free.
- WebKit mobile 3D was not captured because the current script gates the 3D toggle/capture to Chromium. Add a deliberate WebKit capability/capture check before claiming mobile 3D parity.
- Prism/Aura visual-state capture should be added or performed separately if visual acceptance of those effects is required.

## Decision / next actions

1. Treat 10:23 geometry and current desktop overlay alignment as passed for the tested viewports.
2. Keep mobile 3D parity, campaign external-model CORS behavior, and Prism/Aura active-state visual verification open.
3. Before the next feature, close or explicitly scope these QA gaps; do not silently convert missing evidence into a pass.
4. Void has NOT been started by this checkpoint. Begin Void only after the remaining cross-platform QA gaps have been deliberately resolved or accepted with clear evidence.

## Next-chat control phrase

TETRIOS LX — продолжаем с контрольной точки #400. Репозиторий MaiklLX/Tetrios.LX, ветка feature/gameplay-evolution-389-2026-11-03. Cross-platform Visual Preview #171 успешно завершился (run 41686955035, artifact 13256655405) на коммите 5c3f115793177091c2472f10327aec4039cfec99. Геометрия арены 10:23 подтверждена на Chromium 1440×900 и 1920×1080, WebKit 390×844 и 430×932; desktop 3D canvas alignment delta 2 px. Важные незакрытые пункты: WebKit mobile 3D в текущем harness не захватывается; campaign WebKit фиксирует CORS-ошибки загрузки внешних planet GLB; Prism/Aura не были визуально активированы в этом прогоне. Следующий шаг — закрыть эти QA-пробелы или документированно принять ограничения, затем переходить к Void. main не менять, PR #50 не сливать, Golden Desktop Baseline #372 не трогать, APK не собирать, не публиковать.
