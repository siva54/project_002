# Project 002 — initial concept

## Confirmed direction

The owner wants to create something like Project Awakened in `project_002`, using [IGN's Awakened page](https://www.ign.com/games/awakened) as the reference. The directory was empty when inspected on September 12, 2026.

The owner subsequently selected **creating a hero and combining powers** as the strongest priority. Hero building and power interactions lead development; city scale and story follow.

## Implemented starting point

The `client/` Godot project now contains an early Hero Lab prototype: signature color selection, three freely selected power slots from seven abilities, third-person movement, a small arena, physics crates, reactive sentinels, pickups, and a relay objective. It includes resource limits, cloak detection changes, obstacle-aware Blink, damage, defeat, reset, and a pause/build menu. See the README for controls and limitations.

Prototype 04 adds Seeker Missiles. The opening screen starts with three empty slots and requires the player to choose exactly three of seven freely combinable powers before entering.

The mission and expansion sections below remain future proposals. Prototype 02 replaces the capsule with a rigged Quaternius robot, adds imported movement and punch clips, physical energy projectiles, melee combat, ambientCG PBR surfaces, and layered 3D effects. The arena still has a target-disabling objective rather than core retrieval and extraction.

## What to take from the reference

IGN describes a character-driven superpower action game and lists it as canceled. Its material is a reference for an intended experience, not a specification of a completed game.

In their [2013 developer Q&A](https://www.reddit.com/r/IAmA/comments/18l4a1/we_are_phosphor_games_in_chicago_creators_of_ue4/), Phosphor described customizable abilities, a reactive sandbox, and a single-player structure connecting hubs to more focused missions. Their [create-a-player prototype video](https://www.youtube.com/watch?v=-kn8xwa50O8) provides an additional visual reference for later review.

Our proposed guiding principle: **the hero you build changes how you solve the encounter.**

Use an original setting, characters, title, and assets. The mechanics below are our design proposals; they are not claims about features delivered by Awakened.

## Proposed first playable

A short, replayable third-person mission in a compact industrial district. Choose powers at a staging area, retrieve a power core from a guarded facility, and reach extraction. Rooftops, an exposed courtyard, and a side passage offer different approaches.

Start with single-player desktop controls and simple placeholder geometry. Target a satisfying five-to-ten-minute encounter before expanding the city or campaign.

### Hero building

Equip three abilities freely from a small pool; presets are convenient starting loadouts rather than fixed classes. Start with these four powers:

| Power | First implementation | Gameplay purpose |
| --- | --- | --- |
| Blink | Short teleport to a validated clear destination | Cross gaps and change combat position |
| Telekinesis | Grab and throw designated physics props | Move cover, distract guards, and attack |
| Energy bolt | Aimed projectile with visible impact | Direct ranged combat |
| Cloak | Temporary concealment that breaks on attack | Bypass patrols and reposition |
| Seeker Missiles | Staggered three-projectile homing volley | Pursue exposed targets from a safe angle |

Each power needs readable targeting, a clear limit, and immediate feedback. Test combinations such as blinking onto a roof and throwing a crate into the courtyard. Keep the initial appearance editor to a few color choices; detailed body and clothing customization follows the gameplay prototype.

### Reactive encounter

Guards patrol, investigate disturbances, engage when they see the player, and search the last known position when contact is lost. Cloaking must affect perception rather than pause all enemy behavior. Thrown props should make noise and interact with guards through the same damage and impact rules as other attacks.

The objective tracks obtaining the core and reaching extraction, allowing combat, stealth, and traversal routes. Walking and jumping must also provide a valid route so arbitrary loadouts cannot make the mission impossible.

### Completion criteria

- Movement, camera collision, aiming, and jumping feel controllable in the test district.
- Changing the equipped powers changes available tactics without restarting the application.
- All four abilities have visible effects and enforce their costs or cooldowns.
- Blink cannot place the hero inside solid geometry or outside the playable area.
- The same objective is completable through direct combat and a stealth or traversal approach.
- Victory, defeat, and restart work repeatedly without leftover enemies or physics state.

## Suggested implementation sequence

1. **Movement playground:** third-person controller, camera, rooftops, stairs, and a reset action. Review movement feel before adding more systems.
2. **Power playground:** data-defined abilities, loadout selection, targeting, resource limits, and interactive props. Prove that combinations are enjoyable.
3. **Playable mission:** guard perception, combat, core retrieval, extraction, and complete restart flow.
4. **Presentation pass:** original character art, animation, sound, effects, readable UI, saved settings, and controller support.
5. **Expansion:** additional powers, deeper character creation, progression, and another district, guided by playtesting.

## Technical starting point

Godot 4 was used for the first prototype because the adjacent project uses it and a Godot executable is already installed here. This project has its own game rules and scene structure. Long-term platform requirements and engine suitability can be reviewed after the first playtest.

Separate player movement, ability definitions, ability execution, targeting, enemy perception, and mission state. Give actors and props shared damage/interaction contracts so each new power does not require rewriting every enemy. Validate physics-sensitive behavior in an actual playable scene as well as targeted automated checks.

## Scope and open decisions

The full vision can include a larger city and deeper customization. The first milestone concentrates on a complete encounter; unrestricted flight, crowds, vehicles, full building destruction, multiplayer, and modding tools are later scope decisions.

Still to decide: target platforms; visual style; additional desired powers; depth of appearance customization; and intended production scale. No schedule or budget estimate is established yet.
