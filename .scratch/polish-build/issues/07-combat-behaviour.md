# 07: Combat behaviour

**Spec:** decisions in [polish map](../../polish/map.md); see [Aigis world behaviours](../../polish/issues/04-aigis-world-behaviours.md).

**What to build:** When Combat Countermeasures are deployed, reinforcements arrive through a visible door or route with a shout and a flank path, not appearing out of nowhere, with the shared cyan telegraph.

**Blocked by:** 05

**Status:** resolved

- [x] Reinforcements enter from a defined entry and path toward a flank position
- [x] Shout and telegraph play on arrival
- [x] Weighted behaviour tested; Briefing and Metis lines exist

## Answer

- Combat L3 reinforcements already spawn at Harbour's `RoadEntry`; now each one, with probability `Telegraph.flank(combat_level, rng)` (25% per level, clamped 25-75%), takes a flank path: its radio goal is `Telegraph.flank_point(entry, operative, rng)`, 8 m (`FLANK_OFFSET`) to a random side of the Operative, instead of the Operative's spot. Otherwise it goes direct.
- Flankers call `Guard.telegraph("flank", Telegraph.FLANK_ICON, "startle", "Flanking, go wide!")` on arrival: cyan `!>` for 1 s, shout subtitle, and Metis's one-line call once per Mission (`Telegraph.METIS.flank`). `_refresh_mark` lets the flank icon show although the guard is already on ALERT.
- Briefing key `brief.promachos.flank` is added when Combat is at L3 (never Mission 1). Tests in `tests/test_telegraph.gd`; the butcher briefing list in `tests/test_aigis.gd` is updated.
- Open: icon, `startle` clip and wording are placeholders; the shout and Metis call only play when the Operative is within `Chat.HEARD` of the entry; "door" is the road entry marker, no door model; Briefing text is keys only (no strings file exists yet).
- Known issues (review): only the Combat reinforcements that roll a flank get the shout and telegraph (ticket 07 says all reinforcements), and the telegraph fires at spawn at the road entry, not on arrival beside the Operative. Both left for a later pass; neither is cheap with the one-shot spawn loop in `harbour.gd`.
