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

## Not yet specified

- **Schedule and cut line:** how the 6 weeks split up and what gets cut first if things slip. Depends on how the prototypes go.
- **Input:** keyboard+mouse, gamepad, or both.
- **Persistence:** saving the profile and campaign progress between sessions.
- **AI write-up:** format and content. Probably depends on the Voice architecture and the debug overlay.
- **Extra Missions:** whether there's time for revisits of Areas with countermeasures, beyond the 3 + core.

## Out of scope

- Base management (Mother Base) from Peace Walker.
- Machine learning or LLMs in the game.
- Voice acting.
- Controlling a squad or switching between Metis members.
- 3D cinematics.
- Multiplayer / co-op.
