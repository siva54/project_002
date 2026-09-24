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

## 2026-09-15 10:00 CDT — grounded human combatant presentation

- Replaced the runtime robot with authored, tactical human silhouettes: adult proportions, helmet, visor, vest, armor, limbs, boots, and restrained team accents. The previous RobotExpressive GLB remains bundled only as a documented legacy reference.
- Rebuilt idle, locomotion, jump, and punch presentation as procedural poses so the existing movement, melee, sentinels, and powers continue to work without an unavailable external human-model download.
- Darkened the environment, lowered ambient fill, increased fog, and shifted the sun to a neutral hard light for a more serious industrial-combat tone.
- Verification: clean Godot editor import; 70 integration and 62 dedicated selection/power checks headlessly. Both capture scripts completed on Metal; human combatant walking, projectile, and melee screens were reviewed at 1280×800.

## 2026-09-15 12:00 CDT — digital-human replacement

- Replaced the temporary block-built tactical silhouette with the locally bundled CC0 Vitruvian digital-human body and face. Every hero and sentinel now has smooth adult anatomy, clothing, footwear, facial geometry, and the pack’s authored idle and walk animation clips.
- Kept combat functional by repurposing the pack’s compact Wave clip as the melee motion and using a lightweight chest patch for team identity. The source package’s hair physics and custom look-development shaders are intentionally excluded from this POC to preserve its smooth frame time.
- Updated source records, credits, README, concept, and renderer captures for the asset-backed presentation.
- Verification: clean Godot editor import; 70 integration checks and 62 dedicated power/selection checks passed headlessly. Both capture scripts completed on Metal, including the walking and melee human-combat frames.

## 2026-09-21 01:46 CDT — Portable Windows and macOS Make commands

- Added `make play`, `editor`, `doctor`, `import`, `check`/`test`, and `smoke`, with OS-aware Python selection and Godot discovery on PATH, macOS app/Homebrew locations, and nested Windows WinGet packages. Explicit executable paths with spaces are supported.
- Checks import assets then run both existing game suites sequentially, stop on failure, and reject Godot script errors even when the process exits zero. README documents GNU Make/Python/Godot prerequisites and overrides; no neighboring repository dependency.
- Validation: native macOS doctor and `make check` passed (both game suites); eight Python launcher tests passed, including mocked Windows discovery and error handling. Native Windows execution remains unverified.

## 2026-09-21 02:10 CDT - Martial arts attacks and physical grapples

- Replaced the reused Wave attack with original skeletal lead-jab, rear-cross, and front-kick clips for the bundled human rig, plus a guard, anticipation, torso rotation, recovery, and a single late-input buffer. F chains the three strikes; damage timing shares the animation profiles. Attack direction stays committed through contact, and sprint animation speed cannot speed up a strike independently of its damage.
- Added G-key forward throw and leg sweep, alternating after successful releases. Acquisition requires a nearby grounded target in front with clear line of sight. A short clinch stops movement and enemy shooting, followed by gravity/velocity-driven CharacterBody3D flight with arena, prop, and actor collisions, one landing hit, and brief survivor recovery. Pause preserves throw momentum; reset clears pending grabs and combo input. This is capsule-based physics, not a jointed ragdoll or motion-capture asset pack.
- Separated sentinel hit reactions from attacks, added small contact-only melee bursts, and updated the builder and HUD controls, README, and concept scope. Existing power builds remain available. No new third-party assets or dependencies.
- Added run_martial_tests.gd to the standard check command: 31 checks covering non-looping clips, sprint/contact synchronization, combo order/buffering/reset, hit timing, action conflicts, pause, grounded grabs, launch/landing/recovery, wall collisions, facing/cover rejection, and reset cleanup. Fixed the existing launcher test's Mac-path mock to use Path equality so it also runs on Windows; added coverage that the launcher includes the new suite.
- Verification on Windows/Godot 4.7.2: `python tools/project.py check` passed all three game suites; `python -m unittest discover -s tools/tests` passed 9 tests; `git diff --check` passed. Real-renderer `capture_martial_arts.gd` and `capture.gd` completed at fixed 60 FPS. Reviewed jab, front kick, throw, sweep, and updated builder screenshots in docs/qa/.
- Handoff: F for jab/cross/kick, G for throw/sweep. Changes remain uncommitted. Owner playtest should assess cadence and grapple reach before further combat expansion.

