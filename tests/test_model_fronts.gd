@tool
extends McpTestSuite

## A model's front is glTF -Z, or it is listed in area_kit.gd's FRONT (tools/area_kit.gd "Facing"). The lit parts
## (screens, status lamps, keypads) say where a front is: on every prop whose lit parts sit clearly to one side,
## that side, once FRONT turns it, is -Z. A console built backwards fails here before anyone stands at it.

const KIT := preload("res://tools/area_kit.gd")
const DRESSING := preload("res://tools/area_dressing.gd")  # DRESS_PIVOT: models measured from their origin, their bounds skewed
const DIR := "res://assets/models/props/"
## Lit, but not on a front: lamps that light all round or hang off one side, beacons on top.
const SKIP := ["lamp_post", "ceiling_lamp", "wall_lamp", "lighthouse", "buoy_red", "buoy_green", "fulton_balloon", "lantern"]
## How far off centre (a share of the depth) the lit parts must sit to count as one-sided.
const OFF_CENTRE := 0.15


func suite_name() -> String:
	return "model_fronts"


func test_every_lit_front_faces_minus_z() -> void:
	var checked := 0
	var wrong: Array[String] = []
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".glb") or f.get_basename() in SKIP:
			continue
		var key := f.get_basename()
		var m: Node3D = load(DIR + f).instantiate()
		var lit := _lit(m)
		var box := _box(m)
		m.free()
		if lit.w <= 0.0 or box.size.z < 0.05:
			continue
		var turn := Basis(Vector3.UP, deg_to_rad(-float(KIT.FRONT.get(key, 0))))
		var centre := Vector3.ZERO if key in DRESSING.DRESS_PIVOT else box.get_center()
		var off := (turn * (Vector3(lit.x, lit.y, lit.z) - centre)).z
		if absf(off) < OFF_CENTRE * box.size.z:
			continue  # lit all round, or down the middle: says nothing about a front
		checked += 1
		if off > 0.0:
			wrong.append(key)
	assert_gt(checked, 5, "the props with a lit front were found")
	assert_eq(wrong, [] as Array[String], "lit side is +Z (%s): rebuild the model front to -Z, or list it in FRONT" % ", ".join(wrong))


## The area-weighted centre of `m`'s emissive triangles in its own space (w: their total area, 0 if none).
func _lit(m: Node3D) -> Vector4:
	var sum := Vector3.ZERO
	var area := 0.0
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		var xf := _to_root(mi, m)
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i) as BaseMaterial3D
			if not mat or not mat.emission_enabled:
				continue
			var arr := mi.mesh.surface_get_arrays(i)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var n := idx.size() if idx.size() else v.size()
			for t in range(0, n, 3):
				var p := [v[idx[t]] if idx.size() else v[t], v[idx[t + 1]] if idx.size() else v[t + 1], v[idx[t + 2]] if idx.size() else v[t + 2]]
				var a := xf * (p[0] as Vector3)
				var b := xf * (p[1] as Vector3)
				var c := xf * (p[2] as Vector3)
				var s := (b - a).cross(c - a).length() / 2.0
				sum += (a + b + c) / 3.0 * s
				area += s
	if area <= 0.0:
		return Vector4.ZERO
	var centre := sum / area
	return Vector4(centre.x, centre.y, centre.z, area)


func _box(m: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for v: VisualInstance3D in m.find_children("*", "VisualInstance3D", true, false):
		var b: AABB = _to_root(v, m) * v.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## A node's transform in the model root's space (the model isn't in the tree, so no global_transform).
func _to_root(n: Node, root: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	while n != root:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf
