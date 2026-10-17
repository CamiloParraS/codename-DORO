## Builds areas/relay_station/relay_station.tscn, the hillside-terraces greybox, from the Relay station
## diagram's variant D data (.scratch/area-redesign/issues/08-relay-station-diagram.md), bakes its navmesh
## and prints how far the navmesh reaches. Until the layout settles this file is the Relay station's
## source: change the data here and rebuild, don't hand-edit the scene.
##   godot --headless --path . --script tools/build_relay_station.gd
## Data is in diagram metres (tools/area_builder.gd). Guard positions are provisional until Countermeasure
## tuning (.scratch/area-redesign/issues/10-countermeasure-tuning.md).
extends "res://tools/area_builder.gd"

const OUT := "res://areas/relay_station/relay_station.tscn"
const SNOW := Color(0.92, 0.93, 0.97)

## Walkable ground, solid from -1 up to its top h: [rect, material, h, tint]. The terraces' faces are
## their retaining walls. The 2 m landings at the top of each ramp turn it onto the level above flush.
const LAND := [
	[[4, 56, 72, 20], "ground", 0, Color.WHITE],  # motor pool
	[[4, 32, 72, 24], "ground", 3, SNOW],         # barracks terrace
	[[4, 4, 72, 28], "ground", 6, SNOW],          # summit
	[[76, 40, 12, 8], "ground", 3, Color.WHITE],  # the road in from the east
	[[68, 56, 2, 4], "stone", 3, Color.WHITE],    # RoadRamp1's landing
	[[68, 32, 2, 4], "stone", 6, Color.WHITE],    # RoadRamp2's landing
	[[54, 18, 2, 2.5], "stone", 10, Color.WHITE], # the office stair's landing, onto the roof
]
## Solid boxes: [name, rect, h0, h1, material, tint].
const SOLID := [
	["CliffN", [0, 0, 80, 4], -3, 20, "stone", Color(0.8, 0.75, 0.7)],
	["CliffW", [0, 4, 4, 72], -3, 12, "stone", Color(0.8, 0.75, 0.7)],
	["CliffE1", [76, 4, 4, 36], -3, 12, "stone", Color(0.8, 0.75, 0.7)],
	["CliffE2", [76, 48, 4, 28], -3, 12, "stone", Color(0.8, 0.75, 0.7)],
	# edge rails: no jump, so a 1 m rail holds the Operative on a terrace; gaps at the Ladder and ramp tops
	["RailS", [4, 75.8, 72, 0.2], 0, 1, "metal", Color(0.8, 0.3, 0.25)],
	["RailT1a", [4, 55.8, 15, 0.2], 3, 4, "metal", Color(0.8, 0.3, 0.25)],
	["RailT1b", [21, 55.8, 47, 0.2], 3, 4, "metal", Color(0.8, 0.3, 0.25)],
	["RailT1c", [70, 55.8, 6, 0.2], 3, 4, "metal", Color(0.8, 0.3, 0.25)],
	["RailRamp1S", [50, 59.8, 20, 0.2], 0, 4, "metal", Color(0.8, 0.3, 0.25)],
	["RailRamp1E", [70, 56, 0.2, 4], 0, 4, "metal", Color(0.8, 0.3, 0.25)],
	["RailT2a", [9, 31.8, 59, 0.2], 6, 7, "metal", Color(0.8, 0.3, 0.25)],
	["RailT2c", [70, 31.8, 6, 0.2], 6, 7, "metal", Color(0.8, 0.3, 0.25)],
	["RailRamp2S", [50, 35.8, 20, 0.2], 3, 7, "metal", Color(0.8, 0.3, 0.25)],
	["RailRamp2E", [70, 32, 0.2, 4], 3, 7, "metal", Color(0.8, 0.3, 0.25)],
	["RailScreeE", [9, 32, 0.2, 14], 3, 7, "metal", Color(0.8, 0.3, 0.25)],
	["RailStairS", [54, 20.5, 10, 0.2], 6, 11, "metal", Color(0.8, 0.3, 0.25)],
	["RailCatwalkN", [40, 9.8, 10, 0.2], 10, 11, "metal", Color(0.8, 0.3, 0.25)],
	["RailCatwalkS", [43, 11.6, 7, 0.2], 10, 11, "metal", Color(0.8, 0.3, 0.25)],  # open at x 40-43 for the Ladder
	["RoadSideN", [76, 39.8, 12, 0.2], 3, 6, "metal", Color(0.6, 0.65, 0.6)],
	["RoadSideS", [76, 47.8, 12, 0.2], 3, 6, "metal", Color(0.6, 0.65, 0.6)],
	["RoadBarrier", [88, 40, 0.4, 8], 3, 4.2, "metal", Color(0.9, 0.5, 0.2)],
	# summit
	["Mast", [34, 8, 6, 6], 6, 18, "stone", Color(0.75, 0.75, 0.75)],
	["Antenna", [36, 10, 2, 2], 18, 34, "metal", Color(0.85, 0.3, 0.25)],
	["GeneratorShed", [16, 4, 6, 4], 6, 9, "brick", Color.WHITE],
	["ConsoleDesk", [39, 17.5, 2, 1], 6, 7.1, "metal", Color(0.4, 0.45, 0.5)],
	# motor pool
	["Container1", [26, 62, 3, 8], 0, 2.6, "metal", Color(0.75, 0.3, 0.25)],
	["Container2", [36, 66, 8, 3], 0, 2.6, "metal", Color(0.3, 0.5, 0.8)],
	["ResupplyCrate", [49.5, 63.5, 1, 1], 0, 1, "wood", Color(0.6, 0.9, 0.6)],
]
## Raised walkable slabs: [name, rect, top h, material]. The catwalk runs from the mast to the office roof.
const DECKS := [["Catwalk", [40, 10, 10, 1.6], 10, "metal"]]
## Low cover: [rect, h0].
const LOW := [
	[[12, 60, 6, 1.2], 0], [[40, 48, 6, 1.2], 3], [[64, 48, 6, 1.2], 3], [[38, 23, 6, 1.2], 6],
	[[48, 20, 1.2, 5], 6], [[62, 61, 6, 1.2], 0],
]
## Enterable buildings: [name, rect, height, doors [[side, centre]], tint, base].
const BUILDINGS := [
	["Garage", [44, 62, 14, 10], 5.0, [["W", 67.0], ["E", 67.0]], Color(0.85, 0.85, 0.85), 0.0],
	["FuelHut", [66, 66, 6, 6], 3.0, [["W", 69.0]], Color.WHITE, 0.0],
	["MessHut", [52, 38, 12, 8], 3.5, [["S", 58.0], ["W", 42.0]], Color.WHITE, 3.0],
	["Office", [50, 8, 14, 10], 3.7, [["W", 15.0], ["S", 52.0]], Color(0.85, 0.85, 0.8), 6.0],  # roof top at 10, level with the catwalk
]
## The stilted barracks: a 10 m Crawlspace under it, north to south.
const CRAWLSPACES := [
	{name = "BarracksCrawl", rect = [22, 40, 10, 10], h = 4.0, base = 3.0, mat = "wood", tint = Color(0.8, 0.7, 0.55), axis_x = 27.0},
]
## Ladders: [name, bottom [x, y, h], top [x, y, h]]. Both land on ground guards walk to (the diagram's
## lesson 9), so both are `walkable`: a guard who loses the Operative up one walks there.
const LADDERS := [
	["LadderWest", [20, 56.5, 0], [20, 54.5, 3]],
	["LadderCatwalk", [42, 12.1, 6], [42, 10.8, 10]],
]
## Wedges: {name, rect, h0, h1, up: the high side}. The road ramps and the stair end on a LAND landing.
const RAMPS := [
	{name = "RoadRamp1", rect = [50, 56, 18, 4], h0 = 0.0, h1 = 3.0, up = "E", mat = "ground", tint = Color.WHITE},
	{name = "RoadRamp2", rect = [50, 32, 18, 4], h0 = 3.0, h1 = 6.0, up = "E", mat = "ground", tint = Color.WHITE},
	{name = "Scree", rect = [4, 32, 5, 14], h0 = 3.0, h1 = 6.0, up = "N", mat = "stone", tint = Color(0.7, 0.68, 0.65)},
	{name = "OfficeStair", rect = [56, 18, 8, 2.5], h0 = 6.0, h1 = 10.0, up = "W", mat = "metal", tint = Color(0.6, 0.6, 0.6)},
]

