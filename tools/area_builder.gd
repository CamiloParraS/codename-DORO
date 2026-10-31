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

## Set dressing below this height (after scale) gets no collider: cones, cans, desk clutter.
const DRESS_SOLID_H := 0.6
## Colliders that differ from the model's bounds: the lamp post's arm overhangs, so only its pole blocks;
## ceiling lamps hang out of reach.
const DRESS_SHAPES := {lamp_post = Vector3(0.4, 6, 0.4), ceiling_lamp = Vector3.ZERO, freighter_hull = Vector3.ZERO, utility_pole = Vector3(0.4, 9, 0.4),
	pine = Vector3(0.6, 8, 0.6), tyre_fender = Vector3.ZERO, piling = Vector3.ZERO}
## Models that light up: [light offset in the model's own axes, range, colour].
const DRESS_LIGHTS := {
	lamp_post = [Vector3(0, 5.4, -1.1), 14.0, Color(1, 0.62, 0.3)],  # sodium
	ceiling_lamp = [Vector3(0, -0.4, 0), 9.0, Color(1, 0.95, 0.85)],
	lighthouse = [Vector3(0, 12.85, 0), 30.0, Color(1, 0.85, 0.55)],
	buoy_red = [Vector3(0, 3.4, 0), 6.0, Color(1, 0.15, 0.1)], buoy_green = [Vector3(0, 3.4, 0), 6.0, Color(0.15, 1, 0.3)],
}
## Untextured models (made in Blender as bare shape) that wear an area material: model = [material, tint].
## A dress entry's 5th and 6th fields override them.
const SKINS := {
	mountain_a = ["terrain", Color(0.7, 0.7, 0.72)], mountain_b = ["terrain", Color(0.7, 0.7, 0.72)],
	boulder_a = ["rock", Color(0.8, 0.78, 0.75)], boulder_b = ["rock", Color(0.8, 0.78, 0.75)],
	mound = ["ground", Color(0.8, 0.75, 0.65)], water_tower = ["corrugated", Color(0.85, 0.85, 0.82)],
}

