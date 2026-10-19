# 05: Guard patrol → alert chain

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Guards patrol the Harbour on a LimboAI behaviour tree, see the Operative with the tested vision rules, and go patrol → suspicion → alert → evasion → patrol, with ?/! marks and a radio alert that puts every guard on alert.

**Blocked by:** 01, 04

**Status:** done

- [x] A pure, node-free guard alert state machine (shape from the prototype: tick / hear / radio, each returning a reason string) with McpTestSuite tests for: 0.35 suspicion, 0.25/s drain, alert lost after 3 s unseen, 12 s evasion, sighting during evasion re-alerts, radio alert
- [x] Vision: front cone 30° × 16 m plus peripheral 60° × 6 m at half rate, ray to the chest, multipliers for stance, motion and distance (×4 under 3 m)
- [x] Suspicion plays a 1 s turn-and-look beat, investigates, then a 5 s look-around
- [x] "?" and "!" over guards' heads
- [x] Guards path cleanly around obstacles (`path_height_offset`, no large desired distance; avoidance considered)
- [x] 8–10 guards patrol the Harbour
