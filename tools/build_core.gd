## Builds areas/core/core.tscn, the Core Mission's Area: the Harbour's ground (build_harbour.gd's geometry) with
## its own guards, landed at the south pier, plus the freight lift's way down, cut through the west cliff: a
## closed door, a short corridor, a plant room with a stair up to the Core room's gallery, and the Core room,
## whose terminal is the Extraction point. Bakes the navmesh and prints how far it reaches. Drawn and timed in
## .scratch/pw-feel/prototypes/core-onboarding.html. Change the data here and rebuild, don't hand-edit the scene.
##   godot --headless --path . --script tools/build_core.gd
## Data is in diagram metres (tools/area_builder.gd); the corridor and room lie west of the Harbour's 0-80 square.
extends "res://tools/build_harbour.gd"

const CORE_OUT := "res://areas/core/core.tscn"
const ROOM := [-34, 22, 20, 20]
const ROOM_H := 7.5   # the room and the plant room: tall enough for the gallery over the floor
const GALLERY := 3.5  # the gallery's and the mezzanine's floor
## The room, the corridor (x -14 to the lift at 2), the plant room (to y 31, under its corridor door).
const CORE_LAND := [[-34, 22, 20, 20], [-14, 31, 16, 2], [-14, 22, 10, 9]]
const WALL := Color(0.7, 0.75, 0.8)
## The cliff, cut for the corridor (y 30.7-33.3), with a lintel over the cut; the corridor, the room's walls,
## the plant room and the gallery. The room's east wall is built piece by piece: the floor door (y 31-33, up
## to the corridor's 4 m) and the gallery's door (y 22.3-25.3, h 3.5-6.1: at 2.2 m high the navmesh shut it) onto the plant room's mezzanine.
const CORE_SOLID := [
	["CliffN", [-2, -6, 4, 36.7], -3, 14, "stone", Color(0.8, 0.75, 0.7)],
	["CliffS", [-2, 33.3, 4, 42.7], -3, 14, "stone", Color(0.8, 0.75, 0.7)],
	["CliffLintel", [-2, 30.7, 4, 2.6], 4.3, 14, "stone", Color(0.8, 0.75, 0.7)],
	["CorridorN1", [-14, 30.7, 6, 0.3], 0, 4, "brick", Color(0.7, 0.72, 0.75)],  # the plant room's door, x -8 to -6
	["CorridorN2", [-6, 30.7, 8, 0.3], 0, 4, "brick", Color(0.7, 0.72, 0.75)],
	["CorridorS", [-14, 33, 16, 0.3], 0, 4, "brick", Color(0.7, 0.72, 0.75)],
	["CorridorRoof", [-14, 30.7, 16, 2.6], 4, 4.3, "metal", Color(0.6, 0.6, 0.6)],
	["ConsoleDesk", [-33.7, 30.5, 1.2, 3], 0, 1, "metal", Color.WHITE],  # the Core terminal's desk
	["RoomN", [-34, 22, 20, 0.3], 0, ROOM_H, "brick", WALL], ["RoomS", [-34, 41.7, 20, 0.3], 0, ROOM_H, "brick", WALL],
	["RoomW", [-34, 22.3, 0.3, 19.4], 0, ROOM_H, "brick", WALL], ["RoomRoof", [-34, 22, 20, 20], ROOM_H, ROOM_H + 0.3, "metal", Color(0.6, 0.6, 0.6)],
	["RoomE1", [-14.3, 25.3, 0.3, 5.7], 0, ROOM_H, "brick", WALL], ["RoomE2", [-14.3, 33, 0.3, 9], 0, ROOM_H, "brick", WALL],
	["RoomELintel", [-14.3, 31, 0.3, 2], 4, ROOM_H, "brick", WALL],
	["RoomEGalleryLow", [-14.3, 22.3, 0.3, 3], 0, GALLERY, "brick", WALL], ["RoomEGalleryHigh", [-14.3, 22.3, 0.3, 3], GALLERY + 2.6, ROOM_H, "brick", WALL],
	["PlantN", [-14, 22, 10, 0.3], 0, ROOM_H, "brick", WALL], ["PlantE", [-4.3, 22.3, 0.3, 8.4], 0, ROOM_H, "brick", WALL],
	["PlantSHigh", [-14, 30.7, 10, 0.3], 4.3, ROOM_H, "brick", WALL], ["PlantRoof", [-14, 22, 10, 9], ROOM_H, ROOM_H + 0.3, "metal", Color(0.6, 0.6, 0.6)],
	["Mezzanine", [-14, 22.3, 5, 2.7], GALLERY - 0.2, GALLERY, "metal", Color(0.75, 0.75, 0.7)],
	["MezzRailS", [-11.5, 24.8, 2.5, 0.2], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],  # open over the stair
	["MezzRailE1", [-9.2, 22.3, 0.2, 0.7], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],
	["MezzRailE2", [-9.2, 24.2, 0.2, 0.8], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],
	# the gallery down the north wall, 3 m deep (at 2.2 the navmesh dropped it); a 1 m parapet hides a crouched Operative,
	# with a gap at x -20.6 to -19.4 to drop through (3.5 m, no fall damage)
	["Gallery", [-34, 22.3, 19.7, 3], GALLERY - 0.2, GALLERY, "metal", Color(0.75, 0.75, 0.7)],
	["GalleryRailW", [-34, 25.1, 13.4, 0.2], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],
	["GalleryRailE", [-19.4, 25.1, 5.1, 0.2], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],
	# crates under the gap, 1.2 m high: the Operative drops behind them unseen and goes round either end
	["DropCrate1", [-22.6, 27.2, 1.6, 1.3], 0, 1.2, "wood", Color(0.9, 0.8, 0.6)], ["DropCrate2", [-21, 27.4, 1.6, 1.2], 0, 1.2, "wood", Color(0.85, 0.75, 0.55)],
	["DropCrate3", [-19.4, 27.2, 1.6, 1.3], 0, 1.2, "wood", Color(0.9, 0.8, 0.6)],
]
## The plant room's stair up to the mezzanine, ending flush with its edge at y 25 (at 24.8 the slab's lip stopped the
## Operative), along its west wall in view of the corridor door (a ladder there went
## unnoticed in playtest 1).
const CORE_RAMPS := [{name = "PlantStair", rect = [-14, 25, 2.5, 4.6], h0 = 0.0, h1 = GALLERY, up = "N", mat = "metal", tint = Color(0.6, 0.6, 0.6)}]
## No Fulton anywhere below the Harbour (on top of the Harbour's ROOMS).
const CORE_ROOMS := [["Corridor", [-14, 30.7, 16, 2.6], 0, 4], ["CoreRoom", ROOM, 0, ROOM_H], ["PlantRoom", [-14, 22, 10, 9], 0, ROOM_H]]
const CORE_SEAL := [["OpsNorthPlug", [19, 19.85, 2, 0.3], 0, 4, "panels", Color.WHITE]]
## Every guard the Core spawns (the Harbour's GUARD_POSTS are not used). The Operative lands at the south pier,
## so the freighter stands empty; the surface is two Encounters of familiar guards, one job each.
const CORE_POSTS := [
	# E1 Quay and yard (timing): the east way times Y1 and lane W, the west way meets Gate
	["PostY1", [58, 28, 0], 180, {role = "patroller", enc = 1}, [[58, 46, {hold = 4.0, f = 270}]]],  # holds facing the yard, his back to the pier walk
	["PostLaneW", [42.5, 39, 0], 270, {hold = 3.0, role = "patroller", enc = 1}, [[42.5, 56.5, {hold = 5.0, f = 0}]]],  # the Foreman's lane, no code
	["PostObserver", [38.5, 38, 6], 150, {scan = 90.0, role = "observer", enc = 1}, []],  # Warehouse B roof, 7.3 m from lane W: E1's test pair
	# E2 Operations (positioning): the north door is sealed; 20.5 m between them
	["PostGate", [20, 45, 0], 120, {scan = 60.0, role = "gatekeeper", enc = 2}, []],
	["PostLiftHall", [15.5, 25, 0], 180, {hold = 5.0, role = "interceptor", enc = 2}, []],  # faces down the hall; his back to the control room's door
	# E3 the Core room (manipulation): one net by design
	["PostCore1", [-20, 30, 0], 180, {scan = 90.0, role = "observer", enc = 3}, []],  # his back to the crates under the gallery's drop
]
const CORE_TARGET_POSTS := [  # the security director paces beside the terminal
	["TargetPost1", [-26, 36, 0], 90, {hold = 5.0}, [[-26, 30, {hold = 5.0, f = 270}]]],  # north stop 28 → 30 (playtest 2): from 28 he saw the drop's landing past the crates
]
## The Encounters, as build_harbour.gd's ENCOUNTERS, and the exits the session log names.
const CORE_ENCOUNTERS := [
	[1, "Quay and yard", "timing", [26, 19, 36, 61], [26, 46, 0], 2],
	[2, "Operations building", "positioning", [2, 18, 24, 30], [8, 32, 0], 3],
	[3, "Core room", "manipulation", [-34, 22, 36, 20], [-24, 32, 0], 0],
]
const CORE_EXITS := {Forecourt = [26, 46, 0], Alley = [25.5, 38, 0], Lift = [8, 32, 0], RoomDoor = [-15, 32, 0], Gallery = [-14.5, 23.4, GALLERY]}
## The steps: Mission 1's lift panel (hold E, the code is known by now), then the lift.
const CORE_OBJECTIVES := {IntelLiftPanel = {at = [22, 22.2, 0], console = 4.0, prompt = "ui.prompt.enter_code"}}
const CORE_INTEL := {IntelLift = [8, 32]}
## The corridor's, the plant room's and the room's dressing, on top of the Harbour's DRESS.
## Countermeasure spots: the Harbour's, with the freighter's three moved to where the Core is crossed.
## Order matters (harbour.gd): the first extra is Stealth L2's patrol, the rest are Combat L2's guards.
const CORE_EXTRA_POSTS := [
	["PostExtra1", [30, 44, 0], 0, {role = "patroller"}, [[33, 40, {hold = 3.0, f = 0}], [33, 57.5, {hold = 3.0, f = 0}]]],
	["PostExtra2", [15.5, 31, 0], 90, {hold = 5.0, role = "interceptor"}, []],
	["PostExtra3", [49, 59, 0], 0, {hold = 5.0, role = "gatekeeper"}, []],  # the mid lane's south end, in view from the pier
]
const CORE_SENTRIES := [["SentryCrane", [56, 19.5, 8], 230, {scan = 90.0}], ["SentryWarehouseA", [23.5, 50, 5], 90, {scan = 90.0}]]
const CORE_CAMERAS := [
	["CamPier", [56.6, 69.4, 3], 0, 0.0],  # a pole at the pier mouth, up the quay
	["CamLanes", [53.5, 25, 3], 194, 0.0], ["CamOps", [22, 42.05, 3.6], 150], ["CamAlley", [25.95, 29, 5], 200],
]
const CORE_DRESS := [
	["ceiling_lamp", [-4, 32, 3.8], 0], ["ceiling_lamp", [-10, 32, 3.8], 0],
	["ceiling_lamp", [-24, 27, 7.2], 0], ["ceiling_lamp", [-24, 37, 7.2], 0], ["ceiling_lamp", [-17, 32, 7.2], 0],
	["ceiling_lamp", [-28, 23.4, 7.2], 0],  # the plant room, over the gallery
	["monitoring_screen", [-33.1, 31, 1], 90], ["monitoring_screen", [-33.1, 33, 1], 90],
	["cabinet_b", [-33.5, 38, 0], 90], ["cabinet_b", [-33.5, 39.3, 0], 90], ["cabinet_a", [-33.5, 25, 0], 90],
	["pipe_riser", [-14.9, 41, 0], 270], ["pipe_riser", [-4.9, 28, 0], 270],
	# server racks down the north (under the gallery) and south walls, clear of the guards' and the director's beats
	["cabinet_b", [-28, 22.55, 0], 180], ["cabinet_b", [-26.8, 22.55, 0], 180], ["cabinet_b", [-25.6, 22.55, 0], 180],
	["cabinet_b", [-22, 22.55, 0], 180], ["cabinet_b", [-17.6, 22.55, 0], 180], ["cabinet_b", [-16.4, 22.55, 0], 180],
	["cabinet_b", [-28, 41.45, 0], 0], ["cabinet_b", [-26.8, 41.45, 0], 0], ["cabinet_b", [-25.6, 41.45, 0], 0],
	["cabinet_b", [-22, 41.45, 0], 0], ["cabinet_b", [-20.8, 41.45, 0], 0], ["cabinet_b", [-19.6, 41.45, 0], 0],
	["generator", [-16.6, 38.5, 0], 90], ["vent_unit", [-24, 41.5, 5.5], 0],
	["crate_wide", [-32.6, 40.8, 0], 90], ["cardboard_box", [-32.5, 39.6, 0], 15], ["drum", [-15.7, 25.5, 0], 0],
	["ceiling_lamp", [-14.8, 32, 3.8], 0],  # over the room's door
	["ceiling_lamp", [-7, 31.4, 3.8], 0], ["ceiling_lamp", [-11, 27.5, 7.2], 0],  # CORE_LIT: the plant room's door and the stair
	# the plant room: a generator and drums, clear of the stair (x -14 to -11.5) and the door (x -8 to -6)
	["generator", [-6.5, 26.5, 0], 90], ["drum", [-5.2, 23, 0], 0], ["drum", [-5.3, 24, 0], 30],
]
## Red alarm lamps on the roofs, the crane and the north shore's sheds: the lockdown, seen through the red fog.
const ALARM := Color(1, 0.1, 0.05)
## Ceiling lamps of CORE_DRESS that glow green, the way to the stair and the gallery (playtest 4); [x, y] on the map.
const CORE_LIT := [[-7, 31.4], [-11, 27.5]]
const LIT_COLOUR := Color(0.45, 1.0, 0.55)
const LIT_ENERGY := 1.8  # dimmer than the white lamps' 3.0
const CORE_BEACONS := [
	[[18.5, 21, 5.0], ALARM, 8.0, 4.3], [[12, 32, 7.2], ALARM, 8.0, 6.5], [[42, 10, 5.0], ALARM, 8.0, 4.3],
	[[15, 56, 6.0], ALARM, 8.0, 5.3], [[28, 30, 6.7], ALARM, 8.0, 6.0], [[56, 20, 8.6], ALARM, 8.0, 8.0],
	[[11, -24, 12.2], ALARM, 10.0, 11.5], [[50, -34, 13.1], ALARM, 10.0, 12.4],
]
## Hazard paint round the terminal and down the corridor's middle (core-only, on top of MARKINGS).
const CORE_MARKINGS := [
	[[-32.4, 29.8, 0.15, 4.4], 0], [[-32.4, 29.8, 2.6, 0.15], 0], [[-32.4, 34.05, 2.6, 0.15], 0], [[-29.95, 29.8, 0.15, 4.4], 0],
	[[-14, 31.95, 16, 0.1], 1.0], [[-7.1, 28.9, 0.2, 3.4], 0, 0.0, Color(0.4, 1.0, 0.5)], [[-11.5, 28.8, 4.6, 0.2], 0, 0.0, Color(0.4, 1.0, 0.5)], [[-30, 23.8, 12, 0.12], 0], [[-30, 40.1, 12, 0.12], 0],
]
const CORE_REACH := {
	PierMouth = [52, 70, 0], Stack = [30, 66, 0], Forecourt = [28, 46.8, 0], MidLane = [48.5, 38, 0], AlleyMouth = [30, 39.1, 0],
	OpsEastDoor = [23.2, 32, 0], Panel = [21.5, 22.6, 0], LiftHallBack = [16.4, 23, 0], LiftMouth = [8, 32, 0],
	Corridor = [-6, 32, 0], PlantDoor = [-7, 30, 0], PlantStair = [-12.75, 30.1, 0], Mezzanine = [-12, 23.5, GALLERY], Gallery = [-26, 23.8, GALLERY], RoomDoor = [-15, 32, 0], Room = [-24, 32, 0],
	DropLanding = [-20, 26.2, 0], Director = [-26, 36, 0], DirectorRoute = [-26, 30, 0], SafeRoom = [-30, 25, 0], Terminal = [-31, 32, 0],
}


