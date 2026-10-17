## Builds areas/harbour/harbour.tscn, the Tanker berth greybox, from the Harbour diagram's variant B data
## (.scratch/area-redesign/issues/04-harbour-diagram.md), and bakes its navmesh. Until the layout settles
## this file is the Harbour's source: change the data here and rebuild, don't hand-edit the scene.
##   godot --headless --path . --script tools/build_harbour.gd
## Data is in diagram metres: x east, y south, 0-80 across the Area; h is height. Facings are compass
## bearings (0 north, 90 east). Rects are [x, y, w, d].
extends SceneTree

const OUT := "res://areas/harbour/harbour.tscn"
const DECK := 2.0         # the freighter's deck height above the quay
const CONTAINER_H := 2.6
const LOW_H := 1.0        # low cover: hides a crouched Operative
const CRAWL_H := 1.2      # Crawlspace ceiling (Crawlspace and Ladder rules)
const CRAWL_W := 1.2
const KERB_H := 0.5       # no jump, so a kerb holds the Operative off the sea
const RAIL_H := 1.0

const TEX := {
	ground = "res://assets/textures/dirt_03_128.png", brick = "res://assets/textures/brick_07_128.png",
	metal = "res://assets/textures/metal_05_128.png", stone = "res://assets/textures/stone_07_128.png",
	wood = "res://assets/textures/wood_07_128.png",
}

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
const CAMERAS := [
	["CamWarehouseA", [24.5, 49, 4], 300], ["CamPier", [56.5, 61.5, 3], 80],
	["CamGatehouse", [36, 14, 3.8], 200], ["CamLift", [14, 27, 5], 110],
]
const SPOTS := {
	OperativeStart = [71, 7, DECK], RoadEntry = [30, -2, 0], Extraction = [52, 77, 0],
	ResupplyCrate = [59, 49.5, 1], FreightLift = [8, 32, 0], SafeRoom = [46, 7.5, 0],
}
const SPOOFS := {SpoofDock = [52, 72], SpoofWarehouse = [42, 40], SpoofGatehouse = [40, 16.5], SpoofLiftControl = [18.5, 26]}
const INTEL := {IntelManifests = [9, 60], IntelRadioLog = [44, 9], IntelLift = [8, 32]}

var _root: Node3D
var _mats := {}


func _initialize() -> void:
	_build.call_deferred()  # the navmesh bake needs a running tree


func _build() -> void:
	_root = Node3D.new()
	_root.name = "Harbour"
	_root.set_script(load("res://areas/harbour/harbour.gd"))

	var nav := NavigationRegion3D.new()
	nav.name = "NavRegion"
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1  # not the carry blocks
	nm.agent_radius = 0.5
	nm.agent_height = 1.8           # under a Crawlspace's 1.2 m ceiling there is no navmesh
	nm.agent_max_climb = 0.4
	nav.navigation_mesh = nm
	var land := _group(nav, "Land")
	for l in LAND:
		_box(land, "Land%d" % land.get_child_count(), l[0], -1, 0, l[1], Color.WHITE)
	var solid := _group(nav, "Solid")
	for s in SOLID:
		_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	for l in LOW:
		_box(solid, "Low%d" % solid.get_child_count(), l[0], l[1], l[1] + LOW_H, "wood", Color(0.9, 0.8, 0.6))
	for b in BUILDINGS:
		_building(_group(solid, b[0]), b)
	_gangway(solid)
	var crawl := _group(nav, "Crawlspaces")
	for c in CRAWLSPACES:
		_crawlspace(_group(crawl, c.name), c)

	# Bake on its own: the Area script must not run here.
	get_root().add_child(nav)
	nav.bake_navigation_mesh(false)
	print("navmesh polygons: ", nm.get_polygon_count())
	get_root().remove_child(nav)
	_add(_root, nav)
	_own(nav)

	var ladders := _group(_root, "Ladders")
	for l in LADDERS:
		_ladder(ladders, l)
	_backdrop()
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.position.y = 20
	sun.shadow_enabled = true
	_add(_root, sun)

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

	var op: Node3D = load("res://actors/operative/operative.tscn").instantiate()
	op.name = "Operative"
	_add(_root, op)
	op.transform = spots.get_node("OperativeStart").transform
	var hud: Node = load("res://ui/hud/hud.tscn").instantiate()
	hud.name = "HudLayer"
	_add(_root, hud)
	var run := Node.new()
	run.name = "MissionRun"
	run.set_script(load("res://missions/mission_run.gd"))
	_add(_root, run)
	var ep := _area(_root, "ExtractionPoint", SPOTS.Extraction, Vector3(4, 3, 4), "res://areas/extraction_point.gd")
	ep.position.y = 1.5
	var intel := _group(_root, "Intel")
	var intel_mat := StandardMaterial3D.new()
	intel_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for n in INTEL:
		var a := _area(intel, n, INTEL[n] + [0.6], Vector3(1.5, 2, 1.5), "res://areas/intel_pickup.gd")
		var m := MeshInstance3D.new()
		m.name = "Mesh"
		m.mesh = _box_mesh(Vector3(0.4, 0.1, 0.3), intel_mat)
		_add(a, m)
	var sea := _area(_root, "Sea", [40, 40, -5.5], Vector3(160, 5, 160), "res://areas/sea.gd")
	sea.collision_mask = 1  # the Operative's layer

	_check_markers()
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("saved ", OUT, ": ", error_string(err))
	_root.free()
	quit()


