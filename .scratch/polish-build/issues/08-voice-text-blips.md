# 08: Voice text blips

**Spec:** decisions in [polish map](../../polish/map.md); see [audio direction](../../polish/issues/02-audio-direction.md).

**What to build:** Codec calls and Briefing lines play a short blip per character, pitched differently for each of the five Voices (Promachos, Nike, Pallas, Gorgo, Glaukopis). No recorded or TTS voice.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Each Voice is distinguishable by pitch alone
- [ ] Blips play on the UI/Codec bus and do not stack or clip
- [ ] Skipping or fast-forwarding text stops the blips
