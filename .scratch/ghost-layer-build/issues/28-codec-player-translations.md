# 28: Codec/subtitle player + CSV translations

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Story plays through one small codec player: paused full-screen Codec calls before each Mission and live calls over a CALL bar during play, all from keyed lines in a CSV translation table.

**Blocked by:** 22

**Status:** ready-for-human

- [x] One CSV table (keys, en, es) with namespaced keys; tr() everywhere; only proper names are slotted in
- [x] A Codec call is data: an ordered list of [speaker, key]
- [x] Paused full-screen codec: two portraits, frequency, typewriter text, advanced with LMB/Space/Enter, PSone-style beeps
- [x] Live call: Peace Walker subtitles over a "CALL >> <speaker>" bar while play continues
- [x] Each Mission opens with a placeholder handler + analyst call; intel pickups trigger a live call
- [ ] Portraits are in-engine renders through the PSX pass (placeholder frames for now, needs art)

## Comments

- 2026-10-19 (implementation): `text/lines.csv` (keys,en,es; registered in project settings, imported to git-ignored `.translation` files). `CodecCall` (`ui/codec/codec_call.gd`, node-free) is the player model: an ordered list of `[speaker, key]`, typewriter via `VoiceBlip` (new `handler`/`analyst`/`operative` beep pitches), `press()` for paused calls, `advance(delta, true)` for live ones. `CodecScreen` is the full-screen paused view; the Briefing opens it on the last key press and the Mission starts when it finishes. The HUD has `live_call` (group `codec_live`) with the CALL bar and subtitles; `MissionRun` fires the step's `call` on each intel pickup. Calls are data in `Campaign.MISSIONS` (`codec` per Mission, `call` per step). Placeholder lines for all four Missions, English and Spanish. Tested in `test_codec_call.gd` and `test_translations.gd`. Not seen in play: the screen layout and beeps, the CALL bar. Briefing keys (`brief.*`) are still shown raw until tickets 29 and 35 write them into the table.

