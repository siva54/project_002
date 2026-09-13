# Project 002

An original third-person superpower action game inspired by the character-building freedom of Project Awakened.

Status: **Hero Lab — Prototype 03**, a playable Godot power playground with animated characters, textured materials, melee, and 3D energy effects.

## Play

Double-click `play.command` on this Mac, or run this command from `project_002`:

```sh
godot --path client
```

You can also open `client/project.godot` in Godot 4 and press F6 with the hero lab scene open, or F5 to run the project.

The game opens with three empty slots. Choose exactly three of the six powers below; Enter becomes available only when all three slots are filled. Cards and the loadout preview show the assigned keys (1, 2, 3) in selection order. Click a selected card to remove it, then choose a replacement. You can also choose a signature color. Enter the playground and disable five sentinels; Esc pauses and reopens your build.

| Power | What it does |
| --- | --- |
| Energy Bolt | Cast a traveling orb that damages targets and pushes crates. |
| Blink | Teleport up to eight metres through clear space. |
| Telekinesis | Lift a crate, then use the power again to throw it. |
| Cloak | Conceal yourself for five seconds; attacks reveal you. |
| Shockwave | Damage exposed enemies within six metres and fling crates outward. Solid cover blocks it. |
| Energy Shield | Block incoming enemy energy for five seconds while continuing to move and attack. |

All twenty distinct three-power combinations are available. For example, Shield + Shockwave + Blink creates a protected close-range build. Removing Shield or Cloak from the build ends its active effect. Arena reset preserves your selected three powers.

| Control | Action |
| --- | --- |
| WASD / mouse | Move / look and aim |
| Space / Shift | Jump / sprint |
| 1, 2, 3 | Use the corresponding equipped power |
| Left click | Use the first equipped power |
| F | Melee punch (short windup and cooldown) |
| Esc | Open hero creation and pause |

Energy regenerates. Telekinesis grabs amber crates; pressing its key again throws the held crate. Two energy orbs, two melee punches, or one thrown crate disable a sentinel. Cloak lasts five seconds and breaks when attacking. Sentinels lose tracking and fire toward the last visible position. Their projectiles travel through space and can be dodged; already-fired attacks can still hit a cloaked hero. Reset restores health, resources, crates, and sentinels.

## Current limits

The hero and sentinels use a free, rigged Quaternius robot with imported idle, walk, run, jump, and punch animation clips. The arena uses ambientCG concrete and metal color, normal, roughness, and metalness maps. Energy effects use traveling sphere meshes, animated shells, rotating torus meshes, 3D mesh particles, and local lights.

This remains a mechanics POC with a stylized robot and a simple training arena. Appearance customization is color selection. There is no detailed character sculpting, audio, campaign, progression, controller support, or saved loadout yet. Selections persist only during the current session. Sentinels are stationary training enemies, not finished patrol AI. Walking and running blend imported animation clips; advanced foot placement and terrain IK are not implemented.

The intended starting window is 1280 × 800. Godot `4.7.2.stable.official.ed1daf0bf` was used for verification on this Mac.

## Checks

```sh
godot --headless --editor --quit --path client
godot --headless --path client --script res://tests/run_tests.gd
godot --headless --path client --script res://tests/run_power_tests.gd
godot --path client --script res://tests/capture.gd
godot --path client --fixed-fps 60 --script res://tests/capture_actions.gd
```

The automated suite checks loadouts, energy and cooldowns, cloak behavior, traveling projectile damage, physical thrown-crate impact, Blink collision and ground travel, reset, defeat, movement and animation selection, jumping, melee timing, and pause including in-flight attacks. The dedicated power suite also checks all twenty builds, empty/incomplete selection rejection, Shockwave range and cover, Shield expiry and damage blocking, and cleanup when changing powers. The capture command opens a temporary rendered window, saves images to `docs/qa/`, and exits.

Read [the concept and prototype scope](docs/CONCEPT.md) for the proposed direction, milestones, and research references. Decisions in that document are proposals unless explicitly marked as confirmed.

The prototype uses Godot 4, already installed on the development machine and used by the neighboring project. Its implementation is independent of that project.

Development history: [work log](docs/WORK_LOG.md).

## Implementation and free assets

- `hero_controller.gd`: movement, camera, and input.
- `avatar_visual.gd`: imported model, animation transitions, attack pose, and appearance.
- `energy_projectile.gd`: projectile travel and continuous collision queries.
- `power_vfx.gd`: 3D shells, mesh particles, rings, auras, and lights.
- `surface_library.gd`: reusable PBR material setup.
- `hero_lab.gd`: arena assembly, encounters, loadouts, and UI.

See [third-party credits and license records](docs/THIRD_PARTY.md). All downloaded runtime assets are bundled locally, so playing does not require an internet connection.