## 2026-09-21 02:49 CDT - martial-arts-only Flow State rework

- Owner rejected the previous procedural pass and confirmed fast, acrobatic kung fu. Normal launch now opens a dedicated martial arts courtyard with three melee bouts. The power builder remains only in the legacy Hero Lab scene.
- Retargeted actual Quaternius clips and CMU captured kicks/backflip to the human skeleton, with bundled sources, reproducible baking, hashes, and license notices. Added combinations, aerial spin kick, directional acrobatic evasion, guard/deflection, stamina, contact feedback, and recovery. Corrected roundhouse damage to coincide with extension and normalized supporting-foot height while preserving captured aerial elevation.
- Added close clinch/throw and eleven-body jointed ragdolls for throws and heavy knockdowns, world collisions, pause, and surviving-opponent recovery. Interrupted or defeated grapplers release their victim. The clinch still uses an approximate animation and needs a bespoke paired performance; this remains a prototype.
- Verification: all four game suites passed via `python tools/project.py check`, including 51 active-mode checks. The active suite also passed with the real renderer before the final two foot/contact checks were added; those two passed headlessly. Python launcher tests passed 9 tests. Default startup smoke passed, and the 611-frame real-renderer capture completed without errors. Reviewed the action captures and refreshed `docs/qa/kung-fu-preview.mp4`; `git diff --check` passed.
- Handoff: LMB combination, RMB aerial spin kick, Q guard/deflect, Space evade, G throw, WASD/mouse movement/camera. README now describes the active mode and remaining animation limitations. Changes remain uncommitted.

## 2026-09-21 03:32 CDT - Sleeping Dogs reference and connected-exchange correction

- Owner rejected the Flow State result and named Sleeping Dogs as the expected reference. Recorded that the quality target remains unmet. Inspected source clips and measured animated hand positions; previous punch damage could trigger at 1.55 m despite a fist extending roughly 0.47 m. The library-2 hook also collapses the upper body and was removed from the active combination.
- Added collision-respecting approach during the windup and a fist-to-animated-upper-body contact check for jab/cross. A punch hits at most one opponent. Head reactions and contact effects now accompany those strikes; moved the camera closer for review. Kicks and legacy grapples retain their existing limitations.
- Timed frontal guard now deflects and follows with one stronger cross. Counter interruption cancels the queued retaliation, and a live incoming strike plus guard input is covered by integration tests. This is a functional sequence assembled from existing clips, not bespoke paired counter choreography.
- Verification: all four game suites passed via `python tools/project.py check`; the active suite has 58 checks, including out-of-reach misses, actual contact spacing, cover during approach, guard-input counter timing, and interruption. Recorded/reviewed the 264-frame real-renderer exchange; hero retained 100 health and rival lost exactly 12 + 16 + 24 health from two punches and the counter. Saved `docs/qa/combat-exchange.mp4` and contact/deflection frames. No new external assets or licenses.
- Handoff: overall owner request is still not at the requested animation standard. Existing clips lack paired grappling and the current throw is still approximate. Future work must address coordinated body motion, grip, release, footwork, and recovery rather than claim that additional isolated clips make a Sleeping Dogs-quality result. Changes remain uncommitted.

## 2026-09-21 04:29 CDT - full connected-combat controller and animation revamp

