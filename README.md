# Project 002 - Flow State

A third-person martial arts combat prototype rebuilt around connected punch/kick combinations, moving strikes, counters, and controlled paired takedowns. Sifu, Sleeping Dogs and Acts of Blood are the owner's references for combat feel; this remains a prototype with simpler art and animation.

Double-click `play.bat` (Windows) or `play.command` (macOS), or run `python tools/project.py play`. Enter the courtyard to fight three groups of two, three, and four opponents. There is no power-selection screen in the active game.

## Controls

| Control | Action |
| --- | --- |
| WASD | Move during combat; aim toward the opponent for the next strike |
| Mouse | Orbit the camera |
| LMB | Punch branch; stepping straight when initiating while moving |
| RMB | Kick branch |
| Q | Hold guard; tap at the overhead Q cue for a paired counter finisher |
| Space + WASD | Grounded sidestep; without direction, step backward |
| G | Clinch a close opponent |
| LMB / RMB in clinch | Knee takedown / leg sweep |
| Tab | Pause and open the move list |
| Esc | Pause / resume |
| R | Restart all bouts |

Queue the next punch or kick during an attack. Follow-ups blend in during recovery instead of returning to idle. Changing input changes the next move; holding a movement direction lets you step through hand strikes and select another opponent. A timed Q intercepts the incoming attack and starts a three-contact finisher: wrist interception, shovel hook, elbow and sweeping drive against punches; deflection, knee, crane straight and driving side kick against kicks. The contacts deal 15, 20 and 65 damage, synchronized to the paired choreography. You can buffer the next attack during the landing to continue into another opponent. Holding Q remains a normal guard. Clinches release after a short timeout if you do not choose a follow-up.

## Moves and combinations

Fourteen strikes have individual limb paths, timings, reactions, costs and transitions: jab, cross, lead hook, rear hook, shovel hook, uppercut, crane straight, elbow, stepping karate straight, front kick, low round kick, high roundhouse, side kick, and knee. The clinch adds knee and sweep takedowns, and timed guard adds two paired counter finishers.

| Input route | Combination |
| --- | --- |
| Repeated LMB | Jab > Cross > Lead hook > Rear hook > Uppercut > Crane straight > Elbow |
| Repeated RMB | Front kick > Side kick > Low kick > Roundhouse |
| LMB, RMB, LMB, LMB | Jab > Low kick > Shovel hook > Uppercut |
| LMB, LMB, RMB, LMB | Jab > Cross > Knee > Elbow |
| RMB, RMB, LMB | Front kick > Side kick > Stepping karate straight |
| G, then LMB or RMB | Hold > Knee takedown or Sweep |
| Timed Q against a punch | Intercept > Shovel hook > Elbow > Sweep and drive |
| Timed Q against a kick | Deflect > Knee > Crane straight > Driving side kick |

Later uppercuts and strong kicks can end a chain with a controlled knockdown. Continue toward another opponent while the fallen opponent recovers. The active mode creates no physical ragdoll bodies: strikes, defeats, paired takedowns, and recovery stay animated. Collision still governs movement and walls, and only a limb that reaches the opponent can deal strike damage.

[Karate positioning review](docs/qa/karate-positioning.mp4)

The latest recording isolates an angled jab-cross, a crane straight, a stepping karate straight, and both defensive slips. Each labeled section resets the sparring fixture; inputs are scripted and ordinary AI is disabled. It is an animation review, not a continuous live bout. Earlier videos, including `grounded-exchange`, describe superseded builds.

The main chain uses captured body motion with hip turns, shoulder rotation, leg motion and weight transfer. Captured attack entries include two distinct karate straight performances; some other moves still share a source performance at different timings. Jab and cross are consecutive parts of one take with a shared heading. Translation is reconstructed from the retargeted support foot so the performer's different proportions do not cause skating. Captured hand/foot contact positions set target approach distance. When the opponent is out of the captured reach, the fighter takes a guarded step before the strike begins; facing settles with that step, and movement input resumes through recovery. Contact correction is capped at 7.5 cm. The elbow, low kick and knee retain constructed adjustments.

