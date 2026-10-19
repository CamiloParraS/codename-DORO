# 05: Aigis telegraph and Stealth behaviour

**Spec:** decisions in [polish map](../../polish/map.md); see [Aigis world behaviours](../../polish/issues/04-aigis-world-behaviours.md). Follows ADR 0001: decision logic is node-free in `ai/`.

**What to build:** When Aigis has deployed a Stealth Countermeasure, guards perform a visible over-the-shoulder head-check with a "?" mutter before turning, on a share of turns that rises with the Habit level (clamped 25-75%). A ~1 s cyan icon and pose marks it. The Briefing names the Countermeasure and Metis gives a one-line radio call the first time the Operative sees it. This ticket also creates the shared telegraph used by tickets 06 and 07.

**Blocked by:** 04

**Status:** resolved

- [x] Shared cyan telegraph (icon + pose, ~1 s) readable from the game camera
- [x] Weighted trigger with seeded RNG; tests cover the 25-75% clamp
- [x] Behaviour debuts in Mission 2; Mission 1 unchanged; testable in Harbour through Free mode Presets
- [x] Briefing line and first-sighting Metis line exist

## Answer

Shared telegraph API (reuse in 06 and 07):
- `Guard.telegraph(kind: String, icon: String, clip: String, mutter := "")` in `actors/guard/guard.gd`: shows `icon` in Aigis cyan (`HudPalette.AIGIS`) on the guard's Mark label for `Telegraph.DURATION` (1 s), plays `clip` via `model.react`, says `mutter` as a subtitle when the Operative is within `Chat.HEARD`, and fires Metis's first-sighting line for `kind` once per Mission if `Telegraph.METIS` has one (`MissionRun.telegraphs_seen`). Add a `METIS[kind]` entry for a new behaviour.
- `ai/telegraph.gd` (`Telegraph`, node-free): `DURATION`, `METIS`, `first_sighting(seen, kind)`, and the Stealth trigger `head_check(level, rng)` / `head_check_share(level)` (25% per level, clamped 25-75%).
- Stealth wiring: `Deployment.head_check_level(deployed)` sets `Guard.head_check_level` (Harbour `_equip`); on reaching a patrol point the guard rolls its seeded `Guard.rng`, and on a hit stands 1 s with the telegraph before turning. Briefing key `brief.glaukopis.head_check` names it whenever Stealth is deployed (never Mission 1). Tests: `tests/test_telegraph.gd`.
- Open: the "?" icon, `look` clip and Metis wording are placeholders; the telegraph icon shows only while the guard is on PATROL.
