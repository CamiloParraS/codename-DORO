# Ghost Layer — Wayfinder Map

Label: wayfinder:map

## Destination

A spec for the whole game, ready for `/to-spec`: 3 Areas, 3+ Missions plus the Aigis core finale, Revenge-style adaptation the player can see, Spoofed transmissions, and an ending decided by Lethality. Milestone 1 is a vertical slice by the end of week 2. Delivered as a playable Windows build (presented live) plus a write-up of the game AI, around 2026-11-19.

## Notes

- **Domain:** solo game project in Godot 4.7 (Jolt, Forward Plus), about 6 weeks starting 2026-10-08. Original pitch: [Ghost Layer 0.2](../../docs/pitch.md), a draft; where it disagrees with a decision on this map, the map wins. Vocabulary: `GLOSSARY.md`.
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
- [Architecture of the five Voices](issues/09-voice-architecture.md): Aigis is a deterministic utility AI that runs only between Missions; guards keep their behaviour tree. Each Countermeasure step has a sponsor Voice; the strongest Habit is pinned, then a greedy fill (sponsor weight × Habit points) spends a budget of 0/2/4/6. The Lethality ratio picks a Dominant Voice (Pallas < 0.10 ≤ Nike ≤ 0.40 < Gorgo, weight 2.0), which closes the briefings and decides the ending. Pallas names Habits in briefings; no Voice lines during a Mission.
- [Campaign plan](issues/10-campaign-plan.md): Palladion's coastal compound. Harbour (Mission 1, also the tutorial) → Radio relay station (Sabotage + relay chief) → Research annex (lead researcher + intel) → Core: back to the Harbour fully fortified, then down to the Core room, where the director choice beside Aigis closes the campaign. Areas ~80×80 m with 8–10 guards and every Countermeasure spot built in. Targets always required. Linear, no replays. Free mode Presets: Clean slate, Ghost, Trickster, Butcher, Custom.
- [Narrative delivery](issues/11-narrative-delivery.md): English source plus Spanish via Godot CSV translations, a small custom codec player, no branching. Metis is a handler + analyst on the radio; non-diegetic Briefings. Story beats from the pitch (Synthetic Content Inflation, dead commanders' memories). The finale is a scripted last spoof → Final debate → Pallas shutdown / Nike dormant / Gorgo shutdown fails → Epilogue: Metis profits from the war. Stock footage only in the ending and an optional intro. 3,500-word cap with a set cut order.
- [Gadgets and items](issues/12-gadgets-and-items.md): two items on HUD E's card, both from Mission 1. Scanner (3 charges × ~10 s, guard and camera cones within 30 m through walls) and Magazine (4, thrown ~15 m, lands as a knock). Neither feeds the Profile directly. No rations, no loud weapon. The Magazine is first to cut.
- [AI write-up](issues/13-ai-write-up.md): live demo + one short Spanish document (Markdown → PDF, written last), no slides. Core sections: architecture, Aigis, evidence. Deployment tables generated from the Presets by a test suite, Mermaid diagrams + a LimboAI screenshot of the guard tree, ~10 min demo script as an appendix.
- [Input](issues/14-input.md): keyboard+mouse only, through InputMap actions, no rebinding. WASD/Shift walk/C crouch/Tab shoulder, RMB aim + LMB fire (aimed only), 1/2 weapons, R reload (4- and 30-round magazines), wheel+F items, E context (choke, carry toggle), X kill, V knock, Q radial, Esc pause, F3 debug overlay. Calls are scripted only. Settings: sensitivity, invert Y, language, window mode, volume.

## Not yet specified

- Nothing left. Persistence and Schedule and cut line (with Extra Missions folded in) are open tickets.

## Out of scope

- Base management (Mother Base) from Peace Walker.
- Machine learning or LLMs in the game.
- Voice acting.
- Controlling a squad or switching between Metis members.
- 3D cinematics.
- Multiplayer / co-op.
- Gamepad support: keyboard+mouse only, decided in [Input](issues/14-input.md); camera, aim and radial on a stick would each need their own tuning.
- Light and night (darkness as a stealth factor, a night Habit): no light model exists, it would need its own prototype, and it doesn't fit 6 weeks solo. Cut while graduating the fog, no ticket.
