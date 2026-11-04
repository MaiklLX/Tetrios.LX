# CHECKPOINT #401 — MOBILE WEBKIT 3D, PRISM/AURA AND CAMPAIGN FALLBACK QA

Date: 2026-11-03
Repository: MaiklLX/Tetrios.LX
Branch: feature/gameplay-evolution-389-2026-11-03
Verified branch HEAD: 3445fb96c5174ff9022c970d8aa733e26858b213

## Scope and guardrails

- All work stayed on feature/gameplay-evolution-389-2026-11-03.
- main was not modified.
- PR #50 remains OPEN and NOT MERGED.
- Golden Desktop Baseline #372 was not changed.
- No APK was built.
- Nothing was deployed or published.
- The only product HTML addition is a QA-only hook guarded by query parameter ?qaVisual=1. Normal sessions do not expose it.
- Changes in this checkpoint are test harness / QA support; gameplay rules, collision, scoring and board dimensions were not changed.

## Final cross-platform run

- Workflow: Cross-platform Visual Preview #193
- Run ID: 41698815693
- Job ID: 126136382931
- Conclusion: SUCCESS
- Tested HEAD: 3445fb96c5174ff9022c970d8aa733e26858b213
- Artifact ID: 13261489158
- Artifact name: tetrios-cross-platform-visual-preview
- Artifact SHA-256: 8b7c10ab5da20272d00baefa0ecec70662906bdd56bdfd6b9f46bf2cd7573605
- Artifact contains 32 screenshots and report.json.

## Arena geometry and 3D support

| Target | Frame size | Ratio | WebGL | 3D canvas alignment |
|---|---:|---:|---|---:|
| Chromium 1440×900 | 320.86×738.00 px | 0.43476880 | available | 2 px |
| Chromium 1920×1080 | 354.73×815.90 px | 0.43477520 | available | 2 px |
| WebKit 390×844 | 256.91×590.88 px | 0.43478951 | available | 0 px |
| WebKit 430×932 | 283.69×652.47 px | 0.43479094 | available | 0 px |

- The 10:23 arena ratio is preserved at all four target sizes.
- WebKit successfully activated the 3D arena at both mobile viewport sizes.
- The harness now captures mobile WebKit 3D screenshots when WebGL is available; it no longer assumes mobile WebKit lacks WebGL.

## Prism and Aura visual QA

- QA-only hook activated Prism and Aura together on an actual active falling piece at all four targets.
- All four reports confirm activePiece=true, boosts include prism and aura, and Prism returned a valid six-digit spectral color.
- Separate Prism/Aura screenshots were captured at desktop and mobile viewports.
- Manual screenshot inspection confirms the spectral piece color and visible glow around the active piece.
- Desktop and WebKit mobile 3D screenshots were also captured after enabling the 3D arena. Prism/Aura are not declared fully production-certified for every device/GPU combination, but the previously missing WebKit 3D evidence is now present.

## Campaign atlas and external GLB behavior

- Campaign atlas contains 12 universe model slots at each viewport.
- Procedural local fallback models were visible in the captured viewport:
  - Desktop 1440×900: 7
  - Desktop 1920×1080: 9
  - WebKit 390×844: 2
  - WebKit 430×932: 2
- Campaign atlas screenshots were captured and manually inspected at desktop 1440×900 and 1920×1080, plus mobile WebKit.
- Grab3D external GLB requests remain blocked by CORS/access-control in WebKit. The procedural local 3D fallbacks remain visible, so the atlas is not blank and the failure is non-fatal.
- This is an accepted graceful-fallback limitation for the current QA scope, not a claim that remote GLB assets load successfully. If detailed source GLBs are required later, self-host them under the project origin or use another CORS-enabled asset source.
- Failed external requests were recorded (desktop 7 and 9; WebKit 2 per viewport). WebKit also reports fetch access-control page errors for planet.glb / jupiter.glb; no gameplay page errors were recorded in the desktop captures.

## Result / decision

- Passed: 10:23 geometry on all four targets.
- Passed: desktop and mobile WebKit 3D activation and canvas alignment.
- Passed: Prism/Aura activation and visual capture on all four targets.
- Passed: campaign atlas remains populated by local procedural fallbacks when external GLB requests fail.
- Accepted limitation: detailed external Grab3D GLB upgrades are not CORS-reliable in WebKit; local procedural models are the current fallback.
- Cross-platform QA gaps from checkpoint #400 are now closed or explicitly scoped as above.
- It is now safe to proceed to the next planned upgrade, Void, on this branch only.

## Next-chat control phrase

TETRIOS LX — продолжаем с контрольной точки #401. Репозиторий MaiklLX/Tetrios.LX, ветка feature/gameplay-evolution-389-2026-11-03. Cross-platform Visual Preview #193 успешно завершился на HEAD 3445fb96c5174ff9022c970d8aa733e26858b213 (run 41698815693, artifact 13261489158). Проверены Chromium 1440×900 и 1920×1080, WebKit 390×844 и 430×932. Арена сохраняет 10:23; 3D WebKit активируется, выравнивание 0 px на обоих мобильных размерах. Prism/Aura включены QA-хуком на активной фигуре и визуально захвачены. Кампания сохраняет локальные процедурные 3D fallback-модели при отказе внешних Grab3D GLB из-за CORS; это ограничение документировано, не блокирует игру. Следующий этап — начать реализацию и проверку улучшения Void. main не менять, PR #50 не сливать, Golden Desktop Baseline #372 не трогать, APK не собирать, не публиковать. Контрольные точки обязательны.
