# KT-493 — Secondary screen visual concept gallery

Date: 2026-11-08
Status: code-drawn concept screens; isolated from live gameplay.

## Purpose

Show the intended visual language across the wider Block Buddies product before wiring navigation, wallet, inventory, hero progression or persistence. This is a reviewable visual prototype, not a claim that these product systems are implemented.

## Screens

1. Main menu — Buddy welcome, primary Play CTA, shop/heroes/upgrades shortcuts, daily challenge teaser and bottom navigation.
2. Shop — three sample cosmetic offers, prices and item presentation.
3. Hero roster — Plush, Prism, Blip, Pixel and Spark cards, level labels and selection CTA.
4. Upgrade workshop — Buddy focal point and Energy/Defense/Score upgrade cards.
5. Block Run hub — floor/room introduction, five-node route with boss node, example goals and start CTA.

All elements are drawn with native Godot 2D primitives and StyleBoxFlat. No generated images, third-party assets, or proprietary references are used.

## Architecture and safety

- The gallery lives in `ui_concept_gallery.gd` and `ui_concept_gallery.tscn`, separate from `main.tscn`.
- CI visual capture includes five additional concept screenshots (10–14).
- No production navigation, purchase actions, wallet mutation, hero unlocks, upgrades, save data or economy integration is implemented.
- Values are illustrative placeholders, not the actual live player profile or store catalog.
- The existing live game and gameplay tests remain separate.

## Review questions

- Does the friendly, glossy blue/cyan/gold direction feel consistent across all five screens?
- Is Buddy prominent without taking too much space?
- Are the menu, shop and hero cards legible on narrow portrait phones?
- Does Block Run read as a roguelike journey with a boss finale?

## Guardrails

Draft-only review. Do not merge, publish, deploy, or build/release APK without explicit user approval. Persistent save/migration remains deferred.
