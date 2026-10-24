@tool
extends McpTestSuite

## Metis's Hint tracker: when idling or wandering earns a Hint, the rate limit, the cap, Alert.


func suite_name() -> String:
	return "hint_tracker"


func test_idle_past_90_s_fires_tier_1() -> void:
	var h := HintTracker.new()
	assert_eq(h.update(1.0, 89.0, 0.0, false), 0)
	assert_eq(h.update(1.0, 90.0, 0.0, false), 1)


func test_wandering_15_m_above_the_best_for_45_s_fires() -> void:
	var h := HintTracker.new()
	h.update(1.0, 0.0, 30.0, false)  # best so far: 30
	assert_eq(h.update(44.0, 0.0, 46.0, false), 0)
	assert_eq(h.update(1.0, 0.0, 46.0, false), 1)


func test_coming_back_within_15_m_resets_the_wander_timer() -> void:
	var h := HintTracker.new()
	h.update(1.0, 0.0, 30.0, false)
	h.update(40.0, 0.0, 50.0, false)
	h.update(1.0, 0.0, 40.0, false)
	assert_eq(h.update(10.0, 0.0, 50.0, false), 0)


func test_best_distance_resets_when_the_step_changes() -> void:
	var h := HintTracker.new()
	h.update(1.0, 0.0, 5.0, false)
	h.new_step()
	h.update(1.0, 0.0, 60.0, false)  # a fresh best, not 55 m above 5
	assert_eq(h.update(50.0, 0.0, 60.0, false), 0)


func test_one_hint_per_60_s_and_timers_reset_after_each() -> void:
	var h := HintTracker.new()
	assert_eq(h.update(1.0, 90.0, 0.0, false), 1)
	assert_eq(h.update(30.0, 120.0, 0.0, false), 0)  # idle 30 s since the hint
	assert_eq(h.update(30.0, 150.0, 0.0, false), 0)  # 60 s gap passed, idle 60 s since
	assert_eq(h.update(30.0, 180.0, 0.0, false), 2)  # idle 90 s since the hint


func test_two_hints_a_step_then_quiet_and_a_new_step_starts_again() -> void:
	var h := HintTracker.new()
	h.update(1.0, 90.0, 0.0, false)
	h.update(100.0, 190.0, 0.0, false)
	assert_eq(h.update(100.0, 290.0, 0.0, false), 0)
	h.new_step()
	assert_eq(h.update(100.0, 90.0, 0.0, false), 1)


func test_a_progress_event_drops_the_logger_idle_below_the_baseline() -> void:
	var h := HintTracker.new()
	h.update(1.0, 90.0, 0.0, false)  # hint; baseline 90
	assert_eq(h.update(1.0, 2.0, 0.0, false), 0)  # logger idle was reset by the step


func test_request_fires_the_next_tier_now_and_counts_toward_the_cap() -> void:
	var h := HintTracker.new()
	assert_eq(h.request(), 1)
	assert_eq(h.request(), 2)
	assert_eq(h.request(), 0)
	assert_eq(h.update(1.0, 500.0, 0.0, false), 0)


func test_a_request_restarts_the_rate_limit() -> void:
	var h := HintTracker.new()
	h.request()
	assert_eq(h.update(1.0, 90.0, 0.0, false), 0)  # idle 90 s but only 1 s since the request


func test_a_due_hint_waits_out_an_alert_then_fires() -> void:
	var h := HintTracker.new()
	assert_eq(h.update(1.0, 90.0, 0.0, true), 0)
	assert_eq(h.update(5.0, 0.0, 0.0, true), 0)
	assert_eq(h.update(1.0, 0.0, 0.0, false), 1)  # the Alert ended (idle reset), the queued Hint speaks
