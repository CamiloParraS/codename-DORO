# 18: Checkpoints

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Dying returns the Operative to the last Checkpoint with everything since undone, under the spec's rules: the dead stay dead, living guards reset to patrol.

**Blocked by:** 17, 14, 11

**Status:** ready-for-agent

- [ ] One Checkpoint per objective step, held in memory only (in memory, one at Mission start; the per-step calls to `MissionRun.take_checkpoint()` land with objective steps in 22)
- [ ] The snapshot holds objective step, position, ammo, Scanner charges, Magazines, Mission Habit tally, Lethality so far, Voiceprints and flags, dead guards and body positions (all but objective step, Scanner charges and Magazines, which don't exist yet: 22, 27)
- [x] On restore, dead guards stay dead and bodies stay put; every living guard (Neutralized too) returns to their post with the alert cleared; Countermeasures stay
- [x] Death and the pause menu's "Restart from checkpoint" both restore
