# Implementation Decisions: Platform and dependencies

- Godot 4.7, Forward Plus, Jolt physics, Windows export. Keyboard and mouse only.
- **LimboAI** (GDExtension) for the guard behaviour tree. Smoke-test it on 4.7 on day 1; **Beehave** is the fallback. Built-in `SpringArm3D` and `NavigationAgent3D`; the PSX shaders are written by hand. No Dialogue Manager.
- Tests use godot_ai's **McpTestSuite**, run from the tests folder at the project root.
- Assets: Quaternius characters and animations (QAL licence: no standalone redistribution; raw files stay in `_raw/`), Kenney as a CC0 fallback, military props built by hand, Screaming Brain Tiny Texture Pack 2 (CC0), Press Start 2P + VT323 (OFL), Kenney/OpenGameArt CC0 sounds, Pexels/Pixabay stock footage for the ending only. Mixamo is not used. Every asset gets a credits line.
- Prototype code: leaf pieces are lifted whole (the PSX shader and post-process, the two-spring-arm camera rig, the detection arc widget). Anything that crosses systems (guard perception and state, Spoofing, alert propagation) is rewritten, reusing the tuned numbers below. The prototypes live on the `prototype/stealth-core`, `prototype/spoofing` and `prototype/psx-look` branches.
