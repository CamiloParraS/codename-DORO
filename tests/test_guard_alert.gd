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
	_run(a, GuardAlert.LOSE_TIME - 1.0, 0.0)
	assert_eq(a.radio(Vector3(50, 0, 50), "Nikos"), "")
	assert_eq(a.last_known, SPOT, "keeps chasing its own lead")
	_run(a, 1.2, 0.0)
	assert_eq(a.state, S.EVASION, "the radio didn't reset the clock")


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
	reasons.append_array(_run(a, GuardAlert.LOSE_TIME + 0.2, 0.0))  # lost: evasion
	reasons.append_array(_run(a, GuardAlert.SEARCH_TIME + 0.2, 0.0, true))  # search: patrol
	assert_eq(reasons.size(), 4, str(reasons))
	assert_eq(a.state, S.PATROL)
	for r in reasons:
		assert_ne(r, "")


func _suspicious() -> GuardAlert:
	var a := GuardAlert.new()
	a.hear(SPOT, "a knock")
	return a


func test_seeing_a_down_guard_fills_the_meter_to_suspicion_only() -> void:
	var a := GuardAlert.new()
	assert_eq(a.see_down(1.0, 0.2, SPOT), "")
	assert_eq(a.state, S.PATROL)
	assert_eq(a.see_down(1.0, 5.0, SPOT), "saw a Down guard")
	assert_eq(a.state, S.SUSPICION)
	assert_eq(a.meter, GuardAlert.SUSPECT_AT, "a Down guard never alerts by sight")
	assert_eq(a.last_known, SPOT)


func test_down_guard_sighting_redirects_the_search_and_alerted_guards_ignore_it() -> void:
	var a := _evading()
	assert_eq(a.see_down(DT, 1.0, Vector3(1, 0, 1)), "")
	assert_eq(a.last_known, Vector3(1, 0, 1))
	a = _alerted()
	a.see_down(DT, 1.0, Vector3(1, 0, 1))
	assert_eq(a.last_known, SPOT)


func test_checking_a_dead_guard_raises_the_alert() -> void:
	var a := _suspicious()
	assert_eq(a.check_down(true), "found a dead guard")
	assert_eq(a.state, S.ALERT)
	a = _evading()
	a.check_down(true)
	assert_eq(a.state, S.ALERT)


func test_checking_a_neutralized_guard_wakes_it_and_stays_suspicious() -> void:
	var a := _suspicious()
	assert_eq(a.check_down(false), "woke a Neutralized guard")
	assert_eq(a.state, S.SUSPICION)
	assert_eq(a.timer, 0.0)


func test_only_a_suspicious_or_searching_guard_checks() -> void:
	assert_eq(GuardAlert.new().check_down(true), "", "patrol")
	assert_eq(_alerted().check_down(true), "", "alert")
	assert_eq(_alerted().state, S.ALERT)


func test_woken_guard_is_suspicious_and_remembers_nothing() -> void:
	var a := GuardAlert.new()
	assert_eq(a.wake(Vector3(2, 0, 2)), "woke up")
	assert_eq(a.state, S.SUSPICION)
	assert_eq(a.meter, GuardAlert.SUSPECT_AT)
	assert_eq(a.last_known, Vector3(2, 0, 2))


func test_a_down_guard_fills_the_meter_at_the_operatives_rate() -> void:
	# A Down guard at a far-range rate (below the 0.25/s drain) still fills, as fast as the Operative would.
	var rate := 0.2
	var down_guard := GuardAlert.new()
	var seen := GuardAlert.new()
	var down_frames := 0
	var seen_frames := 0
	while down_guard.state == S.PATROL and down_frames < 1000:
		down_guard.see_down(DT, rate, SPOT)
		down_guard.tick(DT, 0.0, Vector3.ZERO, "", false)
		down_frames += 1
	while seen.state == S.PATROL and seen_frames < 1000:
		seen.tick(DT, rate, SPOT, "test", false)
		seen_frames += 1
	assert_eq(down_guard.state, S.SUSPICION)
	assert_eq(down_frames, seen_frames, "same meter, same rate")


func test_the_meter_drains_again_once_the_down_guard_is_out_of_sight() -> void:
	var a := GuardAlert.new()
	a.see_down(1.0, 0.3, SPOT)
	a.tick(1.0, 0.0, Vector3.ZERO, "", false)
	assert_true(is_equal_approx(a.meter, 0.3), "no drain the frame the Down guard is seen")
	a.tick(1.0, 0.0, Vector3.ZERO, "", false)
	assert_true(is_equal_approx(a.meter, 0.05), "%f" % a.meter)


func test_noise_reaches_only_guards_in_range_through_walls() -> void:
	var o := Vector3.ZERO
	assert_true(GuardAlert.in_earshot(Vector3(5.9, 0, 0), o, GuardAlert.FOOTSTEP_RANGE))
	assert_false(GuardAlert.in_earshot(Vector3(6.1, 0, 0), o, GuardAlert.FOOTSTEP_RANGE))
	assert_true(GuardAlert.in_earshot(Vector3(6.1, 0, 0), o, GuardAlert.KNOCK_RANGE))
	assert_false(GuardAlert.in_earshot(Vector3(0, 0, 10.1), o, GuardAlert.KNOCK_RANGE))


