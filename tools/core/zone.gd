## A slice of the Core's build data: one zone of the Area, with its geometry, guards, Encounter, dressing, reach
## points and so on, in diagram metres (tools/area_builder.gd). tools/build_core.gd merges the zones' `D` by key, so a
## change to one place is a change to one file. Keys a zone leaves out are empty.
##   land, solid, seal, ramps, rooms  geometry (build_core.gd's boxes, ramps and Fulton-free rooms)
##   posts, target_posts, extra_posts, sentries, cameras  guards and Countermeasures
##   encounters, exits, objectives, intel  what the session log and MissionRun read
##   dress, lit, markings, beacons, clifftop  set dressing and mood
##   spots, areas, reach  markers, trigger areas and the navmesh reach points to report
##   start  where a focused build (zones=...) reaches from
extends RefCounted

const ROOM := [-34, 22, 20, 20]
const ROOM_H := 7.5   # the room and the plant room: tall enough for the gallery over the floor
const GALLERY := 3.5  # the gallery's and the mezzanine's floor
const WALL := Color(0.7, 0.75, 0.8)
## Red alarm lamps: the lockdown, seen through the red fog.
const ALARM := Color(1, 0.1, 0.05)
