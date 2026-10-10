@tool
extends McpTestSuite

## Node-free movement and look rules.


func suite_name() -> String:
	return "locomotion"


func test_speed_by_stance() -> void:
	assert_eq(Locomotion.speed(false, false), Locomotion.RUN)
	assert_eq(Locomotion.speed(false, true), Locomotion.WALK)
	assert_eq(Locomotion.speed(true, false), Locomotion.CROUCH)
	assert_eq(Locomotion.speed(true, true), Locomotion.CROUCH)


func test_look_sensitivity_scales_delta() -> void:
	var a := Locomotion.look(0.0, 0.0, Vector2(10, 0), 0.01, false)
	var b := Locomotion.look(0.0, 0.0, Vector2(10, 0), 0.02, false)
	assert_true(is_equal_approx(a.x, -0.1))
	assert_true(is_equal_approx(b.x, -0.2))


func test_invert_y_flips_pitch() -> void:
	var normal := Locomotion.look(0.0, 0.0, Vector2(0, 10), 0.01, false)
	var inverted := Locomotion.look(0.0, 0.0, Vector2(0, 10), 0.01, true)
	assert_true(is_equal_approx(normal.y, -inverted.y))
	assert_true(normal.y < 0.0)


func test_pitch_is_clamped() -> void:
	assert_true(is_equal_approx(Locomotion.look(0.0, 0.0, Vector2(0, 1e6), 1.0, false).y, Locomotion.PITCH_MIN))
	assert_true(is_equal_approx(Locomotion.look(0.0, 0.0, Vector2(0, -1e6), 1.0, false).y, Locomotion.PITCH_MAX))
