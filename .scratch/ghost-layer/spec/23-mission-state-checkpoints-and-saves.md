# Implementation Decisions: Mission state, Checkpoints and saves

- A Mission's live state (Habit tally, Lethality so far, Voiceprints) is held apart from the campaign record. It is snapshotted at Checkpoints and folded in only on completion.
- **Checkpoint** (in memory only): objective step, Operative position, ammo, Scanner charges, Magazines, the Mission's Habit tally and Lethality, Voiceprints and flags, which guards are dead and where bodies lie. On restore, the dead stay dead and bodies stay put; every living guard (Neutralized ones too) returns to their patrol post with the alert cleared; Countermeasures stay as deployed.
- **Campaign slot file** (three slots): next Mission index, Profile points per Habit, Lethality, denominator, a complete flag, and the time last saved. No version field; a missing or unreadable file is an empty slot. Briefings, deployment and the Dominant Voice are rebuilt by `plan_mission`. A separate settings file survives New game.
- Writes happen only after the post-Mission screen commits the points. The Core is written at the terminal, before the finale, and marks the slot complete.
- Free mode writes nothing. Custom starts from Clean slate.
