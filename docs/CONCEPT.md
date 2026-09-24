# Project 002 — initial concept

## Current confirmed direction - September 21, 2026

The owner explicitly requested a full combat revamp toward Sleeping Dogs: smooth connected movement, many punches and kicks, and coordinated exchanges instead of floppy ragdolls. Martial arts is the entire active game. The prior Flow State and contact-only passes were rejected.

The active combat controller has been replaced with fourteen branching strikes, early input buffering and recovery links, movement beneath hand strikes, directional opponent selection, frontal guard/counters, and grounded sidesteps. A close clinch leads into a knee takedown or sweep. Both fighters remain under animation control through contact, fall and recovery; no PhysicalBone3D or physical ragdoll is created. Three groups of two, three and four melee opponents form the current loop.

The new animation layer samples the bundled source bank, blends between live poses, layers locomotion beneath hand strikes, and uses authored limb arcs and two-bone constraints for contact and grips. This is a constructed animation system, not a new professional motion-capture library. The shared paired clock and controlled falls replace the rejected physics launches. The humanoid, courtyard, choreography and footwork remain prototype presentation, and the Sleeping Dogs quality target has not been established by an owner playtest.

The owner also rejected that implementation for lacking a counter finisher and still looking limp. The next pass adds two paired, two-contact counter finishers, attack timing cues, buffered follow-ups to other opponents, braced falls and forward get-up motion. Normal hits preserve guard and no longer freeze animation clocks. These changes remain subject to owner playtest.

The owner reiterated smooth contact and a strong counter finisher, also naming Acts of Blood. The latest pass accelerates strikes through contact, keeps the follow-through target fixed, preserves outgoing motion through blends, adds a brief planted support foot and immediate recoil, and expands both counters to three strikes. A side camera angle and timed finishing/landing feedback emphasize the final contact.

The owner then reiterated Sifu, Sleeping Dogs and Acts of Blood and specifically rejected the doll-like full-body motion. The next revision replaces the primary procedural punch chain with complete CMU boxing sequences, preserves their hips and legs during moving attacks, restores captured root travel through collision, and caps reach correction at 7.5 cm. The side kick is redirected as a whole-body action, and hit reactions use full-body clips. Eleven attack entries preserve captured body motion; the knee, low kick and elbow retain constructed adjustments. This is an underlying animation change, and owner acceptance remains unconfirmed.

The owner rejected the full-body pass as sloppy too. The current correction focuses on the basic exchange: consecutive jab-cross source frames with a shared heading, translation reconstructed from the retargeted support foot, a bounded approach step that settles before impact, active raised guard, and recoil added to the struck pose. The source reactions begin at impact and end neutral; playback now accounts for that. Front and round kicks receive whole-body heading correction. This addresses measured discontinuities and sliding, not the remaining need for better paired choreography.

The latest review is `docs/qa/karate-positioning.mp4`, a labeled fixture study with resets and fixed camera views; older preview files document superseded implementations. The September 24 pass adds distinct captured Shotokan karate straights and directional slips, and makes a visible guarded approach step before captured strikes. The in-game Tab guide and README describe the current move graph. Preserve martial-arts-only scope and the no-ragdoll direction in future work. The earlier Hero Lab remains a legacy development scene.

## Earlier confirmed direction (superseded for the active game)

The owner wants to create something like Project Awakened in `project_002`, using [IGN's Awakened page](https://www.ign.com/games/awakened) as the reference. The directory was empty when inspected on September 12, 2026.

The owner subsequently selected **creating a hero and combining powers** as the strongest priority. Hero building and power interactions lead development; city scale and story follow.

## Implemented starting point

The `client/` Godot project now contains an early Hero Lab prototype: signature color selection, three freely selected power slots from seven abilities, third-person movement, a small arena, physics crates, reactive sentinels, pickups, and a relay objective. It includes resource limits, cloak detection changes, obstacle-aware Blink, damage, defeat, reset, and a pause/build menu. See the README for controls and limitations.

Prototype 05 replaces the toy-like robot presentation with clothed, adult digital-human combatants. The opening screen starts with three empty slots and requires the player to choose exactly three of seven freely combinable powers before entering.

The mission and expansion sections below remain future proposals. The Hero Lab now includes adult human combatants with body and face geometry, authored locomotion, a jab/cross/front-kick chain and two collision-driven grapples, physical energy projectiles, melee combat, ambientCG PBR surfaces, and layered 3D effects. The arena still has a target-disabling objective rather than core retrieval and extraction.

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

## Martial arts combat pass - September 21, 2026

The owner requested martial arts attacks plus grappling with physics. F chains a lead jab, rear cross, and front kick with guarded recovery and one buffered follow-up. G alternates a forward throw and leg sweep after a close, cover-aware clinch. Throw motion uses velocity, gravity, and capsule collision, followed by one landing hit and a recovery state. These are original skeletal poses on the existing licensed character, not downloaded motion capture or jointed ragdolls. Powers and the three-slot build remain available.