## Materials that sound like a metal deck underfoot: their boxes get the meta `surface = "metal"`.
const METAL_FLOORS := ["deck", "deck_plate", "metal", "hatch", "hatch_cover", "superstructure"]

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
## sky's horizon unless `haze` gives the horizon its own glow, so far hills stand dark against it) colour, begin
## and end in metres; the sky's zenith colour, and how much the sun glows in it.
const MOODS := {
	harbour = {sun = [-14, 235], sun_c = Color(1.0, 0.68, 0.5), sun_e = 0.7, amb = Color(0.42, 0.5, 0.7), amb_e = 0.7,
		fog = Color(0.3, 0.32, 0.42), fog_from = 18.0, fog_to = 120.0,
		zenith = Color(0.07, 0.1, 0.2), glow = 0.9},  # dusk-blue haze, last light low in the west
	relay_station = {sun = [-40, 140], sun_c = Color(0.62, 0.7, 0.95), sun_e = 0.6, amb = Color(0.46, 0.44, 0.52), amb_e = 1.35,
		fog = Color(0.11, 0.09, 0.1), fog_from = 15.0, fog_to = 85.0, haze = Color(0.34, 0.18, 0.1),
		zenith = Color(0.03, 0.04, 0.1), glow = 0.6},  # sodium-lit haze on the horizon, a thin moon in a dark sky
	research_annex = {sun = [-65, 20], sun_c = Color(0.95, 0.97, 1.0), sun_e = 1.0, amb = Color(0.72, 0.78, 0.85), amb_e = 0.5,
		fog = Color(0.66, 0.7, 0.75), fog_from = 40.0, fog_to = 140.0,
		zenith = Color(0.45, 0.52, 0.6), glow = 0.3},  # cold clinical white overcast
	core = {sun = [-60, 35], sun_c = Color(0.75, 0.32, 0.25), sun_e = 0.4, amb = Color(0.46, 0.27, 0.26), amb_e = 0.75,
		fog = Color(0.15, 0.06, 0.06), fog_from = 15.0, fog_to = 80.0,
		zenith = Color(0.05, 0.01, 0.02), glow = 0.4},  # dim red emergency light
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
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://assets/shaders/psx_sky.gdshader")
	sky_mat.set_shader_parameter("horizon", md.get("haze", md.fog))
	sky_mat.set_shader_parameter("zenith", md.zenith)
	sky_mat.set_shader_parameter("glow", md.glow)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32  # nothing reflects it but the sea
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = md.amb
	env.ambient_light_energy = md.amb_e
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = md.fog
	env.fog_density = 1.0
	env.fog_depth_begin = md.fog_from
	env.fog_depth_end = md.fog_to
	env.fog_sky_affect = 0.0  # the sky draws its own horizon
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC  # lamps and glints roll off instead of clipping
	env.tonemap_exposure = 1.15
	env.tonemap_white = 4.0
	env.ssao_enabled = true  # boxes sit on the ground instead of floating on it
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.3
	env.ssao_light_affect = 0.15
	env.glow_enabled = true  # lamps bloom a little at 480 lines
	env.glow_intensity = 0.7
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 0.85
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12
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
	if err == OK:
		_stable_ids(out)
	print("saved ", out, ": ", error_string(err))
	_root.free()


## Godot gives every node a random unique_id on each save, so a rebuild rewrites every node header. Each id becomes a
## hash of the node's path, and a rebuild changes only what the data changed.
func _stable_ids(out: String) -> void:
	var text := FileAccess.get_file_as_string(out)
	var taken := {}
	var root_name := ""
	var rx := RegEx.create_from_string(r'(?m)^\[node name="([^"]*)"([^\]]*?)unique_id=(\d+)')
	var par := RegEx.create_from_string(r'parent="([^"]*)"')
	var result := ""
	var at := 0
	for m in rx.search_all(text):
		var path := m.get_string(1)
		var pm := par.search(m.get_string(2))
		if not pm:
			root_name = path
		else:
			path = "%s/%s" % [root_name if pm.get_string(1) == "." else root_name + "/" + pm.get_string(1), path]
		var id := path.hash() & 0x7fffffff
		while taken.has(id):
			id += 1
		taken[id] = true
		result += text.substr(at, m.get_start(3) - at) + str(id)
		at = m.get_end(3)
	result += text.substr(at)
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(result)


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


## Set dressing from assets/models/props: [model, [x, y, h], facing, scale (1 if missing; a Vector3 per axis), skin material,
## skin tint], each standing on its base at h. Call it before the bake: anything DRESS_SOLID_H or taller is a
## StaticBody3D whose box collider (layer 1) the navmesh routes round, centred on the body like _box's so
## _check_markers sees it. Backdrop dressing passes solid = false: nothing out there is touched.
## A map coordinate as a node-name part: -7.5 -> "m7p5".
func _coord(v: float) -> String:
	return str(snappedf(v, 0.01)).replace("-", "m").replace(".", "p")


func _dress(parent: Node3D, items: Array, solid_ok := true) -> void:
	var g := _group(parent, "Dressing")
	for it in items:
		var key: String = it[0]
		var sc: Variant = it[3] if it.size() > 3 else 1.0
		var s: Vector3 = sc if sc is Vector3 else Vector3.ONE * sc  # a Vector3 stretches per model axis
		var m: Node3D = load("res://assets/models/props/%s.glb" % key).instantiate()
		var box := _model_box(m)
		var size: Vector3 = DRESS_SHAPES.get(key, box.size) * s
		var solid := solid_ok and size.y >= DRESS_SOLID_H
		if size == Vector3.ZERO:
			size = box.size * s  # placed by its real bounds, no collider
		var skin: Array = SKINS.get(key, [])
		if it.size() > 4:
			skin = [it[4], it[5] if it.size() > 5 else Color.WHITE]
		if skin:
			m = _bare(m, _mat(skin[0], skin[1]))
		var b: Node3D = StaticBody3D.new() if solid else Node3D.new()
		b.name = "%s_%s_%s" % [key.to_pascal_case(), _coord(it[1][0]), _coord(it[1][1])]  # by place, so an insertion renames nothing else
		b.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-it[2])), _p(it[1]) + Vector3.UP * size.y / 2)
		g.add_child(b)
		if solid:
			var shape := CollisionShape3D.new()
			shape.name = "Shape"
			shape.shape = _box_shape(size)
			b.add_child(shape)
		b.add_child(m)
		m.scale = s
		m.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * s - Vector3.UP * size.y / 2
		if solid and key == "lamp_post":  # the arm skews the bounds' centre: the pole stands at the model's origin
			b.get_node("Shape").position = Vector3(m.position.x, 0, m.position.z)
		if DRESS_LIGHTS.has(key):
			var l := OmniLight3D.new()
			l.name = "Light"
			l.position = m.position + DRESS_LIGHTS[key][0] * s
			l.omni_range = DRESS_LIGHTS[key][1]
			l.light_color = DRESS_LIGHTS[key][2]
			l.light_energy = 3.0
			_fade(l, key)
			b.add_child(l)
	if _root.is_ancestor_of(g):  # dressing in the NavRegion is owned by _bake
		g.owner = _root
		_own(g)


