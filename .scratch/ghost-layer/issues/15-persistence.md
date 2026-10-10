# Persistence

Type: grilling
Status: resolved
Blocked by:

## Question

What is saved between sessions, when, and where: the Operator profile (Habit points), the Lethality tally, campaign progress (Missions completed), and checkpoints inside a Mission? How many save slots are there? How does saving interact with the existing rules: Habit points apply only on Mission completion, both Profile points and Lethality roll back with checkpoints, and the campaign is linear with no replays? Does Free mode save anything, or does it always start from a Preset?

## Comments

- 2026-10-09 (from the map's fog): rollback rules come from [Operator profile and countermeasures](08-operator-profile.md) and [Combat verbs and Lethality](07-combat-verbs-lethality.md); the linear campaign and Presets from [Campaign plan](10-campaign-plan.md).

## Answer

Settled in a grilling session (2026-10-09). New glossary term: **Checkpoint**.

**Campaign save:** three slots, one playthrough each, all autosaved. A slot is one small file in `user://` holding the next Mission's index, the Profile points per Habit, the Lethality tally plus its denominator so far (guards actually spawned in completed Missions, plus 3 per Target), and a "complete" flag. Everything else (Briefing, Countermeasures, Dominant Voice) is rebuilt by Aigis's deterministic planning. No version field: a missing or unreadable file is an empty slot. Settings (sensitivity, invert Y, language, window mode, volume) live in their own file and survive a New game.

**When it's written:** only when a Mission is completed, after the post-Mission screen commits the points. The Core Mission is saved at the terminal, before the finale, and marks the slot complete, so a crash during the finale loses nothing.

**Checkpoints:** in memory only, never on disk. A snapshot holds the objective step, the Operative's position, ammo, Scanner charges and Magazines, the Mission's Habit points and Lethality so far, Voiceprints and their flags, and which guards are dead and where bodies lie. On restore, dead guards stay dead and bodies stay put; every living guard, Neutralized ones included, returns to their patrol post with the alert cleared; Countermeasures stay as deployed. Quitting mid-Mission loses the Mission: Continue restarts it from its Briefing, the same as aborting.

**Voiceprints:** they roll back with checkpoints (a death undoes the exposure that caused it). Nothing carries between Missions; every Mission starts with no Voiceprints.

**Menus:** the main menu has Continue (the most recently written unfinished slot; hidden if none), New game, Load, Free mode, Settings, Quit. New game and Load share one slot picker that shows each slot's next Mission (or "Complete") and when it was last saved. Overwriting a used slot asks for confirmation; there's no delete. The pause menu has Resume, Restart from checkpoint, Abort Mission (back to this Mission's Briefing, nothing applied), Settings, and Quit to menu (same as Abort, confirmed).

**Finished slot:** loading it replays the finale from its frozen state (Final debate → Ending → Epilogue), then returns to the menu. The Core Mission can't be replayed to choose differently; Free mode shows the other endings.

**Free mode:** writes nothing to disk. Checkpoints work the same way in memory. Custom always starts from Clean slate.
