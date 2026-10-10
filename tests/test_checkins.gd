@tool
extends McpTestSuite

## Check-in timer, Voiceprint capture, radio subtitles.


func suite_name() -> String:
	return "checkins"


func test_checkin_wait_is_20_to_30() -> void:
	for i in 20:
		var c := Checkin.new()
		assert_true(c.wait >= 20.0 and c.wait <= 30.0)


func test_checkin_starts_then_talks_then_rewaits() -> void:
	var c := Checkin.new()
	c.wait = 1.0
	assert_false(c.tick(0.5))
	assert_true(c.tick(0.6))
	assert_true(c.talking())
	assert_false(c.tick(Checkin.TALK_TIME + 0.1))
	assert_false(c.talking())
	assert_true(c.wait >= 20.0)


func test_on_air_only_while_checking_in_on_patrol() -> void:
	var c := Checkin.new()
	assert_false(c.on_air(GuardAlert.State.PATROL))
	c.wait = 0.0
	c.tick(0.1)
	assert_true(c.on_air(GuardAlert.State.PATROL))
	for s in [GuardAlert.State.SUSPICION, GuardAlert.State.ALERT, GuardAlert.State.EVASION]:
		assert_false(c.on_air(s))


func test_capture_after_2_5s_within_6m() -> void:
	var v := Voiceprints.new()
	assert_false(v.tick(2.0, "G1", 5.9, true))
	assert_true(v.tick(0.6, "G1", 5.9, true))
	assert_eq(v.held, ["G1"])


func test_no_progress_when_far_or_silent() -> void:
	var v := Voiceprints.new()
	assert_false(v.tick(5.0, "G1", 6.1, true))
	assert_false(v.tick(5.0, "G1", 2.0, false))
	assert_true(v.held.is_empty())


func test_progress_carries_between_checkins() -> void:
	var v := Voiceprints.new()
	v.tick(1.5, "G1", 3.0, true)
	v.tick(5.0, "G1", 3.0, false)  # between check-ins: nothing lost
	assert_true(v.tick(1.0, "G1", 3.0, true))


func test_subtitles_keep_last_two_and_fade() -> void:
	var s := Subtitles.new()
	s.add("A", "1")
	s.add("B", "2")
	s.add("C", "3")
	assert_eq(s.lines.size(), 2)
	assert_eq(s.lines[0]["who"], "B")
	s.tick(5.0)
	assert_eq(s.lines.size(), 2)
	assert_true(Subtitles.alpha(5.5) < 1.0)
	s.tick(1.1)
	assert_true(s.lines.is_empty())
