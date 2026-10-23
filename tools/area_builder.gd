## Shared builders for the Area greybox generators (tools/build_harbour.gd, tools/build_relay_station.gd,
## tools/build_research_annex.gd).
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
	hatch_cover = ["hatch", "rust"], superstructure = ["deck_plate", "windows"],
}

## Boxes that wear a model (areas/prop_skin.gd) instead of their box mesh.
const PROPS := {
	ResupplyCrate = "crate", DockCrate1 = "container_a", DockCrate2 = "container_b", Container1 = "container_a", Container2 = "container_b",
	Container3 = "container_a", Container4 = "container_b", Container5 = "container_b", Container6 = "container_a",
	DeckContainer1 = "container_a", DeckContainer2 = "container_b", DeckContainer3 = "container_a", Truck = "van", ConsoleDesk = "desk",
	Crane = "crane_tower", CraneBoom = "crane_boom",
}
## Long boxes that wear a row of models instead of their box mesh: name prefix = model. Each copy fills an
## equal share of the length and the full height; its depth scales with its height.
const ROWS := {Fence = "fence", RoadSide = "fence", Low = "roadblock"}

## Set dressing below this height (after scale) gets no collider: cones, cans, desk clutter.
const DRESS_SOLID_H := 0.6
## Colliders that differ from the model's bounds: the lamp post's arm overhangs, so only its pole blocks;
## ceiling lamps hang out of reach.
const DRESS_SHAPES := {lamp_post = Vector3(0.4, 6, 0.4), ceiling_lamp = Vector3.ZERO}
## Models that light up: [light offset in the model's own axes, range, colour].
const DRESS_LIGHTS := {
	lamp_post = [Vector3(0, 5.4, -1.1), 14.0, Color(1, 0.62, 0.3)],  # sodium
	ceiling_lamp = [Vector3(0, -0.4, 0), 9.0, Color(1, 0.95, 0.85)],
}

var _root: Node3D
var _mats := {}


func _initialize() -> void:
	_build.call_deferred()  # the navmesh bake needs a running tree


func _build() -> void:
	pass


## The NavRegion every Area bakes: static colliders on layer 1 only (not the carry blocks).
func _nav_region() -> NavigationRegion3D:
	var nav := NavigationRegion3D.new()
	nav.name = "NavRegion"
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1  # not the carry blocks
	nm.agent_radius = 0.5
	nm.agent_height = 1.8           # under a Crawlspace's 1.2 m ceiling there is no navmesh
	nm.agent_max_climb = 0.4
	nav.navigation_mesh = nm
	return nav


## Bake on its own (the Area script must not run here), then hang it under the root.
func _bake(nav: NavigationRegion3D) -> void:
	get_root().add_child(nav)
	nav.bake_navigation_mesh(false)
	print("navmesh polygons: ", nav.navigation_mesh.get_polygon_count())
	get_root().remove_child(nav)
	_add(_root, nav)
	_own(nav)


## Each Area's light and fog: sun [pitch, yaw], colour and energy; ambient colour and energy; fog (also the
## sky) colour, begin and end in metres.
const MOODS := {
	harbour = {sun = [-18, 235], sun_c = Color(0.95, 0.7, 0.55), sun_e = 0.55, amb = Color(0.42, 0.5, 0.7), amb_e = 0.75,
		fog = Color(0.24, 0.29, 0.4), fog_from = 18.0, fog_to = 110.0},  # dusk-blue haze, last light low in the west
	relay_station = {sun = [-50, 140], sun_c = Color(0.5, 0.55, 0.75), sun_e = 0.25, amb = Color(0.5, 0.34, 0.22), amb_e = 0.7,
		fog = Color(0.2, 0.12, 0.07), fog_from = 15.0, fog_to = 80.0},  # sodium orange night under a thin moon
	research_annex = {sun = [-65, 20], sun_c = Color(0.92, 0.96, 1.0), sun_e = 0.9, amb = Color(0.75, 0.8, 0.85), amb_e = 0.55,
		fog = Color(0.66, 0.7, 0.75), fog_from = 30.0, fog_to = 130.0},  # cold clinical white overcast
	core = {sun = [-60, 35], sun_c = Color(0.7, 0.3, 0.25), sun_e = 0.35, amb = Color(0.55, 0.2, 0.17), amb_e = 0.8,
		fog = Color(0.18, 0.05, 0.05), fog_from = 15.0, fog_to = 80.0},  # dim red emergency light
}


