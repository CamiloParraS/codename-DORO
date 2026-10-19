# Audio packs for Ghost Layer polish (CC0 only)

Researched 2026-10-19 against the owning pages (OpenGameArt node pages, kenney.nl, bigsoundbank.com, Freesound FAQ, Godot docs "latest"). Nothing downloaded; downloads go in `_raw/`, then log each used file in `CREDITS.md` > Audio.

Rule applied: only CC0 / public-domain-equivalent. CC-BY candidates seen and **rejected** are listed at the end so nobody re-finds them by accident.

Confidence legend: **Verified** = license and contents read on the owning page. **Check on download** = license verified, but the page does not list individual files, so confirm the exact clip is in the zip.

## 1. Alert sting (the `!` hit)

| Candidate | Author | Link | License | Notes |
|---|---|---|---|---|
| String and piano horror stings (`abyss.ogg`, `piano_sting.mp3`) | congusbongus | https://opengameart.org/content/string-and-piano-horror-stings | CC0 | Verified. Two short stings, closest true stinger found. Horror tone, so pitch up / bitcrush for a harsher MGS-like stab. |
| Space Impending Danger SFX (`space1.mp3`, `space2.mp3`) | aquinn | https://opengameart.org/content/space-impending-danger-sfx | CC0 | Verified. "Dramatic stabs and growls"; chop a stab from the file. |
| Sci-fi Sounds (70 files) | Kenney | https://kenney.nl/assets/sci-fi-sounds | CC0 | Verified license. Already in CREDITS. Usable for a synthetic blip layered under the sting. |
| Digital Audio (60 files) | Kenney | https://kenney.nl/assets/digital-audio | CC0 | Verified license. Blips/lasers; a rising laser is a cheap "!" layer. |

Gap: no purpose-made CC0 "enemy spotted" sting exists on OGA. Recommendation: build it from `abyss.ogg` or an aquinn stab, plus a short Kenney blip layer, in one clip.

## 2. Footsteps for Harbour surfaces (concrete, metal grating/plates, wood pier, gravel)

| Candidate | Author | Link | License | Surfaces / notes |
|---|---|---|---|---|
| Metal footsteps on concrete | Thimras | https://opengameart.org/content/metal-footsteps-on-concrete | CC0 | Verified. 25 steps, 48 kHz/24-bit in a 7z (`metal_steps_48k24b.7z`). Metal soles on concrete; also works as dock plate/metal grating. |
| Different steps on wood, stone, leaves, gravel and mud | TinyWorlds | https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud | CC0 | Verified. 8 sounds (zip, formats not listed; commenter implies OGG). Covers wood (pier), stone, gravel. Recorded from pdsounds.org (public domain source) per a commenter. |
| Fantozzi's Footsteps (Grass/Sand & Stone) | Fantozzi (via qubodup) | https://opengameart.org/content/fantozzis-footsteps-grasssand-stone | CC0 | Verified. 12 steps, 16-bit 44.1 kHz FLAC + OGG. Stone covers generic hard floor. |
| RPG Audio (50 files, tagged footstep) | Kenney | https://kenney.nl/assets/rpg-audio | CC0 | License verified; tags say footstep/foley/weapon. Check on download which surfaces it has (not stated on the page). |
| Impact Sounds (130 files, tagged impact/foley) | Kenney | https://kenney.nl/assets/impact-sounds | CC0 | License verified; the page does not list contents. Check on download for footstep and wood/metal impact clips. |

Suggested Harbour mapping: concrete = Fantozzi stone or Thimras (lighter pitch); metal = Thimras; wood pier = TinyWorlds wood; gravel = TinyWorlds gravel. Mix sets by surface name to a small `StringName -> Array[AudioStream]` table.

## 3. Knock and throw noises

| Candidate | Author | Link | License | Notes |
|---|---|---|---|---|
| 100 CC0 metal and wood SFX | rubberduck | https://opengameart.org/content/100-cc0-metal-and-wood-sfx | CC0 | Verified. Has wood hit/hammer/slam; no "knock" tag. A short wood hit is a usable wall-knock decoy. Check on download. |
| 100 CC0 SFX | rubberduck | https://opengameart.org/content/100-cc0-sfx | CC0 | Verified. Categories include metal (12), slam, tools, other. Metal tap/clink for the thrown-item landing. |
| Various Sound Effects | laleksic | https://opengameart.org/content/various-sound-effects | CC0 | Verified. 27 WAVs; tags: door, lock, wood, drawer. No knock/throw confirmed. |
| Swishes Sound Pack | artisticdude | https://opengameart.org/content/swishes-sound-pack | CC0 | Verified. 13 WAV swishes (4 light, 9 heavy). Use a light one as the throw whoosh. |
| Impact Sounds | Kenney | https://kenney.nl/assets/impact-sounds | CC0 | Wood/metal/generic impacts are the likely fit for the landing sound; confirm on download. |

