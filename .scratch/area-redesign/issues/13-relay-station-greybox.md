# Relay station greybox

Type: task
Status: resolved
Blocked by: 08

## Question

Build the Radio relay station from its diagram as a playable greybox in `areas/relay_station/`. The diagram is variant D of the [Radio relay station diagram](08-relay-station-diagram.md), on the `prototype/relay-station-diagram` branch. Follow the [Harbour greybox](07-harbour-greybox.md)'s method: a `tools/build_relay_station.gd` generator writes `relay_station.tscn` from the diagram data and bakes the navmesh. Tune the generator's data, never the scene.

It needs:

- **The new data shape:**
  - LAND with heights;
  - BUILDINGS with base heights;
  - RAMPS (road ramps, scree, office stair);
  - DECKS (the catwalk slab with rails).

  Share code with `build_harbour.gd` only where it falls out naturally.
- **The geometry:** the three terraces, the retaining walls and edge rails, the stilted barracks Crawlspace, the mast and antenna, the office with its roof stair, the 10 m catwalk with its Ladder, and the west Ladder.
- **The basic encounters:**
  - every guard post with its idle behaviours;
  - the chief and his escort;
  - the Relay console;
  - every named spot the shared script needs;
  - the Countermeasure spots.

  The SafeRoom moves into the moved office.
- **The Backdrop:** the outline only. This is a hillside with drops off the north and east cliffs, so check where kill volumes or collision go.

**Guard positions and difficulty are provisional.** They're finalised in [Countermeasure tuning](10-countermeasure-tuning.md), after [Guards and Ladders on alert](12-guards-and-ladders.md) is built in. Until then, check only that every Approach and both carry routes can be played.

Check:
- the navmesh reaches every terrace, the office roof and the catwalk;
- a carried chief can be walked to the helipad by the scree and by the summit ramp, and is refused at both Ladders and the Crawlspace;
- the escort can be spoofed away from the chief.

This is a real build: the map's Notes carry execution into this ticket.

## Answer

**Built.** `tools/build_relay_station.gd` writes `areas/relay_station/relay_station.tscn` from variant D's data and bakes its navmesh. The builders both generators use moved into `tools/area_builder.gd`, which `build_harbour.gd` now extends. Rebuilding the Harbour gives the same scene (only node ids change). Rebuild with `godot --headless --path . --script tools/build_relay_station.gd`.

- **The data shape:** LAND carries heights, BUILDINGS and CRAWLSPACES carry base heights, RAMPS are wedges (`_ramp`), and DECKS are raised slabs. Each ramp and the office stair end on a 2 m LAND landing so they meet the level above flush. To fit those landings, the road ramps are 18 m and the stair 8 m (the diagram had 20 and 10). The office walls are 3.7 m, so the roof top sits at 10 m, level with the catwalk. The road runs off the outline to a barrier at x 88.
- **Ladders:** both carry `walkable` meta. `Guard.ladder_foot()` skips walkable Ladders, so a guard who loses the Operative up one goes to the spot itself instead of waiting at the foot. The Harbour's Ladders are unchanged.
- **Backdrop:** a valley floor 14 m below with no collision. No kill volume is needed: the north, west and east cliffs, the 1 m rails on every terrace edge and the road barrier close the Area (there's no jump).
- **Encounters:** 9 posts, 10 guards as spawned (B1 is the chatting pair), plus the chief's escort and 3 extra posts. The SafeRoom is in the moved office. The 4 spoof places, 2 sentry high points and 4 camera mounts follow the diagram.

**Checks (2026-10-17):**
- The generator's reach report: the navmesh reaches every terrace, the office roof, the catwalk, the helipad, the console, the safe room and both of the chief's stops from the start.
- Carry routes measured on the navmesh: **63 m by the scree** and **91 m by the summit ramp** (the diagram says about 60 and 95).
- A carried chief is refused at the Crawlspace by its carry blocks (tested). At both Ladders he's refused by construction: Interact while carrying drops the body, so the Operative can't mount.
- `test_relay_station`: 8/8 pass. Full suite: 280/282. The two failures, `input_map` and `targets`' flee test, happen only in the editor (a non-`@tool` Guard is a placeholder there, and the editor's InputMap has no project actions). This build doesn't touch them.
- **Escort spoof, live:** in Mission 2, `Escort1.obey("go", SpoofGarage)` is believed. After 5 s he's 31 m from the chief, heading down the road ramp unalerted, while the chief walks his loop.

**Not done here:** a hands-on playtest of the three Approaches to each objective. Guard positions and difficulty stay provisional until [Countermeasure tuning](10-countermeasure-tuning.md), after [Guards and Ladders on alert](12-guards-and-ladders.md).
