## The Magazine in flight: a small, slightly curved box that tumbles along the throw arc, lands flat where
## the guards come to investigate, and is cleared after a few seconds.
class_name ThrownMagazine
extends MeshInstance3D

## Emitted when it touches down, at `where`.
signal landed(where: Vector3)

const LENGTH := 0.2
const WIDTH := 0.035
const THICKNESS := 0.012
const BEND := 0.18  # radians across its length
const SEGMENTS := 4
const TUMBLE := 16.0  # rad/s around the axis across the flight
const LINGER := 6.0  # seconds on the floor
const REST_LIFT := 0.01
const STEP := 0.1  # seconds between the arc's points (Items.arc)

var _points: PackedVector3Array
var _across: Vector3


## Throws one along `points` (from the hand to the landing), a child of `parent`.
static func launch(parent: Node, points: PackedVector3Array) -> ThrownMagazine:
	var mag := ThrownMagazine.new()
	parent.add_child(mag)
	mag.fly(points)
	return mag


func _ready() -> void:
	mesh = _curved_box()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.16, 0.17, 0.18)
	m.roughness = 0.6
	m.metallic = 0.4
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true


func fly(points: PackedVector3Array) -> void:
	if points.size() < 2:
		queue_free()
		return
	_points = points
	_across = Vector3.UP.cross(Vector3(points[-1].x - points[0].x, 0, points[-1].z - points[0].z))
	_across = _across.normalized() if _across.length() > 0.001 else Vector3.RIGHT
	_pose(0.0)
	var tw := create_tween()
	tw.tween_method(_pose, 0.0, STEP * (points.size() - 1), STEP * (points.size() - 1))
	tw.tween_callback(_land)
	tw.tween_interval(LINGER)
	tw.tween_callback(queue_free)


## The magazine `t` seconds into the flight: on the arc, tumbling.
func _pose(t: float) -> void:
	var f := t / STEP
	var i := clampi(int(f), 0, _points.size() - 2)
	global_position = _points[i].lerp(_points[i + 1], f - i)
	global_basis = Basis(_across, t * TUMBLE)


func _land() -> void:
	landed.emit(_points[-1])
	global_position = _points[-1] + Vector3.UP * REST_LIFT
	global_basis = Basis(Vector3.UP, randf() * TAU)


## A strip bent about the vertical axis, wide face up, so the curve shows from above when it lies on the floor.
func _curved_box() -> ArrayMesh:
	var r := LENGTH / BEND
	var centre: Array[Vector3] = []
	for i in SEGMENTS + 1:
		var a := (float(i) / SEGMENTS - 0.5) * BEND
		centre.append(Vector3(sin(a) * r, 0, r - cos(a) * r))
	var ring: Array = []
	for i in centre.size():
		var tangent := centre[mini(i + 1, SEGMENTS)] - centre[maxi(i - 1, 0)]
		var side := Vector3.UP.cross(tangent).normalized() * WIDTH * 0.5
		var up := Vector3.UP * THICKNESS * 0.5
		ring.append([centre[i] + side + up, centre[i] - side + up, centre[i] - side - up, centre[i] + side - up])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in SEGMENTS:
		for k in 4:
			var k2 := (k + 1) % 4
			_quad(st, ring[i][k], ring[i + 1][k], ring[i + 1][k2], ring[i][k2])
	_quad(st, ring[0][0], ring[0][3], ring[0][2], ring[0][1])
	_quad(st, ring[SEGMENTS][0], ring[SEGMENTS][1], ring[SEGMENTS][2], ring[SEGMENTS][3])
	st.generate_normals()
	return st.commit()


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, b, c, a, c, d]:
		st.add_vertex(v)
