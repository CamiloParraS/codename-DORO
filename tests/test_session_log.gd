@tool
extends McpTestSuite

## The session logger: per-Mission time and counts, and the idle timer the Hint tracker reads.


func suite_name() -> String:
	return "session_log"


func _log() -> SessionLog:
	var l := SessionLog.new()
	l.start_mission(1)
	return l


func test_idle_grows_with_time_and_resets_on_progress() -> void:
	var l := _log()
	l.tick(10.0, false)
	assert_eq(l.idle_seconds(), 10.0)
	l.progress()
	assert_eq(l.idle_seconds(), 0.0)


func test_alert_and_evasion_time_never_counts_as_idle() -> void:
	var l := _log()
	l.tick(10.0, false)
	l.tick(40.0, true)
	assert_eq(l.idle_seconds(), 10.0)
	assert_eq(l.missions[0].seconds, 50.0)  # but it is still Mission time


func test_alert_ending_is_a_progress_event() -> void:
	var l := _log()
	l.tick(20.0, false)
	l.tick(5.0, true)
	l.tick(1.0, false)
	assert_eq(l.idle_seconds(), 1.0)  # reset at the edge, then this tick counts


func test_idle_over_60_is_logged_with_its_length_when_progress_ends_it() -> void:
	var l := _log()
	l.tick(75.0, false)
	l.progress()
	l.tick(59.0, false)
	l.progress()
	assert_eq(l.missions[0].idles, [75.0])


func test_finishing_flushes_a_running_idle() -> void:
	var l := _log()
	l.tick(90.0, false)
	l.finish_mission()
	assert_eq(l.missions[0].idles, [90.0])


func test_counts_are_per_mission() -> void:
	var l := _log()
	l.count("dart")
	l.count("dart")
	l.count("rifle")
	l.count("spoof")
	l.count("kill")  # not logged
	l.start_mission(2)
	l.count("spoof")
	assert_eq([l.missions[0].dart, l.missions[0].rifle, l.missions[0].spoof], [2, 1, 1])
	assert_eq([l.missions[1].dart, l.missions[1].spoof], [0, 1])


func test_text_has_one_line_per_mission_and_each_idle() -> void:
	var l := _log()
	l.tick(125.0, false)
	l.count("dart")
	l.finish_mission()
	var text := l.to_text()
	assert_contains(text, "mission 1 time 125 s darts 1 rifle 0 spoofs 0 takedowns 0 fultons 0 holdups 0 alerts 0")
	assert_contains(text, "idle 125 s")


func test_seconds_is_the_latest_missions_time() -> void:
	var log := SessionLog.new()
	assert_eq(log.seconds(), 0.0, "no Mission yet")
	log.start_mission(0)
	log.tick(2.5, false)
	assert_eq(log.seconds(), 2.5)


func test_the_runs_shape_first_spotted_encounters_alerts_and_tips() -> void:
	var l := _log()
	l.enter_encounter(1)
	l.tick(12.0, false)
	l.tip("crouch")
	l.spotted()
	l.tick(3.0, false)
	l.spotted()  # only the first counts
	l.enter_encounter(0, "SternDrop")
	l.enter_encounter(2)
	l.alert(2)
	l.count("takedown")
	l.count("holdup")
	var m: Dictionary = l.missions[0]
	assert_eq(m.spotted, 12.0)
	assert_eq(m.encounters, [[1, 0.0, ""], [0, 15.0, "SternDrop"], [2, 15.0, ""]])
	assert_eq(m.alerts, [[2, 15.0]])
	assert_eq(m.tips, [["crouch", 12.0]])
	var text := l.to_text()
	for line in ["takedowns 1 fultons 0 holdups 1 alerts 1", "first spotted 12 s", "15 s: encounter 0 (left by SternDrop)",
			"15 s: alert in encounter 2", "12 s: tip crouch"]:
		assert_contains(text, line)


func test_never_spotted_says_so() -> void:
	assert_contains(_log().to_text(), "first spotted never")
