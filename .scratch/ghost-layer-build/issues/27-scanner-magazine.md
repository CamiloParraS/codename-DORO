# 27: Scanner + Magazine

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The Operative carries two items cycled on the HUD item card: a Scanner that briefly reveals guard and camera cones through walls, and Magazines thrown to make a knock where they land.

**Blocked by:** 06, 07

**Status:** ready-for-human

- [x] Mouse wheel cycles items, F uses; the item card shows name and count/charges
- [x] Scanner: tap F, ~10 s of white/grey cone decals (red for alerted guards) for guards and cameras within 30 m through walls; 3 charges per Mission; usable while carrying
- [x] Magazine: hold F to show the arc, release to throw ~15 m, RMB cancels; it lands as a 10 m knock; 4 per Mission; not while carrying; hitting a guard does nothing
- [x] The resupply crate refills both

## Comments

- 2026-10-19 (verification): numbers checked against `actors/operative/items.gd`: Scanner 3 charges, 10 s, 30 m, usable while carrying; Magazine 4, ~15 m arc (`test_items.gd` lands it at 15 m), 10 m knock (`GuardAlert.KNOCK_RANGE`), not while carrying, RMB cancels, rays use layer 1 so a guard is never hit; wheel/F in `test_input_map.gd`; the HUD item card reads `label()` and `count()`. Ticked from code and tests; the cones through walls and the throw arc have not been seen in play, so the status stays ready-for-human until someone plays it.

