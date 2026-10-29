# Character asset evaluation shortlist

Status: research shortlist only. No third-party models have been copied into the repository or assigned to the five mascots yet.

## Sources worth evaluating

1. **Kenney Mini Characters** — https://kenney.nl/assets/mini-characters
   - Source page lists CC0 and animation support.
   - Evaluate for scale, mesh quality, included clips, and whether any model can serve as a temporary rig/animation test.
   - Not a direct match for Plush, Prism, Blip, Pixel, or Spark.

2. **Kenney Animated Characters Protagonists** — https://kenney.nl/assets/animated-characters-protagonists
   - Source page lists CC0 and animated character assets.
   - Potential animation-pipeline test only; the visual style is not the intended final mascot style.

3. **Quaternius RPG Character Pack** — https://quaternius.com/packs/rpgcharacters.html
   - Third-party catalogue reports six rigged, animated characters and CC0; verify the pack's current official license and exact included formats before shipping.
   - Humanoid fantasy characters are not a direct match for the five mascots.


4. **Gobkit free GLB library** — https://gobkit.com/freebies and https://gobkit.com/api/free
   - Public catalogue reports CC0 1.0 models, including rigged/animated creatures and small GLB files; inspect the specific model record and the shipped file before using it.
   - Best current candidate source for testing a creature/robot-like asset rather than a generic human.
   - The library's existence does not prove that a perfect bear, crystal mage, horned alien, robot, or energy-being match is available. Do not configure a mascot until its exact model, animation layout, and license are reviewed.

## Decisions

- Do not assign generic humanoids as final mascots merely to make the manifest non-empty.
- Do not add remote CDN model URLs to production as a substitute for bundled, reviewed assets.
- Preserve each model's source URL, license evidence, and any required attribution.
- For final mascots, prefer original stylized silhouettes: a fabric/armored bear, a floating crystal mage, an expressive horned alien, a compact screen-faced robot, and a golden energy creature.
- Use third-party packs to validate GLB loading and animation support only after the specific model files are inspected.

## Next acceptance gate

Before a GLB becomes a shipped asset, verify the actual file, textures/materials, skeleton, animation clip names, file size, mobile performance, and redistribution terms. Keep the procedural version as fallback until the candidate passes those checks.