func _build() -> void:
	_root = Node3D.new()
	_root.name = "Core"
	_root.set_script(load("res://areas/core/core.gd"))

	var nav := _nav_region()
	var land := _group(nav, "Land")
	for l in LAND:
		_box(land, "Land%d" % land.get_child_count(), l[0], _land_floor(l[1]), 0, l[1], Color.WHITE)
	for l in CORE_LAND:
		_box(land, "Land%d" % land.get_child_count(), l, -1, 0, "stone", Color.WHITE)
	var solid := _group(nav, "Solid")
	for s in SOLID:
		if s[0] != "Cliff":
			_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	for s in CORE_SOLID + CORE_SEAL:
		_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	_crane_lattice(solid)
	_camera_poles(solid, CORE_CAMERAS)
	for r in CORE_RAMPS:
		_ramp(solid, r)
	for l in LOW:
		_box(solid, "Low%d" % solid.get_child_count(), l[0], l[1], l[1] + LOW_H, "wood", Color(0.9, 0.8, 0.6))
	for b in BUILDINGS:
		_building(_group(solid, b[0]), b)
	_gangway(solid)
	_dress(nav, DRESS + CORE_DRESS)
	_tint_lit_lamps(nav)
	var crawl := _group(nav, "Crawlspaces")
	for c in CRAWLSPACES:
		_crawlspace(_group(crawl, c.name), c)
	_bake(nav)
	var nm := nav.navigation_mesh

	var ladders := _group(_root, "Ladders")
	for l in LADDERS:
		_ladder(ladders, l)
	_backdrop()
	_clifftop_clear_of_the_core()
	_dress(_root.get_node("Backdrop"), BACKDROP_DRESS, false)
	_surroundings()
	_markings(MARKINGS + CORE_MARKINGS)
	_beacons(BEACONS + CORE_BEACONS)
	_mood("core")

	# the Operative lands at the south pier's tip facing north; reinforcements come down the road to the
	# surface (SurfaceEntry) and down the lift to the corridor (RoadEntry) once the Operative is below (core.gd)
	var spots := SPOTS.duplicate()
	spots.erase("DeckEntry")
	spots.OperativeStart = [52, 77, 0]
	spots.SafeRoom = [-30, 25, 0]
	spots.Extraction = [-31, 32, 0]  # the terminal: the Mission ends there, not on entering the room
	spots.RoadEntry = [-2, 32, 0]
	spots.SurfaceEntry = SPOTS.RoadEntry
	spots.PlantStair = [-12.5, 26.5, 2]  # where PlantCue turns the camera
	var spot_group := _group(_root, "Spots")
	for n in spots:
		_marker(spot_group, n, spots[n], 0, {}, "spot")
	var sentries := _group(_root, "SentryHighPoints")
	for s in CORE_SENTRIES:
		_marker(sentries, s[0], s[1], s[2], s[3], "sentry_high_point")
	var cams := _group(_root, "CameraMounts")
	for c in CORE_CAMERAS:
		_marker(cams, c[0], c[1], c[2], {}, "camera_mount")
	_posts("GuardPosts", CORE_POSTS, "guard_post")
	_posts("TargetPosts", CORE_TARGET_POSTS, "target_post")
	_posts("ExtraGuardPosts", CORE_EXTRA_POSTS, "guard_post_extra")
	var spoofs := _group(_root, "SpoofPlaces")
	for n in SPOOFS:
		_marker(spoofs, n, SPOOFS[n], 0, {}, "spoof_place")
	var encounters := _group(_root, "Encounters")  # MissionRun reads which one the Operative is in (the session log)
	for e in CORE_ENCOUNTERS:
		_marker(encounters, "Encounter%d" % e[0], [e[3][0], e[3][1], 0], 0, {id = e[0], size = Vector2(e[3][2], e[3][3])}, "encounter")
	for n in CORE_EXITS:
		_marker(encounters, n, CORE_EXITS[n], 0, {}, "encounter_exit")

	_rooms(ROOMS + CORE_ROOMS)
	_actors()
	# the lift's door: outside the NavRegion, so the navmesh is open and only bodies are held back
	var door := _box(_root, "LiftDoor", [0.5, 31, 0.5, 2], 0, 3, "metal", Color(0.9, 0.5, 0.2))
	door.owner = _root
	_own(door)
	door.set_script(load("res://areas/core/lift_door.gd"))
	var ep := _area(_root, "ExtractionPoint", spots.Extraction, Vector3(4, 3, 4), "res://areas/extraction_point.gd")
	ep.position.y = 1.5
	# a director left lying anywhere in the room counts as dealt with (the room was the Extraction point until playtest 2)
	_area(_root, "CoreRoomZone", [-24, 32, 1.5], Vector3(18, 3, 18), "res://areas/target_zone.gd")
	_area(_root, "PlantCue", [-7, 32, 1.5], Vector3(2, 3, 2.6), "res://areas/core/plant_cue.gd")
	_area(_root, "CoreEntry", [-16, 32, 1.5], Vector3(2, 3, 4), "res://areas/core/core_entry.gd")
	_area(_root, "CoreTerminal", [-31.5, 32, 1.5], Vector3(3, 3, 4), "res://areas/core/core_terminal.gd")
	_core_objectives()
	var sea := _area(_root, "Sea", [40, 40, -5.5], Vector3(160, 5, 160), "res://areas/sea.gd")
	sea.collision_mask = 1  # the Operative's layer
	_save(CORE_OUT)
	await _report_reach(nm, spots.OperativeStart, CORE_REACH, {})
	quit()


