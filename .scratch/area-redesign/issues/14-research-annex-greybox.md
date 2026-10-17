# Research annex greybox

Type: task
Status: resolved
Blocked by: 09

## Question

Build the Research annex from its diagram as a playable greybox, replacing the Relay station copy in `areas/research_annex/`. The diagram is variant A of the [Research annex diagram](09-research-annex-diagram.md), on the `prototype/research-annex-diagram` branch. Follow the [Relay station greybox](13-relay-station-greybox.md)'s method: a `tools/build_research_annex.gd` generator extends `tools/area_builder.gd`, writes `research_annex.tscn` from the diagram data and bakes the navmesh. Tune the generator's data, never the scene.

It needs:

- **The geometry:**
  - the lab with its 48 m corridor and rooms;
  - the interior walls, which are SOLID `Wall*` boxes with 2 m doorway gaps;
  - the six doors;
  - the loading hall and the dock;
  - the stilted pump house with its Crawlspace;
  - the gate and yard towers with their ramps;
  - the quarry pit rim, railed with no way down.
- **The basic encounters:**
  - every guard post with its idle behaviours;
  - the lead researcher and his escort, on the lab–office loop, with the vault as SafeRoom;
  - the files in the Archive;
  - every named spot the shared script needs;
  - the Countermeasure spots.
- **The Backdrop:** the outline only, including the quarry pit edge. Check where collision or kill volumes go.

**Guard positions and difficulty are provisional.** They're finalised in [Countermeasure tuning](10-countermeasure-tuning.md). Until then, check only that every Approach and both carry routes can be played.

Check:
- the navmesh passes every interior doorway, and guards path along the corridor and through the rooms;
- a carried researcher can be walked to Extraction by the north strip and by the corridor and dock, and is refused at the Crawlspace;
- the escort can be spoofed away from the researcher;
- the diagram's weak points, judged by playing:
  - the 48 m corridor sight line;
  - how little cover there is outside;
  - whether Extraction can be found after leaving the Archive or the lab.

This is a real build: the map's Notes carry execution into this ticket.

## Answer

**Built.** `tools/build_research_annex.gd` writes `areas/research_annex/research_annex.tscn` from variant A's data and bakes its navmesh. Rebuild with `godot --headless --path . --script tools/build_research_annex.gd`. On `tools/area_builder.gd`, `_building` now takes any number of doors per side (the lab has two on S, N and E), and `_ramp`, `_report_reach` and `_intel` moved there from the other two generators. Rebuilding the Harbour and the Relay station gives the same scenes (only node ids change).

- **Geometry:** the interior walls are a `WALLS` list (centre line, ends, 2 m gaps) built as `Wall*` boxes under the Lab. Changes from the diagram:
  - The tower stairs are 8 m long, since the diagram's 3 m and 6 m wedges (59° and 40°) are too steep to walk. The gate stair turns west so it clears the truck.
  - Each tower deck stands on one central leg and has a 1 m rail, open at the stair top. Without the rail, walking off an outer edge carries the Operative over the fence.
  - A road strip runs out of the north gate to a barrier, so RoadEntry (outside the fence) stands on ground.
- **Encounters:** 9 posts, 10 guards as spawned (A4 is the chatting pair), plus the researcher's escort and 3 extra posts. Three posts moved 1.5–2 m off cover edges they sat on: A1 off the container and the crawl's south face, the A4 pair off the low cover, and PostExtra3 off the container. A **SpoofDock** joins the diagram's three spoof places, because both deception Approaches send a guard to "the Dock".
- **Backdrop:** a plain outside the fence and a 14 m quarry pit beyond the rim, both without collision. No kill volume is needed: the fences, the rim rails, the tower rails and the road barrier close every edge (there's no jump).
- **Guard fix:** guards followed their path with `path_desired_distance` 0.5. Turning round a wall end into a 2 m doorway, a guard dropped the corner point early and steered straight into the jamb, where he stopped for good: the researcher did this at the lab door on his first trip back from the office. At 0.25 he loops indefinitely. This applies to every guard in every Area.

**Checks (2026-10-17):**
- The generator's reach report: the navmesh reaches every room, all 13 doorways (7 interior, 6 exterior), both tower tops, Extraction and RoadEntry. A spot in a doorway must be within 0.5 m across, so a closed doorway shows as a miss.
- Carry routes measured on the navmesh: **44.6 m by the north strip** and **63.0 m by the corridor and dock** (the diagram says 44 and 58). A carried researcher is refused at the Crawlspace by its carry blocks (tested).
- Mission 3, run headless with the real guards:
  - the corridor guard walks the corridor end to end;
  - the researcher walks lab → corridor → office and back through the doorways;
  - after `Escort1.obey("go", SpoofDock)`, the escort walks out through the loading hall to the dock unalerted and waits there about 10 s. He gets up to 40 m from the researcher, who carries on with his loop.
- `test_research_annex`: 7/7 pass. Full suite: 285/285 in the editor.
- **Weak points, measured rather than played** (raycasts at eye height):
  - **The corridor:** 46 m clear end to end, but a guard's front cone reaches only 16 m. There's a doorway at least every 12 m on each side, so it's long rather than deadly.
  - **Cover outside:** 7 low covers, 2 containers, the truck and 2 dock crates. The north strip has the truck and two low covers.
  - **Finding Extraction:** the light column (seen 12 m up) is visible from the lab's north door, the corridor's east door and the loading hall's east door. It's hidden from the Archive's back door, the front door, the crawl's south mouth and most of the south yard (behind the lab, the pump house and Container2). So after the files, the sneak and deception Approaches leave the Operative unable to see Extraction until the dock or the start corner. This is the lesson-7 warning, confirmed.

**Camera mounts (after the first playtest):** the cameras hung in the air. In all three Areas the diagrams had put the mounts 0.5–4 m out from any wall, while a camera hangs its head 0.5 m out from its mount with nothing drawn between them. Now each camera draws an arm from its mount to its head. A mount near a wall moved onto the wall face, pointing away from it: in the annex, CamFront, CamArchiveBack and CamNorthDoor on the lab; in the Harbour, CamWarehouseA and CamLift. A mount in the open stands on a pole and keeps the diagram's sight line: CamDock, the Harbour's CamPier and all four of the Relay station's. `_check_markers` now warns about any camera mount that isn't on a wall face or a pole. The poles reshaped the Relay station's navmesh polygons, and the path query then took the long way round the barracks: 70.6 m against 62.9 m. The lane itself is still open, so the scree carry route is now pinned to the barracks' north side (63.0 m).

**First playtest (2026-10-17, one run, loud):** knocked out the first guard and was spotted. Fought through with the assault rifle and found the path clear, took the files, knocked out the researcher and carried him to Extraction. The loud Approach plays end to end. That it felt clear once the shooting started is a difficulty question for [Countermeasure tuning](10-countermeasure-tuning.md).

**Not done here:** a hands-on playtest of the sneak and deception Approaches to each objective and of the weak points. Guard positions and difficulty stay provisional until [Countermeasure tuning](10-countermeasure-tuning.md).
