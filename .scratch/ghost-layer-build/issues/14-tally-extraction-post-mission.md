# 14: Mission tally + Extraction + post-Mission screen

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Playing a Mission now feeds Aigis: Habit triggers count during play, reaching the Extraction point ends the Mission, and a post-Mission screen shows the six-Habit icon strip with arrows before the record is updated.

**Blocked by:** 12, 08

**Status:** ready-for-agent

- [ ] Habit triggers from the spec's "Measured by" column add points to a live Mission tally (Lethality joins later), shown in the F3 overlay
- [ ] Reaching the Extraction point with objectives done ends the Mission
- [ ] The post-Mission screen shows a 0–3 icon per Habit with rise/fall arrows, with no raw numbers and no Lethality, in E's white/grey
- [ ] Completing calls complete_mission; aborting applies nothing
