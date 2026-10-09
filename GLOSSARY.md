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
One of Aigis's five weighted personalities (Promachos, Nike, Pallas, Gorgo, Glaukopis), each holding one part of its doctrine.
_Avoid_: Personality, persona, module

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

**Neutralized**:
A guard put out of action without being killed, by a tranquilizer or a choke. It wears off.
_Avoid_: KO'd, subdued, stunned, sleeping

**Down**:
A guard who is either Neutralized or dead, as seen by someone who hasn't checked which.
_Avoid_: Body (when it might be alive)
