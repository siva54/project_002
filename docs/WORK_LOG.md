# Work log

## 2026-09-12 12:00 CDT — initial concept research

- Confirmed `project_002` was empty and found no applicable parent `AGENTS.md` files in the inspected parent directories.
- Reviewed the supplied IGN page through the browser and Phosphor's developer Q&A through web research. IGN lists Project Awakened as canceled.
- Created a README and a proposed concept with a bounded first playable, acceptance criteria, implementation sequence, and source links.
- Confirmed the installed Godot executable reports `4.7.2.stable.official.ed1daf0bf`; no engine project has been created.
- Asked which aspect of the reference matters most. Priority, engine, and platform choices remain open at this entry.
- Next work: incorporate owner preferences, establish the engine project, and implement the movement playground.
- Validation: documentation review only; there is no executable code or test suite yet.

## 2026-09-12 13:00 CDT — Hero Lab first playable

- Owner selected creating a hero and combining powers as the leading priority.
- Created a standalone Godot project under `client/`, plus a macOS `play.command` launcher. No files in project_001 were changed.
- Implemented three selectable power slots from Energy Bolt, Blink, Telekinesis, and Cloak, with signature color selection and session-local loadouts.
- Added third-person movement, aiming, jumping, sprinting, a small arena, physics crates, and five stationary sentinels with visibility checks and last-position search behavior.
- Added resource costs, cooldowns, cloak breaking on attack, physical crate impacts, collision-aware Blink, wall-aware crate holding, score, defeat, reset, and a pause/build menu.
- Fixed ray endpoint precision after aimed-hit testing and made downward aiming preserve usable Blink travel along the ground.
- Verification: Godot editor import passed; the final rendered integration suite completed **38 checks with zero failures** on Apple M2/OpenGL compatibility. The earlier headless suite also passed before the final held-crate wall check was added. Launcher passed `zsh -n`.
- Generated and visually reviewed `docs/qa/hero-builder.png` and `docs/qa/power-playground.png` in the actual renderer. UI is readable at the authored 1280 × 800 size.
- Current limits: capsule avatar, placeholder geometry, stationary enemies, no audio or animation, no persisted builds, and no campaign or detailed appearance editor. This is a power playground, not the full planned mission.
- Handoff: playtest the four powers and choose the next priorities for character appearance and power interactions. Future mission scope and references are in `docs/CONCEPT.md`.
- Research-browser cleanup was interrupted by a notification permission prompt; browser control was returned to the owner. Research was already complete and no further browser action was attempted.

## 2026-09-12 20:00 CDT — animated, textured combat POC

- Owner requested walking and attacking animation, free internet assets, textured surfaces, and effects with 3D depth.
- Added Quaternius/Tomás Laulhé's CC0 RobotExpressive GLB from the official three.js distribution, preserving Don McCurdy's upstream notes. Added ambientCG Concrete030 and Metal032 1K material maps. Sources, download checksums, and CC0 text are bundled; see `docs/THIRD_PARTY.md`.
- Replaced capsule and sphere visuals with animated robots. Imported idle, walk, run, jump, and punch clips now drive movement and attack poses. Added acceleration/deceleration and movement-facing rotation.
- Introduced separate avatar, PBR material, projectile, and VFX modules. Added textured concrete, metal decks, a loading door, pillar bands, and reinforced crates.
- Replaced all line attacks with traveling 3D energy orbs, sphere shells, torus meshes, mesh particles, and local lights. Enemy attacks can be dodged and stop at cover. Cloak removes tracking but does not make the hero immune to an already-fired projectile.
- Added F-key melee with animation, windup, cooldown, distance/facing checks, and cover occlusion. Telekinesis has a rotating 3D aura; Blink has departure/arrival volumes; cloak uses translucent character materials and an aura.
- Pausing freezes projectiles and animations; reset removes pending attacks and restores movement state. Fixed residual attack slowdown on reset, surface-hit aiming precision, and headless shader-uniform tween handling.
- Verification: final rendered integration suite passed **51 checks, zero failures**, including real projectile/crate collisions, thin-cover blocking, melee misses and timing, animation selection, and pause/reset. Earlier headless iteration passed 48 checks before adding the three cover/facing cases. Godot import is clean with tangent generation disabled for the source model's UV-free meshes.
- Visually reviewed action captures under `docs/qa/`; `capture_actions.gd` reproduces the animation/effect screenshots at fixed 60 FPS. No paid asset, third-party code dependency, or runtime network call was added. Runtime assets total approximately 5 MB.
- Remaining POC limits: stylized robot, stationary training enemies, no advanced foot IK, no audio, and session-only customization. Next decisions can be based on playtesting this animation/combat pass.

## 2026-09-12 20:09 CDT — initial Git repository handoff

