# 05: Aigis telegraph and Stealth behaviour

**Spec:** decisions in [polish map](../../polish/map.md); see [Aigis world behaviours](../../polish/issues/04-aigis-world-behaviours.md). Follows ADR 0001: decision logic is node-free in `ai/`.

**What to build:** When Aigis has deployed a Stealth Countermeasure, guards perform a visible over-the-shoulder head-check with a "?" mutter before turning, on a share of turns that rises with the Habit level (clamped 25-75%). A ~1 s cyan icon and pose marks it. The Briefing names the Countermeasure and Metis gives a one-line radio call the first time the Operative sees it. This ticket also creates the shared telegraph used by tickets 06 and 07.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] Shared cyan telegraph (icon + pose, ~1 s) readable from the game camera
- [ ] Weighted trigger with seeded RNG; tests cover the 25-75% clamp
- [ ] Behaviour debuts in Mission 2; Mission 1 unchanged; testable in Harbour through Free mode Presets
- [ ] Briefing line and first-sighting Metis line exist
