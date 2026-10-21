# Ghost Layer

A short stealth game where an enemy AI, Aigis, learns the player's habits and adapts to them across missions.

## Language

### Structure

**Area**:
A physical play space: its geometry, routes and cover. One Area can host several Missions.
_Avoid_: Level, map, stage, zone

**Mission**:
One playable assignment: an Area, a set of objectives, and the state of Aigis's countermeasures at that point in the campaign.
_Avoid_: Level, stage

**Target**:
A named Palladion member a Mission requires the Operative to deal with: killed on the spot, or Neutralized and carried to the Extraction point. Weighs more than a guard in Lethality.
_Avoid_: Mark, VIP, boss

**Extraction point**:
The place in an Area where a Mission ends once its objectives are done, and where a carried Target must be brought.
_Avoid_: Exit, evac, LZ

**Approach**:
One distinct way through an Area to an objective: sneaking, deceiving with Spoofed transmissions, or going loud. Every objective offers at least one of each.
_Avoid_: Path, route, lane

**Crawlspace**:
A low gap, under a raised building or between containers, that the Operative can only get through crouched. Guards never enter it, though one may look in from the mouth.
_Avoid_: Vent, tunnel, duct

**Backdrop**:
The scenery outside an Area's playable boundary (sea, cliffs, distant buildings, sky) that the Operative sees but can't reach.
_Avoid_: Skybox, decoration, set dressing

**Checkpoint**:
A point inside a Mission, one per objective step, where the Operative resumes after dying. Everything since it, including Profile points and Lethality, is undone.
_Avoid_: Save, save point, respawn

**Core**:
Aigis's physical home, a room beneath the Harbour Area, and the setting of the final Mission.
_Avoid_: Server room, mainframe, boss level

**Free mode**:
Playing any Mission with a chosen Preset, apart from the campaign and without touching its Profile or Lethality.
_Avoid_: Debug mode, sandbox, replay

**Preset**:
A ready-made Profile plus a Lethality ratio, loaded in Free mode to show a given set of Countermeasures and a given ending.
_Avoid_: Loadout, save, scenario

### Cast

**Metis**:
The mercenary team hired to investigate Palladion. The player is one of its members, not its leader.
_Avoid_: Squad, unit

**Operative**:
The single Metis member the player controls in the field. The rest of Metis supports by radio.
_Avoid_: Player character, commander, Snake

**Aigis**:
Palladion's tactical intelligence and the game's antagonist. It profiles the Operative and adapts its forces between Missions.
_Avoid_: The AI, the system

**Voice**:
One of Aigis's five weighted personalities (Promachos, Nike, Pallas, Gorgo, Glaukopis), each holding one part of its doctrine and sponsoring the Countermeasures that fit it.
_Avoid_: Personality, persona, module

**Dominant Voice**:
The Voice the campaign's Lethality currently favours. It has the most say in what Aigis deploys, closes each briefing, and decides the ending.
_Avoid_: Leading voice, active voice, winner

### Story

**Briefing**:
The screen before each Mission where the player overhears Aigis's Voices plan against the Operative. Metis never hears it.
_Avoid_: Mission intro, Aigis screen

**Codec call**:
A radio conversation between the Operative and Metis, either full-screen with the game paused or as subtitles while play continues.
_Avoid_: Cutscene, dialogue, transmission

**Final debate**:
The scene at the Core where the five Voices argue over the fabricated memories the Operative feeds Aigis, settled by the Dominant Voice.
_Avoid_: Boss fight, hallucination loop

**Epilogue**:
The Metis Codec call after the ending, revealing that Metis profits from the escalated war.
_Avoid_: Credits scene, outro

### Deception

**Voiceprint**:
A guard's voice sample captured by the Operative, required to impersonate that guard on the radio.
_Avoid_: Voice, voice sample

**Spoofed transmission**:
A fake radio order the Operative sends using a Voiceprint, which Glaukopis may check for authenticity.
_Avoid_: Deepfake, fake call, spoof order

### Record

**Profile**:
Aigis's model of the Operative: a level for each Habit, updated only between Missions.
_Avoid_: Operator profile, revenge, preparedness

**Habit**:
One behaviour of the Operative that Aigis tracks, such as headshots or Spoofing.
_Avoid_: Counter, stat, revenge type

**Countermeasure**:
A change Aigis makes to a Mission in answer to a Habit, always visible or audible to the Operative.
_Avoid_: Counter, upgrade, response

**Lethality**:
The silent campaign-long weighted tally of deaths the Operative has caused, where a Mission's assigned target weighs more than an ordinary guard. It decides which ending plays, and is kept apart from the Profile.
_Avoid_: Karma, morality, kill count

### Combat

**Takedown**:
A close attack on a guard from behind, either a choke (non-lethal) or a kill.
_Avoid_: CQC, melee, stealth kill

**Knock**:
A noise the Operative makes on the spot to draw nearby guards to investigate.
_Avoid_: Tap, noise, distraction

**Neutralized**:
A guard put out of action without being killed, by a tranquilizer or a choke. It wears off.
_Avoid_: KO'd, subdued, stunned, sleeping

**Down**:
A guard who is either Neutralized or dead, as seen by someone who hasn't checked which.
_Avoid_: Body (when it might be alive)

**Head icon**:
The ? or ! shown above a guard's head: ? while suspicious, ! once alerted.
_Avoid_: Mark (that is not a Target), indicator, bubble

### Guidance

**Hint**:
A nudge from Metis toward the current objective step, in two tiers: a direction, then the route. Given when the Operative has been idle or wandering for a while, or on request from the radio menu.
_Avoid_: Tip (that is the tutorial's prompt), clue, help

**Radar**:
The HUD square at the bottom-left, north-up, showing guards within 30 m (farther ones pinned to its edge) and where the objective is. Jammed, with static, during an Alert or Evasion.
_Avoid_: Minimap, Scanner (that shows vision cones)

**Session log**:
The playtest's own record of each Mission played: time, darts, rifle shots, Spoofed transmissions and every idle. Written to `user://session_log.txt` when a Mission ends, is aborted, or the game quits.
_Avoid_: Telemetry, analytics

**Idle**:
Seconds since the last progress (a step done, a Checkpoint, an Alert ending). Alert and Evasion time never counts. Idles over a minute go in the Session log, and the Hint tracker reads it.
_Avoid_: AFK, stall

### Equipment

**Scanner**:
An item that briefly shows the vision cones of nearby guards and cameras, even through walls. Limited charges per Mission.
_Avoid_: Ghost Layer, cone gadget, goggles

**Magazine**:
An empty magazine the Operative throws to make a noise where it lands, drawing guards to investigate.
_Avoid_: Mag, distraction, decoy
