# Block Buddies — Godot Edition
## Product vision
A premium-feeling, portrait-first arcade puzzler for Android. The playfield remains a crisp, readable 2D grid; the world around it is a stylized 3D toy universe. Five block-shaped buddies are the emotional center of the game: expressive, collectible, animated companions with distinct silhouettes and personalities.

## Pillars
1. **Instant readability** — every cell, target, timer, and action remains legible on a phone.
2. **Tactile satisfaction** — blocks land with weight, soft squash, a clean impact sound, and restrained particles.
3. **Character-first charm** — heroes react to combos, near misses, victories, and daily challenges.
4. **Fair progression** — skill earns progress; no pay-to-win pressure and no gameplay-critical paywalls.
5. **Fast sessions** — a run is easy to start, understand, pause, and resume.

## Visual direction
- Working title: **Block Buddies**.
- Art direction: premium collectible vinyl toys meets cosmic arcade cabinet.
- Palette: deep midnight navy, electric cyan, warm gold, violet, mint, coral.
- Board: 2D orthographic presentation with dimensional tile materials, bevel highlights, contact shadows, and restrained glow.
- Characters and menu environments: real-time 3D scenes, soft studio lighting, readable silhouettes, subtle idle animation.
- Avoid visual noise behind the playfield. The board always wins the hierarchy.
- Android renderer target: Godot 4.x Compatibility / OpenGL ES 3 for broad device coverage; profile before considering Mobile renderer.

## Core game loop
Start a mode → play a short block-placement run → clear lines / complete objectives → receive score and progression → celebrate with the selected Buddy → return to the mode hub.

## Modes to preserve from the existing game
The migration audit must map every existing mode before implementation. Candidate mode families include Classic/Arcade, timed challenge, daily challenge, and objective/monster encounters. Exact names, rules, rewards, and unlock conditions must be copied from the source project, not recreated from memory.

## Character direction
Five original block-shaped heroes, each with a distinct color identity, face language, idle loop, celebration, and failure reaction. Existing approved character portraits and assets are references; do not silently redesign character identities during migration.

## Controls
- Large thumb-safe left / right / rotate / soft-drop / hard-drop targets.
- Optional swipe and edge-tap gestures after the button layout is stable.
- No action may depend on a tiny target or a gesture with ambiguous meaning.
- Keyboard controls remain available for desktop test harnesses.

## Accessibility and comfort
- High contrast and scalable UI.
- Haptics and screen shake are independently configurable.
- Reduced motion option.
- Never communicate game state by color alone.

## Non-goals for the first vertical slice
Online accounts, cloud sync, monetization, marketplace, social leaderboard, and a full cosmetic inventory. These are later product decisions, not foundations for the first playable build.
