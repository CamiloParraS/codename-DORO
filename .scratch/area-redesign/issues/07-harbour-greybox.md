# Harbour greybox

Type: task
Status: resolved
Blocked by: 04, 05

## Question

Build the Harbour from its diagram (the Tanker berth layout, variant B on the `prototype/harbour-diagram` branch) as a playable greybox in `areas/harbour/`. It needs:

- the new outline and cover, including the moored freighter (hull, deck cargo, bridge, gangway) built from boxes;
- Crawlspaces and Ladders;
- guard posts with idle behaviours, and a guard count set by the Area;
- every named spot the shared script needs;
- the lift placement, with its shaft lined up over the Core space from the [Core space diagram](05-core-space-diagram.md). The gallery room itself is built by the Core Mission build ticket, not here.

Play it under the Clean slate, Ghost and Butcher Presets. Check whether 10 base guards is right, given that 5 of them are on the deck. Also time a bow-to-lift run under Butcher. The Core Mission starts at the bow again, and it may run long. Record what the approach got right and wrong, so the Relay station and Research annex diagrams can apply it.

This is a real build: the map's Notes carry execution into this ticket.

## Build (2026-10-16)

The greybox is built and runs.

**Source:** `tools/build_harbour.gd` generates `areas/harbour/harbour.tscn` from variant B's data and bakes the navmesh: `godot --headless --path . --script tools/build_harbour.gd`. Until the layout settles, tune the data there and rebuild. Don't hand-edit the scene.

**What's in it:**
- Outline: cliff (west), fence with the road gap (north), quay kerbs, the south pier with the Extraction point at its tip, and a sea plane. Dropping into the sea returns you to the last Checkpoint (`areas/sea.gd`). The rest of the Backdrop kit isn't built.
- The freighter: hull with its deck at 2 m, bow, rails, bridge, deck containers, hatches, and a gangway ramp down to the quay. The stern rail has a 1 m gap above the pontoon for the stern drop.
- Yard: the crane with a Ladder (top at 8 m), raised Warehouse B with a Ladder (roof at 6 m), Warehouse A and the gatehouse as enterable shells with door gaps, containers, low cover, and the lift housing in the cliff (cage at diagram (8, 32), mouth east, lined up over the Core lobby).
- Crawlspaces: under the stern pier (10 m), the container stack (5 m) and Warehouse B (10 m). Each has a 1.2 m ceiling and a carry block at both mouths (collision layer 4, solid only while carrying).
- All named spots, 4 camera mounts, 2 sentry high points (`scan` 90), 3 extra posts (PostExtra1 has look-in `hold` stops at both lane Crawlspace mouths), 4 spoof places, and a placeholder TargetPost by the lift for the Core's director.

**Mechanics added on the way (from the Crawlspace and Ladder rules and Guard idle behaviours):**
- `Guard.patrol()`: facing stops (`hold`) and the `scan` sweep. Chatting pairs use the node-free `Chat` turn timer: a guard on its turn shows ((·)) and can be recorded, and its lines show as a subtitle within 10 m.
- Shared Area script: no more hard-coded 10. Every `$GuardPosts` post is staffed, and it reads `hold`/`scan`/`chat` meta. Relay and Annex have exactly 10 posts, so nothing changes for them.
- Operative: E climbs a Ladder at 1.8 m/s, C or E drops off, and nothing else works while climbing. It can't stand up under a ceiling, and the camera takes the start Marker's facing.

**Checked by machine:** all 279 tests pass, 5 of them new. In the running game, 11 guards spawn, all on the navmesh. The deck connects to the yard over the gangway. The crane Ladder climbs to its top. The chatting pair face each other and alternate turns. The gangway post sweeps.

**Findings so far:**
- **The diagram has 11 base guards, not 10.** The 5 on deck count the chatting pair as 2, and the yard lists 6 (Y1–Y6). The greybox places all 11. Whether that's right is the playtest's call.
- **Bow-to-lift traversal floor:** the loud route (deck, crate, south lanes, lift) is 119 m on the navmesh, about 24 s at a run. The sneak route is about 134 m, 15 m of it crawled, about 75 s fully crouched. The Core's surface leg is short in pure travel. Waiting on sweeps and fighting will set its real length.
- O1 faced the bow, so he spawned looking straight at the player. He now faces starboard (east), across the hatches and container the crouch beat uses, and stays at the diagram's (70, 25). This departs from the diagram's facing.
- The starboard deck container (diagram [74, 20, 3, 7]) runs to the rail, so the crouch beat passes it on the west side, about 3.5 m from O1. Check whether the look-out's peripheral cone catches it.