## The Sun and a WorldEnvironment set from the Area's MOODS entry (psx_look's environment is the fallback).
func _mood(area: String) -> void:
	var md: Dictionary = MOODS[area]
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(md.sun[0], md.sun[1], 0)
	sun.position.y = 20
	sun.light_color = md.sun_c
	sun.light_energy = md.sun_e
	sun.shadow_enabled = true
	_add(_root, sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = md.fog
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = md.amb
	env.ambient_light_energy = md.amb_e
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = md.fog
	env.fog_density = 1.0
	env.fog_depth_begin = md.fog_from
	env.fog_depth_end = md.fog_to
	env.glow_enabled = true  # lamps bloom a little at 480 lines
	env.glow_intensity = 0.6
	env.glow_hdr_threshold = 0.9
	var we := WorldEnvironment.new()
	we.name = "Mood"
	we.environment = env
	_add(_root, we)


## The Operative at $Spots/OperativeStart, the HUD and the MissionRun.
func _actors() -> void:
	var op: Node3D = load("res://actors/operative/operative.tscn").instantiate()
	op.name = "Operative"
	_add(_root, op)
	op.transform = _root.get_node("Spots/OperativeStart").transform
	var hud: Node = load("res://ui/hud/hud.tscn").instantiate()
	hud.name = "HudLayer"
	_add(_root, hud)
	var run := Node.new()
	run.name = "MissionRun"
	run.set_script(load("res://missions/mission_run.gd"))
	_add(_root, run)


func _save(out: String) -> void:
	_check_markers()
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, out)
	print("saved ", out, ": ", error_string(err))
	_root.free()


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
	elif layer == 1:
		var m := MeshInstance3D.new()
		m.name = "Mesh"
		m.mesh = _box_mesh(size, _mat(mat, tint))
		b.add_child(m)
	if PROPS.has(name):
		b.set_script(PropSkin)
		b.model = load("res://assets/models/props/%s.glb" % PROPS[name])
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


## Set dressing from assets/models/props: [model, [x, y, h], facing, scale (1 if missing)], each standing on
## its base at h. Call it before the bake: anything DRESS_SOLID_H or taller is a StaticBody3D whose box
## collider (layer 1) the navmesh routes round, centred on the body like _box's so _check_markers sees it.
func _dress(parent: Node3D, items: Array) -> void:
	var g := _group(parent, "Dressing")
	for it in items:
		var key: String = it[0]
		var s: float = it[3] if it.size() > 3 else 1.0
		var m: Node3D = load("res://assets/models/props/%s.glb" % key).instantiate()
		var box := _model_box(m)
		var size: Vector3 = DRESS_SHAPES.get(key, box.size) * s
		var solid := size.y >= DRESS_SOLID_H
		var b: Node3D = StaticBody3D.new() if solid else Node3D.new()
		b.name = "%s%d" % [key.to_pascal_case(), g.get_child_count()]
		b.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-it[2])), _p(it[1]) + Vector3.UP * size.y / 2)
		g.add_child(b)
		if solid:
			var shape := CollisionShape3D.new()
			shape.name = "Shape"
			shape.shape = _box_shape(size)
			b.add_child(shape)
		b.add_child(m)
		m.scale = Vector3.ONE * s
		m.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * s - Vector3.UP * size.y / 2
		if DRESS_LIGHTS.has(key):
			var l := OmniLight3D.new()
			l.name = "Light"
			l.position = m.position + DRESS_LIGHTS[key][0] * s
			l.omni_range = DRESS_LIGHTS[key][1]
			l.light_color = DRESS_LIGHTS[key][2]
			l.light_energy = 3.0
			b.add_child(l)
	if _root.is_ancestor_of(g):  # dressing in the NavRegion is owned by _bake
		g.owner = _root
		_own(g)


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


## Four walls with door gaps (any number per side) and a roof: [name, rect, height, doors [[side, centre(, width)]],
## tint, base, wall material]. A door is 2 m wide unless given. The walls stand on base (0 if missing) and are brick unless given.
func _building(parent: Node3D, b: Array) -> void:
	var r: Array = b[1]
	var h: float = b[2]
	var base: float = b[5] if b.size() > 5 else 0.0
	var t := 0.3
	var x0: float = r[0]
	var y0: float = r[1]
	var x1: float = r[0] + r[2]
	var y1: float = r[1] + r[3]
	var walls := {N = [x0, y0, x1, y0 + t], S = [x0, y1 - t, x1, y1], W = [x0, y0, x0 + t, y1], E = [x1 - t, y0, x1, y1]}
	for side in walls:
		var w: Array = walls[side]
		var ns: bool = side in ["N", "S"]
		var doors := []
		for d in b[3]:
			if d[0] == side:
				var half: float = (d[2] if d.size() > 2 else 2.0) / 2.0
				doors.append([d[1] - half, d[1] + half])
		doors.sort()
		var spans := _spans(w[0] if ns else w[1], w[2] if ns else w[3], doors)
		for i in spans.size():
			var s: Array = spans[i]
			var rect := [s[0], w[1], s[1] - s[0], w[3] - w[1]] if ns else [w[0], s[0], w[2] - w[0], s[1] - s[0]]
			_box(parent, "Wall%s%d" % [side, i], rect, base, base + h, b[6] if b.size() > 6 else "brick", b[4])
	_box(parent, "Roof", r, base + h, base + h + 0.3, "metal", Color(0.6, 0.6, 0.6))


