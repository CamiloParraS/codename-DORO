## Builds areas/core/core.tscn, the Core Mission's Area: the fortified Harbour (all of build_harbour.gd's data,
## Mission 1's insertion point included) plus the freight lift's way down, cut through the west cliff: a closed
## door, a short corridor and the Core room, which is also the Extraction point. Bakes the navmesh and prints
## how far it reaches. Change the data here (or in build_harbour.gd) and rebuild, don't hand-edit the scene.
##   godot --headless --path . --script tools/build_core.gd
## Data is in diagram metres (tools/area_builder.gd); the corridor and room lie west of the Harbour's 0-80 square.
extends "res://tools/build_harbour.gd"

const CORE_OUT := "res://areas/core/core.tscn"
const ROOM := [-34, 22, 20, 20]
const CORE_LAND := [[-34, 22, 20, 20], [-14, 31, 16, 2]]  # the room, the corridor (x -14 to the lift at 2)
## The cliff, cut for the corridor (y 30.7-33.3), with a lintel over the cut.
const CORE_SOLID := [
	["CliffN", [-2, -6, 4, 36.7], -3, 14, "stone", Color(0.8, 0.75, 0.7)],
	["CliffS", [-2, 33.3, 4, 42.7], -3, 14, "stone", Color(0.8, 0.75, 0.7)],
	["CliffLintel", [-2, 30.7, 4, 2.6], 4.3, 14, "stone", Color(0.8, 0.75, 0.7)],
	["CorridorN", [-14, 30.7, 16, 0.3], 0, 4, "brick", Color(0.7, 0.72, 0.75)],
	["CorridorS", [-14, 33, 16, 0.3], 0, 4, "brick", Color(0.7, 0.72, 0.75)],
	["CorridorRoof", [-14, 30.7, 16, 2.6], 4, 4.3, "metal", Color(0.6, 0.6, 0.6)],
	["ConsoleDesk", [-33.7, 30.5, 1.2, 3], 0, 1, "metal", Color.WHITE],  # the Core terminal's desk
]
const CORE_BUILDING := ["CoreRoom", ROOM, 4.0, [["E", 32.0]], Color(0.7, 0.75, 0.8)]  # one door, east, onto the corridor
## What the Core changes on the Harbour surface (pw-feel issue 07): the smoke break is over and the code is
## known, so the pair and the Foreman are gone; a stern Patroller closes the deck's way round the bridge and
## the stern drop; the Operations building's north door is sealed and an Interceptor stands in the lift hall.
## Its steps are reaching the building (IntelOps) and taking the lift (IntelLift).
const CORE_DROP_POSTS := ["PostP", "PostForeman"]
const CORE_HARBOUR_POSTS := [
	["PostStern", [74, 58, DECK], 270, {role = "patroller", enc = 1}, [[66.2, 58, {hold = 3.0, f = 0}]]],
	["PostLiftHall", [15.5, 25, 0], 180, {hold = 5.0, role = "interceptor", enc = 3}, []],
]
const CORE_SEAL := [["OpsNorthPlug", [19, 19.85, 2, 0.3], 0, 4, "panels", Color.WHITE]]
const CORE_INTEL := {IntelOps = [19.5, 32], IntelLift = [8, 32]}
## The room's two guards (the director's escort is the third).
const CORE_POSTS := [
	["PostCore1", [-20, 25, 0], 180, {scan = 90.0}, []],
	["PostCore2", [-20, 39, 0], 0, {scan = 90.0}, []],
]
const CORE_TARGET_POSTS := [  # the security director paces beside the terminal
	["TargetPost1", [-26, 36, 0], 90, {hold = 5.0}, [[-26, 28, {hold = 5.0, f = 270}]]],
]
## The corridor's and room's dressing, on top of the Harbour's DRESS.
const CORE_DRESS := [
	["ceiling_lamp", [-4, 32, 3.8], 0], ["ceiling_lamp", [-10, 32, 3.8], 0],
	["ceiling_lamp", [-24, 27, 3.8], 0], ["ceiling_lamp", [-24, 37, 3.8], 0], ["ceiling_lamp", [-17, 32, 3.8], 0],
	["monitoring_screen", [-33.1, 31, 1], 90], ["monitoring_screen", [-33.1, 33, 1], 90],
	["cabinet_b", [-33.5, 38, 0], 90], ["cabinet_b", [-33.5, 39.3, 0], 90], ["cabinet_a", [-33.5, 25, 0], 90],
	["pipe_riser", [-14.9, 23, 0], 270], ["pipe_riser", [-14.9, 41, 0], 270],
]
const CORE_REACH := {
	OpsEastDoor = [23.2, 32, 0], LiftHall = [15.5, 30, 0], LiftMouth = [8, 32, 0], Corridor = [-6, 32, 0], RoomDoor = [-15, 32, 0], Room = [-24, 32, 0],
	Director = [-26, 36, 0], DirectorRoute = [-26, 28, 0], SafeRoom = [-30, 25, 0], Terminal = [-31, 32, 0],
}