- Owner explicitly requested an entire combat revamp: smooth connecting movement like Sleeping Dogs, many punches/kicks, and no floppy ragdolls. Replaced the active fighter/controller and visual playback layer. The active scene creates no physical bones and has no ragdoll transition, physics launch, backflip dodge, or aerial-spin default attack.
- Added a fourteen-strike catalog with an explicit punch/kick graph: jab, cross, lead/rear hooks, body cross, uppercut, backfist, elbow, stepping straight, front/low/roundhouse/side kicks and knee. Inputs buffer early and blend into recovery links without an idle reset. Hand strikes retain locomotion, aiming selects the next opponent, and approach assistance respects collision and cover. Actual hand, elbow, knee or foot positions gate damage once per strike.
- Added captured side-kick, stepping-strike and boxing source material, recorded its URLs/hashes and credits, and rebuilt the animation bank. New motion combines captured base clips with project-authored trajectories, torso adjustments, analytic two-bone constraints, lower-body locomotion and live-pose blending. Corrected source kicking-side mismatches, knee reach, and wrist/foot orientation while reviewing rendered poses. These are constructed variants and paired sequences, not fourteen new mocap performances.
- Added timed counters, grounded sidesteps, directional head/body/leg reactions, and animated knockdown/defeat/recovery. A clinch constrains both actors under one clock; LMB selects knee takedown and RMB selects sweep. Contact, release and fall share that clock. Interrupted, timed-out, lethal and completed pairs clean up partner references and collision exceptions. World collision remains active.
- Bouts now have two, three and four melee opponents. Inactive rivals circle while an opponent attacks. Updated camera framing, controls, title and paused Tab move guide; replaced README/current concept descriptions so they reflect the new controls and no-ragdoll requirement.
- Verification: `python tools/project.py check` passed all four game suites, including the then-current 90 active checks. Added two further movement/retarget contact assertions; the full active suite passed **92 checks, zero failures** with the real OpenGL renderer at fixed 60 FPS. Default startup smoke passed. Fixed audio teardown so immediate test exit releases playback cleanly. `git diff --check` passed.
- Recorded and visually reviewed 949 rendered frames (15.82 seconds) covering linked punches, movement, kicks, counter, both clinch branches, controlled falls/recovery and the move guide. Saved `docs/qa/flow-revamp.mp4`, gameplay frames and the strike-pose sheet. The video uses a scripted sparring fixture and resets between sections; it is not presented as an uncut natural bout.
- Handoff: LMB punches, RMB kicks, WASD movement/aim, Q guard/counter, Space sidestep, G clinch then LMB knee/RMB sweep, Tab moves. Changes remain uncommitted. The human/arena art and constructed animation still have prototype limitations; the owner's Sleeping Dogs production-quality expectation has not been claimed as achieved or accepted.


## 2026-09-21 04:52 CDT - paired counter finishers and recovery correction

- Owner rejected the previous pass: no counter finisher, disconnected movement, and limp-looking animation. Inspection confirmed that perfect guard merely queued an ordinary punch and recovery played the death clip backward. Replaced both paths.
- Timed Q now binds attacker and defender to one 1.82-second sequence. Incoming punches select wrist interception, elbow and inside leg reap; incoming kicks select deflection, knee and finishing straight. Damage occurs at 0.48 and 0.98 seconds (20 then 80), and the victim remains owned until the landing completes. Completed and interrupted counters release partner references and collision exceptions. The next punch/kick can be buffered during final recovery and target a different opponent. Bout transitions wait for the paired move to finish.
- Added enemy anticipation and overhead attack/Q timing cues. Removed normal-hit animation pauses. Replaced broad hit clips with short torso/head/leg recoils that retain guard, corrected the sweep wind-up, and constrained falling arms into a protective/bracing pose. Recovery now plays the existing forward GetUp source clip. No new external assets were needed.
- Camera focus stays with the paired opponent, smooths target changes, and eases its field of view during close sequences. Updated the move guide, entry copy, README and current concept.
- Verification: full project check passed all four suites. The expanded active suite passed 120 checks, zero failures, both headlessly and with the real OpenGL renderer. Coverage includes both incoming attack types, staged single-contact damage, close animated limb contact, pause, interruption, low-stamina completion, partner cleanup and buffered handoff to another opponent. Default startup smoke and whitespace checks passed.
- Recorded the 900-frame continuous live-AI counter bout and next-group combat as docs/qa/counter-finishers.mp4. Inputs are scripted; the second rival is initialized to open with a kick, and there are no fixture resets inside this capture. Recorded the isolated 270-frame sweep/get-up sequence as docs/qa/controlled-recovery.mp4. Reviewed rendered sequences using contact sheets and individual frames, including after correcting the sweep. Prior videos remain historical captures.
- Handoff: tap Q at the overhead cue for the finisher, or hold Q for ordinary guard. Fourteen attack branches and both G clinch follow-ups remain available. Changes are uncommitted. The choreography is still constructed from the existing source clips and constraints; the owner's Sleeping Dogs quality target remains subject to actual playtest, not established by the passing checks.


