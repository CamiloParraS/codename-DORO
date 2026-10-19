# 29: Briefings + Voice lines + Profile chatter

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Aigis talks: the Briefing before each Mission plays the Voices' lines chosen by plan_mission, the post-Mission screen adds the Dominant Voice's line, and guards hint at and confirm Countermeasures in the field.

**Blocked by:** 28, 12

**Status:** ready-for-agent

- [ ] The Briefing screen plays briefing_keys: Pallas names the top 1–2 Habits, the sponsor hints per answered Habit, the Dominant Voice closes, Nike's line when Takedowns L3 is deployed; Mission 1 gets only the close
- [ ] With F3 on, the Briefing shows the plan table
- [ ] The post-Mission screen shows one Dominant Voice line by band × whether this Mission's Lethality was 0
- [ ] Guards say the warning chatter for a Habit at 50 points before a level and the confirmation once its Countermeasure is deployed; 2 variants per set; heard only within hearing range
- [x] All lines keyed (placeholder text acceptable until 35 and 36)

## Comments

2026-10-19: Built test-first (`tests/test_voice_lines.gd`, node-free `ai/voice_lines.gd`). Verified in tests: every key `plan_mission` can emit and every ladder hint, post-Mission and chatter key exists in en and es; Mission 1 yields only the close; chatter warns from 50 points and confirms once deployed, 2 variants per set, heard only within `Chat.HEARD`. Wired but left to a playtest (not seen on screen): Briefing now types `tr(key)` lines; F3 plan table on the Briefing (it joins group `mission_plan`, which the overlay reads); post-Mission screen shows `VoiceLines.post_key` line; Harbour guards mutter `chatter_sets` every ~20 s on patrol when the Operative is within 10 m. Line text is placeholder until 35 and 36. Headless runner: `godot --headless --path . tools/run_tests.tscn [-- file_substring]`; 12 scene-heavy tests (character_model, relay_station, targets, debug_overlay, harbour ladder) fail in it for tree reasons unrelated to this ticket.