## Lights past the player's surroundings switch off with distance (the lamp still glows); the lighthouse's
## sweep is meant to be seen from across the bay.
func _fade(l: Light3D, key := "") -> void:
	if key != "lighthouse":
		l.distance_fade_enabled = true
		l.distance_fade_begin = 40.0
		l.distance_fade_length = 20.0


## A model's meshes as plain MeshInstance3Ds wearing mat: an instance saves as a reference, so a material
## set inside it would be lost. The meshes are embedded in the scene when it's saved.
func _bare(m: Node3D, mat: Material) -> Node3D:
	var n := Node3D.new()
	n.name = m.name
	for v in _meshes(m):
		var c := MeshInstance3D.new()
		c.name = "Mesh%d" % n.get_child_count()
		c.mesh = v[0]
		c.transform = v[1]
		c.material_override = mat
		n.add_child(c)
	m.free()
	return n


## [mesh, transform in the model's own axes] for every MeshInstance3D of a model instance outside the tree.
func _meshes(m: Node3D) -> Array:
	var out := []
	for v: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D.IDENTITY
		var n: Node = v
		while n != m:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		out.append([v.mesh, xf])
	return out


## Many copies of one model as a MultiMeshInstance3D per mesh, no colliders: forests, rock fields, pilings.
## at: [[x, y, h], facing, scale] each, standing on its base like _dress. skin: [material, tint] or empty.
func _instances(parent: Node3D, name: String, key: String, at: Array, skin := [], shadows := true) -> void:
	var m: Node3D = load("res://assets/models/props/%s.glb" % key).instantiate()
	var box := _model_box(m)
	var parts := _meshes(m)
	m.free()
	for i in parts.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = parts[i][0]
		var xfs := PackedFloat32Array()  # 12 floats each: the basis' columns, then the origin
		for a in at:
			var turn := Basis(Vector3.UP, deg_to_rad(-a[1]))
			var base: Vector3 = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * a[2]
			var xf: Transform3D = Transform3D(turn.scaled(Vector3.ONE * a[2]), _p(a[0]) + turn * base) * parts[i][1]
			for v in [xf.basis.x, xf.basis.y, xf.basis.z, xf.origin]:
				xfs.append_array([v.x, v.y, v.z])
		var mi := MultiMeshInstance3D.new()
		mi.name = "%s%d" % [name, i] if parts.size() > 1 else name
		mi.multimesh = mm
		mi.set_script(load("res://areas/scatter.gd"))
		mi.set("transforms", xfs)
		if skin:
			mi.material_override = _mat(skin[0], skin[1])
		if not shadows:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(parent, mi)


