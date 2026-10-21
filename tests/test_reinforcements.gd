@tool
extends McpTestSuite

## Reinforcement waves, how alerted guards engage, and health during an Alert.


func suite_name() -> String:
	return "reinforcements"


func _run(r: Reinforcements, seconds: float, alerted: bool, alive := 0, squad := 3) -> int:
	var sent := 0
	for i in roundi(seconds * 10):
		sent += r.tick(0.1, alerted, alive, squad)
	return sent


func test_a_squad_at_once_then_another_every_30_s_of_alert() -> void:
	var r := Reinforcements.new()
	assert_eq(_run(r, 0.1, true), 3, "at once")
	assert_eq(_run(r, 29.0, true), 0)
	assert_eq(_run(r, 1.5, true), 3, "the 30 s wave")


func test_none_in_evasion_and_the_wait_is_cancelled() -> void:
	var r := Reinforcements.new()
	_run(r, 0.1, true)
	assert_eq(_run(r, 29.0, true), 0)
	assert_eq(_run(r, 60.0, false), 0, "evasion sends nobody")
	assert_eq(_run(r, 0.1, true), 3, "a new Alert starts over with a squad")


func test_a_wave_tops_up_to_the_cap_of_6() -> void:
	var r := Reinforcements.new()
	assert_eq(_run(r, 0.1, true, 4), 2)
	assert_eq(_run(r, 0.1, false), 0)
	assert_eq(_run(r, 0.1, true, 6), 0)
	assert_eq(Deployment.squad_size({"combat": 3}), 5)
	assert_eq(_run(Reinforcements.new(), 0.1, true, 3, 5), 3, "a squad of 5 is still held to the cap")


func test_a_guard_that_sees_from_beyond_10_m_holds_and_closer_it_pushes() -> void:
	var squad := [{pos = Vector3.ZERO, unseen = 0.0, last_known = Vector3.ZERO}]
	assert_true(Engage.holds(0, true, 15.0, squad))
	assert_false(Engage.holds(0, true, 8.0, squad))
	assert_false(Engage.holds(0, true, Health.RANGE + 5.0, squad), "too far to shoot: close in")


func test_with_nobody_in_sight_for_5_s_only_the_nearest_pushes() -> void:
	var squad := [
		{pos = Vector3(30, 0, 0), unseen = 6.0, last_known = Vector3.ZERO},
		{pos = Vector3(5, 0, 0), unseen = 7.0, last_known = Vector3.ZERO},
		{pos = Vector3(20, 0, 0), unseen = 9.0, last_known = Vector3.ZERO},
	]
	assert_true(Engage.holds(0, false, 0.0, squad))
	assert_false(Engage.holds(1, false, 0.0, squad), "the nearest pushes")
	assert_true(Engage.holds(2, false, 0.0, squad))
	squad[0].unseen = 2.0
	assert_false(Engage.holds(2, false, 0.0, squad), "someone saw it recently: everyone closes as before")


func test_no_regeneration_during_an_alert() -> void:
	var h := Health.new()
	h.hit()
	h.tick(30.0, true)
	assert_eq(h.life(), 0.75)
	h.tick(10.0, false)
	assert_eq(h.life(), 1.0)


func test_an_all_units_all_clear_ends_the_alert_and_cancels_waves() -> void:
	var guards: Array[GuardAlert] = []
	for i in 3:
		var a := GuardAlert.new()
		a.radio(Vector3.ZERO, "Kostas")
		guards.append(a)
	var r := Reinforcements.new()
	assert_eq(_run(r, 0.1, true), 3)
	guards[0].stand_down("Nikos")
	assert_true(guards.any(func(a: GuardAlert) -> bool: return a.state == GuardAlert.State.ALERT), "chosen guards only: the Alert holds")
	for a in guards:
		a.stand_down("Nikos")
	var alerted := guards.any(func(a: GuardAlert) -> bool: return a.state == GuardAlert.State.ALERT)
	assert_false(alerted)
	assert_eq(guards[1].state, GuardAlert.State.PATROL, "straight to patrol, Evasion skipped")
	assert_eq(_run(r, 60.0, alerted), 0, "the pending wave is cancelled")
