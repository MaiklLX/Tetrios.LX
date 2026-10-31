# Tetrios.LX character assets

Five rigged GLB files from the Gobkit Minion Pack are bundled for future use, but they are currently **not used to replace the five authored Tetrios.LX heroes**. The pack models do not yet match the game's character identities and visual palette closely enough. The distinct procedural Three.js mascots remain active in the character showcase until correctly matched/licensed hero assets are approved.

## Bundled characters

| Tetrios.LX hero | GLB model |
|---|---|
| Plush | `models/minion-a01.glb` |
| Prism | `models/minion-b01.glb` |
| Blip | `models/minion-c01.glb` |
| Pixel | `models/minion-d01.glb` |
| Spark | `models/minion-a02.glb` |

Each model is a self-contained GLB 2.0 file with a skinned rig and named `idle`, `attack`, and `dead` animation clips. When enabled in a future update, the runtime normalizes character height and starts the idle animation. The stage can request another clip with:

```js
stage.dispatchEvent(new CustomEvent('bb3d:animation', {
  detail: { name: 'attack' } // idle | attack | victory | death
}));
```

## License and source

- Pack: Gobkit Minion Pack
- Source manifest: https://gobkit.com/api/free
- Individual GLB URLs are recorded in `manifest.json`.
- License: CC0 1.0 (public domain), commercial and personal use permitted, no attribution required.
- The SHA-256 hashes are pinned in `models.sha256`.

## Validation

Run:

```sh
python3 scripts/validate-glb-characters.py site/characters/models
node site/characters/validate-manifest.mjs
node site/validate-3d-runtime.mjs
```

The pipeline checks GLB v2 headers, embedded resources, rigging, required animation names, manifest paths, license metadata, the pinned Three.js runtime, and local audio. Visual review and testing on real Android/iOS devices are still required before release.
