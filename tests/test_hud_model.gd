@tool
extends McpTestSuite

## HUD E rules: phase and timer, arc fill, arc angle.

const S := GuardAlert.State


func suite_name() -> String:
	return "hud_model"


func test_phase_none_in_normal_and_during_a_call() -> void:
	var c := AlertChain.new()
	assert_eq(HudModel.phase(c)[0], "")
	c.start_call("Kostas", Vector3.ZERO)
	assert_eq(HudModel.phase(c)[0], "", "a Radio call isn't an Alert yet")


func test_alert_evasion_and_caution_count_down() -> void:
	var c := AlertChain.new()
	c.start_call("Kostas", Vector3.ZERO)
	c.tick(2.0, false)
	c.tick(1.0, false)
	assert_eq(HudModel.phase(c), ["ALERT", 19.0, 0.95])
	c.tick(19.0, false)
	c.tick(15.0, false)
	assert_eq(HudModel.phase(c), ["EVASION", 15.0, 0.5])
	c.tick(15.0, false)
	assert_eq(HudModel.phase(c), ["CAUTION", 60.0, 1.0])


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


func test_aigis_weight_grows_with_mission_and_lethality() -> void:
	assert_eq(HudModel.aigis_weight(0, 0.5), 0.0)
	assert_eq(HudModel.aigis_weight(1, NAN), 0.4)
	assert_eq(HudModel.aigis_weight(2, Aigis.GORGO_FROM), 1.0)
	assert_true(HudModel.aigis_weight(2, 0.2) > HudModel.aigis_weight(2, 0.0))


func test_habits_risen_names_each_habit_once() -> void:
	var now := {"headshot": 2, "takedown": 1, "alert": 1, "loud_shot": 3}
	var before := {"headshot": 1, "takedown": 1}
	var risen := HudModel.habits_risen(before, now)
	assert_eq(risen.size(), 2)
	assert_true("headshots" in risen)
	assert_true("combat" in risen)


func test_gorgo_hides_only_the_early_arc() -> void:
	assert_eq(HudModel.deceive(0.2, "GORGO"), -1.0)
	assert_eq(HudModel.deceive(HudModel.GORGO_HIDE, "gorgo"), HudModel.GORGO_HIDE)
	assert_eq(HudModel.deceive(1.0, "gorgo"), 1.0)
	assert_eq(HudModel.deceive(0.2, "nike"), 0.2)
	assert_eq(HudModel.deceive(-1.0, "gorgo"), -1.0)
