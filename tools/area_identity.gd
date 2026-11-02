## What makes a place read as what it is, for the Area builders: doorways that read as doors (a lintel, a frame,
## the leaves swung back against the wall, a lamp over an outside door; a roller shutter over a vehicle bay; a
## hazard-striped blast frame), signs, and mesh-only trim. Each Area's data is tools/identity/<area>.gd (the
## Core's is in its zones). Extends tools/area_dressing.gd; tools/area_builder.gd extends it.
extends "res://tools/area_dressing.gd"

const DOOR_H := 2.6  # a doorway's head above its floor
const BAY_H := 3.8   # a vehicle bay's
const FRAME_W := 0.12
## Leaf models by door style; "bay", "blast" and "frame" have no leaf, "none" isn't dressed at all.
const LEAVES := {door = "door_steel", wood = "door_wood", glass = "door_window"}
const SIGN_FONT := "res://assets/fonts/barlow_condensed_bold.ttf"
## Sign styles: [plate, lettering].
const SIGN_STYLES := {
	white = [Color(0.66, 0.65, 0.6), Color(0.12, 0.12, 0.13)], hazard = [Color(0.72, 0.56, 0.16), Color(0.1, 0.09, 0.08)],
	red = [Color(0.5, 0.17, 0.14), Color(0.8, 0.78, 0.72)], blue = [Color(0.2, 0.28, 0.45), Color(0.8, 0.78, 0.72)],
	green = [Color(0.18, 0.36, 0.24), Color(0.8, 0.78, 0.72)], dark = [Color(0.16, 0.17, 0.18), Color(0.78, 0.66, 0.38)],
}
const LAMP_COLOUR := Color(1.0, 0.85, 0.6)


## An Area's identity data ({doorways, trim, signs, props}; dress, markings and beacons go through the builder's
## own calls) under a group in `parent`: call it before the bake, so lintels are in the navmesh's colliders.
## props: [model, [x, y, h], facing, scale (1)], mesh-only models (keypads, a vault door swung open, a board on a wall).
func _identity(parent: Node3D, idn: Dictionary) -> void:
	var g := _group(parent, "Identity")
	for d in idn.get("doorways", []):
		_door(g, d)
	for p in idn.get("props", []):
		var probe: Node3D = load("res://assets/models/props/%s.glb" % p[0]).instantiate()
		var size: Vector3 = _model_box(probe).size * (p[3] if p.size() > 3 else 1.0)
		probe.free()
		_prop(g, p[0], p[1], p[2], Vector3(size.x, size.y, p[3] if p.size() > 3 else 1.0),
			"%s_%s_%s" % [String(p[0]).to_pascal_case(), _coord(p[1][0]), _coord(p[1][1])])
	for t in idn.get("trim", []):
		_trim(g, t[0], t[1], t[2], t[3], t[4], t[5] if t.size() > 5 else Color.WHITE)
	for s in idn.get("signs", []):
		_sign(g, s)


## A doorway in a wall: {at [x, y], base, along_x (the wall runs east-west), t (wall thickness), wall_h, width, out
## (+1 if the outside is south / east, -1 north / west), style, mat, tint, lamp, head (above base; DOOR_H, or BAY_H
## for a bay)}. The lintel is solid, the rest is mesh.
func _door(parent: Node3D, d: Dictionary) -> void:
	var style: String = d.get("style", "door")
	if style == "none":
		return
	var w: float = d.width
	var t: float = d.t
	var base: float = d.get("base", 0.0)
	var top: float = base + d.wall_h
	var head := minf(base + d.get("head", BAY_H if style == "bay" else DOOR_H), top)
	var c: Array = d.at
	var ax: bool = d.along_x
	var out: float = d.get("out", 1.0)
	var tag := "%s_%s" % [_coord(c[0]), _coord(c[1])]
	# r(u0, u1, v0, v1): a diagram rect from offsets along the wall (u) and across it (v, + toward the outside)
	var r := func(u0: float, u1: float, v0: float, v1: float) -> Array:
		var a := [minf(v0, v1) * out, maxf(v0, v1) * out]
		a.sort()
		return [c[0] + u0, c[1] + a[0], u1 - u0, a[1] - a[0]] if ax else [c[0] + a[0], c[1] + u0, a[1] - a[0], u1 - u0]
	if top - head > 0.05:
		_box(parent, "Lintel_" + tag, r.call(-w / 2, w / 2, -t / 2, t / 2), head, top, d.get("mat", "brick"), d.get("tint", Color.WHITE))
	var blast := style in ["blast", "bay"]
	var fw := 0.3 if blast else FRAME_W
	var fmat := "hazard" if blast else "metal"
	var ftint := Color.WHITE if blast else Color(0.32, 0.33, 0.35)
	var fd := t / 2 + (0.12 if blast else 0.06)
	for s in [-1, 1]:
		# the jamb's inner face stands 2 cm into the opening, off the wall's end face (coplanar, they z-fought)
		var u0: float = w / 2 - 0.02 if s > 0 else -w / 2 - fw
		_trim(parent, "Jamb%d_%s" % [(s + 1) / 2, tag], r.call(u0, u0 + fw + 0.02, -fd, fd), base, head, fmat, ftint)
	# the head dips 2 cm below the lintel's underside and stands 1 cm proud of the jambs, so no two faces share a plane
	_trim(parent, "Head_" + tag, r.call(-w / 2 - fw - 0.01, w / 2 + fw + 0.01, -fd - 0.01, fd + 0.01), head - 0.02, minf(head + fw, top + 0.01), fmat, ftint)
	if style == "bay":  # the shutter rolled most of the way up, its drum on the outside face
		_trim(parent, "Shutter_" + tag, r.call(-w / 2, w / 2, -0.04, 0.04), head - 0.7, head, "corrugated", Color(0.75, 0.78, 0.8))
		if top - head > 0.5:
			_trim(parent, "Drum_" + tag, r.call(-w / 2 - 0.2, w / 2 + 0.2, t / 2, t / 2 + 0.45), head + 0.05, head + 0.55, "metal", Color(0.5, 0.52, 0.55))
	if LEAVES.has(style):
		_leaves(parent, d, LEAVES[style], head - base)
	if d.get("lamp", false):
		_door_lamp(parent, r.call(-0.18, 0.18, t / 2, t / 2 + 0.22), head + 0.2, tag)


