Type: grilling
Status: resolved
Blocked by: -

## Question

Which one or two telegraphed in-world guard behaviours per Countermeasure show Aigis adapting (flank, cover check, etc.)? How does the Briefing or radio name each? Must fit guard BT in `actors/guard/bt/`.

## Answer

- **Scope:** one signature in-world behaviour per Habit family; the already-visible Countermeasures (cameras, helmets, vests, extra patrol, pairs, overwatch) get nothing new.
  - **Stealth** (turn-around, HQ poll): guard does a visible over-the-shoulder head-check with a short "?" mutter before turning.
  - **Spoofing** (Glaukopis threshold, radio callback, single-use Voiceprints): guard stops mid-patrol and keys the radio to call HQ back, with a visible gesture.
  - **Combat** (vests, +guards, reinforcements): reinforcements arrive through a visible door/route with a shout and a flank path.
  - Built in `actors/guard/bt/` from existing nodes (`bt_turn_to_spot`, `bt_follow_order`).
- **Naming it:** the Briefing names the Countermeasure; Metis gives a one-line radio call on first sighting in the Mission.
- **Telegraph:** a ~1 s pose or icon readable from the game camera, in Aigis cyan (matches HUD and post-Mission strip). Legibility is checked in the guard-reactions prototype.
- **Frequency:** weighted, firing on a share of triggers that rises with Habit level, clamped 25-75%; seeded RNG for tests, logic node-free in `ai/` per ADR 0001.
- **Debut (Q5, answered by default, not confirmed):** Mission 2 onward; Mission 1 stays the clean tutorial; Harbour tested via Free mode Presets.
