# 01: Audio buses and music state

**Spec:** decisions in [polish map](../../polish/map.md); open one decision ticket in `../../polish/issues/` only if a question stays open. Supersedes most of build ticket 34 (sounds); see [audio direction](../../polish/issues/02-audio-direction.md).

**What to build:** The game has a working mix. Patrol plays quiet ambience. Alert and Evasion each have a music track that follows the highest guard state in the Mission, holding at least ~2 s on a change. Music ducks about 6 dB while a Codec call is playing. Per-bus volume is exposed for the settings screen.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Buses: Master → Music, SFX, UI/Codec, Ambience; bitcrush on SFX only
- [ ] Highest guard state drives music; Suspicion changes no music; 2 s minimum hold
- [ ] Music ducks ~6 dB during a Codec call and recovers after
- [ ] Per-bus volume setters available to build ticket 33
- [ ] State-to-music logic is node-free and covered by a test
- [ ] Footsteps and knock use the SFX bus; sounds used are CC0 with `CREDITS.md` lines
