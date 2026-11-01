# Tetrios.LX universe models

- `manifest.json`: source, license and mapping for the 12 galaxy cards.
- `../universes-3d.js`: Three.js / GLTFLoader integration.
- Models are loaded lazily from Grab3D's original GLB endpoints. The project does not duplicate or rehost the binary model files.
- License recorded by the publisher: CC0 1.0 Universal.
- Runtime: one shared WebGL renderer with scissored card viewports, so only visible cards are rendered.

If the external host is unavailable or CORS blocks a model, the card keeps its original emoji fallback.
