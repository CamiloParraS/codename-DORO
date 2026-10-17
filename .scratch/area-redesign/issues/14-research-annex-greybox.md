# Research annex greybox

Type: task
Status: open
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
