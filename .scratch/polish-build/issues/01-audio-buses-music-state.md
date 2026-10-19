# 01: Audio buses and music state

**Spec:** decisions in [polish map](../../polish/map.md); open one decision ticket in `../../polish/issues/` only if a question stays open. Supersedes most of build ticket 34 (sounds); see [audio direction](../../polish/issues/02-audio-direction.md).

**What to build:** The game has a working mix. Patrol plays quiet ambience. Alert and Evasion each have a music track that follows the highest guard state in the Mission, holding at least ~2 s on a change. Music ducks about 6 dB while a Codec call is playing. Per-bus volume is exposed for the settings screen.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Buses: Master → Music, SFX, UI/Codec, Ambience; bitcrush on SFX only
- [x] Highest guard state drives music; Suspicion changes no music; 2 s minimum hold
- [x] Music ducks ~6 dB during a Codec call and recovers after
- [x] Per-bus volume setters available to build ticket 33
- [x] State-to-music logic is node-free and covered by a test
- [x] Footsteps and knock use the SFX bus; sounds used are CC0 with `CREDITS.md` lines

## Answer

Added the `Mixer` autoload (`audio/mix.gd`, class `Mix`): buses Music, SFX (LOFI bitcrush), UI (UI and Codec), Ambience under Master; `set_volume(bus, 0..1)` / `volume(bus)` for the settings screen; `codec_call(bool)` ducks Music 6 dB. `ai/music_state.gd` (node-free, tested) maps the highest guard state to alert/evasion music with a 2 s hold; Suspicion and Patrol are ambience only. Operative footsteps and knock play on the SFX bus via `Mix.sfx_at`.

Open: no real CC0 music is on disk (Dark Sci-Fi Audio Pack was not downloaded; Pizza Doggy OST is not CC0). `music_alert`, `music_evasion` are Kenney CC0 placeholder loops, and footstep/knock are Kenney stand-ins; swap files in `assets/audio/` and `CREDITS.md`. Nothing calls `codec_call` yet (no live Codec player exists). Stings are not included.
