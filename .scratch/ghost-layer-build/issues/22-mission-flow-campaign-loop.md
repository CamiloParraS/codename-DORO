# 22: Mission flow + campaign loop

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** A campaign plays end to end in memory: each Mission is data (Area, objective steps, Targets, index), objectives advance through steps including intel pickups, and completing one goes to the post-Mission screen and on to the next Mission with its new plan.

**Blocked by:** 14, 18

**Status:** ready-for-agent

- [x] Mission data defines the Area, ordered objective steps, Targets and Mission index (which sets cap and budget)
- [ ] Extract-intel pickups complete objective steps; each step is a Checkpoint
- [ ] The flow goes placeholder Briefing → Mission → post-Mission screen → next Mission, linear with no replays
- [ ] Mission 1 in the Harbour is completable with intel extraction
- [ ] The current objective is shown on a minimal pause screen

## Comments

- 2026-10-15 (implementation): Missions are plain data in `missions/campaign.gd` (`Campaign.MISSIONS`, by index: title, Area scene, ordered steps `{intel, objective}`, targets), not `.tres` resources; GUIDE updated. `Campaign.record` holds the campaign in memory; `Campaign.play()` starts a Mission for both the Briefing and Free mode. `MissionRun` reads the steps for `record.mission`, shows only the current step's pickup (`areas/intel_pickup.gd`, walk-in Area3D like the Extraction point), takes a Checkpoint per step (the step is in the snapshot), and only allows Extraction once every step is done. The placeholder Briefing (`ui/briefing/`) lists the Mission, its `briefing_keys` raw and the objectives; past the Core it shows the ending band and returns to the main scene. Free mode has a temporary NEW CAMPAIGN button until the main menu (33). The pause screen shows `MissionRun.objective()`.
- Harbour intel: `IntelManifests` by Warehouse A's east wall, `IntelRadioLog` north of the gatehouse, `IntelLift` before the freight lift gate. Missions 2, 3 and the Core reuse these as placeholder steps until their tickets (25, 26, 31).
- Tested: `tests/test_campaign.gd` (Mission data and every step's pickup exists in its Area, objective text per step, a new campaign running Mission 1 to done). The loop was also driven headless through the real scenes (Briefing → Harbour → wrong pickup ignored → both steps → Extraction → commit → Mission 2's Briefing). Criteria 2-5 stay unticked until played: the pickups' reachability and the pause screen haven't been seen in game.
