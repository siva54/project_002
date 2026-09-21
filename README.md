# Project 002

An original third-person superpower action game inspired by the character-building freedom of Project Awakened.

Status: **Hero Lab — Prototype 05**, a grounded human-combat power playground with reactive opponents, objectives, collectibles, and 3D energy effects.

## Play

Double-click `play.command` on macOS or `play.bat` on Windows. You can also run this command from `project_002`:

```sh
godot --path client
```

You can also open `client/project.godot` in Godot 4 and press F6 with the hero lab scene open, or F5 to run the project.

The game opens with three empty slots. Choose exactly three of the seven powers below; Enter becomes available only when all three slots are filled. Cards and the loadout preview show the assigned keys (1, 2, 3) in selection order. Click a selected card to remove it, then choose a replacement. You can also choose a signature color. Enter the playground to disable five sentinels, collect power cells, and charge the central relay; Esc pauses and reopens your build.

| Power | What it does |
| --- | --- |
| Energy Bolt | Cast a traveling orb that damages targets and pushes crates. |
| Seeker Missiles | Fire a staggered three-missile volley that curves toward exposed sentinels. |
| Blink | Teleport up to eight metres through clear space. |
| Telekinesis | Lift a crate, then use the power again to throw it. |
| Cloak | Conceal yourself for five seconds; attacks reveal you. |
| Shockwave | Damage exposed enemies within six metres and fling crates outward. Solid cover blocks it. |
| Energy Shield | Block incoming enemy energy for five seconds while continuing to move and attack. |

All thirty-five distinct three-power combinations are available. For example, Shield + Shockwave + Blink creates a protected close-range build, while Seeker Missiles + Cloak + Blink supports hit-and-reposition play. Removing Shield or Cloak from the build ends its active effect. Arena reset preserves your selected three powers.

| Control | Action |
| --- | --- |
| WASD / mouse | Move / look and aim |
| Space / Shift | Jump / sprint |
| 1, 2, 3 | Use the corresponding equipped power |
| Left click | Use the first equipped power |
| F | Melee punch (short windup and cooldown) |
| Esc | Open hero creation and pause |

Energy regenerates. Telekinesis grabs amber crates; pressing its key again throws the held crate. Two energy orbs, two melee punches, or one thrown crate disable a sentinel. Cloak lasts five seconds and breaks when attacking. Sentinels patrol while unaware, investigate sounds from powers and thrown crates, alert nearby allies when hit, then pursue and strafe at combat range when they see the hero. A hit causes a visible stagger; a lethal hit leaves a short shutdown pose before the sentinel clears. Their projectiles travel through space and can be dodged; already-fired attacks can still hit a cloaked hero.

Seeker Missiles cost 40 energy and launch three small homing projectiles 130 ms apart. Each tracks its initially acquired, exposed sentinel with a bounded turn rate; cover or a destroyed target breaks its lock, then it continues forward and can be avoided.

Four cells are placed in the arena: jade cells restore 30 energy and coral cells restore 25 vitality. The central Power Relay takes charge from Energy Bolts (25%), Shockwaves (30%), melee strikes (12%), and thrown crates (45%). Bringing it to 100% restores all energy and adds 30 vitality. The HUD and the 3D relay label show objective progress. Reset restores enemies, pickups, relay charge, health, and resources.

## Current limits

The hero and sentinels use a CC0 digital-human body and face with adult proportions, clothed materials, an authored idle/walk animation set, and a hand-to-face close-combat strike. Small chest patches identify the two teams without turning the character into a colored mannequin. The arena uses ambientCG concrete and metal color, normal, roughness, and metalness maps. Energy effects use traveling sphere meshes, animated shells, rotating torus meshes, bounded mesh particles, and local lights.

This remains a mechanics POC with a simple training arena. Appearance customization is team-accent selection. There is no detailed character sculpting, audio, campaign, progression, controller support, or saved loadout yet. Selections persist only during the current session. Sentinel navigation is direct local steering with patrol, investigate, search, stagger, and engage states; it does not yet use pathfinding, tactical cover selection, coordinated formations, or melee attacks. The animation set does not include advanced foot placement, terrain IK, or a full combat-animation library.

Effects are intentionally bounded for a smooth playground loop: transient impact volumes are capped, projectiles do not run CPU particle emitters, only three enemy shots may be in flight, and sight checks refresh at 120 ms. Enemy shots have a short visible wind-up before firing.

The intended starting window is 1280 × 800. Godot `4.7.2.stable.official.ed1daf0bf` was used for verification on this Mac.

## Checks

```sh
godot --headless --editor --quit --path client
godot --headless --path client --script res://tests/run_tests.gd
godot --headless --path client --script res://tests/run_power_tests.gd
godot --path client --script res://tests/capture.gd
godot --path client --fixed-fps 60 --script res://tests/capture_actions.gd
```

The automated suite checks loadouts, energy and cooldowns, cloak behavior, traveling projectile damage, physical thrown-crate impact, Blink collision and ground travel, reset, defeat, movement and animation selection, jumping, melee timing, pause including in-flight attacks, reactive sentinel behavior, shot telegraphing, pickups, and relay charging/rewards. The dedicated power suite also checks all thirty-five builds, empty/incomplete selection rejection, Seeker Missile acquisition and homing impact, Shockwave range and cover, Shield expiry and damage blocking, and cleanup when changing powers. The capture command opens a temporary rendered window, saves images to `docs/qa/`, and exits.

Read [the concept and prototype scope](docs/CONCEPT.md) for the proposed direction, milestones, and research references. Decisions in that document are proposals unless explicitly marked as confirmed.

The prototype uses Godot 4, already installed on the development machine and used by the neighboring project. Its implementation is independent of that project.

Development history: [work log](docs/WORK_LOG.md).

## Implementation and free assets

- `hero_controller.gd`: movement, camera, and input.
- `avatar_visual.gd`: instanced CC0 digital human, real face/body materials, animation playback, and team appearance.
- `energy_projectile.gd`: projectile travel and continuous collision queries.
- `sentinel_controller.gd`: patrol, investigate, search, combat, hit response, and shutdown behavior for training opponents.
- `power_vfx.gd`: 3D shells, mesh particles, rings, auras, and lights.
- `surface_library.gd`: reusable PBR material setup.
- `hero_lab.gd`: arena assembly, encounters, loadouts, and UI.

See [third-party credits and license records](docs/THIRD_PARTY.md). All downloaded runtime assets are bundled locally, so playing does not require an internet connection.
