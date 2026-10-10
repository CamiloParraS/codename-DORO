@tool
extends McpTestSuite

## Guard alert state machine: thresholds, timings, noise, radio and reason strings.

const S := GuardAlert.State
const DT := 0.05
const SPOT := Vector3(4, 0, 2)


func suite_name() -> String:
	return "guard_alert"


## Ticks for `seconds` at a fixed seen rate; returns every non-empty reason, in order.
func _run(a: GuardAlert, seconds: float, rate: float, at_target := false) -> Array[String]:
	var out: Array[String] = []
	for i in roundi(seconds / DT):
		var why := a.tick(DT, rate, SPOT, "test", at_target)
		if why != "":
			out.append(why)
	return out


func _alerted() -> GuardAlert:
	var a := GuardAlert.new()
	a.radio(SPOT, "Kostas")
	return a


func _evading() -> GuardAlert:
	var a := _alerted()
	_run(a, GuardAlert.LOSE_TIME + 0.1, 0.0)
	return a


func test_starts_on_patrol_with_empty_meter() -> void:
	var a := GuardAlert.new()
	assert_eq(a.state, S.PATROL)
	assert_eq(a.meter, 0.0)


func test_suspicion_at_035() -> void:
	var a := GuardAlert.new()
	assert_eq(a.tick(1.0, 0.34, SPOT, "test", false), "")
	assert_eq(a.state, S.PATROL, "0.34 is still patrol")
	assert_ne(a.tick(1.0, 0.01, SPOT, "test", false), "")
	assert_eq(a.state, S.SUSPICION, "0.35 is suspicion")


func test_sighting_sets_last_known() -> void:
	var a := GuardAlert.new()
	a.tick(DT, 1.0, SPOT, "test", false)
	assert_eq(a.last_known, SPOT)
	a.tick(DT, 0.0, Vector3(99, 0, 99), "", false)
	assert_eq(a.last_known, SPOT, "an unseen frame doesn't move last_known")


func test_meter_drains_025_per_second() -> void:
	var a := GuardAlert.new()
	a.tick(1.0, 0.3, SPOT, "test", false)
	a.tick(1.0, 0.0, SPOT, "", false)
	assert_true(is_equal_approx(a.meter, 0.05), "0.3 - 0.25 = %f" % a.meter)
	a.tick(1.0, 0.0, SPOT, "", false)
	assert_eq(a.meter, 0.0, "never below zero")


func test_full_meter_alerts_straight_from_patrol() -> void:
	var a := GuardAlert.new()
	var why := a.tick(1.0, 5.0, SPOT, "running, 3 m, in front", false)
	assert_eq(a.state, S.ALERT)
	assert_eq(a.meter, 1.0)
	assert_contains(why, "running, 3 m, in front")


func test_suspicion_fills_on_to_alert() -> void:
	var a := GuardAlert.new()
	a.tick(1.0, 0.4, SPOT, "test", false)
	assert_eq(a.state, S.SUSPICION)
	a.tick(1.0, 0.6, SPOT, "test", false)
	assert_eq(a.state, S.ALERT)


func test_suspicion_looks_around_5s_at_the_spot() -> void:
	var a := GuardAlert.new()
	a.hear(SPOT, "a knock")
	assert_eq(_run(a, 10.0, 0.0, false), [], "the look-around only counts at the spot")
	assert_eq(a.state, S.SUSPICION)
	_run(a, GuardAlert.LOOK_TIME - 0.2, 0.0, true)
	assert_eq(a.state, S.SUSPICION)
	assert_eq(_run(a, 0.4, 0.0, true), ["found nothing, back to patrol"])
	assert_eq(a.state, S.PATROL)
	assert_eq(a.meter, 0.0)


func test_sighting_restarts_the_look_around() -> void:
	var a := GuardAlert.new()
	a.hear(SPOT, "a knock")
	_run(a, GuardAlert.LOOK_TIME - 0.5, 0.0, true)
	a.tick(DT, 0.01, SPOT, "test", true)
	_run(a, GuardAlert.LOOK_TIME - 0.5, 0.0, true)
	assert_eq(a.state, S.SUSPICION, "the glimpse reset the 5 s")


func test_alert_lost_after_3s_unseen() -> void:
	var a := _alerted()
	_run(a, GuardAlert.LOSE_TIME - 0.2, 0.0)
	assert_eq(a.state, S.ALERT)
	assert_eq(_run(a, 0.4, 0.0), ["lost sight of you, searching"])
	assert_eq(a.state, S.EVASION)


func test_sight_during_alert_resets_the_3s() -> void:
	var a := _alerted()
	_run(a, GuardAlert.LOSE_TIME - 0.5, 0.0)
	a.tick(DT, 0.5, SPOT, "test", false)
	_run(a, GuardAlert.LOSE_TIME - 0.5, 0.0)
	assert_eq(a.state, S.ALERT)