## The Core's steps under $Intel: the lift panel (a console, as in Mission 1) and the lift (a walk-in).
## The Harbour's Clifftop is one slab over x -60..-2, h -3..14: the Core's corridor, plant room and room sit inside it,
## and through the lift door a dark face of it showed above the door (the user, playtest 4). The same slab in pieces,
## clear of the rooms (x -34..-2, y 22..42, up to ROOM_H + 0.3) and kept above them.
const CLIFFTOP_PIECES := [
	[[-60, -100, 26, 280], -3, 14], [[-34, -100, 32, 122], -3, 14], [[-34, 42, 32, 138], -3, 14], [[-34, 22, 32, 20], 7.8, 14],
]
func _clifftop_clear_of_the_core() -> void:
	var bd: Node3D = _root.get_node("Backdrop")
	var old: MeshInstance3D = bd.get_node("Clifftop")
	var material: Material = (old.mesh as BoxMesh).material
	bd.remove_child(old)
	old.free()
	for pc in CLIFFTOP_PIECES:
		var r: Array = pc[0]
		var piece := MeshInstance3D.new()
		piece.name = "Clifftop%d" % bd.get_child_count()
		piece.mesh = _box_mesh(Vector3(r[2], pc[2] - pc[1], r[3]), material)
		piece.position = Vector3(r[0] + r[2] / 2.0 - 40.0, (pc[1] + pc[2]) / 2.0, r[1] + r[3] / 2.0 - 40.0)
		_add(bd, piece)


func _tint_lit_lamps(nav: Node3D) -> void:
	for lamp in nav.get_node("Dressing").get_children():
		for at in CORE_LIT:
			var p := _p([at[0], at[1], 0])
			if lamp.name.begins_with("CeilingLamp") and absf(lamp.position.x - p.x) < 0.01 and absf(lamp.position.z - p.z) < 0.01:
				lamp.get_node("Light").light_color = LIT_COLOUR
				lamp.get_node("Light").light_energy = LIT_ENERGY


func _core_objectives() -> void:
	_intel(CORE_INTEL)
	var intel := _root.get_node("Intel")
	for n in CORE_OBJECTIVES:
		var o: Dictionary = CORE_OBJECTIVES[n]
		var c := _area(intel, n, [o.at[0], o.at[1], o.at[2] + 1.5], Vector3(3, 3, 3), "res://areas/relay_station/relay_console.gd")
		c.set("hold_time", o.console)
		c.set("prompt", o.prompt)
		c.set("sweeps", false)
