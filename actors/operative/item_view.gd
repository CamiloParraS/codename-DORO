## What the items draw in the world: the Scanner's cone decals (through walls, white/grey, red for alerted
## guards and cameras) and the Magazine's throw arc (dotted). Rebuilt every frame while either is showing.
class_name ItemView
extends MeshInstance3D

const FRONT := Color(1, 1, 1, 0.2)
const SIDE := Color(0.7, 0.7, 0.7, 0.12)
const ALERTED := Color(1, 0.2, 0.2, 0.24)
const RIM_FILL := 0.2  # a fan's alpha at its far edge, as a share of its alpha at the guard's feet
const RIM_WIDTH := 0.14  # metres, the brighter line along a fan's far edge
const BREATH := 0.12  # how far the whole scan swells and ebbs, a slow breath
const SEGMENTS := 10
const LIFT := 0.05  # metres above the floor, so a decal does not z-fight it

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = _mesh
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true  # through walls
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.use_point_size = true  # the Magazine's arc is square pixels
	m.point_size = 4.0
	m.render_priority = 10
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Redraws: cones of the guards and cameras within Items.SCANNER_RANGE of `at` when `scan`, and the
## Magazine's arc `arc_points` (empty for none).
func show_items(at: Vector3, scan: bool, arc_points: PackedVector3Array) -> void:
	_mesh.clear_surfaces()
	global_transform = Transform3D.IDENTITY
	if scan:
		_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for g: Guard in get_tree().get_nodes_in_group("guards"):
			if not g.is_down():
				_cones(g, at, g.alert.state == GuardAlert.State.ALERT, true)
		for c: SecurityCamera in get_tree().get_nodes_in_group("cameras"):
			if not c.destroyed:
				_cones(c, at, c.alert.state == GuardAlert.State.ALERT, false)
		_mesh.surface_end()
	if arc_points.size() > 1:
		_mesh.surface_begin(Mesh.PRIMITIVE_POINTS)  # a dotted line of square pixels
		for p in arc_points:
			_mesh.surface_set_color(Color.WHITE)
			_mesh.surface_add_vertex(p)
		_mesh.surface_end()


## One target's cones flat on the floor under it: the front cone, plus the side one for a guard.
func _cones(n: Node3D, at: Vector3, alerted: bool, with_side: bool) -> void:
	var o := n.global_position
	if Vector2(o.x - at.x, o.z - at.z).length() > Items.SCANNER_RANGE:
		return
	var facing := -n.global_basis.z
	var floor_y := (o.y if with_side else _floor_under(o + facing * 0.6, at.y)) + LIFT
	if with_side:
		_fan(Vector3(o.x, floor_y, o.z), facing, GuardVision.SIDE_HALF, GuardVision.SIDE_RANGE, ALERTED if alerted else SIDE)
	_fan(Vector3(o.x, floor_y, o.z), facing, GuardVision.FRONT_HALF, GuardVision.FRONT_RANGE, ALERTED if alerted else FRONT)


## Height of the floor below p (a camera hangs high, on a pole or a wall); `fallback` if there is none.
func _floor_under(p: Vector3, fallback: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 30.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if hit else fallback


## A fan fading from the origin out to a faint edge, with a soft line along the edge; the whole scan breathes.
func _fan(origin: Vector3, facing: Vector3, half: float, reach: float, col: Color) -> void:
	var yaw := atan2(-facing.x, -facing.z)
	var breath := 1.0 + BREATH * sin(Time.get_ticks_msec() / 1000.0 * 1.8)
	var near := Color(col, col.a * breath)
	var far := Color(col, col.a * breath * RIM_FILL)
	var edge := Color(col, minf(col.a * breath * 2.2, 1.0))
	var prev := origin
	var prev_in := origin
	for i in SEGMENTS + 1:
		var a := yaw + lerpf(-half, half, i / float(SEGMENTS))
		var dir := Vector3(-sin(a), 0, -cos(a))
		var p := origin + dir * reach
		var q := origin + dir * (reach - RIM_WIDTH)
		if i > 0:
			_tri([origin, prev_in, q], [near, far, far])
			_tri([prev_in, prev, p], [far, edge, edge])
			_tri([prev_in, p, q], [far, edge, far])
		prev = p
		prev_in = q


func _tri(vs: Array, cols: Array) -> void:
	for k in 3:
		_mesh.surface_set_color(cols[k])
		_mesh.surface_add_vertex(vs[k])