## `count` random placements of a model over rects [[x, y, w, d]...], standing on h (a float, or a Callable
## (x, y) -> h for ground that isn't flat), kept `clear` metres off every avoid rect. Scale is random in
## [s0, s1]. The seed fixes the layout, so a rebuild doesn't reshuffle the forest.
func _scatter(parent: Node3D, name: String, key: String, rects: Array, count: int, h: Variant, s0: float, s1: float,
		rng_seed: int, avoid := [], clear := 2.0, skin := [], shadows := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var at := []
	var tries := 0
	while at.size() < count and tries < count * 20:
		tries += 1
		var r: Array = rects[rng.randi() % rects.size()]
		var x := rng.randf_range(r[0], r[0] + r[2])
		var y := rng.randf_range(r[1], r[1] + r[3])
		if avoid.any(func(a: Array) -> bool: return x > a[0] - clear and x < a[0] + a[2] + clear and y > a[1] - clear and y < a[1] + a[3] + clear):
			continue
		var gh: float = h.call(x, y) if h is Callable else h
		at.append([[x, y, gh - 0.15], rng.randf_range(0, 360), rng.randf_range(s0, s1)])
	_instances(parent, name, key, at, skin, shadows)


## Ground beyond the Area: a grid of `cell` metres over rect, its height fn.call(x, y), cells whose centre is
## in a hole rect left out (the Area's own boxes are there; a hole edge off the grid lines is off by up to half
## a cell, fine where the ground sits under the Area's land). Flat-shaded, wearing material key (top / sides
## split by slope, see psx_surface). No collision: rails, fences and cliffs keep the Operative off it. The mesh
## is saved to `save_to` (a binary .res) so the scene, which is text, only refers to it.
func _heightfield(parent: Node3D, name: String, rect: Array, cell: float, fn: Callable, holes: Array, key: String, tint: Color,
		save_to: String) -> void:
	var nx := roundi(rect[2] / cell)
	var ny := roundi(rect[3] / cell)
	var hs := []
	for i in nx + 1:
		var col := PackedFloat32Array()
		for j in ny + 1:
			col.append(fn.call(rect[0] + i * cell, rect[1] + j * cell))
		hs.append(col)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)  # flat: one normal per face
	var v := func(i: int, j: int) -> Vector3: return _p([rect[0] + i * cell, rect[1] + j * cell, hs[i][j]])
	for i in nx:
		for j in ny:
			var cx: float = rect[0] + (i + 0.5) * cell
			var cy: float = rect[1] + (j + 0.5) * cell
			if holes.any(func(r: Array) -> bool: return cx > r[0] and cx < r[0] + r[2] and cy > r[1] and cy < r[1] + r[3]):
				continue
			var a: Vector3 = v.call(i, j)
			var b: Vector3 = v.call(i + 1, j)
			var c: Vector3 = v.call(i + 1, j + 1)
			var d: Vector3 = v.call(i, j + 1)
			for p in [a, b, c, a, c, d]:
				st.add_vertex(p)
	st.generate_normals()
	var m := MeshInstance3D.new()
	m.name = name
	var mesh := st.commit()
	print("saved ", save_to, ": ", error_string(ResourceSaver.save(mesh, save_to)))
	mesh.take_over_path(save_to)
	m.mesh = mesh
	m.material_override = _mat(key, tint)
	_add(parent, m)


## Where the wires hang on a model, [across the line, up from its base] each, and how far a span sags.
const POWER := {
	utility_pole = {arms = [[-1.05, 8.5], [0.0, 8.5], [1.05, 8.5]], sag = 0.5},
	pylon = {arms = [[-6.7, 18.4], [6.7, 18.4], [-4.7, 23.4], [4.7, 23.4]], sag = 1.2},
}


## A power line: `model` (a POWER key) at each of points [[x, y, h], ...], turned across the line, and its
## wires strung between neighbours under a "Wires" group. No colliders.
func _power_line(parent: Node3D, model: String, points: Array) -> void:
	var items := []
	for k in points.size():
		var along := _p(points[mini(k + 1, points.size() - 1)]) - _p(points[maxi(k - 1, 0)])
		items.append([model, points[k], rad_to_deg(atan2(along.x, -along.z))])  # the line's bearing: arms run across it
	_dress(parent, items, false)
	var wires := _group(parent, "%sWires" % model.to_pascal_case())
	wires.owner = _root
	_wires(wires, points, POWER[model].arms, POWER[model].sag)


