# Third-party assets

All runtime assets below were downloaded between September 12 and 15, 2026 and are bundled locally. No account, payment, or runtime network access is required. Assets identified as CC0 1.0 are covered by the included [full CC0 text](../client/assets/licenses/CC0-1.0.txt).

| Asset | Creator / source | Local files | Use and modifications |
| --- | --- | --- | --- |
| RobotExpressive / Animated Robot | Tomás Laulhé (Quaternius), with modifications by Don McCurdy. [Creator page](https://quaternius.com/packs/animatedrobot.html), [distribution and source credit](https://github.com/mrdoob/three.js/tree/dev/examples/models/gltf/RobotExpressive) | `client/assets/characters/RobotExpressive.glb` | Retained as a legacy reference asset. It is no longer instantiated at runtime; the digital human now drives the hero and training enemies. |
| Vitruvian digital human | [VitruvianGodot](https://github.com/ibrews/VitruvianGodot), derived from Sean Buckley and Olaf Delgado-Friedrichs’ CharMorph Vitruvian / Antonia Polygon work | `client/assets/characters/vitruvian/` | CC0 body, head, and texture assets; uses the supplied idle, walk, and wave animation clips, with Wave repurposed for this melee POC. The runtime omits the source package’s hair and custom shaders, and assigns lightweight Godot materials. The upstream credit and MIT code license are retained locally. |
| Concrete 030, 1K JPG | Lennart Demes / ambientCG. [Asset page](https://ambientcg.com/view?id=Concrete030) | `client/assets/materials/Concrete030/` | Retained color, OpenGL normal, and roughness maps. Runtime triplanar tiling and tint on arena geometry. |
| Metal 032, 1K JPG | Lennart Demes / ambientCG. [Asset page](https://ambientcg.com/view?id=Metal032) | `client/assets/materials/Metal032/` | Retained color, OpenGL normal, roughness, and metalness maps. Runtime tiling and tint on crates, deck plates, and the loading door. |

RobotExpressive's upstream license and modification notes are preserved in [RobotExpressive-README.md](../client/assets/licenses/RobotExpressive-README.md). VitruvianGodot's asset provenance and its distinction between CC0 character assets and MIT project code are preserved in [VitruvianGodot-NOTICE.md](../client/assets/licenses/VitruvianGodot-NOTICE.md). ambientCG's license explicitly covers redistribution of raw asset files in a game: [published license](https://docs.ambientcg.com/license/).

[Download checksums and source URLs](../client/assets/sources.json) record the downloaded GLBs and texture archives. The downloaded source models themselves are unmodified.

The arena geometry, game logic, shell shaders, mesh-particle effects, and UI were authored for this project. No third-party effect package or code library is required. Godot is the game engine and is not bundled by this source project.
