# 12: Aigis campaign module

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Aigis's between-Missions brain as a pure, deterministic module: fold a completed Mission into the campaign record, plan the next Mission's Countermeasures through the Voices, and resolve the ending. The four Presets and a generated Preset × Mission deployment table come with it.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] complete_mission: cap 0/1/2/3 and clamp to cap × 100 + 99, Stealth↔Combat tug of war (a no-alert Mission counts as Stealth), decay of at most ½ level for the other Habits, Lethality and denominator accumulation
- [ ] plan_mission returns weights, Dominant Voice, budget (0/2/4/6), pinned Habit, picks (step, sponsor, score, candidates) and briefing keys; pin first, then greedy fill by sponsor weight × points, ties in Habit-table order, steps in ladder order
- [ ] resolve_ending: ratio bands < 0.10 Pallas, 0.10–0.40 Nike, > 0.40 Gorgo, a value on a threshold goes up, an undefined ratio gives Pallas; Dominant Voice weight 2.0, others 1.0
- [ ] Presets Clean slate, Ghost, Trickster and Butcher as data (Habit levels + ratio)
- [ ] Tests cover every rule above, determinism, and a multi-Mission simulation
- [ ] A test writes the Preset × Mission deployment table as Markdown
