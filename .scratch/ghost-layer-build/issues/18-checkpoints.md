# 18: Checkpoints

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Dying returns the Operative to the last Checkpoint with everything since undone, under the spec's rules: the dead stay dead, living guards reset to patrol.

**Blocked by:** 17, 14, 11

**Status:** ready-for-agent

- [ ] One Checkpoint per objective step, held in memory only
- [ ] The snapshot holds objective step, position, ammo, Scanner charges, Magazines, Mission Habit tally, Lethality so far, Voiceprints and flags, dead guards and body positions
- [ ] On restore, dead guards stay dead and bodies stay put; every living guard (Neutralized too) returns to their post with the alert cleared; Countermeasures stay
- [ ] Death and the pause menu's "Restart from checkpoint" both restore
