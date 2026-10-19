# 31: Core Mission

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** The final Mission starts at Mission 1's insertion point in the Harbour, now fully fortified, then goes down the freight lift to the Core room, where the security director stands beside Aigis.

**Blocked by:** 24, 19, 20, 21

**Status:** done

- [x] The Core Mission runs at cap 3 / budget 6 in the Harbour from Mission 1's insertion point
- [x] Reaching the freight lift opens it (live call) and leads through a short corridor to the Core room with 2–3 guards
- [x] The director is the Target; the Core room is the Extraction point, so killing or choking completes it with no carry
- [x] The director says one subtitle line to Aigis when the Operative enters
- [x] Afterwards, E at the Core terminal hands off to the finale (stub until 32)

## Comments

- 2026-10-19 (implementation): `areas/core/core.tscn` is built by `tools/build_core.gd` (extends build_harbour.gd: the same fortified Harbour and insertion point, the west cliff cut for a 2 m corridor to a 20x20 Core room). `LiftDoor` is outside the NavRegion and frees itself when `IntelLift` is reached (the live call is that step's). The Core room is the Extraction point, so `MissionRun` now also counts a Down Target lying inside Extraction (choke needs no carry) and re-checks Extraction when a Target goes down with the Operative already standing in it. `CoreEntry` says `core.director.01` once; `CoreTerminal` calls the `finale` group's `begin()` after the Mission (stub: leaves to the Briefing until ticket 32). `core.gd` keeps the Operative in the room after the post-Mission screen. Tested in `tests/test_core.gd` and headless through the real scene (lift step, door opens, choke in the room ends the Mission). Not played in a window: guard feel in the room and corridor, the terminal prompt, and how the Core room reads visually are left to a playtest. Run suites headless with `godot --headless --path . --script tests/support/run.gd -- core campaign` (no names = all; `character_model.test_the_pistol_plays_its_own_clips` fails on a fresh clone without the Mixamo bake).
