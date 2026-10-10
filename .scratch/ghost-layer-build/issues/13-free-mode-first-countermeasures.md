# 13: Free mode + first Countermeasures + F3 overlay

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** From a minimal Free mode screen, the presenter picks a Preset and Mission and the Harbour visibly fights back: cameras, helmets and an extra patrol spawn per the plan, and F3 shows why. This is Milestone 1's "done when".

**Blocked by:** 12, 05, 09

**Status:** done

- [x] Free mode lists the four fixed Presets and the Missions; the cap still applies by Mission index; nothing is written anywhere
- [x] The Area places Countermeasures from plan_mission at its built-in spots
- [ ] Security cameras sweep with a guard-style front-cone meter; a full meter is a radio alert with no suspicion step (tested in the alert module); the tranq does nothing to them
- [ ] Helmets on the planned share of guards turn headshots into body hits
- [x] The extra patrol spawns as one more guard route
- [ ] F3 toggles an overlay on any screen showing Profile points/levels, Voice weights, Dominant Voice, Lethality (raw, ratio, band, projected ending), the plan (budget, pinned Habit, each pick with candidates and scores), guard alert reasons and Glaukopis's doubt
- [x] Playing the Harbour under Clean slate and then Butcher shows a visible difference

## Comments

- 2026-10-10 (implementation): Free mode is `ui/free_mode/free_mode.tscn`, now the project's main scene: toggle rows for the four Presets and the four Mission indices, a plan summary, PLAY. `Aigis.preset_record(preset, mission)` turns a Preset into a record (the ratio is stored as Lethality out of 100); the screen hands it to the Area's `MissionRun.record` and sets `return_to`, so committing the post-Mission screen comes back to Free mode. Nothing is written. `MissionRun` makes the plan in `_ready`; `areas/harbour/harbour.gd` reads `plan.deployed` through the node-free `Deployment` module (`missions/deployment.gd`, tested in `tests/test_deployment.gd`): cameras on all 4 mounts at Stealth L1, one extra patrol at L2 (`PostExtra1`, now with a route), helmets at 33/66/100% rounded, spread evenly over the spawned guards.
- Security camera: `actors/security_camera/security_camera.gd` (a StaticBody3D built in code, so a dart stops on it and does nothing). It uses `GuardAlert.camera_tick` (same meter and drain, no suspicion step, back to watching after 3 s unseen; tested) and radios every guard while alerted and seeing the Operative. Camera mounts now face away from their buildings, and the head sits 0.5 m out so its ray clears the wall. The sweep was tuned to ±35° over 10 s: at ±50° a still Operative at 13 m drained faster than it filled.
- Helmets: `Guard.wear_helmet()` adds a dark dome. A helmeted headshot still counts as a `headshot` tally event (the player's habit), but plays as a body shot.
- F3 is now an autoload CanvasLayer (`DebugOverlay`), so it shows on every screen. Left column: Profile points, levels, unlocked and deployed steps, plus this Mission's points; Voice weights and the Dominant Voice; Lethality (raw, ratio, band, and projected with this Mission folded in); the plan (budget, pinned Habit, each pick with sponsor, score and candidates). Right column: the tally, each guard's and camera's state and last reason, and Glaukopis's threshold and last judgement. It reads group `mission_plan` (MissionRun, or the Free mode screen as a preview). The radial radio now sends the `spoof` and `spoof_exposed` tally events.
- Fixed while playing: `MissionRun` never connected to the Extraction point, because the point joined its group in `_ready` after MissionRun's. It now joins in `_enter_tree`. Also, the post-Mission screen crashed when committing changed the scene, so it now marks the input handled first.
- Verified in play through the MCP: Free mode lists the four Presets and the Missions; Butcher on Mission 1 deploys nothing (the cap holds). Clean slate on Mission 1 shows 10 bare guards. Butcher on the Core shows all 10 guards in visible helmets. Ghost on the Core spawns 4 sweeping cameras and GuardExtra1, which walks its route. CamWarehouseB filled, radioed (guards show "CamWarehouseB radioed an alert"), then went back to "camera lost you". F3 works on the Free mode, Mission and post-Mission screens. Extraction, the post-Mission screen and the return to Free mode all work.
- Left unticked: the camera box, because a tranq dart on a camera was not tried in play (the code path is: the hit isn't a guard, so nothing happens). The helmet box, because the helmets were seen but a headshot on a helmeted guard was not tried in play. The F3 box, because Glaukopis's section was only seen empty ("no transmission yet"); no Spoofed transmission was sent in play. Vests, +2 guards and reinforcements show in the plan but aren't built yet (ticket 19). Mission 2 and Mission 3 play in the Harbour until their Areas exist.
