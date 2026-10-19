# 29: Briefings + Voice lines + Profile chatter

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Aigis talks: the Briefing before each Mission plays the Voices' lines chosen by plan_mission, the post-Mission screen adds the Dominant Voice's line, and guards hint at and confirm Countermeasures in the field.

**Blocked by:** 28, 12

**Status:** ready-for-agent

- [ ] The Briefing screen plays briefing_keys: Pallas names the top 1–2 Habits, the sponsor hints per answered Habit, the Dominant Voice closes, Nike's line when Takedowns L3 is deployed; Mission 1 gets only the close
- [ ] With F3 on, the Briefing shows the plan table
- [ ] The post-Mission screen shows one Dominant Voice line by band × whether this Mission's Lethality was 0
- [ ] Guards say the warning chatter for a Habit at 50 points before a level and the confirmation once its Countermeasure is deployed; 2 variants per set; heard only within hearing range
- [ ] All lines keyed (placeholder text acceptable until 35 and 36)
