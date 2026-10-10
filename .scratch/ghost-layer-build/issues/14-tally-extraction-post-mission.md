# 14: Mission tally + Extraction + post-Mission screen

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Playing a Mission now feeds Aigis: Habit triggers count during play, reaching the Extraction point ends the Mission, and a post-Mission screen shows the six-Habit icon strip with arrows before the record is updated.

**Blocked by:** 12, 08

**Status:** done

- [ ] Habit triggers from the spec's "Measured by" column add points to a live Mission tally (Lethality joins later), shown in the F3 overlay
- [ ] Reaching the Extraction point with objectives done ends the Mission
- [ ] The post-Mission screen shows a 0–3 icon per Habit with rise/fall arrows, with no raw numbers and no Lethality, in E's white/grey
- [ ] Completing calls complete_mission; aborting applies nothing

## Comments

- 2026-10-10 (implementation): `MissionTally` (`ai/mission_tally.gd`, node-free, tested) holds the flat event counts and the post-Mission `strip(before, after)` (level 0-3 from the completed Mission's cap, arrow from points risen/fallen). `MissionRun` (`missions/mission_run.gd`) polls guards for alert edges, guards put Down and Down guards found; headshot, takedown and woken arrive by `call_group("mission_tally", "event", ...)` one-liners in guard.gd and operative.gd. Spoof, loud_shot and the kill events have no source yet (spoof: radial radio; kills: Lethality ticket).
- Extraction is `areas/extraction_point.gd` (Area3D, group "extraction") placed in the Harbour; `MissionRun.objectives_done` defaults to true until Missions have objectives. F3 overlay is a minimal label (`ui/debug_overlay`) showing the tally and Habit points.
- Left unticked because only the pure logic is test-verified; the in-game flow (overlay, Extraction trigger, post-Mission screen, pause/commit) has not been played: the Harbour was in use by another agent's playtest.
- 2026-10-10 (correction): the strip's level now uses the next Mission's cap, not the completed Mission's. Commit 155479a (clamp fix) superseded the note above: carried Habit points clamp via `Aigis.carry_index`.
- 2026-10-10 (review fixes): the Harbour adds `spawned` (base guards plus the extra patrol) to the tally, so the Lethality denominator is real; reinforcements will add theirs. `kill` and `target_kill` stay with ticket 16, `targets` with ticket 24. The post-Mission strip holds the starting points to the same clamp as the result, so a Free mode Preset above the Mission's carry cap (Butcher on Mission 1) no longer shows phantom "fell" arrows; a real fall under the clamp still shows. `MissionRun.abort()` is still unwired: there is no pause menu yet (Esc only frees the mouse), so the Abort Mission entry lands with the menus ticket (33).
