@tool
extends McpTestSuite

## Partner reaction (pw-feel 03): a guard who sees another drop, in his cone within 15 m, goes "?", calls
## the name to the guards within 15 m, and 3 s later starts a stoppable Radio call.

const GUARD := preload("res://actors/guard/guard.tscn")
const DT := 0.1


func suite_name() -> String:
	return "partner_reaction"


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


## A guard at (x, 0, z) facing -Z (yaw 0) or +Z (yaw PI).
func _guard(n: String, x: float, z: float, yaw := 0.0) -> Guard:
	var g: Guard = GUARD.instantiate()
	g.name = n
	_root().add_child(g)
	g.global_position = Vector3(x, 0, z)
	g.rotation.y = yaw
	return g


## Far away and still, never seen: lets the guards tick their alert.
func _operative() -> CharacterBody3D:
	var s := GDScript.new()
	s.source_code = """extends CharacterBody3D
var voiceprints := Voiceprints.new()
var moving := false
func chest_height() -> float: return 1.3
func looks_crouched() -> bool: return false
func looks_walking() -> bool: return false
"""
	s.reload()
	var op := CharacterBody3D.new()
	op.set_script(s)
	_root().add_child(op)
	op.global_position = Vector3(0, 0, 500)
	return op


func _tick(guards: Array, seconds: float) -> void:
	for i in roundi(seconds / DT):
		for g: Guard in guards:
			g._physics_process(DT)


func _free(nodes: Array) -> void:
	for n: Node in nodes:
		_root().remove_child(n)  # gone now; freed at the frame end, after its deferred seeding
		n.queue_free()


func test_a_partner_in_cone_within_15_m_goes_suspicious_and_his_name_call_carries_15_m() -> void:
	AlertChain.area = AlertChain.new()
	var a := _guard("Kostas", 0, 0)
	var b := _guard("Nikos", 0, -10)
	var c := _guard("Yannis", 0, 12, PI)  # behind Kostas, facing away: hears the call only
	var far := _guard("Petros", 0, 30)
	b.neutralize()
	assert_eq(a.alert.state, GuardAlert.State.SUSPICION)
	assert_eq(a.last_reason, "saw Nikos drop")
	assert_eq(c.alert.state, GuardAlert.State.SUSPICION, "heard the name")
	assert_eq(far.alert.state, GuardAlert.State.PATROL, "out of earshot")
	_free([a, b, c, far])


func test_out_of_range_or_out_of_cone_no_reaction() -> void:
	AlertChain.area = AlertChain.new()
	var behind := _guard("Kostas", 0, 0, PI)  # faces away from the drop
	var wide := _guard("Yannis", 9, -10)       # 90 degrees off his facing, 9 m: side vision only
	var far := _guard("Petros", 0, -10 + 16.5)  # 16.5 m off, facing it
	var b := _guard("Nikos", 0, -10)
	b.neutralize()
	for g: Guard in [behind, wide, far]:
		assert_eq(g.alert.state, GuardAlert.State.PATROL, g.name)
	_free([behind, wide, far, b])


func test_a_dead_guard_choked_again_is_no_new_drop() -> void:
	AlertChain.area = AlertChain.new()
	var b := _guard("Nikos", 0, -10)
	b.neutralize()
	var a := _guard("Kostas", 0, 0)
	b.neutralize()  # the 90 s start over: not a drop
	assert_eq(a.alert.state, GuardAlert.State.PATROL)
	_free([a, b])


func test_3_s_later_the_partner_starts_a_radio_call() -> void:
	AlertChain.area = AlertChain.new()
	var op := _operative()
	var a := _guard("Kostas", 0, 0)
	a.operative = op
	var b := _guard("Nikos", 0, -10)
	b.neutralize()
	_tick([a], 2.8)
	assert_false(AlertChain.area.calling(a))
	_tick([a], 0.4)
	assert_true(AlertChain.area.calling(a), "\"!\" and on the radio")
	_free([a, b, op])


func test_downing_the_partner_within_3_s_means_no_call() -> void:
	AlertChain.area = AlertChain.new()
	var op := _operative()
	var a := _guard("Kostas", 0, 0)
	a.operative = op
	var b := _guard("Nikos", 0, -10)
	b.neutralize()
	_tick([a], 1.0)
	a.tranquilize(false, op.global_position)  # a body dart: stumbles, then drops
	_tick([a], 4.0)
	assert_false(AlertChain.area.calling(a))
	assert_true(a.is_down())
	assert_eq(AlertChain.area.tick(DT, false), &"")
	_free([a, b, op])


func test_a_held_up_guard_seen_by_a_partner_is_freed_and_the_partner_reacts() -> void:
	AlertChain.area = AlertChain.new()
	var a := _guard("Kostas", 0, 0)
	var b := _guard("Nikos", 0, -10)
	b.hold_up()
	b._physics_process(DT)
	assert_false(b.held_up, "freed")
	assert_true(b.alert.calling, "the freed guard radios, and shouts")
	assert_eq(a.last_reason, "Nikos shouted, running over", "saw him kneel, then hears him")
	_free([a, b])
