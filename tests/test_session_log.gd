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


func test_spotted_notes_who_and_where_once() -> void:
	var l := _log()
	l.tick(4.0, false)
	l.spotted("GuardB2", "(12, 46, 3)")
	l.spotted("GuardB3", "(30, 40, 3)")
	assert_eq(l.missions[0].notes, [[4.0, "first spotted by GuardB2, Operative at (12, 46, 3)"]])


func test_notes_sit_in_time_order_with_the_encounters() -> void:
	var l := _log()
	l.tick(5.0, false)
	l.note("held up GuardA2")
	l.tick(5.0, false)
	l.enter_encounter(2, "LadderWest")
	var text := l.to_text()
	assert_true(text.find("5 s: held up GuardA2") < text.find("10 s: encounter 2 (left by LadderWest)"), text)


func test_the_trail_keeps_one_place_every_ten_seconds() -> void:
	var l := _log()
	for i in 25:
		l.place(Vector3(i, 2, 3), 1)
		l.tick(1.0, false)
	assert_eq(l.missions[0].trail.map(func(p: Array) -> float: return p[0]), [0.0, 10.0, 20.0])
	assert_contains(l.to_text(), "10: 10 2 3 E1")


func test_write_appends_each_finished_mission_once() -> void:
	var path := "user://test_session_log.txt"
	DirAccess.remove_absolute(path)
	var l := SessionLog.new()
	l.start_mission(1, "RelayStation, campaign")
	l.finish_mission()
	l.write(path)
	l.write(path)  # quit after the end writes again: nothing new
	var other := SessionLog.new()  # the next game run
	other.start_mission(2, "ResearchAnnex, free mode")
	other.finish_mission()
	other.write(path)
	var text := FileAccess.get_file_as_string(path)
	DirAccess.remove_absolute(path)
	assert_eq(text.count("mission 1 time"), 1)
	assert_eq(text.count("mission 2 time"), 1)
	assert_contains(text, "RelayStation, campaign")


func test_a_live_file_left_by_a_crash_is_recovered_into_the_log() -> void:
	var live := "user://test_session_log_live.txt"
	var path := "user://test_session_log.txt"
	DirAccess.remove_absolute(path)
	var l := SessionLog.new()
	l.start_mission(1, "RelayStation, free mode")
	l.tick(12.0, false)
	l.note("held up GuardA2")
	l.write_live(live)  # then the game dies: no finish, no write
	SessionLog.recover(live, path)
	var text := FileAccess.get_file_as_string(path)
	DirAccess.remove_absolute(path)
	assert_false(FileAccess.file_exists(live))
	assert_contains(text, "12 s: held up GuardA2")
	assert_contains(text, "the game stopped here")
