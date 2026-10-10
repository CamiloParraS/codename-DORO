# 02: Operative movement + shoulder camera

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The Operative can be moved around a test room with the Peace Walker-style camera: running by default, walking quietly, crouching, and a shoulder camera that never gets stuck in walls.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] WASD runs, holding Shift walks, C/Ctrl toggles crouch
- [ ] The camera is built from two spring arms (shoulder, then back), lifted from the stealth-core prototype; Tab swaps the shoulder
- [ ] The camera never clips into walls; the Operative's body hides when the camera is very close
- [ ] Mouse look respects a sensitivity value and an invert-Y flag (hardcoded defaults for now)
