@tool
extends McpTestSuite

## Node-free movement and look rules.


func suite_name() -> String:
	return "locomotion"


func test_heavier_tuned_values() -> void:
	assert_eq(Locomotion.RUN, 4.8)
	assert_eq(Locomotion.WALK, 1.9)
	assert_eq(Locomotion.CROUCH, 1.3)
	assert_eq(Locomotion.GET_GOING, 7.0)
	assert_eq(Locomotion.SLOW_DOWN, 20.0)
	assert_eq(Locomotion.TURN_RATE, 8.0)


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


func test_move_starts_gradually_and_reaches_full_speed() -> void:
	var v := Locomotion.move(Vector2.ZERO, Vector2.RIGHT * Locomotion.RUN, 1.0 / 60.0)
	assert_true(v.length() < Locomotion.RUN * 0.3)  # not a snap from standstill
	v = Locomotion.move(v, Vector2.RIGHT * Locomotion.RUN, 1.0 / 60.0)
	for i in 30:  # half a second at 60 fps is enough to be at full speed
		v = Locomotion.move(v, Vector2.RIGHT * Locomotion.RUN, 1.0 / 60.0)
	assert_true(v.length() > Locomotion.RUN * 0.95)
	assert_true(v.length() < Locomotion.RUN)


func test_move_stops_quicker_than_it_starts() -> void:
	var stopping := Locomotion.move(Vector2.RIGHT * Locomotion.RUN, Vector2.ZERO, 1.0 / 60.0)
	var starting := Locomotion.move(Vector2.ZERO, Vector2.RIGHT * Locomotion.RUN, 1.0 / 60.0)
	assert_true(stopping.length() > starting.length() * 2.0)


func test_move_converges_on_the_target() -> void:
	var v := Vector2.ZERO
	for i in 60:  # one second: no drift, no overshoot
		v = Locomotion.move(v, Vector2.DOWN * Locomotion.CROUCH, 1.0 / 60.0)
	assert_true(v.distance_to(Vector2.DOWN * Locomotion.CROUCH) < 0.01)


func test_aiming_caps_standing_at_walk_and_crouched_keeps_crouch() -> void:
	assert_eq(Locomotion.speed(false, false, true), 1.9)
	assert_eq(Locomotion.speed(true, false, true), 1.3)
	assert_eq(Locomotion.speed(false, false, false), Locomotion.RUN, "releasing RMB restores the run")


func test_choke_moves_at_half_walk() -> void:
	assert_true(is_equal_approx(Locomotion.CHOKE_SPEED, 0.95))


func test_sway_targets_by_stance() -> void:
	assert_eq(Locomotion.sway(0.0, true, false, 0.016), 0.6, "moving resets to full")
	assert_eq(Locomotion.sway(0.0, true, true, 0.016), 0.6)
	var s := 0.6
	for i in 100:  # 1 s of standing still
		s = Locomotion.sway(s, false, false, 0.01)
	assert_true(is_equal_approx(s, 0.25))
	for i in 100:
		s = Locomotion.sway(s, false, true, 0.01)
	assert_true(is_equal_approx(s, 0.1), "crouched still")


func test_sway_settles_over_point_eight_seconds() -> void:
	var s := 0.6
	for i in 40:  # 0.4 s: about halfway
		s = Locomotion.sway(s, false, false, 0.01)
	assert_true(s > 0.25 and s < 0.6)
	for i in 40:  # 0.8 s total
		s = Locomotion.sway(s, false, false, 0.01)
	assert_true(is_equal_approx(s, 0.25))


func test_aim_drift_follows_the_sway_and_stays_small() -> void:
	assert_eq(Locomotion.drift(0.0, 3.0), Vector2.ZERO)
	var worst := 0.0
	for i in 200:
		worst = maxf(worst, Locomotion.drift(Locomotion.SWAY_MOVING, i * 0.1).length())
	assert_true(worst < Locomotion.SWAY_MOVING * Locomotion.DRIFT_GAIN * 2.0)
	assert_true(Locomotion.drift(Locomotion.SWAY_CROUCHED, 1.0).length() < Locomotion.drift(Locomotion.SWAY_MOVING, 1.0).length())


func test_drift_px_is_zero_at_centre_and_y_is_screen_down() -> void:
	assert_eq(Locomotion.drift_px(Vector2.ZERO, 50.0, 360.0), Vector2.ZERO)
	assert_true(Locomotion.drift_px(Vector2(0, 1), 50.0, 360.0).y < 0.0, "up in the world is up the screen")