func test_evasion_searches_12s_at_the_spot() -> void:
	var a := _evading()
	assert_eq(_run(a, 20.0, 0.0, false), [], "the search only counts at the spot")
	_run(a, GuardAlert.SEARCH_TIME - 0.2, 0.0, true)
	assert_eq(a.state, S.EVASION)
	assert_eq(_run(a, 0.4, 0.0, true), ["gave up the search"])
	assert_eq(a.state, S.PATROL)
	assert_eq(a.meter, 0.0)


func test_sighting_during_evasion_realerts_at_once() -> void:
	var a := _evading()
	_run(a, 6.0, 0.0, true)
	var why := a.tick(DT, 0.01, Vector3(7, 0, 7), "walking, 15 m, in front", true)
	assert_eq(a.state, S.ALERT, "even the slowest sighting")
	assert_contains(why, "found you again")
	assert_eq(a.last_known, Vector3(7, 0, 7))


func test_radio_alerts_from_any_calm_state() -> void:
	for setup in ["patrol", "suspicion", "evasion"]:
		var a := GuardAlert.new()
		if setup == "suspicion":
			a.hear(SPOT, "a knock")
		elif setup == "evasion":
			a = _evading()
		var why := a.radio(Vector3(-3, 0, 8), "Kostas")
		assert_eq(a.state, S.ALERT, setup)
		assert_eq(a.meter, 1.0, setup)
		assert_eq(a.last_known, Vector3(-3, 0, 8), setup)
		assert_eq(why, "Kostas radioed an alert", setup)


func test_radio_to_an_alerted_guard_is_ignored() -> void:
	var a := _alerted()
	_run(a, 2.0, 0.0)
	assert_eq(a.radio(Vector3(50, 0, 50), "Nikos"), "")
	assert_eq(a.last_known, SPOT, "keeps chasing its own lead")
	_run(a, 1.2, 0.0)
	assert_eq(a.state, S.EVASION, "the radio didn't reset the 3 s")


func test_radioed_alert_also_drops_after_3s() -> void:
	var a := _alerted()
	_run(a, GuardAlert.LOSE_TIME + 0.1, 0.0)
	assert_eq(a.state, S.EVASION)


func test_noise_never_alerts() -> void:
	var a := GuardAlert.new()
	assert_eq(a.hear(SPOT, "footsteps"), "heard footsteps")
	assert_eq(a.state, S.SUSPICION)
	assert_eq(a.meter, GuardAlert.SUSPECT_AT)
	for i in 10:
		a.hear(SPOT, "footsteps")
	assert_eq(a.state, S.SUSPICION, "repeated noise stays suspicion")
	assert_eq(a.meter, GuardAlert.SUSPECT_AT)


func test_noise_redirects_a_search() -> void:
	var a := _evading()
	_run(a, 8.0, 0.0, true)
	var there := Vector3(-10, 0, 3)
	assert_eq(a.hear(there, "a knock"), "")
	assert_eq(a.state, S.EVASION)
	assert_eq(a.last_known, there)
	assert_eq(a.timer, 0.0, "the 12 s start over at the new spot")


func test_noise_doesnt_distract_an_alerted_guard() -> void:
	var a := _alerted()
	assert_eq(a.hear(Vector3(-10, 0, 3), "a knock"), "")
	assert_eq(a.last_known, SPOT)


func test_quiet_frames_return_no_reason() -> void:
	var a := GuardAlert.new()
	assert_eq(_run(a, 30.0, 0.0), [])
	a = _alerted()
	assert_eq(_run(a, 2.0, 1.0), [], "staying alerted while seen")


func test_full_cycle() -> void:
	var a := GuardAlert.new()
	var reasons: Array[String] = []
	reasons.append_array(_run(a, 0.5, 1.0))          # suspicion at 0.35
	reasons.append_array(_run(a, 1.0, 1.0))          # alert at 1.0
	reasons.append_array(_run(a, 3.2, 0.0))          # lost: evasion
	reasons.append_array(_run(a, 12.2, 0.0, true))   # search: patrol
	assert_eq(reasons.size(), 4, str(reasons))
	assert_eq(a.state, S.PATROL)
	for r in reasons:
		assert_ne(r, "")


class StubEar:
	extends Node3D
	var heard: Array[String] = []

	func on_noise(_pos: Vector3, what: String) -> void:
		heard.append(what)


func test_broadcast_reaches_only_guards_in_range() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var near: StubEar = track(StubEar.new())
	var far: StubEar = track(StubEar.new())
	tree.root.add_child(near)
	tree.root.add_child(far)
	near.add_to_group("guards")
	far.add_to_group("guards")
	near.global_position = Vector3(5.9, 0, 0)
	far.global_position = Vector3(6.1, 0, 0)
	GuardAlert.broadcast(tree, Vector3.ZERO, GuardAlert.FOOTSTEP_RANGE, "footsteps")
	assert_eq(near.heard, ["footsteps"])
	assert_eq(far.heard, [])
	GuardAlert.broadcast(tree, Vector3.ZERO, GuardAlert.KNOCK_RANGE, "a knock")
	assert_eq(far.heard, ["a knock"])
	near.remove_from_group("guards")
	far.remove_from_group("guards")
