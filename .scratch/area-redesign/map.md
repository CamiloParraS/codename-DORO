# Area Redesign — Wayfinder Map

Label: wayfinder:map

## Destination

A level-design spec for every Area and its Missions (Harbour + Core space, Radio relay station, Research annex), ready to turn into build tickets, **plus the Harbour rebuilt as a playable greybox** that proves the approach before the other two Areas are specified. Each Area keeps its objectives. What changes is the space around them, the guard setup, and a low-detail Backdrop so the Area no longer floats in a void.

## Notes

- **Domain:** Ghost Layer, Godot 4.7, solo. Vocabulary: `GLOSSARY.md` (say Area/Mission, never "level"). Parent effort and spec: [Ghost Layer map](../ghost-layer/map.md), [spec](../ghost-layer/spec.md). Build tickets this map will rewrite: `ghost-layer-build/issues/25`, `26`, `30`, `31`.
- **Budget:** about 4–5 days in total (≈1 day planning, the rest rebuilding the Areas). It can take time from the Magazine and the early items on the cut list. Feature freeze is still 11-11.
- **Execution override:** the [Harbour greybox](issues/07-harbour-greybox.md) and [Relay station greybox](issues/13-relay-station-greybox.md) and [Research annex greybox](issues/14-research-annex-greybox.md) tickets are real builds inside this map. Everything else stays planning.
- **Skills:** grilling tickets → `grilling` + `domain-modeling`. Diagram tickets → `prototype`: a top-down HTML/SVG diagram showing routes, guard loops, sight lines, Approaches and the MGS reference. Research → `research` (subagent).
- **Research output:** `.scratch/area-redesign/research/<name>.md`, written in place. There's no `research/*` branch, so nothing switches the shared checkout.
- **Current state (survey, 2026-10-16):**
  - All three Areas are the same walled 80×80 m box built from hand-placed boxes. The Research annex is a copy of the Relay station.
  - Guards only walk loops of 2–3 points or stand still, and 10 base guards are hard-coded. There are no doors, Ladders, Crawlspaces or lockers.
  - The Core lift is a solid box, and the Core room doesn't exist.
- **Settled while charting:**
  - **MGS use:** borrow design patterns (layered perimeter, vantage point, bypass, posts at chokepoints, a guided opening), with one named MGS location per Area as its mood anchor. Don't copy layouts.
  - **Guards:** use the existing behaviours better through placement, plus at most 2–3 cheap new idle behaviours.
  - **New layout pieces:** Crawlspaces and Ladders up to vantage points. No doors, lockers, vents or light.
  - **Area shape:** each Area gets its own outline (coastline, cliff, fence) at about 80×80 m, instead of the walled square.
  - **Guard count:** each Area sets its own, roughly 8–12, replacing the hard-coded 10.
  - **Shared Area script stays:** every Area keeps the named spots the Harbour script uses, so every Countermeasure works everywhere. Crawlspaces and Ladders are added as optional spots.
  - **Approach rule:** every Area offers at least 3 Approaches to each objective:
    - sneak;
    - deception: a spoof spot plus a guard whose Voiceprint you can record;
    - loud: a direct line with resupply.

    Countermeasure spots sit on those Approaches, so Aigis visibly closes the one you used. This is the checklist every Area diagram is checked against.
  - **Method:** every Area starts as a top-down diagram you react to. Only the Harbour gets greyboxed inside this map.
  - **Backdrop:** a shared kit of low-detail scenery outside the playable boundary, reused around each Area's outline. Dressing the play space itself is a later effort; props that work as cover count as level design.
  - **Core space:** the lift, corridor and Core room are designed here, together with the Harbour.
  - **Mission 1:** the Harbour opens with an onboarding stretch (MGS1 Dock, MGS2 Tanker deck) that introduces each verb before the main yard.

## Decisions so far

- [MGS level-design patterns for our Areas](issues/01-mgs-pattern-research.md): anchors are MGS1 Dock/MGS2 Tanker (Harbour), MGS1 underground facility (Core), MGS1 Comm Tower (Relay), MGS3 Graniny Gorki lab (Annex); principles are layered perimeter, Ladder vantage, Crawlspace bypass and chokepoint posts, but layout pairings are inference, not sourced.

- [Crawlspace and Ladder rules](issues/02-crawlspace-ladder-rules.md): Crawlspace 1.2 m ceiling, 4–10 m, off the 1.8 m navmesh, guards look in from the mouth but never enter; Ladder climbs at 1.8 m/s, seen and shot normally, no actions or carrying; no carrying into either; Ladders and Crawlspaces are plain geometry plus triggers, and Crawlspace coverage rides on the Stealth Countermeasures with no new Habit.

- [Guard idle behaviours for placement](issues/03-guard-idle-behaviours.md): three behaviours in `Guard.patrol()`, declared as Marker meta: a facing stop (`hold`, covers Crawlspace look-in and look-out), a `scan` sweep on any stop (a waypoint-less post with `scan` is a scanning post), and a `chat` post spawning a pair facing each other who take turns speaking, recordable like check-ins: the deception Approach's eavesdrop spot.