## 2026-09-21 05:20 CDT - full-body motion replacement and three-hit counters

- Owner reiterated smooth, believable human combat and strong finishers, naming Sifu, Sleeping Dogs and Acts of Blood. During the pass, they explicitly rejected the continuing doll-like appearance. Changed the animation foundation rather than treating additional effects as sufficient.
- Rebuilt the bank with six trimmed boxing sequences from the already bundled CMU 14_01 take. The main punch chain now preserves full-body source rotations. Eleven move entries preserve captured hips, shoulders and legs; variants can share a source performance. Selected a sweeping left hook from frames 2355-2420, and corrected the side kick on the whole body instead of pulling its foot forward. No new third-party files were downloaded.
- Stored captured planar movement in clip metadata and applied it through CharacterBody3D collision. Removed the run-cycle lower-body overlay and broad procedural strike arcs from captured attacks. Limited contact correction to 7.5 cm near impact and kept the follow-through target fixed. Slowed kicks to retain their chamber and recovery. The knee uses the captured kick chamber, while elbow/low-kick/knee adjustments and paired grips remain constructed. Preserved a captured guard stance.
- Added bounded outgoing angular motion to transitions. Whole-body hit clips now compress promptly after contact and recover over the remaining reaction interval. Source motion, movement, limb contact, collision and buffering remain integrated; the animation changes do not introduce ragdolls.
- Expanded both counters to three contacts at 0.34, 0.68 and 1.16 seconds, dealing 15/20/65 damage. Punch counter: shovel hook, elbow, sweeping drive. Kick counter: knee, turning hook, driving side kick. Final landing feedback occurs at 1.64 seconds; ownership ends at 2.08 seconds, with buffered attacks handing off to another opponent. Added eased side framing, directional camera response, differentiated generated impact/landing sound and brief floor dust.
- Verification: full project check passed all four suites. The active suite reached 132 passing checks headlessly and with the real OpenGL renderer; the final hook-source adjustment was rechecked headlessly and in the final gameplay capture. New checks cover early recoil, torso/wrist continuity, fixed follow-through targets, preserved captured hips/legs under movement, root travel, all three counter contacts, single landing feedback at floor height, interruption and cleanup. Startup smoke passed. Whitespace check passed with Windows CR-at-EOL handling.
- Recorded the final 900-frame continuous encounter to docs/qa/contact-flow.mp4 and reviewed rendered strike/counter sequences. The recording uses scripted attack/guard inputs, close starting positions and a kick-opening second opponent, with live AI and no resets within the recording. Updated README, concept, move guide and third-party technical notes. Diagnostic source studies and peak measurements are reproducible through the added study scripts.
- Handoff: changes remain uncommitted. The latest build replaces much of the rejected procedural motion, but character art and constructed paired choreography remain weaker than the named commercial references. Passing checks establish functional behavior, not owner acceptance or equivalent production animation quality.

## 2026-09-21 06:10 CDT - grounding and basic exchange correction

