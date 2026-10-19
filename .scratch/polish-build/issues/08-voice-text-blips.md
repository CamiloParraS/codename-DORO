# 08: Voice text blips

**Spec:** decisions in [polish map](../../polish/map.md); see [audio direction](../../polish/issues/02-audio-direction.md).

**What to build:** Codec calls and Briefing lines play a short blip per character, pitched differently for each of the five Voices (Promachos, Nike, Pallas, Gorgo, Glaukopis). No recorded or TTS voice.

**Blocked by:** 01

**Status:** resolved

- [x] Each Voice is distinguishable by pitch alone
- [x] Blips play on the UI/Codec bus and do not stack or clip
- [x] Skipping or fast-forwarding text stops the blips

## Answer

`audio/voice_blip.gd` (`VoiceBlip`, node-free) types text at 30 cps and returns one pitch per visible character; each Voice has its own disjoint pitch band (Gorgo 0.5, Promachos 0.7, Nike 1.0, Pallas 1.4, Glaukopis 2.0, plus a small per-character nudge). `Mixer.blip(pitch)` plays a generated 40 ms tone (no asset, nothing for CREDITS) on the UI bus through a single player, so blips cut rather than stack. The Briefing types its `brief.<voice>.*` lines this way; the first key press skips the typing and calls `Mixer.stop_blips()`. The Codec call player does not exist yet: it should use `VoiceBlip` + `Mixer.blip` the same way, and call `skip()` + `stop_blips()` on fast-forward.
