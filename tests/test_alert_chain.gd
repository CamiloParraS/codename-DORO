@tool
extends McpTestSuite

## The Area's Alert chain: Radio calls, Alert → Evasion → Caution → Normal, and shared search spots.

const P := AlertChain.Phase
const DT := 0.1
const AT := Vector3(4, 0, 2)


func suite_name() -> String:
	return "alert_chain"


## Ticks for `seconds`; returns every non-empty event, in order.
func _run(c: AlertChain, seconds: float, seen := false) -> Array:
	var out := []
	for i in roundi(seconds / DT):
		var ev := c.tick(DT, seen)
		if ev != &"":
			out.append(ev)
	return out


func _alerted() -> AlertChain:
	var c := AlertChain.new()
	c.start_call("Kostas", AT)
	_run(c, 2.0)
	return c


func test_a_call_completes_after_2_s_into_one_alert() -> void:
	var c := AlertChain.new()
	assert_true(c.start_call("Kostas", AT))
	assert_eq(_run(c, 1.9), [], "still calling")
	assert_eq(_run(c, 0.1), [&"alert"])
	assert_eq(c.phase, P.ALERT)
	assert_eq(c.call_pos, AT)


func test_one_completed_call_is_one_alert_however_long_detection_holds() -> void:
	var c := _alerted()
	assert_false(c.start_call("Kostas", AT), "no calls during an Alert")
	assert_false(c.start_call("Nikos", AT))
	assert_eq(_run(c, 120.0, true), [])
	assert_eq(c.alerts, 1)


func test_a_stopped_call_is_no_alert_and_leaves_the_others_running() -> void:
	var c := AlertChain.new()
	c.start_call("Kostas", AT)
	_run(c, 1.0)
	c.start_call("Nikos", AT)
	c.stop_call("Kostas")
	assert_eq(_run(c, 1.5), [], "Nikos still has 0.5 s")
	assert_eq(_run(c, 0.5), [&"alert"])
	assert_eq(c.alerts, 1)


func test_stopping_every_call_means_no_alert() -> void:
	var c := AlertChain.new()
	c.start_call("Kostas", AT)
	c.stop_call("Kostas")
	assert_eq(_run(c, 5.0), [])
	assert_eq(c.alerts, 0)
	assert_eq(c.phase, P.NORMAL)


func test_the_first_call_to_complete_clears_the_others() -> void:
	var c := AlertChain.new()
	c.start_call("Kostas", AT)
	_run(c, 0.5)
	c.start_call("Nikos", Vector3(9, 0, 9))
	_run(c, 1.5)
	assert_false(c.calling("Nikos"))
	assert_eq(_run(c, 5.0, true), [], "Nikos's call never completes into a second Alert")
	assert_eq(c.alerts, 1)


func test_a_camera_window_is_1_5_s() -> void:
	var c := AlertChain.new()
	c.start_call("Cam", AT, AlertChain.CAMERA_CALL_TIME)
	assert_eq(_run(c, 1.5), [&"alert"])


func test_a_responder_never_calls_while_his_spotter_does() -> void:
	var c := AlertChain.new()
	c.start_call("Kostas", AT)
	assert_false(c.start_call("Nikos", AT, AlertChain.CALL_TIME, "Kostas"))
	c.stop_call("Kostas")
	assert_true(c.start_call("Nikos", AT, AlertChain.CALL_TIME, "Kostas"), "the call was stopped: a fresh one")


func test_alert_drains_in_20_s_unseen_then_30_s_evasion_then_60_s_caution() -> void:
	var c := _alerted()
	_run(c, 15.0)
	_run(c, 0.1, true)  # a sighting fills the counter again
	assert_eq(_run(c, 19.8), [])
	assert_eq(_run(c, 0.3), [&"evasion"])
	assert_eq(_run(c, 29.6), [], "the 0.3 s step already ran part of it")
	assert_eq(_run(c, 0.4), [&"caution"])
	assert_eq(_run(c, 59.6), [])
	assert_eq(_run(c, 0.4), [&"normal"])
	assert_eq(c.alerts, 1, "Evasion and Caution aren't Alerts")


func test_a_sighting_in_evasion_is_an_instant_alert_without_a_call() -> void:
	var c := _alerted()
	_run(c, 20.1)
	assert_eq(c.phase, P.EVASION)
	assert_false(c.start_call("Nikos", AT), "no call in Evasion")
	assert_eq(_run(c, 0.1, true), [&"realert"])
	assert_eq(c.phase, P.ALERT)
	assert_eq(c.alerts, 1, "not a new Alert for Rank or Reinforcements")


func test_a_sighting_in_caution_starts_a_call() -> void:
	var c := AlertChain.new()
	c.caution()
	assert_true(c.start_call("Kostas", AT))
	assert_eq(_run(c, 2.0), [&"alert"])


func test_caution_refreshes_to_60_s_and_never_stacks() -> void:
	var c := AlertChain.new()
	c.caution()
	_run(c, 50.0)
	c.caution()
	assert_eq(c.left, AlertChain.CAUTION_TIME)
	c.caution()
	assert_eq(c.left, AlertChain.CAUTION_TIME)
	assert_eq(_run(c, 60.1), [&"normal"])
	assert_eq(c.alerts, 0, "Caution sends nothing and counts nothing")


func test_caution_triggers_are_ignored_in_alert_and_evasion() -> void:
	var c := _alerted()
	c.caution()
	assert_eq(c.phase, P.ALERT)


func test_searchers_reserve_distinct_spots_nearest_first_one_holds_the_point() -> void:
	var c := AlertChain.new()
	c.spots = [Vector3(8, 0, 2), Vector3(6, 0, 2), Vector3(30, 0, 2)]
	assert_eq(c.reserve("A", AT), AT, "the first holds the point")
	assert_eq(c.reserve("B", AT), Vector3(6, 0, 2), "nearest first")
	assert_eq(c.reserve("C", AT), Vector3(8, 0, 2))
	assert_eq(c.reserve("D", AT), AT, "30 m is out of reach: back to the point")
	assert_eq(c.reserve("B", AT), Vector3(6, 0, 2), "asking again keeps the spot")


func test_a_released_spot_goes_to_the_next_searcher() -> void:
	var c := AlertChain.new()
	c.spots = [Vector3(6, 0, 2)]
	c.reserve("A", AT)
	c.reserve("B", AT)
	c.release("B")
	assert_eq(c.reserve("C", AT), Vector3(6, 0, 2))
	c.release("A")
	assert_eq(c.reserve("D", AT), AT, "the point is free again")
