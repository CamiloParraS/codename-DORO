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

**Encounter**:
One part of an Area built around a single tactical problem (timing, positioning, manipulation or information) and the guards placed to pose it. An Area's Encounters connect and build on each other; they are not separate rooms.
_Avoid_: Room, zone, section, arena

**Rank**:
The grade (S, A, B or C) a Mission attempt earns from how it was played: time, Alerts, kills, Down guards found and Continues, counted over the whole attempt. A Checkpoint never rolls it back, and it is kept apart from the Profile.
_Avoid_: Score, grade, rating

**Continue**:
Resuming from the last Checkpoint after dying (CONTINUE on the Game Over screen), or by restarting from it in the pause menu. Unlimited, but each one counts against the Rank.
_Avoid_: Retry, respawn, lives

**Mission Record**:
The four bests a slot keeps for each cleared Mission: Rank, fastest time, fewest kills and fewest Alerts.
_Avoid_: High score, stats

**Mission select**:
The main-menu list of the slot's cleared Missions, each shown with its Mission Record, from which one is replayed.
_Avoid_: Level select, Free mode

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
A point inside a Mission, one at its start and one per objective step, where the Operative resumes after dying. Everything since it, including Profile points and Lethality, is undone; the Rank is not.
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

**Fulton**:
A balloon the Operative clips to a Neutralized guard, in the open only, to lift him out of the Area for Metis. Guards who see it rising grow suspicious.
_Avoid_: Extraction (that is the Extraction point), airlift, balloon

**Recruit**:
A guard Fultoned out of a Mission who now works for Metis. Worth one point of Requisition currency, banked when the Mission's post-Mission screen commits; a first clear only.
_Avoid_: Prisoner, POW, staff

**Requisition**:
The step between Missions where Metis turns its Recruits into permanent gear upgrades for the Operative. Only first clears pay Recruits and use the gear.
_Avoid_: Shop, store, upgrades

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

**Hint**:
A live Codec call in which Metis points a lost player at the current objective step, in two tiers (a direction, then the route), fired when the player idles or wanders, or on request from the radio menu.
_Avoid_: Tip, tutorial prompt

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

**Reinforcements**:
Guards sent into the Area once per completed Radio call, to hunt the Operative down. They stay through Evasion and Caution and leave when Caution ends, or at once when a believed all clear reaches every guard. Caution sends none; the Combat Countermeasure sends more.
_Avoid_: Backup, squad, wave

**Radio call**:
The moment between a spotter's ! and the Area's Alert, while he radios it in and can still be stopped.
_Avoid_: Grace period, call-in, backup call

**Alert**:
The phase that starts when a Radio call completes: every guard in the Area hunts the Operative.
_Avoid_: Combat, red alert

**Evasion**:
The phase after an Alert, when guards have lost the Operative and search around where he was last seen.
_Avoid_: Search mode, lost

**Caution**:
The 60 s phase after Evasion, after a stopped Radio call's local search, or after a guard finds a Neutralized partner or wakes up: guards are back on patrol, faster, more watchful and more numerous. A new trigger restarts the 60 s. It is not an Alert.
_Avoid_: Wary, aftermath, yellow alert

**Hold-up**:
Holding a guard at gunpoint from close behind until he surrenders, so he can be interrogated.
_Avoid_: Stick-up, arrest, freeze

**Head icon**:
The ? or ! shown above a guard's head: ? while suspicious, ! once alerted.
_Avoid_: Mark (that is not a Target), indicator, bubble

### Playtest

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

**Radar**:
The always-on map in the corner showing nearby guards as dots with their facing, and the current objective. It goes dark during Alert and Evasion only; a Radio call, a local search and Caution leave it on, and a guard mid-call flashes red. Vision cones stay the Scanner's job.
_Avoid_: Soliton, minimap

**Magazine**:
An empty magazine the Operative throws to make a noise where it lands, drawing guards to investigate.
_Avoid_: Mag, distraction, decoy
