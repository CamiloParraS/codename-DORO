## A take's intel mark, in the radio mode's look (RadioLook): a stippled beam rising out of a pixel ring, a tag over it, and
## (when `target` names a node of the Area) that node's meshes filled white through walls. The take steps `lit`; built by a
## take's tool (tools/cine/*.gd) under its props, it makes its own visuals at runtime, so it can follow a guard the Area only
## spawns in _ready (the dock guard, a Target). Nothing it does touches gameplay: no collider, no state, no Guard method.
class_name CineMark
extends Node3D

const BEAM := 12            # pixel diamonds in the column, 2 m apart
const TAG_H := 3.4          # m over the mark's foot
const FILL := Color(1, 1, 1, 0.9)

@export var target := ""    # a node path from the Area root ("GuardA9", "LEAD RESEARCHER"); "" marks this spot
@export var tag := ""       # a lines.csv key, translated by the Label3D
var lit := false:
	set(v):
		if v == lit:
			return
		lit = v
		if is_inside_tree():
			_apply()

var _fill := Fx.radio_fill(FILL, false, 0.4, 11)
var _filled: Array[MeshInstance3D] = []
var _beam: Node3D
var _ring: Sprite3D
var _t := 0.0


func _ready() -> void:
	_beam = Node3D.new()
	add_child(_beam)
	for k in BEAM:
		var d := Fx.pixel_sprite(Fx.DASH_ICON, 0.07)
		d.no_depth_test = true
		d.render_priority = 12
		d.modulate = Color(1, 1, 1, 0.85 * (1.0 - float(k) / BEAM))
		d.position.y = 1.0 + k * 2.0
		_beam.add_child(d)
	_ring = Fx.pixel_sprite(Fx.RING_ICON, 1.7 / 15.5, false)
	_ring.hframes = 5
	_ring.axis = Vector3.AXIS_Y
	_ring.no_depth_test = true
	_ring.render_priority = 12
	_ring.position.y = 0.05
	add_child(_ring)
	if tag != "":
		var l := Label3D.new()
		l.text = tag
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
		l.font = HudPalette.DISPLAY
		l.font_size = 40
		l.pixel_size = 0.0011
		l.fixed_size = true
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.render_priority = 13
		l.outline_render_priority = 12
		l.outline_size = 10
		l.outline_modulate = Color(0, 0, 0, 0.85)
		l.modulate = Color.WHITE
		l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		l.position.y = TAG_H
		add_child(l)
	_apply()


func _process(delta: float) -> void:
	if not lit:
		return
	_t += delta
	var node := _target()
	if node:
		global_position = node.global_position
	_beam.position.y = fmod(_t, Fx.BEACON_PERIOD) / Fx.BEACON_PERIOD * 2.0
	_ring.frame = mini(int(fmod(_t, Fx.BEACON_PERIOD) / Fx.BEACON_PERIOD * 5.0), 4)


func _target() -> Node3D:
	if target == "" or owner == null:
		return null
	return owner.get_node_or_null(target) as Node3D


func _apply() -> void:
	for c in get_children():
		c.visible = lit
	for m in _filled:
		if is_instance_valid(m):
			m.material_overlay = null
	_filled.clear()
	var node := _target()
	if not lit or node == null:
		return
	global_position = node.global_position
	for m: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if m.is_visible_in_tree():
			m.material_overlay = _fill
			_filled.append(m)


func _exit_tree() -> void:
	lit = false
	for m in _filled:
		if is_instance_valid(m):
			m.material_overlay = null
	_filled.clear()