## Power lines: each span a few thin boxes along a parabola that sags `sag` metres mid-span. poles:
## [[x, y, h], ...]; arms: the attachment offsets [across the line, up from a pole's base].
func _wires(parent: Node3D, poles: Array, arms: Array, sag: float) -> void:
	const SEGMENTS := 5
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # wires read as dark lines, whatever the light
	mat.albedo_color = Color(0.06, 0.06, 0.06)
	for k in poles.size() - 1:
		var a := _p(poles[k])
		var b := _p(poles[k + 1])
		var across := (b - a).cross(Vector3.UP).normalized()
		for arm in arms:
			var p0: Vector3 = a + across * arm[0] + Vector3.UP * arm[1]
			var p1: Vector3 = b + across * arm[0] + Vector3.UP * arm[1]
			var at := func(t: float) -> Vector3: return p0.lerp(p1, t) + Vector3.DOWN * 4.0 * sag * t * (1.0 - t)
			for i in SEGMENTS:
				var q0: Vector3 = at.call(float(i) / SEGMENTS)
				var q1: Vector3 = at.call(float(i + 1) / SEGMENTS)
				var w := MeshInstance3D.new()
				w.name = "Wire%d" % parent.get_child_count()
				w.mesh = _box_mesh(Vector3(0.15, 0.15, q0.distance_to(q1)), mat)
				w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				w.transform = Transform3D(Basis.looking_at(q1 - q0), (q0 + q1) / 2)
				_add(parent, w)


## Painted strips a hair above the floor, no collision: [rect, dash length (0 = solid), floor h (0), colour
## (worn yellow)]. Dashes run along the long side.
func _markings(marks: Array) -> void:
	var g := _group(_root, "Markings")
	for mk in marks:
		var r: Array = mk[0]
		var floor_h: float = mk[2] if mk.size() > 2 else 0.0
		var mat := _mat("concrete", mk[3] if mk.size() > 3 else Color(1.0, 0.78, 0.2))
		var along_x: bool = r[2] > r[3]
		var length: float = r[2] if along_x else r[3]
		var dash: float = mk[1] if mk[1] > 0 else length
		var t := 0.0
		while t < length:
			var d := minf(dash, length - t)
			var strip := MeshInstance3D.new()
			strip.name = "Strip%d" % g.get_child_count()
			strip.mesh = _box_mesh(Vector3(d, 0.02, r[3]) if along_x else Vector3(r[2], 0.02, d), mat)
			strip.position = _p([r[0] + t + d / 2, r[1] + r[3] / 2, floor_h + 0.01] if along_x else [r[0] + r[2] / 2, r[1] + t + d / 2, floor_h + 0.01])
			strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_add(g, strip)
			t += dash * 2


## Small lights with a lamp you can see from afar: [[x, y, h], colour, range, pole base h or -1 for none].
func _beacons(beacons: Array) -> void:
	var g := _group(_root, "Beacons")
	for bc in beacons:
		var at := _p(bc[0])
		var lamp := MeshInstance3D.new()
		lamp.name = "Lamp%d" % g.get_child_count()
		var sphere := SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = bc[1]
		sphere.material = m
		lamp.mesh = sphere
		lamp.position = at
		_add(g, lamp)
		var l := OmniLight3D.new()
		l.name = "Light"
		l.light_color = bc[1]
		l.omni_range = bc[2]
		l.light_energy = 2.0
		_fade(l)
		_add(lamp, l)
		if bc[3] >= 0:
			var pole := MeshInstance3D.new()
			pole.name = "Pole"
			var ph: float = bc[0][2] - bc[3] - 0.15
			pole.mesh = _box_mesh(Vector3(0.1, ph, 0.1), _mat("rust", Color(0.6, 0.6, 0.6)))
			pole.position = Vector3(0, -0.15 - ph / 2, 0)
			_add(lamp, pole)


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
	if r.mat in METAL_FLOORS:
		b.set_meta("surface", "metal")
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


## No-Fulton rooms (areas/no_fulton.gd) under $NoFulton: [name, rect, h0, h1] each.
func _rooms(rooms: Array) -> void:
	var g := _group(_root, "NoFulton")
	for r in rooms:
		var rect: Array = r[1]
		_area(g, r[0], [rect[0] + rect[2] / 2.0, rect[1] + rect[3] / 2.0, (r[2] + r[3]) / 2.0],
			Vector3(rect[2], r[3] - r[2], rect[3]), "res://areas/no_fulton.gd")


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
		if parent.name in ["SentryHighPoints", "CameraMounts", "Encounters"] or parent.is_in_group("ladders"):  # an Encounter marker is a rect's corner
			continue
		for b in boxes:
			if b[1].has_point(_world(m).origin + Vector3.UP * 0.5):
				push_warning("%s sits inside %s" % [_root.get_path_to(m), b[0]])
