# 23: Characters + animations

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** The Operative and guards are Quaternius characters with animations instead of capsules, including the carry pose, and Targets have a distinct silhouette variant ready.

**Blocked by:** 08

**Status:** ready-for-agent

- [x] Operative and guard models with idle, walk, run, crouch, aim, takedown, Down and carry animations, retargeted in Godot (partial: the Quaternius free body is bare, so kinds are told apart by tint and Nikita gear props)
- [x] The carried guard rides in a fixed pose on the shoulder bone
- [x] A Target variant (red beret + red tint; no Target actor exists yet to use it) (cap or beret plus a different colour)
- [x] Only the files used are copied from `_raw/`; `CREDITS.md` notes the QAL licence
