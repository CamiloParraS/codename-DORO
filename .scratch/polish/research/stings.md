# Stings re-pick: bright, sharp, MGS-like (CC0 only)

Researched 2026-10-19 for ticket 08. Replaces the stings from `audio-packs.md` section 1 (horror stings, "too creepy"). Same license rule: CC0 only, license read from the owning page.

**Audition caveat:** this session has no audio playback. Kenney zips and the OGA files were downloaded to `_raw/stings/` (git-ignored) and their durations measured from the file headers, but character ("bright/sharp") is inferred from the file names, tags and descriptions. Listen to the shortlist once in `prototype/alert-loop` before locking. Nothing in `assets/` or `CREDITS.md` was touched.

Durations below are measured (Ogg granule position / WAV frame count), except `alert-beep.mp3` (35 KB, not measured, no decoder available).

## Why the earlier set failed, and what to look for

Kenney's UI/arcade synth packs are the right family: pure synth tones, short, no reverb tail, no horror texture. The OGA "stinger" results are almost all music-bed or horror material; the only true CC0 chiptune stings are congusbongus's. There is no purpose-made CC0 "enemy spotted" `!` sting on OGA or itch.io (itch CC0 packs found are generic 8-bit SFX libraries, see "Not used"). The `!` is therefore built from a Kenney synth stab, optionally layered.

## Cue 1: suspicion "?" blip

| Rank | Pick | Pack / author | License | Source | Duration | Why |
|---|---|---|---|---|---|---|
| Top | `question_001.ogg` (also `question_002..004`, 0.33 s each) | Interface Sounds, Kenney | CC0 (License.txt + page) | https://kenney.nl/assets/interface-sounds | 0.49 s (`_002.._004`: 0.33 s) | Purpose-named "question" UI blip: short synth, rising query feel. Four variants let you pick the least cute one or rotate them. |
| Alt | `highUp.ogg` | Digital Audio, Kenney | CC0 | https://kenney.nl/assets/digital-audio | 0.55 s | Single rising high tone, reads as "hm?"; cheaper-sounding and more 8-bit than the Interface set. (`pepSound3.ogg`, 0.44 s, is a second alternate.) |

## Cue 2: alert "!" sting

Sits with the ~0.2 s hit-stop, so the sound must hit in its first 10 ms.

| Rank | Pick | Pack / author | License | Source | Duration | Why |
|---|---|---|---|---|---|---|
| Top | `twoTone1.ogg` (variant `twoTone2.ogg`, 0.73 s) | Digital Audio, Kenney | CC0 | https://kenney.nl/assets/digital-audio | 0.72 s | Two-note synth alert, the closest thing in the pack to the MGS "!" two-pitch stab. Trim to ~0.4 s or fade the tail so it ends with the hit-stop. Optional layer: `phaseJump2.ogg` (0.39 s) for a sharper attack. |
| Alt | `alarm.ogg` ("Short alarm") | yd | CC0 (OGA page badge) | https://opengameart.org/content/short-alarm | 1.71 s | Tags: alarm, warning, attention, robot, computer. Beepy LMMS synth, bright not horror. Too long as-is; trim to the first beep(s). Fallback chiptune: `alert-beep.mp3` by chrispwns (CC0, https://opengameart.org/content/alertmenu-effect, 35 KB, FL Studio, "basic alert sound"), which is simpler and more notification-like. |

Other Digital Audio candidates if neither lands: `threeTone1.ogg` (0.83 s), `zapTwoTone.ogg` (1.31 s), `phaseJump1..5.ogg` (0.39-0.47 s).

## Cue 3: evasion-end relief

Wants a short, resolving, major-leaning cue that says "you are safe", not a fanfare.

