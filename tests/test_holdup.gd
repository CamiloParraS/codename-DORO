@tool
extends McpTestSuite

## Hold-up and interrogation (pw-feel 06): who can be held up, what frees him, and his one answer.

const GUARD := preload("res://actors/guard/guard.tscn")


func suite_name() -> String:
	return "holdup"


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func test_the_answer_is_the_voiceprint_then_the_objective_then_a_scan() -> void:
	assert_eq(Holdup.answer("", true, true), "voiceprint")
	assert_eq(Holdup.answer("", false, true), "objective")
	assert_eq(Holdup.answer("", false, false), "scan")


func test_a_scripted_answer_comes_first() -> void:
	assert_eq(Holdup.answer("lift_code", true, true), "lift_code")


func test_freed_4_s_after_aim_is_lost() -> void:
	var h := Holdup.new()
	assert_false(h.tick(3.9, false, 3.0, false))
	assert_true(h.tick(0.2, false, 3.0, false))


func test_back_on_aim_restarts_the_4_s() -> void:
	var h := Holdup.new()
	h.tick(3.0, false, 3.0, false)
	h.tick(0.1, true, 3.0, false)
	assert_false(h.tick(3.9, false, 3.0, false))


func test_freed_beyond_6_m_or_on_alert() -> void:
	assert_true(Holdup.new().tick(0.1, true, 6.1, false), "out of range")
	assert_true(Holdup.new().tick(0.1, true, 3.0, true), "an Alert")
	assert_false(Holdup.new().tick(0.1, true, 6.0, false), "6 m still holds")


func test_the_objective_answer_names_distance_and_heading() -> void:
	assert_eq(Holdup.bearing(Vector3(0, 0, -20)), "20 m north")
	assert_eq(Holdup.bearing(Vector3(30, 5, 30)), "42 m south-east")


func test_a_voiceprint_interrogation_is_10_spoofing_points() -> void:
	var with := Aigis.mission_points({alert = 1, interrogated_voiceprint = 1})
	var without := Aigis.mission_points({alert = 1})
	assert_eq(with.spoofing - without.spoofing, 10)


## Stand-in Operative (Voiceprints, items), also standing in for the tally and the radio log.
func _operative() -> Node3D:
	var s := GDScript.new()
	s.source_code = """extends Node3D
var voiceprints := Voiceprints.new()
var items := Items.new()
var events: Array[String] = []
var said: Array[String] = []
func event(n: String) -> void: events.append(n)
func say(_who: String, text: String) -> void: said.append(text)
func _enter_tree() -> void:
	add_to_group("mission_tally")
	add_to_group("radio_log")
"""
	s.reload()
	var n := Node3D.new()
	n.set_script(s)
	_root().add_child(n)
	return n


func _guard() -> Guard:
	var g: Guard = GUARD.instantiate()
	_root().add_child(g)
	return g


func test_a_guard_who_sees_the_operative_or_is_calling_cant_be_held_up() -> void:
	AlertChain.area = AlertChain.new()
	var g := _guard()
	var behind := g.global_position + g.global_basis.z * 4.0
	assert_true(g.can_be_held_up(behind))
	g.seen_rate = 0.2
	assert_false(g.can_be_held_up(behind), "he sees him")
	g.seen_rate = 0.0
	AlertChain.area.start_call(g, Vector3.ZERO)
	assert_false(g.can_be_held_up(behind), "in a Radio call")
	g.free()


func test_a_freed_guard_starts_a_radio_call() -> void:
	AlertChain.area = AlertChain.new()
	var g := _guard()
	g.hold_up()
	g.release(Vector3(0, 0, 5))
	assert_false(g.held_up)
	assert_true(g.alert.calling, "he goes for his radio")
	g.free()


func test_interrogation_records_the_voiceprint_once_and_scores_it() -> void:
	AlertChain.area = AlertChain.new()
	var op := _operative()
	var g := _guard()
	g.hold_up()
	g.answer(op)
	assert_true(str(g.name) in op.voiceprints.held)
	assert_eq(op.events, ["interrogated_voiceprint"] as Array[String])
	g.answer(op)
	assert_eq(op.events.size(), 1, "a second ask yields nothing new")
	assert_eq(op.items.scan_left, 0.0)
	g.free()
	op.free()


func test_with_his_voiceprint_held_and_no_objective_he_gives_a_free_scan() -> void:
	AlertChain.area = AlertChain.new()
	var op := _operative()
	var g := _guard()
	op.voiceprints.held.append(str(g.name))
	g.hold_up()
	g.answer(op)
	assert_eq(op.items.scan_left, Items.SCANNER_TIME)
	assert_eq(op.items.charges, Items.SCANNER_CHARGES, "no charge spent")
	assert_eq(op.events.size(), 0)
	g.free()
	op.free()


func test_with_his_voiceprint_held_he_gives_the_objective_location() -> void:
	AlertChain.area = AlertChain.new()
	var op := _operative()
	var s := GDScript.new()
	s.source_code = "extends Node\nfunc intel_hint(_from: Vector3) -> String: return \"the office · 20 m north\"\n"
	s.reload()
	var run := Node.new()
	run.set_script(s)
	run.add_to_group("mission_plan")
	_root().add_child(run)
	var g := _guard()
	op.voiceprints.held.append(str(g.name))
	g.hold_up()
	g.answer(op)
	assert_true("the office · 20 m north" in op.said, "on the INTEL line")
	assert_eq(op.items.scan_left, 0.0, "the objective comes before the scan")
	g.free()
	op.free()
	run.free()
