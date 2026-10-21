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
	assert_contains(text, "mission 1 time 125 s darts 1 rifle 0 spoofs 0")
	assert_contains(text, "idle 125 s")


func test_seconds_is_the_latest_missions_time() -> void:
	var log := SessionLog.new()
	assert_eq(log.seconds(), 0.0, "no Mission yet")
	log.start_mission(0)
	log.tick(2.5, false)
	assert_eq(log.seconds(), 2.5)
