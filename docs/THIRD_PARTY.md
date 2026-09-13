# Third-party assets

All runtime assets below were downloaded on September 12, 2026 and are bundled locally. No account, payment, or runtime network access is required. Their source pages identify them as CC0 1.0; a copy of the [full CC0 text](../client/assets/licenses/CC0-1.0.txt) is included.

| Asset | Creator / source | Local files | Use and modifications |
| --- | --- | --- | --- |
| RobotExpressive / Animated Robot | Tomás Laulhé (Quaternius), with modifications by Don McCurdy. [Creator page](https://quaternius.com/packs/animatedrobot.html), [distribution and source credit](https://github.com/mrdoob/three.js/tree/dev/examples/models/gltf/RobotExpressive) | `client/assets/characters/RobotExpressive.glb` | Original GLB retained. Runtime scale, color, metal material overrides, animation loop configuration, and blending. Imported idle, walking, running, jump, and punch clips drive the hero and training enemies. |
| Concrete 030, 1K JPG | Lennart Demes / ambientCG. [Asset page](https://ambientcg.com/view?id=Concrete030) | `client/assets/materials/Concrete030/` | Retained color, OpenGL normal, and roughness maps. Runtime triplanar tiling and tint on arena geometry. |
| Metal 032, 1K JPG | Lennart Demes / ambientCG. [Asset page](https://ambientcg.com/view?id=Metal032) | `client/assets/materials/Metal032/` | Retained color, OpenGL normal, roughness, and metalness maps. Runtime tiling and tint on crates, deck plates, door, and robot surfaces. Robot uses triplanar color/roughness without tangent-space normal mapping because the source mesh has no UVs. |

RobotExpressive's upstream license and modification notes are preserved in [RobotExpressive-README.md](../client/assets/licenses/RobotExpressive-README.md). ambientCG's license explicitly covers redistribution of raw asset files in a game: [published license](https://docs.ambientcg.com/license/).

[Download checksums and source URLs](../client/assets/sources.json) record the downloaded GLB and texture archives. The GLB import disables automatic tangent generation because the source uses solid materials without texture UVs. The downloaded model itself is unmodified.

The arena geometry, game logic, shell shaders, mesh-particle effects, and UI were authored for this project. No third-party effect package or code library is required. Godot is the game engine and is not bundled by this source project.