## Guard posts: [name, [x, y, h], facing, meta, route [[x, y, meta]]]. Meta: hold / scan / chat.
## 9 posts, 10 guards as spawned (B1 is a chatting pair), plus the chief's escort.
const GUARD_POSTS := [
	["PostA1", [36, 60, 0], 270, {}, [[24, 60, {hold = 4.0, f = 310}], [36, 73, {}]]],  # motor pool loop
	["PostA2", [52, 68, 0], 270, {scan = 60.0}, []],                                    # garage, on the crate
	["PostA3", [73, 63, 0], 260, {scan = 60.0}, []],                                    # foot of the road ramp
	["PostB1", [67, 44, 3], 0, {chat = true}, []],                                      # the pair by the road: eavesdrop spot
	["PostB2", [12, 52, 3], 90, {}, [[44, 52, {hold = 5.0, f = 180}]]],                 # barracks terrace walk
	["PostB3", [32, 37, 3], 270, {scan = 60.0}, []],                                    # barracks north mouth, sweeps the scree line
	["PostC1", [44, 26, 6], 220, {scan = 60.0}, []],                                    # summit, over the console
	["PostC2", [66, 15, 6], 300, {scan = 60.0}, []],                                    # office east
	["PostC3", [16, 20, 6], 90, {}, [[50, 26, {hold = 4.0, f = 90}], [28, 16, {}]]],     # summit loop past the helipad
]
const EXTRA_POSTS := [
	["PostExtra1", [24, 53, 3], 0, {}, [[27, 51.5, {hold = 3.0, f = 0}], [8, 49, {hold = 3.0, f = 0}]]],  # Stealth L2: barracks mouth, then up the scree
	["PostExtra2", [70, 29, 6], 180, {hold = 5.0}, []],  # Combat L2: summit ramp top
	["PostExtra3", [52, 22, 6], 0, {hold = 5.0}, []],    # Combat L2: office south door
]
const TARGET_POSTS := [  # the relay chief: the mess door, then looking up at the summit
	["TargetPost1", [50, 41, 3], 90, {hold = 6.0}, [[34, 40, {hold = 6.0, f = 0}]]],
]
const SENTRIES := [
	["SentryMast", [37, 11, 18], 180, {scan = 120.0}],
	["SentryOffice", [57, 12, 10], 250, {scan = 90.0}],
]
## Camera mounts: [name, [x, y, h], facing, pole base h]. All four stand in the open, on poles.
const CAMERAS := [
	["CamLadderWest", [23, 54, 4.5], 270, 3.0], ["CamBarracks", [33, 38, 4.5], 250, 3.0],
	["CamScree", [10, 30, 7.5], 200, 6.0], ["CamRoad", [72, 61, 4], 270, 0.0],
]
const SPOTS := {
	OperativeStart = [8, 72, 0], RoadEntry = [82, 44, 3], Extraction = [9, 14, 6],
	ResupplyCrate = [50, 64, 1], SafeRoom = [60, 12, 6], RelayConsole = [40, 20, 6],
}
const START_FACING := 45
const SPOOFS := {SpoofGarage = [47, 60, 0], SpoofMess = [50, 44, 3], SpoofHelipad = [12, 16, 6], SpoofMast = [44, 15, 6]}