func _build() -> void:
	_root = Node3D.new()
	_root.name = "Core"
	_root.set_script(load("res://areas/core/core.gd"))

	var nav := _nav_region()
	var land := _group(nav, "Land")
	for l in LAND:
		_box(land, "Land%d" % land.get_child_count(), l[0], -1, 0, l[1], Color.WHITE)
	for l in CORE_LAND:
		_box(land, "Land%d" % land.get_child_count(), l, -1, 0, "stone", Color.WHITE)
	var solid := _group(nav, "Solid")
	for s in SOLID:
		if s[0] != "Cliff":
			_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	for s in CORE_SOLID + CORE_SEAL:
		_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	_crane_lattice(solid)
	_camera_poles(solid, CAMERAS)
	for l in LOW:
		_box(solid, "Low%d" % solid.get_child_count(), l[0], l[1], l[1] + LOW_H, "wood", Color(0.9, 0.8, 0.6))
	for b in BUILDINGS + [CORE_BUILDING]:
		_building(_group(solid, b[0]), b)
	_gangway(solid)
	_dress(nav, DRESS + CORE_DRESS)
	var crawl := _group(nav, "Crawlspaces")
	for c in CRAWLSPACES:
		_crawlspace(_group(crawl, c.name), c)
	_bake(nav)
	var nm := nav.navigation_mesh

	var ladders := _group(_root, "Ladders")
	for l in LADDERS:
		_ladder(ladders, l)
	_backdrop()
	_dress(_root.get_node("Backdrop"), BACKDROP_DRESS)
	_mood("core")

	var spots := SPOTS.duplicate()
	spots.SafeRoom = [-30, 25, 0]
	spots.Extraction = [-24, 32, 0]
	spots.RoadEntry = [-12, 32, 0]  # reinforcements come down the corridor, near CoreEntry
	var spot_group := _group(_root, "Spots")
	for n in spots:
		_marker(spot_group, n, spots[n], 180 if n == "OperativeStart" else 0, {}, "spot")
	var sentries := _group(_root, "SentryHighPoints")
	for s in SENTRIES:
		_marker(sentries, s[0], s[1], s[2], s[3], "sentry_high_point")
	var cams := _group(_root, "CameraMounts")
	for c in CAMERAS:
		_marker(cams, c[0], c[1], c[2], {}, "camera_mount")
	var harbour_posts := GUARD_POSTS.filter(func(p: Array) -> bool: return p[0] not in CORE_DROP_POSTS)
	_posts("GuardPosts", harbour_posts + CORE_HARBOUR_POSTS + CORE_POSTS, "guard_post")
	_posts("TargetPosts", CORE_TARGET_POSTS, "target_post")
	_posts("ExtraGuardPosts", EXTRA_POSTS, "guard_post_extra")
	var spoofs := _group(_root, "SpoofPlaces")
	for n in SPOOFS:
		_marker(spoofs, n, SPOOFS[n] + [0], 0, {}, "spoof_place")

	_rooms()
	_actors()
	# the lift's door: outside the NavRegion, so the navmesh is open and only bodies are held back
	var door := _box(_root, "LiftDoor", [0.5, 31, 0.5, 2], 0, 3, "metal", Color(0.9, 0.5, 0.2))
	door.owner = _root
	_own(door)
	door.set_script(load("res://areas/core/lift_door.gd"))
	var ep := _area(_root, "ExtractionPoint", spots.Extraction, Vector3(18, 3, 18), "res://areas/extraction_point.gd")
	ep.position.y = 1.5
	_area(_root, "CoreEntry", [-16, 32, 1.5], Vector3(2, 3, 4), "res://areas/core/core_entry.gd")
	_area(_root, "CoreTerminal", [-31.5, 32, 1.5], Vector3(3, 3, 4), "res://areas/core/core_terminal.gd")
	_intel(CORE_INTEL)
	var sea := _area(_root, "Sea", [40, 40, -5.5], Vector3(160, 5, 160), "res://areas/sea.gd")
	sea.collision_mask = 1  # the Operative's layer
	_save(CORE_OUT)
	await _report_reach(nm, SPOTS.OperativeStart, CORE_REACH, {})
	quit()