**Playtest checklist (HITL):** open Free mode and play the Harbour under each Preset.
1. **Clean slate:** walk the five onboarding beats in order (crouch past O1, choke O2, hide the body in the nook, record the pair, spoof O5 "go check the Dock"). Note any beat that doesn't read or can't be done.
2. **Ghost:** take the manifests' and the radio log's sneak Approaches. Check that CamPier and CamWarehouseA see the Crawlspace exits and that PostExtra1 looks into both lane mouths. Try carrying a body into a Crawlspace: it should refuse.
3. **Butcher:** time a bow-to-lift run on the loud line, and note how long reinforcements from the north road take to reach the manifests.
4. **Guard count:** 11 or 10? If 10, say which one to drop.
5. Write down what the approach got right and wrong, for the Relay station and Research annex diagrams.

## Answer

**The approach holds.** Two playtest runs (2026-10-16):

- **Stealth run:** the onboarding beats played as designed:
  1. Choked O1 and hid him behind a container.
  2. Recorded a voice and spoofed the gangway guard away.
  3. Took the usual route and rerouted a guard to grab the manifests.
  4. Tranqed the guard at the next objective.
  5. Came back through the tower.

  Two things went wrong:
  - **Couldn't find the Extraction point.** The player went back to the ship looking for it. Nothing marked it in any Area, and the old Harbour had it in the start corner. **Fixed:** `areas/extraction_point.gd` now draws a faint green light column over every Extraction point.
  - **O1 woke while the player was still on the deck** and had to be put down again. Then the alert came, and the run ended with a sprint to the Extraction point. Waking after 90 s is by design (`NEUTRALIZED_TIME`), so this is the intended pressure, not a bug.
- **Loud run:** every guard on the tanker could be killed, so the run was easy. The deck's 5 guards fight alone. → [Countermeasure tuning](10-countermeasure-tuning.md).
- **Not tried:** a full stealth, no-trace run.
- **Ladders:** guard behaviour needed work. **Partly fixed:** an alerted or searching guard whose last-known spot is on a Ladder's roof now goes to that Ladder's foot and watches the roof. It doesn't stand at the nearest navmesh point and sweep. This is the Crawlspace and Ladder rules as written (`Guard.goal()` / `ladder_foot()`). Verified in game: GuardY6 went to Warehouse B's Ladder foot facing the roof. One test was added; 280 pass. But on a loud run every guard gathers at the foot, and the player is stuck on the roof. → [Guards and Ladders on alert](12-guards-and-ladders.md).

Decisions:
- **Guard count: 11, kept.** The diagram's "10" missed that the chatting pair counts as 2. The Area sets its count by the posts it places: 5 on deck, 6 in the yard.
- **Bow-to-lift under Butcher:** not timed separately. Pure travel is 119 m on the loud line (about 24 s at a run), so the Core's surface leg is not what makes it long.
- **Departures from the diagram:** O1 faces starboard instead of the bow, because facing the bow had him spawn looking at the player.

**Lessons for the Relay station and Research annex diagrams:**
1. **Count guards as spawned.** A chat post is 2 guards. Write the total next to the diagram.
2. **Check every facing against the start and the main route.** A guard facing the spawn reads as unfair, however far away he is.
3. **Mark heights.** The Operative can't jump, so every level change needs a ramp or a Ladder, and every drop the player shouldn't take needs a kerb or rail. The diagram should show deck, roof and ledge heights.
4. **Crawlspaces fix the footprint.** The structure around a tunnel is solid, and a tunnel is at most 10 m long, so Warehouse B shrank from 12 m to 10 m deep to fit. Size buildings with Crawlspaces to the tunnel.
5. **Keep route points clear of cover.** Two of the diagram's route points sat inside low cover. The generator now warns about any marker inside solid geometry.
6. **Draw the diagram as metre data the generator can read.** Variant B went from data to a playable scene in one script, `tools/build_harbour.gd`. The Relay station and Annex diagrams should keep the same data shape, so their greyboxes can reuse it.
7. **Make the Extraction point findable from the route back.** A Mission that ends far from the start needs a sightline to its beacon from the last objective.
8. **An isolated group must have a way to call for help.** Every group of guards cut off from the rest, like the tanker deck, needs a reason the loud player can't clear it alone: a reinforcement path, an alarm, or a camera.

**Left open, small:**
- Carrying a body into a Crawlspace mouth is blocked, but no "put the body down" prompt shows.
- The Core room is its own Extraction point, so the beacon column would poke through its ceiling. Hide the beacon there when the Core Mission is built.
