# 12: Aigis campaign module

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Aigis's between-Missions brain as a pure, deterministic module: fold a completed Mission into the campaign record, plan the next Mission's Countermeasures through the Voices, and resolve the ending. The four Presets and a generated Preset × Mission deployment table come with it.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] complete_mission: cap 0/1/2/3 and clamp to cap × 100 + 99, Stealth↔Combat tug of war (a no-alert Mission counts as Stealth), decay of at most ½ level for the other Habits, Lethality and denominator accumulation
- [x] plan_mission returns weights, Dominant Voice, budget (0/2/4/6), pinned Habit, picks (step, sponsor, score, candidates) and briefing keys; pin first, then greedy fill by sponsor weight × points, ties in Habit-table order, steps in ladder order
- [x] resolve_ending: ratio bands < 0.10 Pallas, 0.10–0.40 Nike, > 0.40 Gorgo, a value on a threshold goes up, an undefined ratio gives Pallas; Dominant Voice weight 2.0, others 1.0
- [x] Presets Clean slate, Ghost, Trickster and Butcher as data (Habit levels + ratio)
- [x] Tests cover every rule above, determinism, and a multi-Mission simulation
- [x] A test writes the Preset × Mission deployment table as Markdown

## Comments

- 2026-10-10 (implementation): `ai/aigis.gd` (`class_name Aigis`, static and node-free), tested by `tests/test_aigis.gd`, which also writes `docs/deployment-tables.md`. Decisions the spec left open:
  - **Tally** is a flat dictionary of event counts (`quiet_down`, `alert`, `loud_shot`, `alert_kill`, `headshot`, `takedown`, `down_found`, `woken`, `spoof`, `spoof_exposed`, plus `kill`, `target_kill`, `spawned`, `targets`). Trigger points live in `Aigis.TRIGGERS` and `mission_points(tally)` gives the overlay the per-Habit view. A Mission with no alert adds 50 Stealth points.
  - **Tug of war:** no alert means Stealth. Otherwise a side wins by leading by 30% of both sides' Mission points. The winner adds its points and the loser loses 50. On a draw, both sides add their own points.
  - **Decay:** a flat 50 points (half a level) for any of the other four Habits that earned nothing, floored at 0.
  - **The ratio** is a float, NAN while undefined (`lethality_ratio(record)`). `plan_mission` takes the ratio and caps levels by the Mission index. Scores and pin ties use raw points, so Presets keep their intent.
  - **Briefing keys:** `brief.pallas.habit.<h>` + `brief.<sponsor>.hint.<h>.<level>` for the top 1–2 answered Habits, `brief.nike.noisy_choke` when Takedowns L3 is deployed, and `brief.<dominant>.close`. With two named Habits and Nike's line, that comes to 6 lines; ticket 29 can trim.
  - **Open question for the user (cap):** `complete_mission` clamps with the cap of the Mission just completed, as the spec says ("at most 99 points carry out of Mission 1"). In a real campaign this means Mission 2 deploys nothing and the Core tops out at L2 steps. That contradicts "Mission 2 shows L1 steps … the Core up to L3" (campaign plan, user story 69). Clamping with the *next* Mission's cap instead is a one-line change in `complete_mission` plus the clamp and simulation tests. Presets in Free mode are unaffected.
