# Ghost Layer — Wayfinder Map

Label: wayfinder:map

## Destination

A spec for the whole game, ready for `/to-spec`: 3 Areas, 3+ Missions plus the Aigis core finale, Revenge-style adaptation the player can see, Spoofed transmissions, and an ending decided by Lethality. Milestone 1 is a vertical slice by the end of week 2. Delivered as a playable Windows build (presented live) plus a write-up of the game AI, around 2026-11-19.

## Notes

- **Domain:** solo game project in Godot 4.7 (Jolt, Forward Plus), about 6 weeks starting 2026-10-08. Original pitch: "Ghost Layer 0.2" (in the conversation that charted this map). Vocabulary: `GLOSSARY.md`.
- **Requirement:** add "AI" = **game AI** (behaviour trees, utility AI, profiling). No ML or LLMs.
- **Design pillar: the adaptation must be visible.** The evaluator should not read it as "the game got harder." Every AI decision needs a way to show up on screen.
- **Planning budget:** about 4 days including prototypes. Anything not decided by then gets a sensible default in the spec.
- **Skills:** grilling tickets → `grilling` + `domain-modeling`; prototypes → `prototype`; research → `research` (subagent, Sonnet 5.5).
- **Research output:** `.scratch/ghost-layer/research/<name>.md`. The repo has no commits yet, so there are no `research/*` branches.
- **Settled while charting:**
  - Peace Walker-style third-person camera (over the shoulder), not MGS1 top-down.
  - The player controls one Operative of Metis. The rest of Metis is radio support. The player is not the leader.
  - Adaptation made visible four ways: countermeasures you can see in the world, a pre-Mission briefing where the Voices name your habit, a post-Mission screen with Aigis's profile, and a debug overlay with the profile and Voice weights.
  - Debug/free mode: Mission select plus preset profiles, for the live presentation.
  - No voice acting: text plus PSone-style radio beeps. Spoofing works through a menu.
  - External assets (CC0 or compatible) for characters and props. Areas built from simple geometry.
  - Visual reference: the general PSone-era look. No specific reference images.
  - Pitch features that can't be cut: profiling/Revenge adaptation, the ending driven by Voices + Lethality, and Spoofing. The amount of story can be cut.

## Decisions so far

- [Addons and Godot 4.7 compatibility](issues/02-godot-addons-research.md): LimboAI (smoke-test it on 4.7, fall back to Beehave), tests with godot_ai's McpTestSuite, hand-written PSX shaders on Forward Plus, built-in SpringArm3D and NavigationAgent3D, Dialogue Manager only if codec calls branch.
- [Asset sources and licenses](issues/03-asset-sources-research.md): Quaternius characters + animations (license now QAL, not CC0: no standalone redistribution), Kenney as a CC0 fallback, military props built by hand, OFL fonts, Kenney/OGA CC0 sounds. Mixamo stays out of a public repo.
- [How the MGSV Revenge System works](issues/01-revenge-system-research.md): about 10 point counters (100 per level), changes only between Missions, stealth↔combat tug of war, decay of at most ½ level per Mission. Visible through gear, a 0–3 icon strip, and guard chatter (hint at 50, confirmation at the level). Gap: little evidence on readability (reflex mode, indicator).
- [Core stealth feel prototype](issues/04-stealth-core-prototype.md): the stealth reads and feels right. Two-spring-arm shoulder camera with a shoulder swap, front + peripheral vision cones, footstep/knock hearing, patrol→suspicion→alert (radio)→evasion→patrol with the tested timings, and the MGSV arc + ?/! marks as the detection indicator. No always-on cones or reason feed needed. Prototype on branch `prototype/stealth-core`.
- [Combat verbs and Lethality](issues/07-combat-verbs-lethality.md): a suppressed tranq pistol, plus a rifle whose suppressor breaks after 10 shots. Takedowns are a choke or a kill. Guards are carried MGSV-style. Neutralized guards wake after ~90 s, and a found Down guard gets checked before the alert. Open combat is viable but costly. Lethality is a silent weighted tally of deaths (a target counts 3), separate from the profile, and rolled back with checkpoints. No Mission requires a death.
- [Spoofing prototype](issues/05-spoofing-prototype.md): fun and challenging. Voiceprints recorded by eavesdropping on check-ins (6 m), three orders, Glaukopis scores deterministic doubt points (exposed at 40+, Voiceprint flagged, recipients search where you transmitted from). The player finds out through guards' chatter. Radio is a radial menu with slowed time; the doubt preview stays debug-only. Prototype on branch `prototype/spoofing`.
- [Operator profile and countermeasures](issues/08-operator-profile.md): six Habits (Stealth↔Combat tug of war, Headshots, Takedowns, Downs, Spoofing), each with a 3-step ladder of visible Countermeasures; MGSV points (100/level, cap rising by Mission, applied only on completion, rolled back with checkpoints). Levels unlock, the Voices deploy, and the strongest Habit is always answered. HQ polls for missing guards, plus a "Report in" spoof order. No counter item.
- [PSX look and HUD prototype](issues/06-psx-look-and-hud-prototype.md): modern-retro look (854×480 nearest, per-pixel light + shadows, 15-bit banding, far fog, 128 px textures; no vertex snap or affine). HUD E, Peace Walker side strips, with C-style subtitles for radio; radial and codec in E's white/grey. Codec: full screen when the call pauses the game, PW subtitles + CALL bar when play continues. Prototype on branch `prototype/psx-look`.

## Not yet specified

- **Schedule and cut line:** how the 6 weeks split up and what gets cut first if things slip. Depends on how the prototypes go.
- **Input:** keyboard+mouse, gamepad, or both.
- **Persistence:** saving the profile and campaign progress between sessions.
- **AI write-up:** format and content. Probably depends on the Voice architecture and the debug overlay.
- **Light and night:** darkness as a stealth factor (for the Operative and for bodies). There's no light model for now; it would need its own prototype, and it ties into a possible night Habit in the Profile.
- **Extra Missions:** whether there's time for revisits of Areas with countermeasures, beyond the 3 + core. A revisit would make a "favourite flank" Habit meaningful (Aigis guards the approach you used last time).

## Out of scope

- Base management (Mother Base) from Peace Walker.
- Machine learning or LLMs in the game.
- Voice acting.
- Controlling a squad or switching between Metis members.
- 3D cinematics.
- Multiplayer / co-op.
