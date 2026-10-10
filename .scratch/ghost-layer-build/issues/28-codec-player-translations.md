# 28: Codec/subtitle player + CSV translations

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Story plays through one small codec player: paused full-screen Codec calls before each Mission and live calls over a CALL bar during play, all from keyed lines in a CSV translation table.

**Blocked by:** 22

**Status:** ready-for-agent

- [ ] One CSV table (keys, en, es) with namespaced keys; tr() everywhere; only proper names are slotted in
- [ ] A Codec call is data: an ordered list of [speaker, key]
- [ ] Paused full-screen codec: two portraits, frequency, typewriter text, advanced with LMB/Space/Enter, PSone-style beeps
- [ ] Live call: Peace Walker subtitles over a "CALL >> <speaker>" bar while play continues
- [ ] Each Mission opens with a placeholder handler + analyst call; intel pickups trigger a live call
- [ ] Portraits are in-engine renders through the PSX pass
