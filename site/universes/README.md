# Tetrios.LX universe models

- `manifest.json`: source, CC0 license, local filenames and mapping for all 24 campaign-atlas models.
- `../universes-3d.js`: Three.js / GLTFLoader integration with procedural fallbacks.
- The web build lazy-loads GLB models from their original Grab3D publisher URLs.
- The Android APK build downloads all 24 GLB files, verifies their GLB headers and packages them in `assets/universes/models/`; the packaged manifest is rewritten to relative local URLs for offline use.
- All 24 models are marked **CC0 1.0 Universal** by Grab3D. Original source pages are preserved in the manifest and in `MODEL_CREDITS.md`.
- The atlas now mixes planets, ships, a lunar outpost, drones, a mech, a portal, a communications array and alien flora instead of repeating only spherical planets.
- Runtime: one shared WebGL renderer with scissored card viewports; models are loaded lazily as cards approach the visible horizontal atlas.
- On WebGL or model-load failure, each slot keeps a distinct procedural fallback rather than a blank card.

## Android offline behaviour

The 24 GLB models are bundled in the APK. The first APK installation therefore contains the models; opening the campaign atlas does not need to fetch the model files from the network. Website updates remain separate from the Android package.
