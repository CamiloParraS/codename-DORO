## The ground floor of the Area builders (tools/area_dressing.gd, then tools/area_builder.gd, extend it): textures,
## materials, the diagram-to-world mapping and solid boxes.
## Data is in diagram metres: x east, y south, 0-80 across the Area; h is height. Facings are compass
## bearings (0 north, 90 east). Rects are [x, y, w, d].
extends SceneTree

const LOW_H := 1.0        # low cover: hides a crouched Operative
const CRAWL_H := 1.2      # Crawlspace ceiling (Crawlspace and Ladder rules)
const CRAWL_W := 1.2
const RAIL_H := 1.0

const TEX := {
	ground = "res://assets/textures/dirt_03_128.png", brick = "res://assets/textures/brick_07_128.png",
	metal = "res://assets/textures/metal_05_128.png", stone = "res://assets/textures/stone_07_128.png",
	wood = "res://assets/textures/wood_07_128.png",
	asphalt = "res://assets/textures/asphalt_128.png", concrete = "res://assets/textures/concrete_128.png",
	corrugated = "res://assets/textures/corrugated_rust_128.png", panels = "res://assets/textures/panels_128.png",
	deck_plate = "res://assets/textures/deck_plate_128.png", rust = "res://assets/textures/rust_128.png",
	planks = "res://assets/textures/planks_128.png", rock = "res://assets/textures/rock_128.png",
	cargo = "res://assets/textures/cargo_green_128.png",
	hatch = "res://assets/textures/hatch_128.png", windows = "res://assets/textures/bridge_windows_128.png",
	hazard = "res://assets/textures/hazard_128.png",
}
## Metres per repeat where it isn't 2: wall textures span a wall's height.
const TILE := {asphalt = 6.0, concrete = 4.0, corrugated = 5.0, panels = 4.0, rock = 6.0, cargo = 2.6,
	hatch = 2.5, windows = 3.0, hazard = 1.0}
## Materials whose top and sides differ: key = [top, sides].
const SPLIT := {
	quay = ["asphalt", "concrete"], deck = ["deck_plate", "rust"], pier = ["planks", "rust"], kerb = ["concrete", "hazard"],
	hatch_cover = ["hatch", "rust"], superstructure = ["deck_plate", "windows"], terrain = ["ground", "rock"],
}

## Boxes that wear a model (areas/prop_skin.gd) instead of their box mesh.
const PROPS := {
	ResupplyCrate = "crate", DockCrate1 = "container_a", DockCrate2 = "container_b", Container1 = "container_a", Container2 = "container_b",
	Container3 = "container_a", Container4 = "container_b", Container5 = "container_b", Container6 = "container_a",
	DeckContainer1 = "container_a", DeckContainer2 = "container_b", DeckContainer3 = "container_a", Truck = "van", ConsoleDesk = "desk",
	Crane = "crane_tower", CraneBoom = "crane_boom", Bridge = "freighter_bridge", Antenna = "lattice_mast",
}
## Boxes with no mesh of their own: a dress model draws them (the freighter_hull shell over the hull and bow).
const SHELLED := ["Hull", "Bow", "BowTip"]
## Long boxes that wear a row of models instead of their box mesh: name prefix = model. Each copy fills an
## equal share of the length and the full height; its depth scales with its height.
const ROWS := {Fence = "fence", RoadSide = "fence", Low = "roadblock"}
## Materials that sound like a metal deck underfoot: their boxes get the meta `surface = "metal"`.
const METAL_FLOORS := ["deck", "deck_plate", "metal", "hatch", "hatch_cover", "superstructure"]

var _root: Node3D
var _mats := {}


func _initialize() -> void:
	_build.call_deferred()  # the navmesh bake needs a running tree


func _build() -> void:
	pass


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
		if c.scene_file_path == "":  # a model instance saves as a reference, not its insides
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
		var top: String = SPLIT[key][0] if SPLIT.has(key) else key
		m.set_shader_parameter("albedo_tex", load(TEX[top]))
		m.set_shader_parameter("tint", tint)
		m.set_shader_parameter("tile_m", TILE.get(top, 2.0))
		if SPLIT.has(key):
			m.set_shader_parameter("split", true)
			m.set_shader_parameter("side_tex", load(TEX[SPLIT[key][1]]))
			m.set_shader_parameter("side_tile_m", TILE.get(SPLIT[key][1], 2.0))
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
	var row: String = ROWS.keys().reduce(func(found: String, k: String) -> String: return k if name.begins_with(k) else found, "")
	if layer == 1 and row != "":
		_row(b, size, ROWS[row])
	elif layer == 1 and name not in SHELLED:
		var m := MeshInstance3D.new()
		m.name = "Mesh"
		m.mesh = _box_mesh(size, _mat(mat, tint))
		b.add_child(m)
	if PROPS.has(name):
		b.set_script(PropSkin)
		b.model = load("res://assets/models/props/%s.glb" % PROPS[name])
		if PROPS[name].begins_with("container"):
			b.tint = tint
	if mat in METAL_FLOORS:
		b.set_meta("surface", "metal")
	parent.add_child(b)
	if name == "ResupplyCrate":
		b.add_to_group("resupply_crate", true)
	return b


## A row of `key` models filling a box of `size` centred on b, along its long side.
func _row(b: Node3D, size: Vector3, key: String) -> void:
	var scene: PackedScene = load("res://assets/models/props/%s.glb" % key)
	var probe: Node3D = scene.instantiate()
	var box := _model_box(probe)
	probe.free()
	var along_x := size.x >= size.z
	var length := size.x if along_x else size.z
	var m_along_x := box.size.x >= box.size.z
	var m_len := box.size.x if m_along_x else box.size.z
	var sh := size.y / box.size.y
	var n := maxi(1, roundi(length / (m_len * sh)))
	var sl := length / n / m_len
	var fit := Vector3(sl, sh, sh) if m_along_x else Vector3(sh, sh, sl)
	var turn := Basis(Vector3.UP, PI / 2) if m_along_x != along_x else Basis()
	for i in n:
		var m: Node3D = scene.instantiate()
		m.name = "Row%d" % i
		m.basis = turn * Basis.from_scale(fit)
		var at := -length / 2 + (i + 0.5) * length / n
		m.position = (Vector3(at, 0, 0) if along_x else Vector3(0, 0, at)) - m.basis * box.get_center()
		b.add_child(m)


## The bounds of a model instance outside the tree, in its own axes.
func _model_box(m: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for v: VisualInstance3D in m.find_children("*", "VisualInstance3D", true, false):
		var xf := Transform3D.IDENTITY
		var n: Node = v
		while n != m:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b := xf * v.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
