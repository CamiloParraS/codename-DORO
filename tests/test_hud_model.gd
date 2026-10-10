@tool
extends McpTestSuite

## HUD E rules: phase and timer, arc fill, arc angle.

const S := GuardAlert.State


func suite_name() -> String:
	return "hud_model"


func test_phase_none_when_patrolling() -> void:
	assert_eq(HudModel.phase([GuardAlert.new()])[0], "")


func test_alert_wins_over_evasion_and_counts_down() -> void:
	var alerted := GuardAlert.new()
	alerted.state = S.ALERT
	alerted.unseen = 1.0
	var searching := GuardAlert.new()
	searching.state = S.EVASION
	var ph := HudModel.phase([searching, alerted])
	assert_eq(ph[0], "ALERT")
	assert_eq(ph[1], GuardAlert.LOSE_TIME - 1.0)


func test_evasion_counts_down_search_time() -> void:
	var a := GuardAlert.new()
	a.state = S.EVASION
	a.timer = 4.0
	assert_eq(HudModel.phase([a]), ["EVASION", GuardAlert.SEARCH_TIME - 4.0])


func test_arc_fill() -> void:
	var a := GuardAlert.new()
	assert_eq(HudModel.arc_fill(a, false), -1.0)
	a.meter = 0.5
	assert_eq(HudModel.arc_fill(a, false), 0.5)
	a.state = S.ALERT
	assert_eq(HudModel.arc_fill(a, false), -1.0)
	assert_eq(HudModel.arc_fill(a, true), 1.0)


func test_arc_angle_points_at_guard() -> void:
	var fwd := Vector3.FORWARD
	var right := Vector3.RIGHT
	assert_true(is_equal_approx(HudModel.screen_angle(Vector3.FORWARD * 5, fwd, right), -PI / 2))
	assert_true(is_equal_approx(HudModel.screen_angle(Vector3.RIGHT * 5, fwd, right), 0.0))


func test_pips_lit_scale_the_load_and_never_hide_a_round() -> void:
	assert_eq(HudModel.pips_lit(3, 4, 4), 3)
	assert_eq(HudModel.pips_lit(30, 30, 6), 6)
	assert_eq(HudModel.pips_lit(25, 30, 6), 5)
	assert_eq(HudModel.pips_lit(1, 30, 6), 1)
	assert_eq(HudModel.pips_lit(0, 30, 6), 0)
