@tool
extends McpTestSuite

## The alert beat: which cue a change in the Mission's highest guard state fires, and the hit-stop clock.

const P := GuardAlert.State.PATROL
const S := GuardAlert.State.SUSPICION
const A := GuardAlert.State.ALERT
const E := GuardAlert.State.EVASION


func suite_name() -> String:
	return "alert_beat"


func _beat(seq: Array) -> Array:
	var b := AlertBeat.new()
	var out := []
	for states in seq:
		out.append(b.update(states, 0.0))
	return out


func test_patrol_to_suspicion_is_a_question_blip() -> void:
	assert_eq(_beat([[P], [S, P]]), [&"", &"question"])


func test_alert_is_a_sting_with_hit_stop() -> void:
	var b := AlertBeat.new()
	assert_eq(b.update([S], 1.0), &"question")
	assert_eq(b.update([A, S], 2.0), &"alert")
	assert_eq(b.scale(2.0 + AlertBeat.STOP_TIME / 2, false), AlertBeat.STOP_SCALE)


func test_evasion_end_is_relief_but_evasion_to_alert_is_a_new_sting() -> void:
	assert_eq(_beat([[A], [E], [P]]), [&"alert", &"", &"relief"])
	assert_eq(_beat([[A], [E], [A]]), [&"alert", &"", &"alert"])


func test_no_repeat_cue_while_state_holds_and_second_guard_adds_none() -> void:
	assert_eq(_beat([[S], [S, S], [A, S], [A, A]]), [&"question", &"", &"alert", &""])


func test_each_beat_has_its_own_sound() -> void:
	var seen := {}
	for c in [&"question", &"alert", &"relief"]:
		seen[Mix.STREAMS[&"sting_" + c]] = true
	assert_eq(seen.size(), 3)


func test_hit_stop_ends_after_duration() -> void:
	var b := AlertBeat.new()
	b.update([A], 10.0)
	assert_eq(b.scale(10.0 + AlertBeat.STOP_TIME - 0.01, false), AlertBeat.STOP_SCALE)
	assert_eq(b.scale(10.0 + AlertBeat.STOP_TIME + 0.01, false), 1.0)


func test_pause_or_death_cancels_hit_stop_for_good() -> void:
	var b := AlertBeat.new()
	b.update([A], 10.0)
	assert_eq(b.scale(10.05, true), 1.0)
	assert_eq(b.scale(10.1, false), 1.0)


func test_no_relief_when_the_last_evading_guard_is_downed_or_the_list_empties() -> void:
	assert_eq(_beat([[E, P], [P]]), [&"", &""], "downed guard leaves the list")
	assert_eq(_beat([[E], []]), [&"", &""], "scene change empties it")
	assert_eq(_beat([[E, P], [P, P]]), [&"", &"relief"], "a genuine end still cues")


func test_a_hit_stop_on_demand_never_shortens_a_running_one() -> void:
	var b := AlertBeat.new()
	b.stop(10.0, 0.04)
	assert_eq(b.scale(10.02, false), AlertBeat.STOP_SCALE)
	assert_eq(b.scale(10.05, false), 1.0)
	b.update([A], 20.0)  # the "!" stop is STOP_TIME
	b.stop(20.0, 0.03)
	assert_eq(b.scale(20.0 + AlertBeat.STOP_TIME - 0.01, false), AlertBeat.STOP_SCALE)
