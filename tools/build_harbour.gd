## Builds areas/harbour/harbour.tscn, the Tanker berth greybox, from the Harbour diagram's variant B data
## (.scratch/area-redesign/issues/04-harbour-diagram.md), and bakes its navmesh. Until the layout settles
## this file is the Harbour's source: change the data here and rebuild, don't hand-edit the scene.
##   godot --headless --path . --script tools/build_harbour.gd
## Data is in diagram metres (tools/area_builder.gd).
extends "res://tools/area_builder.gd"

const OUT := "res://areas/harbour/harbour.tscn"
const DECK := 2.0         # the freighter's deck height above the quay
const CONTAINER_H := 2.6
const KERB_H := 0.5       # no jump, so a kerb holds the Operative off the sea


## Walkable at quay height, top at 0: [rect, material].
const LAND := [
	[[2, 2, 60, 68], "ground"],     # the yard
	[[26, -6, 8, 8], "ground"],     # the road through the north fence
	[[48, 70, 8, 9], "wood"],       # south pier, the Extraction point at its tip
	[[62, 60, 8, 7], "wood"],       # the pontoon under the stern pier
]
## Solid boxes: [name, rect, h0, h1, material, tint].
const SOLID := [
	["Cliff", [-2, -6, 4, 82], -3, 14, "stone", Color(0.8, 0.75, 0.7)],
	["FenceW", [2, 1.8, 24, 0.4], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
	["FenceE", [34, 1.8, 28, 0.4], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
	["RoadSideW", [25.8, -6, 0.4, 7.8], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
	["RoadSideE", [33.8, -6, 0.4, 7.8], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
	["RoadBarrier", [26, -6.2, 8, 0.4], 0, 1.2, "metal", Color(0.9, 0.5, 0.2)],
	# kerbs along the sea
	["KerbE1", [61.7, 2, 0.3, 42.8], 0, KERB_H, "stone", Color.WHITE],
	["KerbE2", [61.7, 47.2, 0.3, 12.8], 0, KERB_H, "stone", Color.WHITE],
	["KerbE3", [61.7, 67, 0.3, 3], 0, KERB_H, "stone", Color.WHITE],
	["KerbS1", [2, 69.7, 46, 0.3], 0, KERB_H, "stone", Color.WHITE],
	["KerbS2", [56, 69.7, 6, 0.3], 0, KERB_H, "stone", Color.WHITE],
	["KerbPierW", [47.7, 70, 0.3, 9.3], 0, KERB_H, "wood", Color.WHITE],
	["KerbPierE", [56, 70, 0.3, 9.3], 0, KERB_H, "wood", Color.WHITE],
	["KerbPierTip", [47.7, 79, 8.6, 0.3], 0, KERB_H, "wood", Color.WHITE],
	["KerbPontoonS", [62, 66.7, 8, 0.3], 0, KERB_H, "wood", Color.WHITE],
	["KerbPontoonE", [69.7, 60, 0.3, 7], 0, KERB_H, "wood", Color.WHITE],
	# the freighter: hull to deck height, bow, rails with a gap for the gangway and the stern drop
	["Hull", [65, 11, 12, 49], -3, DECK, "metal", Color(0.55, 0.6, 0.7)],
	["Bow", [67.5, 5, 7, 6], -3, DECK, "metal", Color(0.55, 0.6, 0.7)],
	["BowTip", [69.5, 3.5, 3, 1.5], -3, DECK, "metal", Color(0.55, 0.6, 0.7)],
	["RailPort1", [65, 11, 0.2, 33.8], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailPort2", [65, 47.2, 0.2, 12.8], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailStarboard", [76.8, 11, 0.2, 49], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailBowW", [67.5, 3.5, 0.2, 7.5], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailBowE", [74.3, 3.5, 0.2, 7.5], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailBowFront", [67.5, 3.3, 7, 0.2], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailShoulderW", [65, 10.9, 2.5, 0.2], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailShoulderE", [74.5, 10.9, 2.5, 0.2], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailSternW", [65, 59.8, 3.6, 0.2], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["RailSternE", [69.6, 59.8, 7.4, 0.2], DECK, DECK + RAIL_H, "metal", Color(0.8, 0.3, 0.25)],
	["Bridge", [67, 48, 8, 8], DECK, DECK + 6, "metal", Color(0.85, 0.85, 0.8)],
	["DeckContainer1", [74, 20, 3, 7], DECK, DECK + CONTAINER_H, "metal", Color(0.3, 0.5, 0.8)],
	["DeckContainer2", [73, 30, 2.4, 8], DECK, DECK + CONTAINER_H, "metal", Color(0.8, 0.4, 0.2)],
	["DeckContainer3", [66.5, 36, 2.4, 6], DECK, DECK + CONTAINER_H, "metal", Color(0.3, 0.6, 0.35)],
	["HatchStarboard", [73, 12, 3, 7], DECK, DECK + LOW_H, "metal", Color(0.5, 0.5, 0.45)],
	["HatchPort", [68, 12, 2.5, 5], DECK, DECK + LOW_H, "metal", Color(0.5, 0.5, 0.45)],
	# yard, east to west
	["Crane", [54, 18, 4, 4], 0, 8, "metal", Color(0.9, 0.75, 0.2)],
	["CraneBoom", [58, 19.5, 7, 1], 7.5, 8, "metal", Color(0.9, 0.75, 0.2)],
	["ResupplyCrate", [58.5, 49, 1, 1], 0, 1, "wood", Color(0.6, 0.9, 0.6)],
	["Container1", [44, 42, 3, 10], 0, CONTAINER_H, "metal", Color(0.75, 0.3, 0.25)],
	["Container2", [38, 56, 3, 8], 0, CONTAINER_H, "metal", Color(0.3, 0.5, 0.8)],
	["LiftControl", [16, 19, 5, 5], 0, 3.5, "brick", Color.WHITE],
	# the freight lift, set into the cliff, mouth east
	["LiftWallN", [2, 26, 12, 0.5], 0, 6, "stone", Color(0.7, 0.7, 0.7)],
	["LiftWallS", [2, 37.5, 12, 0.5], 0, 6, "stone", Color(0.7, 0.7, 0.7)],
	["LiftRoof", [2, 26, 12, 12], 6, 6.5, "stone", Color(0.7, 0.7, 0.7)],
]
## Low cover: [rect, h0].
const LOW := [
	[[51, 28, 1, 12], 0], [[44, 22, 6, 1.2], 0], [[26, 45, 8, 1.2], 0], [[16, 40, 6, 1.2], 0],
	[[48, 14, 1.2, 6], 0], [[52, 56, 6, 1.2], 0],
]
## Enterable buildings: [name, rect, height, doors [[side, centre]], tint]. A door is a 2 m gap.
const BUILDINGS := [
	["Gatehouse", [36, 6, 12, 8], 4.0, [["W", 10.0], ["S", 42.0]], Color.WHITE],
	["WarehouseA", [6, 48, 18, 16], 5.0, [["E", 54.0], ["N", 14.0]], Color(0.85, 0.85, 0.85)],
]
## Crawlspaces: a structure [name, rect, height, material, tint] with a 1.2 m tunnel through it along
## x = axis_x (N-S) or y = axis_y (E-W). Mouths get a carry block each.
const CRAWLSPACES := [
	{name = "StackCrawl", rect = [28, 51, 10, 5], h = CONTAINER_H, mat = "metal", tint = Color(0.6, 0.55, 0.3), axis_x = 33.0},
	{name = "WarehouseBCrawl", rect = [26, 28.5, 14, 10], h = 6.0, mat = "brick", tint = Color(0.8, 0.8, 0.75), axis_x = 33.0},
	{name = "SternPierCrawl", rect = [58.5, 60, 10, 7], h = 1.5, mat = "wood", tint = Color.WHITE, axis_y = 64.0},
]
## Ladders: [name, bottom [x, y, h], top [x, y, h]]. The rungs run up the face at the bottom marker.
const LADDERS := [
	["LadderCrane", [56, 22.5, 0], [56, 20.5, 8]],
	["LadderWarehouseB", [40.5, 31, 0], [38.5, 31, 6]],
]
## The gangway: a ramp from the port rail gap down to the quay.
const GANGWAY := {top = [65, 46], bottom = [61, 46], width = 2.4}

## Guard posts: [name, [x, y, h], facing, meta, route [[x, y, meta]]]. Meta: hold / scan / chat.
const GUARD_POSTS := [
	["PostO1", [70, 25, DECK], 90, {hold = 5.0}, []],                                 # deck look-out across the starboard hatches
	["PostO2", [70.5, 30, DECK], 180, {}, [[70.5, 42, {}]]],                          # port-side deck loop
	["PostP", [73, 58, DECK], 0, {chat = true}, []],                                  # smoke break behind the bridge
	["PostO5", [66.5, 45, DECK], 10, {scan = 60.0}, []],                              # gangway head
	["PostY1", [58, 24, 0], 180, {}, [[58, 48, {hold = 4.0, f = 90}], [57, 59, {}]]],  # quay; holds facing the gangway foot
	["PostY2", [12, 57, 0], 80, {scan = 90.0}, []],                                   # on the manifests
	["PostY3", [30, 47.5, 0], 90, {}, [[43, 47.5, {}], [46, 64, {}], [28, 62, {}]]],   # container lanes
	["PostY4", [40, 18, 0], 180, {scan = 90.0}, []],                                  # gatehouse post
	["PostY5", [17, 32, 0], 90, {scan = 60.0}, []],                                   # lift chokepoint
	["PostY6", [22, 22, 0], 90, {}, [[48, 20.5, {}], [48, 40, {}], [22, 43, {}]]],     # centre loop round Warehouse B
]
const EXTRA_POSTS := [
	["PostExtra1", [30, 44, 0], 0, {}, [[33, 40, {hold = 3.0, f = 0}], [33, 57.5, {hold = 3.0, f = 0}]]],  # Stealth L2: looks into both Crawlspaces
	["PostExtra2", [26, 55, 0], 90, {hold = 5.0}, []],   # Combat L2: Warehouse A east door
	["PostExtra3", [45, 17, 0], 135, {hold = 5.0}, []],  # Combat L2: gatehouse south door
]
const TARGET_POSTS := [  # ponytail: the Core's director waits by the lift until the Core Mission builds the gallery room
	["TargetPost1", [10, 30, 0], 180, {}, [[10, 35, {}]]],
]
const SENTRIES := [
	["SentryCrane", [56, 19.5, 8], 200, {scan = 90.0}],
	["SentryWarehouseB", [34, 31, 6], 160, {scan = 90.0}],
]
## Camera mounts: [name, [x, y, h], facing, pole base h]. Without a pole base the mount is on a wall face.
const CAMERAS := [
	["CamWarehouseA", [24.05, 47.95, 4], 310], ["CamPier", [56.5, 61.5, 3], 80, 0.0],
	["CamGatehouse", [36, 14, 3.8], 200], ["CamLift", [14.05, 26.25, 5], 110],
]
const SPOTS := {
	OperativeStart = [71, 7, DECK], RoadEntry = [30, -2, 0], Extraction = [52, 77, 0],
	ResupplyCrate = [59, 49.5, 1], FreightLift = [8, 32, 0], SafeRoom = [46, 7.5, 0],
}
const SPOOFS := {SpoofDock = [52, 72], SpoofWarehouse = [42, 40], SpoofGatehouse = [40, 16.5], SpoofLiftControl = [18.5, 26]}
const INTEL := {IntelManifests = [9, 60], IntelRadioLog = [44, 9], IntelLift = [8, 32]}


func _build() -> void:
	_root = Node3D.new()
	_root.name = "Harbour"
	_root.set_script(load("res://areas/harbour/harbour.gd"))

	var nav := _nav_region()
	var land := _group(nav, "Land")
	for l in LAND:
		_box(land, "Land%d" % land.get_child_count(), l[0], -1, 0, l[1], Color.WHITE)
	var solid := _group(nav, "Solid")
	for s in SOLID:
		_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	_camera_poles(solid, CAMERAS)
	for l in LOW:
		_box(solid, "Low%d" % solid.get_child_count(), l[0], l[1], l[1] + LOW_H, "wood", Color(0.9, 0.8, 0.6))
	for b in BUILDINGS:
		_building(_group(solid, b[0]), b)
	_gangway(solid)
	var crawl := _group(nav, "Crawlspaces")
	for c in CRAWLSPACES:
		_crawlspace(_group(crawl, c.name), c)
	_bake(nav)

	var ladders := _group(_root, "Ladders")
	for l in LADDERS:
		_ladder(ladders, l)
	_backdrop()
	_sun()

	var spots := _group(_root, "Spots")
	for n in SPOTS:
		_marker(spots, n, SPOTS[n], 180 if n == "OperativeStart" else 0, {}, "spot")
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
		_marker(spoofs, n, SPOOFS[n] + [0], 0, {}, "spoof_place")

	_actors()
	var ep := _area(_root, "ExtractionPoint", SPOTS.Extraction, Vector3(4, 3, 4), "res://areas/extraction_point.gd")
	ep.position.y = 1.5
	_intel(INTEL)
	var sea := _area(_root, "Sea", [40, 40, -5.5], Vector3(160, 5, 160), "res://areas/sea.gd")
	sea.collision_mask = 1  # the Operative's layer
	_save(OUT)
	quit()


# --- Harbour-only builders ---------------------------------------------------------------------

## The gangway: a sloped deck from the ship's port gap to the quay, with side rails.
func _gangway(parent: Node3D) -> void:
	var top := _p(GANGWAY.top + [DECK])
	var bottom := _p(GANGWAY.bottom + [0])
	var run := top - bottom
	var length := run.length()
	var basis := Basis(Vector3.BACK, atan2(run.y, run.x))  # tilt about z so +x climbs to the deck
	for part in [["Gangway", 0.0, 0.2, GANGWAY.width], ["GangwayRailN", -GANGWAY.width / 2, 2.0, 0.1], ["GangwayRailS", GANGWAY.width / 2, 2.0, 0.1]]:
		var b := StaticBody3D.new()
		b.name = part[0]
		var size := Vector3(length, part[2], part[3])
		b.transform = Transform3D(basis, (top + bottom) / 2 + Vector3(0, part[2] / 2 - 0.1, part[1]))
		var shape := CollisionShape3D.new()
		shape.name = "Shape"
		shape.shape = _box_shape(size)
		b.add_child(shape)
		var m := MeshInstance3D.new()
		m.name = "Mesh"
		m.mesh = _box_mesh(size, _mat("metal", Color(0.8, 0.3, 0.25)))
		b.add_child(m)
		parent.add_child(b)


## The sea plane under the Area. ponytail: the rest of the Backdrop kit (cliffs, skyline, fog) is its own build.
func _backdrop() -> void:
	var bd := _group(_root, "Backdrop")
	bd.add_to_group("backdrop", true)
	var sea := MeshInstance3D.new()
	sea.name = "SeaPlane"
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.2, 0.3)
	m.roughness = 1.0
	plane.material = m
	sea.mesh = plane
	sea.position = Vector3(0, -1.0, 0)
	_add(bd, sea)