- Owner rejected the full-body pass as sloppy. Focused this revision on the jab-cross foundation instead of adding more move variants. Measured a 26-degree lead-arm mismatch at the old jab-cross cut and about 44 cm of support-foot travel across the retargeted roundhouse. These measurements included the old root translation, not just local limb motion.
- Made jab and cross consecutive portions of CMU 14_01 with one heading (584 start, 623 cut, 688 end), retimed cross contact, and shortened the blend for that connection. The corresponding lead-arm mismatch is now below one degree. Reconstructed grounded root travel from the retargeted supporting foot, with support selection hysteresis; retained original translation metadata for diagnostics. Front and round kicks now receive whole-body heading correction too.
- Replaced accumulated chase velocity with a bounded approach step that finishes before impact. Turning eases during that step and stays fixed through contact; movement input contributes to the step and recovery. Collision still constrains travel. This removes the extra translation/rotation that previously fought the captured support leg.
- Replaced the relaxed pre-performance idle with an active guard from frames 480-520. Inspection showed the Quaternius hit clips start already struck and end neutral. Recoil now uses that neutral reference, builds into impact over 70 ms, and applies bounded torso/head motion to the actual struck pose while retaining arms and stance. It no longer switches the entire character into an unrelated standing pose.
- Verification: full project check passed all four suites. The active suite passed 137 checks headlessly and with the real OpenGL renderer. Added world-space support-foot drift checks through impact for jab/front/round/side kick (under 2.5 cm), and a 1.5 cm continuity bound on hands/head/feet at the one-two source cut. Existing move contact, direction changes, moving attacks, cover, counter branches, interruptions and recovery checks passed. Startup smoke and Windows-aware whitespace checks passed.
- Recorded `docs/qa/grounded-exchange.mp4`: an 11-second labeled animation study with fixture resets, fixed three-quarter and side views, jab-cross, front kick and punch counter. Ordinary AI is disabled; this is not a live-bout recording. Reviewed rendered sequences/contact sheets and individual contact poses. Added reproducible capture and measurement scripts. No new external assets or licenses.
- Handoff: changes remain uncommitted. The basic exchange now has measured continuity and grounding fixes. The model, other source transitions, constructed close moves and paired finishers still need stronger authored choreography; this does not establish Sifu/Sleeping Dogs/Acts of Blood quality or owner acceptance.

## 2026-09-24 - karate source and opponent positioning

- Studied the Sifu animation director's account of hand-posed gameplay and heavily reworked takedowns, Epic's target-aligned motion windows, and CMU's Shotokan karate capture. Added licensed CMU subject 135 take 02 to the local source bank for a distinct raised-knee straight and directional defensive slips. Recut take 09 for a stepping straight. Rebuilt the bank and recorded source provenance and SHA-256.
- The bake now records the attacking limb's source-space contact position. Target approach uses that position and the opponent's current pose. A guarded step covers missing reach before the strike starts, avoiding the previous half-meter body drag through a planted jab. Both slips now use captured left/right body motion instead of translating an idle pose.
- Updated the Tab guide, move catalog labels, README and motion design notes. Recorded `docs/qa/karate-positioning.mp4`, a labeled 750-frame fixture review of the angled one-two, both karate straights and both slips. Reviewed rendered contact frames. It is a scripted pose review, not a live AI bout.
- Verification: all five full-check stages passed, including the active suite with 146 checks; the same suite passed with the OpenGL renderer. Support-foot drift after the guarded approach is under 6 cm in the measured contact window, and the original planted impact checks remain under 2.5 cm. Startup smoke, nine Python launcher tests, source hash and whitespace checks passed.
- Limitation: the character rig and especially assembled two-person counters, falls and reactions remain prototype quality. This pass does not establish equivalence to Sifu, Sleeping Dogs or Acts of Blood; visual feel needs owner playtest and dedicated paired animation direction.

## 2026-09-24 - faster checks and ready stance

- The Project 2 check runner now drives all Godot test suites with a fixed 60 FPS clock. This preserves their frame-based contact assertions while avoiding wall-clock pacing. Added `python tools/project.py check combat` for active-combat iteration; the full check remains available. Local full-check time fell from roughly 55 seconds to 8.5 seconds, with all suites passing.
- Replaced the square, sideways-spread ready stance with a narrower lead/rear foot placement, slight forward torso angle and asymmetric jaw-level guard. The constraints fade under movement and blend into source attacks. Added stance geometry checks; the active suite now has 148 passing checks.
- Captured and reviewed front and side views of the stance, then refreshed `docs/qa/karate-positioning.mp4`. The revised posture is an incremental prototype improvement; motion and character art remain below the owner's commercial-game reference.
