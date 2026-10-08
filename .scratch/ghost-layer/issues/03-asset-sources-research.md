# Asset sources and licenses

Type: research
Status: resolved
Blocked by:

## Question

Where can we get, with licenses that allow a student project (ideally CC0): animated low-poly soldier characters, props (crates, fences, radars, military buildings), PSone-style textures (64–128px), PSone-style fonts and UI, and radio/stealth sound effects? How do you bring Mixamo animations into Godot 4.7 (retargeting, licensing)? Note any trap (licenses that forbid redistribution, attribution requirements).

Output: `.scratch/ghost-layer/research/asset-sources.md`

## Answer

- Characters: Quaternius Universal Base Characters + Universal Animation Library (humanoid rig, built for Godot retargeting; free Standard tier), Kenney Blocky Characters as a CC0 fallback. No verified-CC0 animated PSX soldier exists; closest is yugg0's free "Modern Rebel Soldier" (own terms, Mixamo rig).
- Props/textures/audio/fonts: Kenney Survival/City Industrial kits (CC0), Screaming Brain Tiny Texture Pack (CC0, 128px) or downscaled ambientCG/Poly Haven, Press Start 2P/VT323 (OFL), Kenney + OpenGameArt CC0 sounds. No CC0 PSX military pack found; hand-build the missing props.
- Traps: Quaternius now publishes a non-CC0 "QAL v1.0" license (no standalone redistribution); Mixamo forbids distributing raw files (keep out of a public repo); Freesound is per-sound (BY / BY-NC); Sonniss bans redistribution and AI training.
- Mixamo workflow: FBX (ufbx) -> Skeleton3D `bone_map` with SkeletonProfileHumanoid -> Rest Fixer (Overwrite Axis) -> AnimationLibrary import; prefer "In Place" clips over root motion.

Full details, CREDITS.md template and starter kit: [research/asset-sources.md](../research/asset-sources.md)
