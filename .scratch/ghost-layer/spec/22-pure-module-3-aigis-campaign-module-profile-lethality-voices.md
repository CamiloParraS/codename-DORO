# Implementation Decisions: Pure module 3: Aigis campaign module (Profile, Lethality, Voices)

This is one seam. A **campaign record** (Profile points per Habit, Lethality, Lethality denominator, next Mission index) plus a **Mission tally** go in; a new record, a Mission plan and an ending come out.

- `complete_mission(record, tally) -> record` folds a completed Mission into the record:
  - Habit points are clamped MGSV-style to cap × 100 + 99. The cap is per Mission: **0 / 1 / 2 / 3** (Missions 1, 2, 3, Core). Levels = points ÷ 100.
  - **Stealth and Combat tug of war:** the Mission decides one tendency (whichever side leads by a margin), which adds to that side and subtracts from the other. A Mission completed with no alert counts as Stealth.
  - Decay of at most ½ level per Mission for the other four Habits when they weren't used.
  - Lethality adds the Mission's weighted deaths (a guard 1, a Target 3; killing a Neutralized guard counts in full). The denominator adds the guards **actually spawned** in the Mission (extras and reinforcements included) plus 3 per Target.
  - An aborted or quit Mission is never folded in.
- `plan_mission(profile, lethality, mission_index) -> {weights, dominant, budget, pinned, picks[{step, sponsor, score, candidates}], briefing_keys}`:
  - Levels **unlock** Countermeasure steps, and the plan **deploys** them. The budget counts response levels: **0 / 2 / 4 / 6**. Steps deploy in order up each Habit's ladder. Unspent budget is fine.
  - **Pin:** the strongest Habit (highest level, ties broken by more points) gets its full unlocked response first.
  - **Greedy fill:** the candidates are each Habit's next unlocked step. Score = sponsor Voice weight × that Habit's points. Take the highest; break ties in Habit-table order.
  - **Weights:** the Dominant Voice is 2.0, every other Voice 1.0.
  - Fully deterministic: the same inputs always give the same plan.
- `resolve_ending(lethality) -> band`. **Lethality ratio** = Lethality ÷ denominator; undefined before Mission 1 (the band is then Pallas). Bands: **< 0.10 Pallas, 0.10–0.40 Nike, > 0.40 Gorgo**; a value exactly on a threshold goes to the higher band. The thresholds are tuned during the build.
- Accepted side effect: Lethality leaks into deployment (a lethal campaign gets more Gorgo gear), while the number stays silent and separate from the Profile.

**Habits and Countermeasure ladders** (sponsor Voice in brackets):

| Habit | Measured by | L1 | L2 | L3 |
|---|---|---|---|---|
| Stealth | guards put Down while no alert is active; a Mission with no alert | security cameras [Glaukopis] | one extra patrol [Promachos] | overwatch sentries on high points [Gorgo] |
| Combat | alerts raised, loud shots, kills during an alert | vests [Gorgo] | +2 guards [Promachos] | 2 reinforcements from the road entry, once per alert [Promachos] |
| Headshots | tranq or rifle headshots | helmets on 33% [Gorgo] | 66% [Gorgo] | 100% [Gorgo] |
| Takedowns | chokes and kills from behind | guards turn around more often [Pallas] | patrols in pairs [Gorgo] | choke takes 3 s and makes noise within 6 m; the kill stays at 0.5 s [Nike] |
| Downs | Down guards found, Neutralized guards woken | random HQ poll [Pallas] | a found Down guard means an instant alert [Nike] | targeted HQ poll [Pallas] |
| Spoofing | Spoofed transmissions sent, extra weight if exposed | threshold 40 → 25 [Glaukopis] | callback [Glaukopis] | single-use Voiceprints [Glaukopis] |

- Helmet: a headshot counts as a body hit. Vest: stops tranq body shots; rifle body hits needed go from 2 to 4. Cameras: the rifle destroys them, the tranq does nothing, and a destroyed camera is treated as a missing guard.
- HQ poll L1: about every 45 s, "<X>, report" to one random living guard, weighted toward guards who are Down. No answer within ~10 s sends the nearest guard to X's last position in suspicion. L3: polls the guard nobody has seen for the longest, using the guards' sight check run at a low rate on each other (fallback if that's too expensive: a random poll every 20 s).
- Trigger point values are tuned during the build and checked by a test that simulates several Missions.
