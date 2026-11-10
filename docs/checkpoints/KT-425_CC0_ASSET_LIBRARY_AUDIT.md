# KT-425 — Block Buddies visual asset library audit

Date: 2026-11-07
Status: source audit and integration plan; no third-party binaries imported yet.

## Goal

Build a coherent, engine-independent visual asset library for Block Buddies:
- arena backplates, board surrounds and subtle texture layers;
- touch controls and state variants (normal, pressed, disabled);
- HUD panels, frames, meters and dialog surfaces;
- icons for currencies, skills, boosts, timer and progression;
- Roguelike cards for heroes, items, abilities, rarity and rewards;
- tile/block faces and optional clear/impact effects.

## Current repository inventory

Existing project-authored assets in `site/assets/ui/`:
- `boost-spark.svg`
- `coin-emblem.svg`
- `gem-crystal.svg`
- `level-chevron.svg`
- `level-insignia.svg`
- `line-clear.svg`
- `next-piece.svg`
- `panel-frame.svg`
- `score-star.svg`
- `timer-orbit.svg`

Existing space art:
- `site/assets/deep_space_no_sun_2k.webp`
- `site/assets/space-nebula-01.png`

Keep original assets as the primary identity layer. Third-party assets are candidates, not automatic replacements.

## Candidate packs and license review

| Pack | Useful for | License / caveat | Decision |
|---|---|---|---|
| Kenney UI Pack | General panels, buttons, sliders, interface chrome | CC0 on publisher page; 430 files | First candidate for UI primitives |
| Kenney UI Pack - Sci-Fi | Sci-fi panels, buttons and HUD pieces | CC0 on publisher page; 130 files | First candidate for arena/HUD experiments |
| Kenney UI Pack (RPG Expansion) | RPG panels and buttons | CC0 on publisher page; 85 files | Candidate for Roguelike card frames |
| Kenney Roguelike/RPG Pack | RPG tiles, props, buttons and panels | CC0; 16×16 pixel art, 3/4 perspective | Do not mix directly with current clean UI; selectively prototype |
| Screaming Brain Simple Interface Button Pack | Button states, tabs, square controls | CC0; 72 buttons; PNG | Candidate for button-state tests |
| Screaming Brain Portrait Frame Pack | Character/hero portrait frames | CC0; 300 frames, multiple materials/styles/sizes | Candidate for card frame tests |
| Screaming Brain Tiny Buttons Pack | Compact controls and bullets | CC0; 16×16 and 24×24; released/pressed states | Candidate for small indicators |

Publisher source links:
- https://kenney.nl/assets/ui-pack
- https://kenney.nl/assets/ui-pack-sci-fi
- https://kenney.nl/assets/ui-pack-rpg-expansion
- https://kenney.nl/assets/roguelike-rpg-pack
- https://kenney.nl/support
- https://screamingbrainstudios.com/downloads/
- https://screamingbrainstudios.itch.io/button-pack
- https://screamingbrainstudios.itch.io/portrait-frame-pack
- https://screamingbrainstudios.itch.io/tiny-buttons-pack

License notes:
- Kenney states assets on its asset pages are CC0; attribution is optional, not required. Re-check the included LICENSE file for every downloaded pack.
- Screaming Brain Studios states its packs are CC0/Public Domain. Keep a copy of each source license/readme beside imported assets.
- Do not import assets from repack sites or unverified mirrors. Download from the publisher's own page only.
- Do not copy EA Tetris art, logos, sounds, UI compositions or extracted APK resources. Use the reference only for usability and hierarchy.

## Visual direction

1. Keep Block Buddies' existing graphite/deep-space base and turquoise/gold accents.
2. Use Sci-Fi UI assets only where they improve legibility; avoid a noisy cockpit look.
3. Use one consistent frame family for hero, item and ability cards. Rarity should be conveyed by controlled border/glow accents, not entirely different art styles.
4. Keep tile/block faces readable at small phone sizes; test contrast and color-blind distinction.
5. Use nine-slice or scalable SVG for panels/buttons where practical. Do not stretch pixel-art assets.
6. Preserve touch targets (aim for at least 48 CSS px for primary mobile controls); visual decoration must not shrink hit areas.

## Import / implementation workflow

- Download official source ZIPs to a temporary staging area.
- Inspect archive contents, dimensions, alpha/transparency, sprite sheets, fonts and license files.
- Create contact sheets for visual review before selecting individual files.
- Copy only selected assets into namespaced folders under `site/assets/ui/` (e.g. `kenney-sci-fi/`, `sbs-frames/`); retain original filenames where useful.
- Add `SOURCES.md` metadata per imported pack: publisher, source URL, license, download date, original archive name, selected files and any edits.
- Optimize raster images and keep SVG source where available.
- Integrate one family at a time behind CSS variables/classes; preserve DOM IDs, game logic and save data.
- Verify mobile portrait, desktop, contrast, pressed/disabled states, and no overflow before proposing merge.

## Explicit non-goals

- No mass import of entire asset packs.
- No replacing the existing game identity with generic RPG/pixel art.
- No changes to gameplay, balance, rewards, save format or monetization.
- No merge to main, deployment or APK release in this checkpoint.

## Acceptance criteria

- User sees a contact sheet and selects a visual direction before broad integration.
- Every imported file has traceable publisher/license provenance.
- UI assets remain separate reusable files, not one flattened screenshot.
- Main controls remain thumb-friendly and readable on 375×812 and 393×873 phone viewports.
