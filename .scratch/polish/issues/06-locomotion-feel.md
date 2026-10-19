Type: prototype
Status: resolved
Blocked by: -

## Question

Tune `actors/operative/locomotion.gd` (acceleration, turn rate, crouch speed, stop). Which values feel like MGS-weight rather than floaty? Record target values.

## Answer

Played on `prototype/locomotion-feel`: "feels really good like that". Keep the tuned values: run 4.8 (was 5.0), walk 1.9 (2.0), crouch 1.3 (1.8), GET_GOING 7 (10), SLOW_DOWN 20 (16), body turn rate 8 (12), plus the widened window in `tests/test_locomotion.gd` (18 -> 30 frames).