- [Harbour and onboarding diagram](issues/04-harbour-diagram.md): Tanker berth. The onboarding is the deck of a moored freighter (crouch, choke, hide, eavesdrop, spoof the gangway post), then a yard layered east to west: quay, then warehouses, then the lift in the west cliff. 10 base guards, 3 Crawlspaces, 2 Ladders.

- [Core space diagram](issues/05-core-space-diagram.md): the Core starts at the bow again and crosses the whole fortified Harbour. The lift drops about 30 m into a gallery room: a walkway ring, Aigis as a column, a cable-trench Crawlspace, and 3 guards plus the director. Arriving under alert puts the Core in suspicion. Only gear, orders and Combat L3 (reinforcements by lift) reach underground.

- [Backdrop kit](issues/06-backdrop-kit.md): six no-collision pieces (sea, cliff, distant block, skyline strip, fence, horizon sky) hand-placed per Area outline, per-Area fog override (Harbour ~140 m), real matching collision at the boundary with kill volumes only at the pier tip and stern, never visible to guards.

- [Harbour greybox](issues/07-harbour-greybox.md): built from the diagram data by `tools/build_harbour.gd` and playtested as working. 11 base guards (the chatting pair counts as 2), O1 turned to face starboard, and eight lessons for the next diagrams: count guards as spawned, check facings against the start, mark heights, size buildings to their Crawlspaces, keep route points clear of cover, draw diagrams as generator-ready data, make the Extraction point findable, and give isolated guard groups a way to call for help. The playtest also brought two fixes: Extraction points now show a light column, and guards watch a Ladder's foot when they lose the Operative on its roof. On a loud run, though, every guard waits at the foot. [Guards and Ladders on alert](issues/12-guards-and-ladders.md) reopens that.

- [Radio relay station diagram](issues/08-relay-station-diagram.md): B's hillside terraces (0, 3 and 6 m, road halfway up, loud east, quiet west) plus a 10 m catwalk at 10 m from the mast to the office roof, reached by guards by a stair. A west scree path replaces the summit Ladder. No Ladder leads anywhere guards can't walk to. The relay chief has two carry routes: about 60 m in the open by the scree, about 95 m with cover by the summit ramp. The escort spoof stays as the chief's deception Approach. Build now; guard positions and difficulty wait on [Guards and Ladders on alert](issues/12-guards-and-ladders.md).

- [Relay station greybox](issues/13-relay-station-greybox.md): built by `tools/build_relay_station.gd` on a shared `tools/area_builder.gd` (the Harbour generator extends it too). The navmesh reaches every terrace, the office roof and the catwalk. The carry routes measure 63 m by the scree and 91 m by the summit ramp. Both Ladders are `walkable`, so guards go to the spot. The escort spoof works live. Guard positions are still provisional, and the three Approaches haven't been playtested by hand yet.

- [Research annex diagram](issues/09-research-annex-diagram.md): A, Main block (MGS3 Graniny Gorki lab as one building). It's ground level: a 48 m corridor with rooms off it, the files in the Archive with a Crawlspace to its back door, and the researcher looping between the lab and the office before running to the vault on alert. 4 of 10 base guards are indoors, there are no Ladders, and interior walls are `Wall*` SOLID boxes. Accepted weak points (the corridor sight line, little cover outside, a beacon hidden from both objectives) go to the greybox playtest.

- [Research annex greybox](issues/14-research-annex-greybox.md): built by `tools/build_research_annex.gd`. The navmesh passes all 13 doorways and reaches both tower tops. The carry routes measure 45 m by the north strip and 63 m by the corridor and dock, and the escort spoof works headless. Guards now follow their path within 0.25 m, after the researcher stuck on a doorway jamb. Measured weak points: the corridor is 46 m but a guard sees 16 m, and Extraction's light column can't be seen from the Archive's back door or the south yard. Four runs played end to end, covering every Approach; the last one had Countermeasures deployed. Questions for tuning:
  - the lab can be cleared one room at a time;
  - the researcher's own Voiceprint works as a spoof;
  - the files' deception Approach has no pull until the crawl beside it is closed;
  - a radioed alert pulls every guard off his post to a found body, so a far-off body lures guards away from the objective (this one is true in every Area: [Who answers an alert](issues/15-who-answers-an-alert.md)). Every camera now hangs on a wall face or a pole, in all three Areas (they had hung in the air).

## Not yet specified

Nothing left: every remaining question is a ticket.

## Out of scope

- **Dressing the play space** (props that do nothing for play): a later effort, once these layouts are stable. Only the Backdrop is in.
- **Bugs found while surveying:** the Harbour's ExtractionPoint node sat in the start corner (the Harbour greybox rebuild fixes it there), and Checkpoints don't save Scanner charges or Magazines. They're unrelated to layout, so they belong in fix tickets.
- **Doors, lockers, vents, light and dark:** each adds state that guards would have to understand, and the budget can't absorb it. Light was already cut on the Ghost Layer map.