## The [from, to] stretches of a wall from `from` to `to` left between its sorted gaps [[from, to]].
func _spans(from: float, to: float, gaps: Array) -> Array:
	var spans := []
	for gap in gaps:
		spans.append([from, gap[0]])
		from = gap[1]
	spans.append([from, to])
	return spans


## A wedge over rect rising from h0 to h1 toward its `up` side: a PrismMesh with its right angle there.
func _ramp(parent: Node3D, r: Dictionary) -> void:
	var rect: Array = r.rect
	var along_x: bool = r.up in ["E", "W"]
	var size := Vector3(rect[2] if along_x else rect[3], r.h1 - r.h0, rect[3] if along_x else rect[2])
	var b := StaticBody3D.new()
	b.name = r.name
	var yaw: float = {E = 0.0, N = 90.0, W = 180.0, S = -90.0}[r.up]  # turns local +x (the high side) to face up
	b.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)),
		Vector3(rect[0] + rect[2] / 2.0 - 40.0, (r.h0 + r.h1) / 2.0, rect[1] + rect[3] / 2.0 - 40.0))
	var h := size / 2
	var wedge := ConvexPolygonShape3D.new()
	wedge.points = PackedVector3Array([
		Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z),
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z)])
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	shape.shape = wedge
	b.add_child(shape)
	var m := MeshInstance3D.new()
	m.name = "Mesh"
	var prism := PrismMesh.new()
	prism.size = size
	prism.left_to_right = 1.0
	prism.material = _mat(r.mat, r.tint)
	m.mesh = prism
	b.add_child(m)
	parent.add_child(b)


## A structure with a 1.2 m tunnel through it: the two halves, the roof over the tunnel, a carry block
## at each mouth (layer 4: solid only to an Operative carrying a body). It stands on c.base (0 if missing).
func _crawlspace(parent: Node3D, c: Dictionary) -> void:
	var r: Array = c.rect
	var b: float = c.get("base", 0.0)
	var h: float = b + c.h
	if c.has("axis_x"):
		var a: float = c.axis_x - CRAWL_W / 2
		_box(parent, "SideW", [r[0], r[1], a - r[0], r[3]], b, h, c.mat, c.tint)
		_box(parent, "SideE", [a + CRAWL_W, r[1], r[0] + r[2] - a - CRAWL_W, r[3]], b, h, c.mat, c.tint)
		_box(parent, "Ceiling", [a, r[1], CRAWL_W, r[3]], b + CRAWL_H, h, c.mat, c.tint)
		_box(parent, "CarryBlockN", [a, r[1] - 0.1, CRAWL_W, 0.2], b, b + CRAWL_H, c.mat, c.tint, 8)
		_box(parent, "CarryBlockS", [a, r[1] + r[3] - 0.1, CRAWL_W, 0.2], b, b + CRAWL_H, c.mat, c.tint, 8)
	else:
		var a: float = c.axis_y - CRAWL_W / 2
		_box(parent, "SideN", [r[0], r[1], r[2], a - r[1]], b, h, c.mat, c.tint)
		_box(parent, "SideS", [r[0], a + CRAWL_W, r[2], r[1] + r[3] - a - CRAWL_W], b, h, c.mat, c.tint)
		_box(parent, "Ceiling", [r[0], a, r[2], CRAWL_W], b + CRAWL_H, h, c.mat, c.tint)
		_box(parent, "CarryBlockW", [r[0] - 0.1, a, 0.2, CRAWL_W], b, b + CRAWL_H, c.mat, c.tint, 8)
		_box(parent, "CarryBlockE", [r[0] + r[2] - 0.1, a, 0.2, CRAWL_W], b, b + CRAWL_H, c.mat, c.tint, 8)


## A Ladder: group "ladders", Bottom and Top markers, and rungs (no collision) up the face.
func _ladder(parent: Node3D, l: Array) -> Node3D:
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
	rungs.mesh = _box_mesh(Vector3(0.6, tall, 0.1), _mat("metal", Color(1.0, 0.85, 0.25)))
	_add(n, rungs)
	_place(rungs, Transform3D(Basis.looking_at(toward), bottom + toward.normalized() * 0.4 + Vector3.UP * (tall / 2)))
	return n


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


