# 24: Targets + Eliminate

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Missions can require a Target: a distinct, unarmed Palladion member on a fixed route with an escort, who flees to a safe room on alert, and who must be killed (weight 3) or Neutralized and carried to the Extraction point.

**Blocked by:** 22, 16

**Status:** ready-for-agent

- [ ] A Target walks a fixed 2–3-point route with one escort guard, using the guard tree
- [ ] On alert the Target runs to a safe room and stays until evasion ends
- [ ] Killing completes the objective on the spot and adds 3 to Lethality; a Neutralized Target carried to Extraction completes it
- [ ] The denominator adds 3 per Target; a carried Target spotted counts as a Down guard

## Comments

- 2026-10-16 (implementation): A Target is a `Guard` with `target = true` (group `targets`, Kind.TARGET model, unarmed, `safe_room`). Alert/evasion make `chase`/`search` flee to the safe room and `arrived()` means "in the safe room", so evasion times out there. `Guard.kill()` emits `target_kill`; the Harbour adds `targets` to the tally (escorts count as spawned). `MissionRun` gates Extraction on every Target being dead or carried and shows "KILL OR CARRY OUT". A carried Target spotted already counted as a Down guard through `_sense_down`. Missions 2, 3 and the Core carry a placeholder Target in the Harbour (greybox safe room beside the gatehouse). Checked headless (spawn, flee, kill, objective); not played yet, so the criteria stay for a playtest.