# --- builders ---------------------------------------------------------------------------------

func _p(v: Array) -> Vector3:
	return Vector3(v[0] - 40.0, v[2] if v.size() > 2 else 0.0, v[1] - 40.0)


## The scene is built outside the tree, where global transforms don't work: walk the parents instead.
func _world(n: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	while n is Node3D:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf


func _place(n: Node3D, xf: Transform3D) -> void:
	n.transform = _world(n.get_parent()).affine_inverse() * xf


func _add(parent: Node, n: Node) -> void:
	parent.add_child(n)
	n.owner = _root


## Owners for nodes built before the root existed in their subtree (the baked NavRegion).
func _own(n: Node) -> void:
	for c in n.get_children():
		c.owner = _root
		_own(c)


func _group(parent: Node, name: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	if parent == _root:
		_add(parent, n)
	else:
		parent.add_child(n)
	return n


func _mat(key: String, tint: Color) -> ShaderMaterial:
	var k := "%s %s" % [key, tint.to_html()]
	if not _mats.has(k):
		var m := ShaderMaterial.new()
		m.shader = load("res://assets/shaders/psx_surface.gdshader")
		m.set_shader_parameter("albedo_tex", load(TEX[key]))
		m.set_shader_parameter("tint", tint)
		m.set_shader_parameter("tile_m", 2.0)
		_mats[k] = m
	return _mats[k]


func _box_mesh(size: Vector3, mat: Material) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	m.material = mat
	return m


func _box_shape(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s


## A solid box over rect from h0 to h1: a StaticBody3D with its mesh and shape.
func _box(parent: Node, name: String, r: Array, h0: float, h1: float, mat: String, tint: Color, layer := 1) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = name
	b.collision_layer = layer
	b.position = Vector3(r[0] + r[2] / 2.0 - 40.0, (h0 + h1) / 2.0, r[1] + r[3] / 2.0 - 40.0)
	var size := Vector3(r[2], h1 - h0, r[3])
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	shape.shape = _box_shape(size)
	b.add_child(shape)
	if layer == 1:
		var m := MeshInstance3D.new()
		m.name = "Mesh"
		m.mesh = _box_mesh(size, _mat(mat, tint))
		b.add_child(m)
	parent.add_child(b)
	if name == "ResupplyCrate":
		b.add_to_group("resupply_crate", true)
	return b


## Four walls with 2 m door gaps and a roof.
func _building(parent: Node3D, b: Array) -> void:
	var r: Array = b[1]
	var h: float = b[2]
	var t := 0.3
	var x0: float = r[0]
	var y0: float = r[1]
	var x1: float = r[0] + r[2]
	var y1: float = r[1] + r[3]
	var walls := {N = [x0, y0, x1, y0 + t], S = [x0, y1 - t, x1, y1], W = [x0, y0, x0 + t, y1], E = [x1 - t, y0, x1, y1]}
	for side in walls:
		var w: Array = walls[side]
		var door := -1.0
		for d in b[3]:
			if d[0] == side:
				door = d[1]
		var spans := [[w[0], w[1], w[2], w[3]]]
		if door >= 0.0:
			spans = [[w[0], w[1], door - 1.0, w[3]], [door + 1.0, w[1], w[2], w[3]]] if side in ["N", "S"] \
				else [[w[0], w[1], w[2], door - 1.0], [w[0], door + 1.0, w[2], w[3]]]
		for i in spans.size():
			var s: Array = spans[i]
			_box(parent, "Wall%s%d" % [side, i], [s[0], s[1], s[2] - s[0], s[3] - s[1]], 0, h, "brick", b[4])
	_box(parent, "Roof", r, h, h + 0.3, "metal", Color(0.6, 0.6, 0.6))


## A structure with a 1.2 m tunnel through it: the two halves, the roof over the tunnel, a carry block
## at each mouth (layer 4: solid only to an Operative carrying a body).
func _crawlspace(parent: Node3D, c: Dictionary) -> void:
	var r: Array = c.rect
	var h: float = c.h
	if c.has("axis_x"):
		var a: float = c.axis_x - CRAWL_W / 2
		_box(parent, "SideW", [r[0], r[1], a - r[0], r[3]], 0, h, c.mat, c.tint)
		_box(parent, "SideE", [a + CRAWL_W, r[1], r[0] + r[2] - a - CRAWL_W, r[3]], 0, h, c.mat, c.tint)
		_box(parent, "Ceiling", [a, r[1], CRAWL_W, r[3]], CRAWL_H, h, c.mat, c.tint)
		_box(parent, "CarryBlockN", [a, r[1] - 0.1, CRAWL_W, 0.2], 0, CRAWL_H, c.mat, c.tint, 8)
		_box(parent, "CarryBlockS", [a, r[1] + r[3] - 0.1, CRAWL_W, 0.2], 0, CRAWL_H, c.mat, c.tint, 8)
	else:
		var a: float = c.axis_y - CRAWL_W / 2
		_box(parent, "SideN", [r[0], r[1], r[2], a - r[1]], 0, h, c.mat, c.tint)
		_box(parent, "SideS", [r[0], a + CRAWL_W, r[2], r[1] + r[3] - a - CRAWL_W], 0, h, c.mat, c.tint)
		_box(parent, "Ceiling", [r[0], a, r[2], CRAWL_W], CRAWL_H, h, c.mat, c.tint)
		_box(parent, "CarryBlockW", [r[0] - 0.1, a, 0.2, CRAWL_W], 0, CRAWL_H, c.mat, c.tint, 8)
		_box(parent, "CarryBlockE", [r[0] + r[2] - 0.1, a, 0.2, CRAWL_W], 0, CRAWL_H, c.mat, c.tint, 8)


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


## A Ladder: group "ladders", Bottom and Top markers, and rungs (no collision) up the face.
func _ladder(parent: Node3D, l: Array) -> void:
	var n := Node3D.new()
	n.name = l[0]
	_add(parent, n)
	n.add_to_group("ladders", true)
	for end in [["Bottom", l[1]], ["Top", l[2]]]:
		var m := Marker3D.new()
		m.name = end[0]
		_add(n, m)
		_place(m, Transform3D(Basis(), _p(end[1])))
	var bottom := _p(l[1])
	var toward := (_p(l[2]) - bottom) * Vector3(1, 0, 1)
	var rungs := MeshInstance3D.new()
	rungs.name = "Rungs"
	var tall: float = l[2][2] - l[1][2] + 1.0
	rungs.mesh = _box_mesh(Vector3(0.6, tall, 0.1), _mat("metal", Color(0.4, 0.9, 1.0)))
	_add(n, rungs)
	_place(rungs, Transform3D(Basis.looking_at(toward), bottom + toward.normalized() * 0.4 + Vector3.UP * (tall / 2)))


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


func _marker(parent: Node3D, name: String, at: Array, facing: float, meta: Dictionary, group := "") -> Marker3D:
	var m := Marker3D.new()
	m.name = name
	_add(parent, m)
	if group != "":
		m.add_to_group(group, true)
	_place(m, Transform3D(Basis(Vector3.UP, deg_to_rad(-facing)), _p(at)))
	for k in meta:
		if k != "f":
			m.set_meta(k, meta[k])
	return m


func _posts(container: String, posts: Array, group: String) -> void:
	var g := _group(_root, container)
	for p in posts:
		var post := _marker(g, p[0], p[1], p[2], p[3], group)
		for i in p[4].size():
			var wp: Array = p[4][i]
			_marker(post, "Route%d" % (i + 1), [wp[0], wp[1], p[1][2]], wp[2].get("f", 0), wp[2])


func _area(parent: Node, name: String, at: Array, size: Vector3, script: String) -> Area3D:
	var a := Area3D.new()
	a.name = name
	a.collision_layer = 0
	a.set_script(load(script))
	_add(parent, a)
	a.position = _p(at)
	var s := CollisionShape3D.new()
	s.name = "Shape"
	s.shape = _box_shape(size)
	_add(a, s)
	return a


## Every guard and Spot marker should stand clear of solid boxes, or the navmesh won't reach it.
func _check_markers() -> void:
	var boxes := []
	for b: StaticBody3D in _root.find_children("*", "StaticBody3D", true, false):
		var s: BoxShape3D = b.get_node("Shape").shape
		if b.collision_layer == 1 and b.get_parent().name != "Land" and b.name != "ResupplyCrate":
			boxes.append([b.name, AABB(_world(b).origin - s.size / 2, s.size).grow(0.3)])
	for m: Marker3D in _root.find_children("*", "Marker3D", true, false):
		var parent := m.get_parent()
		if parent.name in ["SentryHighPoints", "CameraMounts"] or parent.is_in_group("ladders"):
			continue
		for b in boxes:
			if b[1].has_point(_world(m).origin + Vector3.UP * 0.5):
				push_warning("%s sits inside %s" % [_root.get_path_to(m), b[0]])
