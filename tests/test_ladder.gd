@tool
extends McpTestSuite

## The Operative on a Ladder: getting on holds him on the bottom rung until he climbs, he steps off only at the
## end he is climbing towards (easing across onto the top), and the climb clip keeps pace with him.

const OPERATIVE := preload("res://actors/operative/operative.tscn")
const DT := 1.0 / 60


func suite_name() -> String:
	return "ladder"


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


## A 4 m ladder at the origin whose top lands 1 m to the north (-Z).
func _ladder() -> Node3D:
	var l := Node3D.new()
	l.add_to_group("ladders")
	for end in [["Bottom", Vector3.ZERO], ["Top", Vector3(0, 4, -1)]]:
		var m := Marker3D.new()
		m.name = end[0]
		m.position = end[1]
		l.add_child(m)
	_root().add_child(l)
	return l


func _operative() -> Node:
	var op: Node = OPERATIVE.instantiate()
	_root().add_child(op)
	op.set_physics_process(false)  # driven by hand below
	op.set_process(false)
	return op


func test_getting_on_holds_him_on_the_bottom_rung() -> void:
	var l := _ladder()
	var op := _operative()
	op.global_position = Vector3.ZERO
	op._mount(l)
	op._climb(0.0, DT)
	assert_eq(op.ladder, l, "no key held the frame after E: still on")
	op._climb(-1.0, DT)
	assert_true(op.ladder == null, "climbing down off the bottom steps off")
	op.free()
	l.free()


func test_he_climbs_to_the_top_and_steps_off_onto_it() -> void:
	var l := _ladder()
	var op := _operative()
	op.global_position = Vector3.ZERO
	op._mount(l)
	for i in 300:
		if not op.ladder:
			break
		op._climb(1.0, DT)
	assert_true(op.ladder == null, "off the ladder")
	assert_true(op.global_position.is_equal_approx(Vector3(0, 4, -1)), "on the Top marker: %s" % op.global_position)
	op.global_position = Vector3.ZERO
	op._mount(l)
	while op._step_off <= 0.0:
		op._climb(1.0, DT)
	assert_true(op.ladder != null and is_equal_approx(op.global_position.y, 4.0), "at the top, still on")
	for i in int(op.STEP_OFF_TIME / DT / 2):
		op._climb(0.0, DT)
	assert_true(op.global_position.z < -0.1 and op.global_position.z > -0.9, "eased across, not snapped: %s" % op.global_position)
	op.free()
	l.free()


func test_getting_on_from_the_top_holds_him_until_he_climbs_down() -> void:
	var l := _ladder()
	var op := _operative()
	op.global_position = Vector3(0, 4, -1)
	op._mount(l)
	op._climb(0.0, DT)
	assert_eq(op.ladder, l)
	assert_true(op.global_position.y < 4.0, "just under the top, over the foot")
	for i in 300:
		if not op.ladder:
			break
		op._climb(-1.0, DT)
	assert_true(op.global_position.is_equal_approx(Vector3.ZERO), "off at the foot: %s" % op.global_position)
	op.free()
	l.free()


func test_the_climb_clip_keeps_pace_with_him() -> void:
	if not ResourceLoader.exists(CharacterModel.MIXAMO):
		return
	var l := _ladder()
	var op := _operative()
	op.global_position = Vector3.ZERO
	op._mount(l)
	var anim: AnimationPlayer = op.model.find_children("*", "AnimationPlayer", true, false)[0]
	var rate := func(dir: float) -> float:
		op._climb(dir, DT)
		op._process(DT)
		return anim.speed_scale
	assert_eq(rate.call(0.0), 0.0, "holding on: the pose holds")
	assert_true(is_equal_approx(rate.call(1.0), op.CLIMB_SPEED / CharacterModel.CLIMB_SPEED), "up, paced so the hands hold the rungs")
	for i in 60:  # halfway up, clear of the foot
		op._climb(1.0, DT)
	assert_true(rate.call(-1.0) < 0.0, "down: the clip runs backwards")
	op.free()
	l.free()
