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

**Lethality**:
The silent campaign-long record of how lethal or restrained the Operative has been. It decides which ending plays.
_Avoid_: Karma, morality, kill count
