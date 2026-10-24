@tool
extends McpTestSuite

## Reinforcements, how alerted guards engage, and health during an Alert.


func suite_name() -> String:
	return "reinforcements"


## Runs a chain for `seconds` (seen: the Operative in sight), with r answering it; returns how many were sent.
func _run(c: AlertChain, r: Reinforcements, seconds: float, seen := false, alive := 0, squad := 3) -> int:
	var sent := 0
	for i in roundi(seconds * 10):
		c.tick(0.1, seen)
		sent += r.tick(c.alerts, alive, squad)
	return sent


func test_one_squad_per_completed_call_however_long_the_alert_holds() -> void:
	var c := AlertChain.new()
	var r := Reinforcements.new()
	c.start_call("Kostas", Vector3.ZERO)
	assert_eq(_run(c, r, 1.9), 0, "nobody while the call runs")
	assert_eq(_run(c, r, 0.1), 3, "the call completed")
	assert_eq(_run(c, r, 120.0, true), 0, "never a second squad for the same call")
	assert_eq(_run(c, r, 21.0), 0, "Evasion sends nobody")
	assert_eq(_run(c, r, 0.1, true), 0, "nor a sighting in Evasion: no new call")


func test_a_stopped_call_and_caution_send_nobody() -> void:
	var c := AlertChain.new()
	var r := Reinforcements.new()
	c.start_call("Kostas", Vector3.ZERO)
	c.stop_call("Kostas")
	c.caution()
	assert_eq(_run(c, r, 70.0), 0)


func test_a_new_completed_call_after_normal_sends_again() -> void:
	var c := AlertChain.new()
	var r := Reinforcements.new()
	c.start_call("Kostas", Vector3.ZERO)
	_run(c, r, 2.0)
	_run(c, r, 115.0)
	assert_eq(c.phase, AlertChain.Phase.NORMAL)
	c.start_call("Nikos", Vector3.ZERO)
	assert_eq(_run(c, r, 2.0), 3)


func test_a_squad_tops_up_to_the_cap_of_6() -> void:
	var c := AlertChain.new()
	c.start_call("Kostas", Vector3.ZERO)
	c.tick(2.0, false)
	assert_eq(Reinforcements.new().tick(c.alerts, 4, 3), 2)
	assert_eq(Reinforcements.new().tick(c.alerts, 6, 3), 0)
	assert_eq(Deployment.squad_size({"combat": 3}), 5)
	assert_eq(Reinforcements.new().tick(c.alerts, 3, 5), 3, "a squad of 5 is still held to the cap")


func test_a_fresh_chain_after_a_checkpoint_restore_is_answered_again() -> void:
	var r := Reinforcements.new()
	assert_eq(r.tick(2, 0, 3), 3)
	assert_eq(r.tick(0, 0, 3), 0)
	assert_eq(r.tick(1, 0, 3), 3)


func test_reinforcements_stay_through_evasion_and_caution_and_leave_in_normal() -> void:
	assert_false(Reinforcements.leaves(AlertChain.Phase.ALERT))
	assert_false(Reinforcements.leaves(AlertChain.Phase.EVASION))
	assert_false(Reinforcements.leaves(AlertChain.Phase.CAUTION))
	assert_true(Reinforcements.leaves(AlertChain.Phase.NORMAL))


func test_a_guard_that_sees_from_beyond_10_m_holds_and_closer_it_pushes() -> void:
	var squad := [{pos = Vector3.ZERO, unseen = 0.0, last_known = Vector3.ZERO}]
	assert_true(Engage.holds(0, true, 15.0, squad))
	assert_false(Engage.holds(0, true, 8.0, squad))
	assert_false(Engage.holds(0, true, Health.RANGE + 5.0, squad), "too far to shoot: close in")


func test_a_fresh_reinforcement_does_not_stop_the_squad_pushing() -> void:
	var squad := [
		{pos = Vector3(30, 0, 0), unseen = 9.0, last_known = Vector3.ZERO},
		{pos = Vector3(5, 0, 0), unseen = 9.0, last_known = Vector3.ZERO},
		{pos = Vector3(60, 0, 0), unseen = 0.0, last_known = Vector3.ZERO, fresh = true},
	]
	assert_false(Engage.holds(1, false, 0.0, squad), "the nearest still pushes")
	assert_true(Engage.holds(0, false, 0.0, squad))
	squad[2].fresh = false
	assert_false(Engage.holds(0, false, 0.0, squad), "one that really saw it recently: everyone closes")


func test_a_new_alert_marks_a_guard_as_not_having_seen() -> void:
	var a := GuardAlert.new()
	a.radio(Vector3.ZERO, "x")
	assert_false(a.saw)
	a.tick(0.1, 1.0, Vector3.ZERO, "t", false)
	assert_true(a.saw)


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


func test_an_all_units_all_clear_ends_the_alert() -> void:
	var guards: Array[GuardAlert] = []
	for i in 3:
		var a := GuardAlert.new()
		a.radio(Vector3.ZERO, "Kostas")
		guards.append(a)
	guards[0].stand_down("Nikos")
	assert_true(guards.any(func(a: GuardAlert) -> bool: return a.state == GuardAlert.State.ALERT), "chosen guards only: the Alert holds")
	for a in guards:
		a.stand_down("Nikos")
	var alerted := guards.any(func(a: GuardAlert) -> bool: return a.state == GuardAlert.State.ALERT)
	assert_false(alerted)
	assert_eq(guards[1].state, GuardAlert.State.PATROL, "straight to patrol, Evasion skipped")
	var c := AlertChain.new()
	c.start_call("Kostas", Vector3.ZERO)
	c.tick(2.0, false)
	c.stand_down()  # MissionRun: nobody hunts any more
	assert_eq(c.phase, AlertChain.Phase.NORMAL)
	assert_true(Reinforcements.leaves(c.phase), "the reinforcements leave at once")
