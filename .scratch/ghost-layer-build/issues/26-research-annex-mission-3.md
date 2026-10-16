# 26: Research annex + Mission 3

**Spec:** [Ghost Layer spec](../../ghost-layer/spec.md)

**What to build:** Mission 3 plays in the Research annex: extract the intel that reveals the Core under the Harbour and deal with the lead researcher.

**Blocked by:** 24

**Status:** ready-for-agent

- [x] The Area follows the Harbour template
- [ ] An intel extraction objective plus the lead researcher Target as the main objective

## Comments

- 2026-10-16 (implementation): `areas/research_annex/research_annex.tscn` is a greybox Area with the Harbour's node layout (copied from the Relay station), so it runs `harbour.gd` unchanged (guards, Countermeasures, crate, Extraction, named places, Target + escort, navmesh baked under the voxel limit). The intel step is `Intel/ResearchFiles`, a plain `intel_pickup.gd` (walk into it), so no new mechanic and no new script. Mission 3 in `Campaign` now uses this Area, the `ResearchFiles` step ("EXTRACT THE RESEARCH FILES THAT REVEAL THE CORE") and the `LEAD RESEARCHER` Target. Checked in `tests/test_research_annex.gd` (spots, 80x80 ground, navmesh, route/safe room/files on the navmesh, Mission 3 data) and headless (the Area loads with 12 guards and one `LEAD RESEARCHER` Target). The final criterion is unticked: the step and the Target are wired but the Mission is not played through (find the files, kill or carry the researcher, extract), so it waits for a playtest. The Area reuses the Relay station's layout and geometry (renamed), so it plays like it until it gets its own layout.