## What the navmesh must reach from the start: every terrace, the office roof, the catwalk, and every objective.
const REACH := {
	MotorPool = [30, 74, 0], BarracksTerrace = [40, 54, 3], Summit = [28, 26, 6], OfficeRoof = [58, 12, 10],
	Catwalk = [45, 10.8, 10], Helipad = [9, 14, 6], Console = [40, 20, 6], SafeRoom = [60, 12, 6],
	ChiefMess = [50, 41, 3], ChiefLookout = [34, 40, 3], ScreeTop = [6.5, 31, 6],
}
## The two carry routes, chief to helipad, as waypoints the shortest path is forced through. The scree
## route is pinned to the barracks' north side: left free, the path query can take the long way round.
const CARRY := {
	"West, up the scree" = [[34, 40, 3], [27, 39, 3], [6.5, 47, 3], [9, 14, 6]],
	"East, up the summit ramp" = [[50, 41, 3], [50, 34, 3], [69, 30, 6], [9, 14, 6]],
}


func _build() -> void:
	_root = Node3D.new()
	_root.name = "RelayStation"
	_root.set_script(load("res://areas/harbour/harbour.gd"))

	var nav := _nav_region()
	var land := _group(nav, "Land")
	for l in LAND:
		_box(land, "Land%d" % land.get_child_count(), l[0], -1, l[2], l[1], l[3])
	var solid := _group(nav, "Solid")
	for s in SOLID:
		_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	_camera_poles(solid, CAMERAS)
	for d in DECKS:
		_box(solid, d[0], d[1], d[2] - 0.3, d[2], d[3], Color(0.55, 0.6, 0.7))
	for l in LOW:
		_box(solid, "Low%d" % solid.get_child_count(), l[0], l[1], l[1] + LOW_H, "wood", Color(0.9, 0.8, 0.6))
	for b in BUILDINGS:
		_building(_group(solid, b[0]), b)
	for r in RAMPS:
		_ramp(solid, r)
	var crawl := _group(nav, "Crawlspaces")
	for c in CRAWLSPACES:
		_crawlspace(_group(crawl, c.name), c)
	_bake(nav)
	var nm := nav.navigation_mesh

	var ladders := _group(_root, "Ladders")
	for l in LADDERS:
		_ladder(ladders, l).set_meta("walkable", true)
	_backdrop()
	_sun()

	var spots := _group(_root, "Spots")
	for n in SPOTS:
		_marker(spots, n, SPOTS[n], START_FACING if n == "OperativeStart" else 0, {}, "spot")
	var sentries := _group(_root, "SentryHighPoints")
	for s in SENTRIES:
		_marker(sentries, s[0], s[1], s[2], s[3], "sentry_high_point")
	var cams := _group(_root, "CameraMounts")
	for c in CAMERAS:
		_marker(cams, c[0], c[1], c[2], {}, "camera_mount")
	_posts("GuardPosts", GUARD_POSTS, "guard_post")
	_posts("TargetPosts", TARGET_POSTS, "target_post")
	_posts("ExtraGuardPosts", EXTRA_POSTS, "guard_post_extra")
	var spoofs := _group(_root, "SpoofPlaces")
	for n in SPOOFS:
		_marker(spoofs, n, SPOOFS[n], 0, {}, "spoof_place")

	_actors()
	var ep := _area(_root, "ExtractionPoint", SPOTS.Extraction, Vector3(4, 3, 4), "res://areas/extraction_point.gd")
	ep.position.y += 1.5
	var intel := _group(_root, "Intel")
	var console := _area(intel, "RelayConsole", SPOTS.RelayConsole, Vector3(5, 3, 5), "res://areas/relay_station/relay_console.gd")
	console.position.y += 1.5
	_save(OUT)
	await _report_reach(nm, SPOTS.OperativeStart, REACH, CARRY)
	quit()


## The valley the hillside drops into, seen past the south rail. ponytail: the rest of the Backdrop kit
## (distant blocks, skyline, fog) is its own build. No kill volume: rails and cliffs close every edge.
func _backdrop() -> void:
	var bd := _group(_root, "Backdrop")
	bd.add_to_group("backdrop", true)
	var valley := MeshInstance3D.new()
	valley.name = "ValleyFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.58, 0.6)
	m.roughness = 1.0
	plane.material = m
	valley.mesh = plane
	valley.position = Vector3(0, -14.0, 0)
	_add(bd, valley)