Transitions retain outgoing angular motion. The idle now places the lead foot ahead of a narrower rear foot, turns the torso slightly into range, and keeps one hand forward while the other protects the jaw. It eases back to captured movement and strikes. Hit recoil is applied to the pose that was struck, retaining the hands and lower-body stance before recovering to guard; it no longer replaces the body with an unrelated standing pose. Normal strikes do not pause the animation clock. Counter framing eases toward a side view, with directional camera response and separate finishing/landing audio. Landing feedback occurs when the body reaches the floor.

## Animation and scope

Quaternius and CMU source motion supply the body animation. The primary punch chain uses trimmed sequences from CMU subject 14 take 01; the new crane straight and defensive slips use subject 135 take 02, and the stepping straight uses subject 135 take 09. Kicks also use subject 135. Front, side and round kicks are oriented as whole-body actions toward the opponent. The bake stores corrected planar travel, support-foot and strike-contact metadata for collision-respecting movement. Procedural constraints remain for small contact corrections, selected close moves, and grips. Paired counters and takedowns are constructed sequences rather than captured two-person performances. All source assets and baking code are bundled locally. [Motion design references and limitations](docs/COMBAT_MOTION.md) explain the approach.

The model, arena, footwork and choreography remain prototype quality. This build does not reproduce Sleeping Dogs' production animation library, environmental finishers, open world, character customization, controller support or saved progression. Hero Lab remains a legacy scene at `client/scenes/hero_lab.tscn`.

## Development

Requires Godot 4 and Python 3. `make play`, `make check`, `make smoke`, and `make editor` are aliases when GNU Make is installed. The launcher discovers Godot on PATH, Windows WinGet, and macOS app/Homebrew locations.

```sh
python tools/project.py check
python tools/project.py check combat  # fast active-combat iteration
python tools/project.py smoke
python -m unittest discover -s tools/tests
# Rebuild the bundled source animation bank:
python tools/project.py play --headless --script res://tools/bake_combat_library.gd
# Active integration tests and rendered review:
python tools/project.py play --headless --fixed-fps 60 --script res://tests/run_kung_fu_tests.gd
python tools/project.py play --fixed-fps 60 --script res://tests/capture_karate_positioning.gd
python tools/project.py play --fixed-fps 60 --script res://tests/capture_controlled_recovery.gd
```

The active suite verifies every move through the input graph, actual limb contact and single-hit damage, early combo buffering, movement and target switching, stamina, both three-hit counter finishers, limb contact, floor-timed landing feedback, early recoil, transition continuity, fixed follow-through targets, preserved captured hips/legs, captured movement, staged damage, counter interruption and buffered target handoff, directional guard, grounded evasion, cover, both paired takedowns, pause, interruption, recovery, defeat, melee AI, bout progression, restart, and absence of ragdolls. The standard check command also runs the retained legacy suites.

Checks run the simulation with a fixed 60 FPS clock, so authored frame timing advances without waiting for wall-clock pacing. `check combat` runs the active combat suite after a Godot import; `check` runs all four suites.

- `combat_moves.gd`: move definitions and punch/kick graph.
- `counter_sequences.gd`: shared counter choreography and contact/landing times.
- `combat_pose.gd`: limb arcs, two-bone constraints and grip alignment.
- `kung_fu_visual.gd`: sampled base motion, pose blending, locomotion layering and paired poses.
- `kung_fu_fighter.gd`: movement, links, defense, clinch ownership and animated defeat/recovery.
- `kung_fu_dojo.gd`: input, directional target selection, contact checks, opponents, camera and UI.

See [the concept](docs/CONCEPT.md), [credits](docs/THIRD_PARTY.md), and [work log](docs/WORK_LOG.md).
