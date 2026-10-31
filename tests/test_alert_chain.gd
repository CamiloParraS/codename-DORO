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


## A chain with no open-ground ring: every ring spot lands far off the floor, so only the fixed spots count.
func _no_ring() -> AlertChain:
	var c := AlertChain.new()
	c.snap = func(p: Vector3) -> Vector3: return p + Vector3(100, 0, 0)
	return c


func test_searchers_reserve_distinct_spots_nearest_first_one_holds_the_point() -> void:
	var c := _no_ring()
	c.spots = [Vector3(8, 0, 2), Vector3(6, 0, 2), Vector3(30, 0, 2)]
	assert_eq(c.reserve("A", AT), AT, "the first holds the point")
	assert_eq(c.reserve("B", AT), Vector3(6, 0, 2), "nearest first")
	assert_eq(c.reserve("C", AT), Vector3(8, 0, 2))
	assert_eq(c.reserve("D", AT), AT, "30 m is out of reach: back to the point")
	assert_eq(c.reserve("B", AT), Vector3(6, 0, 2), "asking again keeps the spot")


func test_a_released_spot_goes_to_the_next_searcher() -> void:
	var c := _no_ring()
	c.spots = [Vector3(6, 0, 2)]
	c.reserve("A", AT)
	c.reserve("B", AT)
	c.release("B")
	assert_eq(c.reserve("C", AT), Vector3(6, 0, 2))
	c.release("A")
	assert_eq(c.reserve("D", AT), AT, "the point is free again")


# ----- fanning out -----

func test_the_ring_puts_open_ground_spots_round_the_point_on_the_floor() -> void:
	var c := AlertChain.new()
	var ring := c.ring(AT)
	assert_eq(ring.size(), AlertChain.RING_DIRS * AlertChain.RING_RADII.size())
	for p: Vector3 in ring:
		var r := Vector2(p.x - AT.x, p.z - AT.z).length()
		assert_true(is_equal_approx(r, 6.0) or is_equal_approx(r, 11.0), "on one of the two rings")
	c = AlertChain.new()
	c.snap = func(p: Vector3) -> Vector3: return p if p.z <= 2.0 else p + Vector3(0, 9, 0)  # past z 2: up on a roof
	for p: Vector3 in c.ring(AT):
		assert_true(p.z <= 2.0, "a spot snapped up onto a roof (or into a wall) is dropped")
	assert_gt(c.ring(AT).size(), 0)


func test_a_squad_fans_out_each_to_the_free_spot_on_its_own_side() -> void:
	var c := AlertChain.new()
	var first := c.reserve("A", AT, AT + Vector3(20, 0, 0))
	assert_eq(first, AT, "the first checks the sighting itself, even from afar")
	var east := c.reserve("B", AT, AT + Vector3(20, 0, 0))
	var west := c.reserve("C", AT, AT + Vector3(-20, 0, 0))
	assert_gt(east.x, AT.x, "the guard to the east searches east of it")
	assert_true(west.x < AT.x, "the one to the west searches west")
	assert_true(is_equal_approx(east.distance_to(AT), 6.0), "the inner ring before the outer")


func test_a_swept_spot_is_not_searched_again_until_a_new_sighting() -> void:
	var c := AlertChain.new()
	var at_a := c.reserve("A", AT, AT)
	c.searched("A")
	var next := c.reserve("A", AT, AT)
	assert_ne(next, at_a, "it moves on")
	assert_ne(c.reserve("B", AT, AT), at_a, "and nobody else is sent to the swept spot")
	c.start_call("g", AT)
	c.tick(AlertChain.CALL_TIME, false)  # a completed call: fresh information
	c.release("A")
	c.release("B")
	assert_eq(c.reserve("C", AT, AT), AT, "after a new sighting the point is worth checking again")


func test_with_every_spot_swept_the_search_starts_over() -> void:
	var c := _no_ring()
	assert_eq(c.reserve("A", AT), AT)
	c.searched("A")
	assert_eq(c.reserve("A", AT), AT, "nothing else to search: round again")
