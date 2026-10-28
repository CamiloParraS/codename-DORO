## The radio mode's 3D side, one per Area: the world dim, the fills on the guards the radial names and the
## Radio point's marker. Presentation only; radio.gd says what is hot (hovered) and cold (earlier picks).
class_name RadioLook
extends Node3D

const DIM := preload("res://ui/radio/radio_dim.gdshader")
const FADE := 0.18  # s, real time

var _dim_mat := ShaderMaterial.new()
var _dim := MeshInstance3D.new()
var _hot := Fx.radio_fill(Color(1, 1, 1, 0.92), false, 0.4, 11)
var _cold := Fx.radio_fill(Color(HudPalette.CHROME, 0.5), true, 0.0, 10)
var _lit: Array[MeshInstance3D] = []
var _marker: Node3D
var _marker_key := ""
var _beat: Node3D


func _ready() -> void:
	_dim_mat.shader = DIM
	_dim.mesh = QuadMesh.new()
	_dim.custom_aabb = AABB(Vector3.ONE * -1e5, Vector3.ONE * 2e5)  # never culled
	_dim.material_override = _dim_mat
	_dim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dim.visible = false
	add_child(_dim)


func open() -> void:
	_dim_mat.set_shader_parameter("amount", 0.0)
	_dim.visible = true
	create_tween().set_ignore_time_scale(true).tween_property(_dim_mat, "shader_parameter/amount", 1.0, FADE)


func close() -> void:
	_dim.visible = false
	show_referents([], [], Vector3.INF, false)


## hot, cold: guards; place: a Radio point's position (INF = none).
func show_referents(hot: Array, cold: Array, place: Vector3, place_hot: bool) -> void:
	for m in _lit:
		if is_instance_valid(m):
			m.material_overlay = null
	_lit.clear()
	for set: Array in [[cold, _cold], [hot, _hot]]:
		for g: Node3D in set[0]:
			for m: MeshInstance3D in g.find_children("*", "MeshInstance3D", true, false):
				if m.is_visible_in_tree():
					m.material_overlay = set[1]
					_lit.append(m)
	var key := "%s %s" % [place, place_hot]
	if key == _marker_key:
		return
	_marker_key = key
	if _marker:
		_marker.queue_free()
		_marker = null
	if place != Vector3.INF:
		_marker = Fx.beacon(self, place, place_hot)


## The send beat, about 1.3 s of real time: a ring bursts at `from`, a spark runs to each recipient and a ring
## bursts on them, then a Go check's Radio point (INF = none) flares as a full beam. All white, through walls.
func beat(from: Vector3, recipients: Array, place: Vector3) -> void:
	clear_beat()
	_beat = Node3D.new()
	add_child(_beat)
	var t := _beat.create_tween().set_ignore_time_scale(true)
	t.tween_callback(_burst.bind(from + Vector3.UP, 3.0, 0.25))
	t.tween_interval(0.25)
	t.tween_callback(func() -> void:
		for r: Node3D in recipients:
			if is_instance_valid(r):
				_spark(from + Vector3.UP * 1.6, r))
	t.tween_interval(0.45)
	t.tween_callback(func() -> void:
		for r: Node3D in recipients:
			if is_instance_valid(r):
				_burst(r.global_position + Vector3.UP, 2.5, 0.3)
		if place != Vector3.INF:
			Fx.beacon(_beat, place))
	t.tween_interval(0.6 if place != Vector3.INF else 0.3)
	t.tween_callback(clear_beat)


## Drops the beat mid-flight (a Checkpoint restore, or the next beat).
func clear_beat() -> void:
	if _beat:
		_beat.queue_free()
		_beat = null


func _burst(at: Vector3, to: float, time: float) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.55
	torus.ring_segments = 4
	var m := _flat(torus, at)
	m.scale = Vector3.ONE * 0.1
	var tw := m.create_tween().set_ignore_time_scale(true)
	tw.tween_property(m, "scale", Vector3.ONE * to, time)
	tw.tween_callback(m.queue_free)


func _spark(from: Vector3, to: Node3D) -> void:
	var ball := SphereMesh.new()
	ball.radius = 0.25
	ball.height = 0.5
	var m := _flat(ball, from)
	var tw := m.create_tween().set_ignore_time_scale(true)
	tw.tween_property(m, "global_position", to.global_position + Vector3.UP * 1.6, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(m.queue_free)


func _flat(mesh: Mesh, at: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = Fx.radio_fill(Color.WHITE, false, 0.0, 13)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beat.add_child(m)
	m.global_position = at
	return m