## A pole under each camera mount that stands in the open: CAMERAS entries [name, [x, y, h], facing,
## pole base h]. Mounts without a pole base are on a wall face.
func _camera_poles(parent: Node3D, cameras: Array) -> void:
	for c in cameras:
		if c.size() > 3:
			_box(parent, c[0] + "Pole", [c[1][0] - 0.1, c[1][1] - 0.1, 0.2, 0.2], c[3], c[1][2], "metal", Color(0.5, 0.5, 0.5))


## Intel pickups: {name: [x, y[, floor h]]}, each a small unshaded slab 0.6 m up under $Intel.
func _intel(pickups: Dictionary) -> void:
	var intel := _group(_root, "Intel")
	var intel_mat := StandardMaterial3D.new()
	intel_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for n in pickups:
		var a := _area(intel, n, [pickups[n][0], pickups[n][1], pickups[n][2] + 0.6 if pickups[n].size() > 2 else 0.6], Vector3(1.5, 2, 1.5), "res://areas/intel_pickup.gd")
		var m := MeshInstance3D.new()
		m.name = "Mesh"
		m.mesh = _box_mesh(Vector3(0.4, 0.1, 0.3), intel_mat)
		_add(a, m)


## Prints whether the navmesh reaches each `reach` spot from `start_at` (within 0.5 m across and 1 m up,
## so a spot in a doorway misses if the doorway is closed), and the length of each `carry` route, the
## shortest path forced through its waypoints. Warns on any spot it can't reach.
func _report_reach(nm: NavigationMesh, start_at: Array, reach: Dictionary, carry: Dictionary) -> void:
	var map := NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(map, nm.cell_size)
	NavigationServer3D.map_set_cell_height(map, nm.cell_height)
	var region := NavigationServer3D.region_create()
	NavigationServer3D.region_set_map(region, map)
	NavigationServer3D.region_set_navigation_mesh(region, nm)
	NavigationServer3D.map_set_active(map, true)
	var start := _p(start_at)
	for i in 300:  # the server takes the region in on a later frame of its own
		if NavigationServer3D.map_get_iteration_id(map) > 0 and NavigationServer3D.map_get_closest_point(map, start) != Vector3.ZERO:
			break
		await physics_frame
	for n in reach:
		var path := NavigationServer3D.map_get_path(map, start, _p(reach[n]), true)
		var off := path[-1] - _p(reach[n]) if path.size() else Vector3.INF
		var miss := Vector2(off.x, off.z).length() if absf(off.y) < 1.0 else INF
		print("reach %-16s %5.1f m %s" % [n, _length(path), "ok" if miss < 0.5 else "MISSES BY %.1f m" % miss])
		if miss >= 0.5:
			push_warning("the navmesh doesn't reach %s" % n)
	for n in carry:
		var legs: Array = carry[n]
		var total := 0.0
		for i in legs.size() - 1:
			total += _length(NavigationServer3D.map_get_path(map, _p(legs[i]), _p(legs[i + 1]), true))
		print("carry %-26s %5.1f m" % [n, total])
	NavigationServer3D.free_rid(region)
	NavigationServer3D.free_rid(map)


func _length(path: PackedVector3Array) -> float:
	var d := 0.0
	for i in path.size() - 1:
		d += path[i].distance_to(path[i + 1])
	return d


## Every guard and Spot marker should stand clear of solid boxes, or the navmesh won't reach it.
func _check_markers() -> void:
	var boxes := []
	for b: StaticBody3D in _root.find_children("*", "StaticBody3D", true, false):
		var s := (b.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
		if s and b.collision_layer == 1 and b.get_parent().name != "Land" and b.name != "ResupplyCrate":
			boxes.append([b.name, AABB(_world(b).origin - s.size / 2, s.size).grow(0.3)])
	for m: Marker3D in _root.find_children("*", "Marker3D", true, false):
		var parent := m.get_parent()
		# a camera hangs from its mount, so the mount must be on a wall face or a pole (within 0.3 m)
		if parent.name == "CameraMounts" and not boxes.any(func(b: Array) -> bool: return b[1].has_point(_world(m).origin)):
			push_warning("%s hangs in the air" % _root.get_path_to(m))
		if parent.name in ["SentryHighPoints", "CameraMounts"] or parent.is_in_group("ladders"):
			continue
		for b in boxes:
			if b[1].has_point(_world(m).origin + Vector3.UP * 0.5):
				push_warning("%s sits inside %s" % [_root.get_path_to(m), b[0]])
