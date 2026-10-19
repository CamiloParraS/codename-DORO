# 25: Radio relay station + Mission 2

**Spec:** only if this ticket leaves a question open: open the one matching section file listed in [spec index](../../ghost-layer/spec.md), never the whole spec.

**What to build:** Mission 2 plays in the Radio relay station on a ridge: sabotage the relay console and deal with the relay chief, after which HQ sends every guard sweeping the station.

**Blocked by:** 24

**Status:** ready-for-agent

- [x] The Area follows the Harbour template (80×80 m, approaches, every Countermeasure spot, crate, Extraction, named places, navmesh)
- [ ] Holding E for 5 s at the console sabotages it, with the Operative exposed
- [ ] About 30 s later HQ radios "Relay's offline. All units, sweep the station." and every guard goes to suspicion and searches; no alert
- [x] The relay chief is the Target

## Comments

- 2026-10-16 (implementation): `areas/relay_station/relay_station.tscn` is a greybox Area with the Harbour's node layout, so it runs `harbour.gd` unchanged (guards, Countermeasures, Target + escort, reinforcements from `Spots/RoadEntry`). Approaches: north road and east gap; start on the east side, Extraction in the SW corner. Navmesh baked (mast kept to 7 m so the bake fits the voxel limit). `relay_console.gd` is the Mission 2 step (group `intel`, so MissionRun treats it like a pickup): standing still beside it with E held 5 s completes the step, then 30 s later HQ says the sweep line and every guard goes through `on_noise` at its own position (suspicion, an alerted guard is left alone). Mission 2 in `Campaign` now uses this Area, the `RelayConsole` step and the relay chief Target. Checked in the suite (spots, navmesh, hold/release, sweep via a stand-in guard) and headless (Mission 2 loads, 12 guards, `RELAY CHIEF` Target, step done then "KILL OR CARRY OUT", all guards in suspicion after the sweep). "Exposed" is read as: you stand still in the open for 5 s; the console takes no extra exposure mechanic. The 30 s delay, the HQ subtitle and the search look are not played yet, so that criterion stays for a playtest.