## The leaves of a doorway swung back flat against the wall's inside face: one for a narrow door, two for a wide one.
func _leaves(parent: Node3D, d: Dictionary, key: String, tall: float) -> void:
	var w: float = d.width
	var count := 1 if w <= 1.5 else 2
	var lw := w / count
	var inside: float = -d.get("out", 1.0)
	var off: float = d.t / 2 + 0.1
	var facing: float = (180.0 if inside > 0 else 0.0) if d.along_x else (90.0 if inside > 0 else 270.0)
	for i in count:
		var s := 1.0 if i == 0 else -1.0
		var u: float = s * (w / 2 + FRAME_W + lw / 2 + 0.02)
		var at: Array = [d.at[0] + u, d.at[1] + inside * off] if d.along_x else [d.at[0] + inside * off, d.at[1] + u]
		_prop(parent, key, [at[0], at[1], d.get("base", 0.0)], facing, Vector3(lw, tall - 0.05, 1.0), "Leaf%d_%s_%s" % [i, _coord(d.at[0]), _coord(d.at[1])])


## A warm bulkhead lamp over an outside door.
func _door_lamp(parent: Node3D, rect: Array, h: float, tag: String) -> void:
	var lamp := _trim(parent, "Lamp_" + tag, rect, h, h + 0.18, "metal", Color(0.3, 0.3, 0.3))
	var glow := _glow_mat(LAMP_COLOUR, 3.5)
	var bulb := MeshInstance3D.new()
	bulb.name = "Bulb"
	bulb.mesh = _box_mesh(Vector3(rect[2] * 0.8, 0.06, rect[3] * 0.8), glow)
	bulb.position.y = -0.11
	lamp.add_child(bulb)
	var l := OmniLight3D.new()
	l.name = "Light"
	l.position.y = -0.4
	l.omni_range = 5.5
	l.light_energy = 1.4
	l.light_color = LAMP_COLOUR
	l.shadow_enabled = true
	_fade(l)
	lamp.add_child(l)


## A mesh-only box over rect from h0 to h1: trim, plates, painted panels. No collider, so the navmesh, sight and
## the camera pass through it.
func _trim(parent: Node3D, name: String, r: Array, h0: float, h1: float, mat: String, tint := Color.WHITE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = name
	m.mesh = _box_mesh(Vector3(r[2], h1 - h0, r[3]), _mat(mat, tint))
	m.position = Vector3(r[0] + r[2] / 2.0 - 40.0, (h0 + h1) / 2.0, r[1] + r[3] / 2.0 - 40.0)
	parent.add_child(m)
	return m


## A model with no collider, standing on its base at [x, y, h], its front to `facing`, scaled to `size` metres
## (x across its front, y up; z of 1 keeps its own depth).
func _prop(parent: Node3D, key: String, at: Array, facing: float, size: Vector3, name: String) -> Node3D:
	var m: Node3D = load("res://assets/models/props/%s.glb" % key).instantiate()
	var box := _model_box(m)
	var s := Vector3(size.x / box.size.x, size.y / box.size.y, size.z)
	m.name = name
	var turn := _turn(key, facing)
	m.transform = Transform3D(turn * Basis.from_scale(s), _p(at) + turn * (Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * s))
	parent.add_child(m)
	return m


## A sign: [text key, [x, y, h] (the plate's centre on the wall face), facing, width, style (SIGN_STYLES), height
## (width / 4)]. A plate with the line on it; the text key is translated at run time (text/lines.csv).
func _sign(parent: Node3D, s: Array) -> void:
	var width: float = s[3]
	var height: float = s[5] if s.size() > 5 else width / 4.0
	var style: Array = SIGN_STYLES[s[4] if s.size() > 4 else "white"]
	var plate := MeshInstance3D.new()
	plate.name = "Sign_%s_%s" % [_coord(s[1][0]), _coord(s[1][1])]
	plate.mesh = _box_mesh(Vector3(width, height, 0.05), _mat("metal", style[0]))
	plate.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-s[2]) + PI), _p(s[1]))
	parent.add_child(plate)
	var l := Label3D.new()
	l.name = "Text"
	l.text = s[0]
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
	l.font = load(SIGN_FONT)
	l.font_size = roundi(height * 0.62 / l.pixel_size)
	l.outline_size = 0
	l.modulate = style[1]
	l.shaded = true  # painted lettering takes the light like the plate, so it doesn't glow against the wall
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.width = width / l.pixel_size
	l.position.z = 0.03
	plate.add_child(l)
