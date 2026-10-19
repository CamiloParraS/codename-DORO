# 02: Operative movement + shoulder camera

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The Operative can be moved around a test room with the Peace Walker-style camera: running by default, walking quietly, crouching, and a shoulder camera that never gets stuck in walls.

**Blocked by:** 01

**Status:** done

- [x] WASD runs, holding Shift walks, C/Ctrl toggles crouch
- [x] The camera is built from two spring arms (shoulder, then back), lifted from the stealth-core prototype; Tab swaps the shoulder
- [x] The camera never clips into walls; the Operative's body hides when the camera is very close
- [x] Mouse look respects a sensitivity value and an invert-Y flag (hardcoded defaults for now)
