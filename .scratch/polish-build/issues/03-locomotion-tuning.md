# 03: Locomotion tuning

**Spec:** decisions in [polish map](../../polish/map.md); see [locomotion feel](../../polish/issues/06-locomotion-feel.md).

**What to build:** The Operative moves with the heavier feel played in the prototype: run 4.8, walk 1.9, crouch 1.3, start-up 7, stop 20, body turn rate 8.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Values applied in the Operative's locomotion
- [x] Locomotion tests pass, with the full-speed window widened to fit the slower start-up
- [x] Nothing else regresses: guard and carry tests still pass

## Answer

Tuned values live in `actors/operative/locomotion.gd` (run 4.8, walk 1.9, crouch 1.3, GET_GOING 7, SLOW_DOWN 20, new `TURN_RATE` 8 used by the body turn in `operative.gd`). `tests/test_locomotion.gd` pins the values and the full-speed window is 30 frames.