Gap: no dedicated CC0 door-knock found on OGA. Fallback: wood hit from rubberduck pitched up and doubled (two hits ~150 ms apart), or a Freesound CC0 search ("knock") with the account login Freesound requires for downloads (https://freesound.org/help/faq/). Every Freesound sound must be CC0 filtered; log with the existing CREDITS line format.

## 4. Codec ring

| Candidate | Author | Link | License | Notes |
|---|---|---|---|---|
| Modern Ringtone [Chirptone] (`chirptone.wav`) | Zane Little Music | https://opengameart.org/content/modern-ringtone-chirptone | CC0 | Verified. Chick-chirp tone; closest in spirit to the MGS two-note codec "pi-pi". Short WAV. |
| Doorbell ring (`doorbell-old-tring.ogg`) | Dub (Wikimedia Commons), uploaded by qubodup | https://opengameart.org/content/doorbell-ring | CC0 | Verified on OGA page (CC0 1.0). Old mechanical bell tring; tagged telephone. Fine as a rotary-ish ring. |
| Interface Sounds (100 files) | Kenney | https://kenney.nl/assets/interface-sounds | CC0 | License verified. Already in CREDITS. Two clicks/blips, pitched, make a clean codec ring and a pick-up blip. |
| Digital Audio (60 files) | Kenney | https://kenney.nl/assets/digital-audio | CC0 | License verified. Alternative synth beeps. |
| "Frequency Static Sound Effects" | bretbernhoft | https://opengameart.org/content/frequency-static-sound-effects | CC0 | Already in CREDITS. Use for the radio static bed under the portrait. |

Recommendation: do not hunt a real telephone; the MGS codec ring is a synthetic two-note chirp. Layer two Kenney blips (a fourth or fifth apart), repeat twice, then bitcrush. Chirptone is the drop-in alternative.

## 5. Ambience without guard barks

| Candidate | Author | Link | License | Notes |
|---|---|---|---|---|
| Sea Waves with Tern Calls (S0267) | DenisChardonnet, BigSoundBank | https://www.bigsoundbank.com/sea-waves-and-seagulls-s0267.html | CC0 | Verified. 58 s, 44.1 kHz/16-bit stereo, WAV/OGG/MP3. Page states CC0 public-domain-equivalent, no attribution. Outdoor, no voices or music. Best Harbour bed. Loop point needs a crossfade. |
| Sea and river wave sounds | RandomMind | https://opengameart.org/content/sea-and-river-wave-sounds | CC0 | Verified. Vistula river waves, 5 min MP3 (12 MB) and 1.5 h zip. Long enough to need no loop; river rather than sea, so use quieter under the gulls. |
| Dark Sci-Fi Audio Pack (`Pulse`, `Airy`) | SRG774 | https://opengameart.org/content/dark-sci-fi-audio-pack | CC0 | Verified. "Pulse" is a continuous low drone; good ambience for the Relay station and Research annex interiors. |
| Interface Sounds / Sci-fi Sounds | Kenney | https://kenney.nl/assets/sci-fi-sounds | CC0 | Engine-tagged hums; usable for interior machine room tone. |

Notes: no voice-bearing candidate was accepted; the wave and drone files above contain none per their pages (the tern calls are birds). Listen once before shipping to confirm no distant human voice.

## 6. Three music beds: calm / alert / search

Only one coherent CC0 set was found, so the three beds come from the same author and match in tone.

**Dark Sci-Fi Audio Pack** by SRG774, https://opengameart.org/content/dark-sci-fi-audio-pack, CC0 (verified; "no attribution required", author appreciates a credit). Tracks: Sector, Airy, Pulse, Urgent, Transmission, Title, Hover, Victory. Designed to loop; author recommends a slight crossfade when looping. Individual MP3s, plus a 13.3 MB `ogg.zip`. Made for Ball Logic.

| Bed | Pick from pack | Rationale (from track descriptions; audition before locking) |
|---|---|---|
| Calm | Airy (alt: Sector) | Atmospheric pad |
| Alert | Urgent | Described as a driving, high-stakes pulse |
| Search | Pulse (alt: Transmission) | Low-profile continuous heartbeat-like pulse; hold tension without full alert intensity |

Alternates:
- Alert Music by Muerteloca12 ("TheGrimdarkStudios"), https://opengameart.org/content/alert-music, CC0, one MP3 (1.8 MB) made for "enemy detects the player", credit requested as courtesy only. Duration not stated.
- Elevator To Reactor (loop), Hazmat Harry: appears under a bundle page whose resulting license is CC-BY 4.0. **Do not use** unless the individual page is confirmed CC0.

Risk: all three come from one pack, so the Aigis cross-fade between beds should be tested on tempo/key match (not verified here). The pack's `Title`/`Victory` could cover the main menu and post-Mission stinger.

## 7. PSX-processing in Godot 4.7

Sources: Godot docs (latest) for importing audio samples, AudioEffectDistortion, audio buses, ProjectSettings.

**Godot has no bitcrush effect.** The `AudioEffectDistortion` class has `MODE_LOFI` that "reduces bit depth from 16-bit down to 2-bit, imitating early digital audio devices". It does not reduce sample rate, so combine with import-time rate capping. (The docs fetched for AudioEffectDelay and the effects list show no separate bitcrush class.)

Import time (per file, `.import`):
- WAV import options: `Force > Max Rate` (caps sample rate; set 11025 Hz for SFX/footsteps/stings, 22050 Hz for ambience and music), `Force > Mono` (halves size; mono also suits 3D positional SFX), `Force > 8 Bit` (available but docs say it "noticeably lowers quality"; use it on SFX for the crunch, not music), `Edit > Trim`, `Edit > Normalize`, `Compress > Mode` (PCM, IMA ADPCM, Quite OK Audio; use PCM for tiny SFX you want to crunch predictably; ADPCM adds its own PS1-like artefacts).
- Docs recommend WAV for short repetitive SFX; Ogg Vorbis for music, speech and long sounds; MP3 for CPU-limited platforms. Ogg/MP3 imports have Loop, Loop Offset, BPM, Beat Count and Bar Beats but **no Max Rate option**, so pre-resample music to ~22 kHz outside Godot (Audacity or ffmpeg `-ar 22050`) before saving to `assets/`, or rely on the bus effect.
- Project: `audio/driver/mix_rate` default 44100; lowering it (for example 22050) would make the whole mix coarser, but it is global (including the codec voice) and I did not test it. Prefer per-file and per-bus processing.

Bus layout (Audio tab, effects applied top to bottom; buses route left toward Master, Master below 0 dB):
- `SFX` bus: `AudioEffectDistortion` mode `LOFI`, `drive` ~0.3-0.5, `pre_gain` ~0 dB, `post_gain` -3 dB to compensate; then `AudioEffectLowPassFilter` at ~6-8 kHz to remove the fizz (docs: attenuates above `cutoff_hz`). Note `keep_hf_hz` default 16000 Hz passes content above that cutoff unprocessed; lower it to affect more of the spectrum.
- `Music` bus: same LOFI with lower `drive` (~0.15-0.25) and LPF ~8-10 kHz so the bed is not muddy.
- `Codec` bus: stronger LOFI (`drive` ~0.6), high-pass plus low-pass band-limiting (~300 Hz to ~3 kHz) for the radio feel; the static pack goes through this too.
- Per the docs, an enabled effect still alters sound at `drive = 0`; toggle with `AudioServer.set_bus_effect_enabled()` to bypass (useful for a settings toggle and A/B testing).
- Web exports: effects don't work with the default Sample playback mode; they need Stream mode (docs). Not relevant for a desktop build, noted for completeness.

Starting values are my suggestions, not from the docs; tune by ear. The doc-sourced facts are the mode list, property ranges (`drive` 0-1, `pre_gain` -60..60 dB, `post_gain` -80..24 dB, `keep_hf_hz` 1-20000), and the import options.

## Licensing checks

- Kenney packs: kenney.nl pages list "Creative Commons CC0" (Impact 130 files v1.0 2019; Sci-fi 70 v1.0 2020; Interface 100 v1.0 2020; Digital Audio 60 v1.0 2012; RPG Audio 50 v1.0 2014).
- OpenGameArt CC0 pages quote the license in the page badge; where a listing shows licenses per item, I confirmed the individual item page.
- BigSoundBank: page states CC0, "public-domain equivalent".
- Freesound: FAQ states CC0 lets you do "pretty much what you want"; no attribution requirement; you may not claim authorship; downloads need a logged-in account.

## Rejected (not CC0)

- Footsteps on different surfaces, congusbongus: CC-BY 3.0 (https://opengameart.org/content/footsteps-on-different-surfaces). Best surface coverage, but needs attribution and underlying clips are Freesound mixes of unknown license. Usable only if the polish bar allows CC-BY credit.
- Phone Ring Tone: CC-BY-SA 4.0.
- Distant Screams horror pack: CC-BY-SA 4.0.
- Dark Ambience Loop (qubodup): CC-BY 3.0 / GPL.
- Eyes in the Shadows, Continuum compilations: CC-BY 4.0.
- Paid itch.io packs (footsteps, horror stingers): not free.

## CREDITS lines to add when files are used

Format used by the repo: `- "<title>" by <author>, <url>, CC0 1.0`. One line per pack above that ships a file. Kenney Sci-fi Sounds and Interface Sounds and bretbernhoft static are already listed; add Impact Sounds, RPG Audio, Digital Audio if they supply clips.
