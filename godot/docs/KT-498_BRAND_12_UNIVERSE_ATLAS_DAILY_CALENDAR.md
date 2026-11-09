# KT-498 — Block Buddies identity, full atlas and daily calendar markers

Date: 2026-11-08
Branch: `godot/kt493-gallery-validated-2026-11-08`
Status: Draft-only visual gallery refinement.

## Home brand hierarchy
- Removed the obsolete TETRIOS.LX wordmark from the home header.
- The top bar is now profile/utility chrome (Buddy portrait, profile label, sound/settings icons).
- The hero panel below is the single primary BLOCK BUDDIES wordmark.
- Other gallery screens retain a compact BLOCK BUDDIES app bar with their own page heading below; no duplicate title is shown on the home screen.

## Restored campaign scale from the original project
The previous production campaign data defines 12 universes and 360 planet nodes, with 30 sequential nodes per universe. The gallery now restores all 12 original biome names and their node ranges:
1. Зелёные равнины — 001–030
2. Караван звёзд — 031–060
3. Огненные земли — 061–090
4. Ледяная корона — 091–120
5. Лунная колония — 121–150
6. Крылья экспедиции — 151–180
7. Пески времени — 181–210
8. Врата междумирья — 211–240
9. Небесный архипелаг — 241–270
10. Станция дронов — 271–300
11. Космический разлом — 301–330
12. Дальний рубеж — 331–360

The old atlas data also maps distinct 3D showcase models to each universe and procedural planet variants to all 360 nodes. This visual gallery uses native Godot drawing primitives to represent each universe distinctly; it does not replace the existing 3D model runtime or alter campaign progression.

## Daily challenge calendar
- Added a visible daily-rule symbol and short label to every date.
- Markers are based on the existing 17-rule daily challenge catalogue (solar resonance, gravity, gravity flip, glitch reactor, artifact hunt, red zone, echo combo, chrono rift, chroma storm, comet hunt, mirror sector, core pulse, relic silence, blind assembly, prismatic chaos, last shield, singularity).
- Added a clear legend/context line so the calendar is no longer just date tiles.
- Corrected November 2026 alignment: November 1 is Sunday; November 8 is highlighted as current date in the static reference.

## Scope
The gallery remains a visual prototype. It does not connect calendar markers to live date assignments, history, streaks or reward receipts; no campaign navigation, planet unlocking, wallet or save data is changed. No merge, production deployment or APK release.
