## Set dressing, light and scenery for the Area builders: the mood, dress models, scattered instances, the
## heightfield past the Area, power lines, floor markings and beacons. Extends tools/area_kit.gd.
extends "res://tools/area_kit.gd"

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


## A map coordinate as a node-name part: -7.5 -> "m7p5".
func _coord(v: float) -> String:
	return str(snappedf(v, 0.01)).replace("-", "m").replace(".", "p")


## Set dressing from assets/models/props: [model, [x, y, h], facing, scale (1 if missing; a Vector3 per axis), skin material,
## skin tint], each standing on its base at h. Call it before the bake: anything DRESS_SOLID_H or taller is a
## StaticBody3D whose box collider (layer 1) the navmesh routes round, centred on the body like _box's so
## _check_markers sees it. Backdrop dressing passes solid = false: nothing out there is touched.
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
