## A 2D pixel item a questioned guard drops (a letter, a confidential doc): it pops out of him, lands at his feet,
## hovers low where he fell, bobbing like a classic pickup, and is picked up by walking close. Only dressing: the Mission step is done by
## objective_watch.gd, not by this.
class_name DroppedItem
extends Node3D

const ART := {
	&"letter": preload("res://assets/items/letter.svg"),
	&"doc": preload("res://assets/items/doc.svg"),
}
## What each scripted Hold-up answer (Guard.holdup_answer) leaves on the ground.
const BY_ANSWER := {"lift_code": &"letter", "keys": &"letter", "code": &"doc"}
const RING_ICON := preload("res://assets/ui/icons/ring.svg")  # 5 frames, as the Radio point's ground ring
const RING_M := 0.9    # metres across, a small one to fit the document
const RING_STEP := 1.0 # seconds for the ring to step out once
const PIXEL := 0.016   # metres per art pixel
const REST := 0.4      # sprite centre above the floor: it hovers low, where he fell
const BOB := 0.05      # metres up and down
const TAKE_RANGE := 1.2   # walk this close to pick it up
const TAKE_AFTER := 1.0   # seconds after it lands before it can be taken
const FLIGHT := 0.45

var _sprite: Sprite3D
var _age := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _taken := false
var _ring: Sprite3D


## Drop `kind` out of `from` (the guard's chest) onto the floor at `to`; false if there's no art for it.
static func drop(parent: Node, kind: StringName, from: Vector3, to: Vector3) -> DroppedItem:
	if not ART.has(kind):
		return null
	var d := DroppedItem.new()
	d.name = "Dropped_" + String(kind)
	d._sprite = Fx.pixel_sprite(ART[kind], PIXEL)  # a billboard: it always faces the player
	d._from = from
	d._to = to + Vector3(0, REST, 0)
	d._sprite.double_sided = true
	d.add_child(d._sprite)
	d._ring = Fx.pixel_sprite(RING_ICON, RING_M / 31.0, false)  # a pixel ring stepping outward on the floor
	d._ring.hframes = 5
	d._ring.axis = Vector3.AXIS_Y
	d._ring.no_depth_test = true  # it shows through cover, so the drop can be found from across the Area
	d._ring.render_priority = 12
	d._ring.top_level = true
	d._ring.visible = false
	d.add_child(d._ring)
	parent.add_child(d)
	d.global_position = from
	return d


## The item a scripted answer drops, "" = none.
static func kind_for(answer: String) -> StringName:
	return BY_ANSWER.get(answer, &"")


func _process(delta: float) -> void:
	if _taken:
		return
	_age += delta
	if _age < FLIGHT:  # a short hop out of his hands
		var t := _age / FLIGHT
		global_position = _from.lerp(_to, t) + Vector3(0, sin(t * PI) * 0.35, 0)
		return
	_ring.visible = true
	_ring.global_position = _to - Vector3(0, REST - 0.05, 0)
	_ring.frame = mini(int(fmod(_age, RING_STEP) / RING_STEP * 5.0), 4)
	global_position = _to + Vector3(0, sin((_age - FLIGHT) * 2.6) * BOB, 0)
	var op := get_tree().get_first_node_in_group("operative") as Node3D
	if _age > FLIGHT + TAKE_AFTER and op and op.global_position.distance_to(_to - Vector3(0, REST, 0)) <= TAKE_RANGE:
		_take()


func _take() -> void:
	_taken = true
	Fx.puff(get_parent(), global_position, Color.WHITE, 6, 1.5, 0.3)
	_ring.visible = false
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector3.ZERO, 0.15)
	tw.tween_callback(queue_free)
