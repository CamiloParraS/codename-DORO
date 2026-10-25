@tool
extends McpTestSuite

## Which music track follows the guards, and the duck level during a Codec call.

const P := GuardAlert.State.PATROL
const S := GuardAlert.State.SUSPICION
const A := GuardAlert.State.ALERT
const E := GuardAlert.State.EVASION


func suite_name() -> String:
	return "music_state"


func test_patrol_plays_the_quiet_loop() -> void:
	assert_eq(MusicState.new().update(1.0, [P, P]), &"patrol")
	assert_eq(MusicState.new().update(1.0, []), &"patrol")  # every guard down


func test_suspicion_keeps_the_patrol_loop() -> void:
	assert_eq(MusicState.new().update(1.0, [S, P]), &"patrol")
	var m := MusicState.new()
	m.update(1.0, [A])
	m.update(3.0, [A])
	assert_eq(m.update(0.1, [A, S]), &"alert")  # a Suspicion beside an Alert does not move the track


func test_highest_guard_state_wins() -> void:
	assert_eq(MusicState.new().update(0.1, [P, E, S]), &"evasion")
	assert_eq(MusicState.new().update(0.1, [E, A, P]), &"alert")


func test_change_holds_two_seconds() -> void:
	var m := MusicState.new()
	m.update(0.1, [A])
	assert_eq(m.update(1.0, [P]), &"alert")
	assert_eq(m.update(0.5, [P]), &"alert")
	assert_eq(m.update(0.5, [P]), &"patrol")  # 2.0 s since the change


func test_patrol_ceiling_is_quieter_than_the_other_tracks() -> void:
	assert_eq(MusicState.ceiling_db(&"patrol"), -14.0)
	assert_eq(MusicState.ceiling_db(&"alert"), 0.0)


func test_held_change_lands_when_hold_ends() -> void:
	var m := MusicState.new()
	m.update(0.1, [A])
	assert_eq(m.update(1.0, [E]), &"alert")
	assert_eq(m.update(1.0, [E]), &"evasion")


func test_duck_is_six_db_only_during_a_call() -> void:
	assert_eq(MusicState.duck_db(true), -6.0)
	assert_eq(MusicState.duck_db(false), 0.0)