| Rank | Pick | Pack / author | License | Source | Duration | Why |
|---|---|---|---|---|---|---|
| Top | `confirmation_002.ogg` (alts `_001` 0.29 s, `_003` 0.32 s, `_004` 0.49 s) | Interface Sounds, Kenney | CC0 | https://kenney.nl/assets/interface-sounds | 0.54 s | Clean synth "confirmed" resolve; short and bright, reads as relief. Pair with the Evasion music fading out. |
| Alt | `victory sting.ogg` (trim the final flourish) | congusbongus | CC0 (OGA page, CC0 1.0 link) | https://opengameart.org/content/victory-sting | 7.6 s whole file | TIC-80 8-bit sting: short buildup, pause, flourish. Far too long whole; cut to the flourish (~1-2 s) for a stronger "all clear". Same author's `betterluck.ogg` (https://opengameart.org/content/better-luck-next-time, CC0) is a failure sting, not for this cue. Also consider `powerUp2.ogg` (0.47 s) or `powerUp12.ogg` (0.86 s) from Digital Audio. |

## Exact files and where they are

All in `D:\Projects\codename-doro\_raw\stings\` (git-ignored):

- `kenney_digital\Audio\` (Digital Audio, 60 files, zip from kenney.nl): `twoTone1/2`, `threeTone1/2`, `phaseJump1-5`, `highUp`, `highDown`, `pepSound1-5`, `powerUp1-12`, `zapTwoTone*`.
- `kenney_interface\Audio\` (Interface Sounds, 100 files): `question_001-004`, `confirmation_001-004`, `select_*`, `glass_*`, `pluck_*`.
- `kenney_scifi\Audio\` (Sci-fi Sounds, 70 files): downloaded, no stings in it (engines, lasers, doors); not used.
- `alarm.ogg`, `alertbeep.mp3`, `victory.ogg`, `r1.wav`, `r2.wav` (loose files).

Kenney License.txt in each zip states CC0; kenney.nl pages list "Creative Commons CC0".

## Processing notes

- Keep the PSX pass light for these three: Max Rate 11025 Hz, mono, 8-bit optional. Heavy LOFI on a two-tone stab will turn it into noise; the `Music`-level drive (~0.15-0.25) is enough. This is a suggestion, tune by ear.
- Give the three cues distinct pitch registers so they read apart: "?" mid-high rising, "!" the loudest and the only one with a hard attack, relief lower and resolving.
- If the Kenney `!` still sounds too cute, layer `alarm.ogg`'s first beep under it rather than going back to horror material.

## CREDITS lines to add if used

Format: `- "<title>" by <author>, <url>, CC0 1.0`

- "Interface Sounds" by Kenney, https://kenney.nl/assets/interface-sounds, CC0 1.0 (already listed)
- "Digital Audio" by Kenney, https://kenney.nl/assets/digital-audio, CC0 1.0 (add; already floated in audio-packs.md)
- "Short alarm" by yd, https://opengameart.org/content/short-alarm, CC0 1.0 (only if used)
- "Victory sting" by congusbongus, https://opengameart.org/content/victory-sting, CC0 1.0 (only if used)

## Not used

- 8-Bit Sound Effect Pack by OwlishMedia (OGA): listed as CC0, but its bundled license text says "except reselling" and a commenter disputes true CC0. Rejected.
- Ultimate 8BIT SFX Library Vol 1-3 (ef9/mOsh, itch.io): CC0, but categories are blips/pickups/jumps/explosions with no alert content; not better than Kenney. The 1000-sound pack is paid.
- Polar_34 "8-bit Sound Effects" (itch.io): page says CC0 v1.0; contents not inspected, optional extra browse.
- Retro SFX Teaser by bitbleep: CC-BY 4.0. Cyberleaf Retro SFX: paid, non-CC0. WOW Sound jingles: paid.
- "tx alert" and "Zot" (OGA): CC-BY-SA 4.0.
- "Victory 2" (jkfite01): CC-BY 3.0. "Level finish fanfares" (jobromedia): CC-BY-SA 3.0.
- "Retro Sounds" by artisticdude (https://opengameart.org/content/retro-sounds-0, CC0): two arcade shooter WAVs (`retro_sound_1_0.wav` 0.84 s, `retro_sound_2.wav` 0.70 s, 48 kHz). Licensed fine but shooter-flavoured, not an alert; backup layer material only.
- Freesound CC0: not searched; downloads need a login and previews cannot be auditioned here. Open item if the Kenney set disappoints.
- "Sirens and Alarm Noise" (aquinn, CC0): siren-length, better for a whole alert state than a one-shot.
