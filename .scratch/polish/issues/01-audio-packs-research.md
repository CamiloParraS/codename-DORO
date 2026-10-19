Type: research
Status: resolved
Blocked by: -

## Question

Which CC0/free-licensed packs cover: alert sting, footsteps (surfaces in Harbour), knock/throw noises, codec ring, guard barks-free ambience, and 3 music beds (calm/alert/search)? Report name, author, link, license per candidate, and how to PSX-process them in Godot (import sample rate, bitcrush bus effect). Findings to `.scratch/polish/research/audio-packs.md`.

## Answer

Findings: [research/audio-packs.md](../research/audio-packs.md). Every category has a verified CC0 source, with these gaps:
- Music: the SRG774 Dark Sci-Fi Audio Pack (OGA, CC0) covers calm (Airy), alert (Urgent) and search (Pulse). All three come from one pack, so audition them before locking.
- Alert sting: no dedicated CC0 sting exists, so build one from congusbongus's `abyss.ogg` or an aquinn stab, plus a Kenney blip.
- Footsteps: Thimras (metal on concrete), TinyWorlds (wood, stone, gravel) and Fantozzi (stone) are CC0. The best-covering pack, congusbongus's, is CC-BY and was rejected.
- Knock: no CC0 knock found. Use a rubberduck wood hit, doubled. Throw: use the artisticdude swishes.
- Codec ring: synthesise from two Kenney blips, or use Chirptone (CC0).
- Ambience: BigSoundBank "Sea Waves with Tern Calls" (CC0).
- PSX look: Godot has no bitcrush effect. Use WAV import `Max Rate` (11025 Hz for SFX, 22050 Hz for ambience), `Force > Mono` and optionally `8 Bit`. On the buses, use `AudioEffectDistortion` in `LOFI` mode plus a low-pass filter. Ogg/MP3 imports have no Max Rate option, so pre-resample music outside Godot.
- Kenney Impact Sounds and RPG Audio have verified CC0 licences, but their file lists need checking after download.