func test_all_clear_stands_any_state_down_to_patrol() -> void:
	assert_eq(GuardAlert.new().stand_down("Kostas"), "")
	for a in [_alerted(), _evading()]:
		assert_eq(a.stand_down("Kostas"), "Kostas called all clear")
		assert_eq(a.state, S.PATROL)
		assert_eq(a.meter, 0.0)
	var s := GuardAlert.new()
	s.hear(SPOT, "a knock")
	s.stand_down("Kostas")
	assert_eq(s.state, S.PATROL)


func test_go_and_hold_orders_give_their_own_reason_even_on_patrol() -> void:
	var s := GuardAlert.new()
	s.hear(SPOT, "a knock")
	assert_eq(s.stand_down("Kostas", "go"), "Kostas sent it to check a place")
	assert_eq(s.state, S.PATROL)
	var p := GuardAlert.new()
	p.meter = 0.2
	assert_eq(p.stand_down("Kostas", "hold"), "Kostas told it to hold position")
	assert_eq(p.meter, 0.2)  # already patrolling: nothing else changes


# ----- Security cameras: same meter, no suspicion step -----

func test_camera_full_meter_alerts_with_no_suspicion_step() -> void:
	var a := GuardAlert.new()
	var reasons: Array[String] = []
	for i in roundi(1.0 / DT):
		var why := a.camera_tick(DT, 1.2, SPOT, "running, 9 m, in front")
		if why != "":
			reasons.append(why)
		assert_ne(a.state, S.SUSPICION, "a camera never goes '?'")
	assert_eq(a.state, S.ALERT)
	assert_eq(reasons, ["camera spotted you (running, 9 m, in front)"])
	assert_eq(a.last_known, SPOT)


func test_camera_meter_drains_like_a_guard() -> void:
	var a := GuardAlert.new()
	a.camera_tick(1.0, 0.5, SPOT, "test")
	a.camera_tick(1.0, 0.0, SPOT, "")
	assert_true(is_equal_approx(a.meter, 0.25), "%f" % a.meter)
	assert_eq(a.state, S.PATROL)


func test_camera_drops_back_to_watching_after_3s_unseen() -> void:
	var a := GuardAlert.new()
	a.camera_tick(1.0, 1.0, SPOT, "test")
	assert_eq(a.state, S.ALERT)
	assert_eq(a.camera_tick(2.9, 0.0, SPOT, ""), "")
	assert_eq(a.camera_tick(0.2, 0.0, SPOT, ""), "camera lost you")
	assert_eq(a.state, S.PATROL)
	assert_eq(a.meter, 0.0)


func test_downs_l2_a_down_guard_in_sight_is_an_instant_alert() -> void:
	var a := GuardAlert.new()
	assert_eq(a.see_down(1.0, 0.2, SPOT, true), "", "the meter still has to fill to suspicion")
	assert_eq(a.state, S.PATROL)
	assert_eq(a.see_down(1.0, 5.0, SPOT, true), "found a Down guard")
	assert_eq(a.state, S.ALERT)
	assert_eq(a.last_known, SPOT)


func test_downs_l2_a_suspicious_guard_that_sees_a_body_alerts_without_walking_over() -> void:
	var a := _suspicious()
	assert_eq(a.see_down(DT, 1.0, SPOT, true), "found a Down guard")
	assert_eq(a.state, S.ALERT)
	a = _evading()
	a.see_down(DT, 1.0, SPOT, true)
	assert_eq(a.state, S.ALERT)


func test_downs_l2_leaves_alerted_guards_and_unseen_bodies_alone() -> void:
	var a := _alerted()
	assert_eq(a.see_down(DT, 1.0, SPOT, true), "")
	assert_eq(a.state, S.ALERT)
	a = _suspicious()
	assert_eq(a.see_down(DT, 0.0, SPOT, true), "", "no sight, no alert")
	assert_eq(a.state, S.SUSPICION)


func test_flinch_fires_on_entering_alert_only_and_is_quick() -> void:
	assert_true(GuardAlert.flinches(S.PATROL, S.ALERT))
	assert_true(GuardAlert.flinches(S.EVASION, S.ALERT))
	assert_false(GuardAlert.flinches(S.ALERT, S.ALERT))
	assert_false(GuardAlert.flinches(S.PATROL, S.SUSPICION))
	assert_true(GuardAlert.FLINCH < 0.5, "well under half a second")


func test_a_loud_shot_goes_straight_to_alert_not_suspicion() -> void:
	var a := GuardAlert.new()
	assert_eq(a.shot(SPOT), "heard a gunshot")
	assert_eq(a.state, S.ALERT)
	assert_eq(a.last_known, SPOT)
	assert_eq(a.shot(SPOT), "", "already alerted")
	var e := _evading()
	e.shot(SPOT)
	assert_eq(e.state, S.ALERT, "a searching guard too")


func test_alert_lasts_20_s_unseen_and_the_search_30_s() -> void:
	assert_eq(GuardAlert.LOSE_TIME, 20.0)
	assert_eq(GuardAlert.SEARCH_TIME, 30.0)
	var a := _alerted()
	_run(a, 19.5, 0.0)
	assert_eq(a.state, S.ALERT)
	_run(a, 1.0, 0.0)
	assert_eq(a.state, S.EVASION)


func test_a_camera_still_drops_its_alert_after_3_s() -> void:
	var a := GuardAlert.new()
	a.camera_tick(DT, 1.0, SPOT, "test")
	a.meter = 1.0
	a.camera_tick(DT, 1.0, SPOT, "test")
	for i in 80:
		a.camera_tick(DT, 0.0, SPOT, "test")
	assert_eq(a.state, S.PATROL)