- Owner authorized committing all project changes and pushing to `git@github.com:siva54/project_002.git`.
- Confirmed the remote was empty; initialized the local repository on `main` and configured `origin` to the requested SSH URL.
- Prepared the complete prototype source, bundled assets and licenses, documentation, launcher, and QA screenshots for the initial commit. Godot's generated cache and local QA logs remain excluded by `.gitignore`.
- Pre-commit verification: Godot headless editor import passed, the rendered integration suite passed **51 checks with zero failures**, and `zsh -n play.command` passed.

## 2026-09-12 21:00 CDT — six powers and explicit opening selection

- Owner requested two more superpowers and emphasized choosing three powers at the beginning.
- Added Shockwave (six-metre, cover-aware area damage and physics impulses on loose crates) and Energy Shield (five seconds of protection against incoming enemy energy, with an eight-second cooldown). Both use authored 3D meshes and layered effects; no additional downloaded assets are required.
- Opening now starts with three empty slots. A two-column grid displays all six powers, costs, cooldowns, and descriptions. The assigned key order is shown in both cards and a three-slot preview. Entry requires exactly three valid, distinct selections; a fourth selection is rejected until one is removed.
- Shield remains active while moving and attacking, pauses with the game, expires normally, and clears on reset or unequip. Removing Cloak likewise clears its active effect. Arena reset preserves the selected build.
- Updated capture tools to explicitly choose their test builds, added selected-build/Shield/Shockwave screenshots, and updated the README and concept notes.
- Validation: clean Godot editor import; **57 existing integration checks and 43 dedicated power/selection checks passed** in both headless and rendered runs. Coverage includes all twenty distinct builds, initial empty/incomplete selection rejection, actual incoming-projectile blocking, Shield expiry, Shockwave range and cover, crate movement, and swapping/reset cleanup.
- Visually reviewed the initial and selected three-slot screens plus both new effects at 1280 × 800. Preparing this update for commit and push to `origin/main` under the owner's existing instruction.

## 2026-09-12 22:00 CDT — reactive sentinel combat playground

- Replaced static target logic with reusable `SentinelController` actors. Each sentinel now patrols, investigates nearby power/crate noise, searches a last-known location after losing sight, maintains combat distance while strafing, and fires a physical energy projectile when engaged.
- Direct hits now preserve health state, play a stagger response, notify nearby sentinels, and leave a short visible shutdown before removal. Bolts, melee, Shockwave, Blink, and Telekinesis all report noise through the same encounter reaction path.
- Updated the player-facing scope and controls notes so the actual behavior and remaining tactical limits are clear.
- Verification: clean Godot editor import; **64 integration checks and 43 dedicated power/selection checks passed** headlessly. The macOS Metal renderer completed the fixed-FPS action capture run successfully, and its regenerated gameplay captures were visually reviewed.

## 2026-09-13 09:00 CDT — objectives and exploration content

- Added a central Power Relay with an animated 3D core, in-world status label, HUD progress, and a concrete reward: full energy plus 30 vitality when it reaches 100% charge.
- Energy Bolts, Shockwaves, melee strikes, and thrown crates can charge the relay, so different three-power builds have useful environmental interactions beyond direct damage.
- Added four floating power cells across the arena. Jade cells restore energy, coral cells restore vitality, and each has an animated, emissive 3D presentation.
- Verification: clean Godot editor import; **69 integration checks and 43 dedicated power/selection checks passed** headlessly. The fixed-FPS Metal capture completed with the new relay objective, and the rendered relay screen was visually reviewed at 1280 × 800.

## 2026-09-13 10:00 CDT — combat feel and performance pass

- Reduced the cost of combat effects by lowering procedural mesh detail, reducing burst particles, skipping small-impact lights, shortening transient lifetime, and removing CPU particles from every in-flight projectile. A global transient-effect cap prevents repeated impacts from accumulating frame work.
- Limited the encounter to three concurrent hostile projectiles and sampled sentinel line-of-sight at 120 ms intervals, preserving reactive behavior while avoiding repeated physics queries each frame.
- Added a brief cast flash to Energy Bolt, slowed the shared punch clip, and gave sentinel fire a 220 ms animation wind-up. The visual action now precedes the damaging projectile instead of occurring simultaneously.
- Verification: clean Godot editor import; **70 integration checks and 43 dedicated power/selection checks passed** headlessly. Fixed-FPS Metal captures were regenerated and the Energy Bolt and melee frames were visually reviewed.

## 2026-09-13 11:00 CDT — Seeker Missiles

- Added Seeker Missiles as the seventh selectable power. It spends 40 energy to launch three lightweight gold missiles in a staggered volley toward visible sentinels.
- Each missile uses bounded steering, verifies line of sight every 120 ms, and drops to a harmless ballistic path if cover appears or its acquired target is removed. The implementation reuses the bounded projectile/effect system from the performance pass.
- Updated the build UI, catalog, concept, README, automated combination coverage, and rendered capture plan for seven powers and 35 possible three-power builds.
- Verification: clean Godot editor import; **70 integration checks and 62 dedicated power/selection checks passed** headlessly. Both renderer capture scripts completed on Metal, including the seven-power builder and Seeker Volley action frame.
