# Godot migration plan
## Strategy
Build a parallel native implementation under `godot/` on a dedicated branch. The existing web/Android project remains intact and is the source of truth for current rules and content until each migration slice passes parity checks. No main-branch deployment and no replacement of the current APK during the prototype phase.

## Architecture
- `core/`: deterministic rules and state; no scene-tree or rendering dependencies.
- `scenes/`: game screens and reusable scene composition.
- `scripts/`: controllers and presentation glue.
- `actors/`: 3D Buddy scenes, rigs, animation state machines.
- `art/`: licensed/owned textures, materials, meshes, audio.
- `tests/`: deterministic rule tests and migration fixtures.
- `docs/`: design decisions, parity matrix, checkpoints.

The first commit uses a small playable 2D vertical slice to validate project boot, portrait scaling, input, and core board rules. The 3D character showcase is introduced after this foundation is stable.

## Migration gates
1. **KT-GODOT-001 — Foundation:** project opens, scene runs, portrait layout adapts, touch and keyboard controls work.
2. **KT-GODOT-002 — Rules parity:** compare board dimensions, tetromino definitions, rotation, collision, gravity, lock, line clear, score, and level rules against the current implementation.
3. **KT-GODOT-003 — Visual target:** build one hero-quality 3D Buddy, a dimensional tile material, lighting, and a polished menu scene.
4. **KT-GODOT-004 — Mode parity:** migrate modes one by one with objective/reward/timer fixtures.
5. **KT-GODOT-005 — Android device QA:** real-device input, safe areas, thermal/performance, pause/resume, audio focus, save migration.
6. **KT-GODOT-006 — Release candidate:** signed APK/AAB, crash-free smoke test, store assets, rollback plan.

## Guardrails
- Never change the old implementation while building Godot parity unless explicitly requested.
- Never claim parity based on appearance alone; use test fixtures.
- Keep gameplay rules separate from visual effects.
- Do not introduce the removed 3D arena into gameplay. The board stays a 2D play surface.
- Do not build a release APK until the user explicitly resumes packaging after visual approval.

## First vertical slice
A portrait game scene with a 10×20 board, falling pieces, rotation, left/right movement, soft drop, hard drop, line clears, score, level, restart, and large touch controls. It is intentionally a mechanics and layout proof, not the final art pass.
