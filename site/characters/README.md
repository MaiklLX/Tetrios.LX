# Tetrios.LX character asset pipeline

This folder is the home for licensed character models. The game continues to use its procedural Three.js mascots until a real model is added and verified; an absent or broken asset must never break the game.

## Required asset format

- One `.glb` file per mascot, with embedded textures where practical.
- Y-up orientation; character faces toward positive Z.
- Centered around X/Z origin, feet near Y=0.
- Target visible height around 1.8 units (the loader normalizes scale).
- Prefer a single skinned mesh or a small number of meshes, PBR materials, sensible polygon count, and no external texture paths.
- Optional animation clips named `Idle`, `Victory`, and `Attack`. Missing clips are allowed.
- Include a license file or source URL and explicit license in `manifest.json` before shipping an asset.

## Current status

No production GLB assets have been added yet. All five manifest entries intentionally have `model: null`; the current procedural models remain the fallback and are still used by the game.

## Validation gate

Before committing a new GLB, run this from the repository root with Node.js 18 or newer:

```sh
node site/characters/validate-manifest.mjs
```

The validator checks the five mascot entries, safe local paths, explicit license/source metadata, file existence, and the GLB v2 header. It deliberately accepts `model: null` while the procedural fallback is in use. It does not replace visual inspection or a browser/device test.

## Safe integration checklist

1. Confirm the asset can be redistributed and modified under its license.
2. Add the GLB and update only that mascot's `model` field with a relative path such as `./characters/plush.glb`.
3. Add the license/source information.
4. Test load failure, mobile viewport, orientation, scale, and animation clips before replacing the fallback.
5. Keep the procedural mascot available as a runtime fallback.
