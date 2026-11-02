@tool
extends McpTestSuite

## Node-free movement and look rules.


func suite_name() -> String:
	return "locomotion"


func test_heavier_tuned_values() -> void:
	assert_eq(Locomotion.RUN, 4.4)
	assert_eq(Locomotion.CARRY, 2.6)
	assert_eq(Locomotion.GRAVITY, 35.0)
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


func test_carrying_is_quicker_than_a_walk_and_slower_than_the_run() -> void:
	assert_eq(Locomotion.speed(false, true, false, true), Locomotion.CARRY, "carrying beats the walk flag it also sets")
	assert_true(Locomotion.WALK < Locomotion.CARRY and Locomotion.CARRY < Locomotion.RUN)


func test_the_run_stays_slower_than_a_chasing_guard() -> void:
	assert_true(Locomotion.RUN < Guard.CHASE_SPEED)


func test_a_short_drop_keeps_steering_a_fall_loses_its_way() -> void:
	var run := Vector2.RIGHT * Locomotion.RUN
	assert_eq(Locomotion.fall(run, run, 0.05, 1.0 / 60.0), Locomotion.move(run, run, 1.0 / 60.0), "a curb or stair edge steers as on the floor")
	var v := run
	var x := 0.0
	var t := Locomotion.AIR_GRACE
	while t < 1.0:  # held forward the whole way down
		v = Locomotion.fall(v, run, t + 0.01, 1.0 / 60.0)
		x += v.length() / 60.0
		t += 1.0 / 60.0
	assert_true(v.length() < 0.01, "the keys don't carry him on in the air")
	assert_true(x < 0.5, "he lands close under the edge, not out past it: %.2f m" % x)


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


func test_aiming_faces_the_camera_even_on_the_move() -> void:
	var yaw := 0.7
	var right := Vector3(1, 0, 0)
	assert_true(is_equal_approx(Locomotion.heading(true, true, right, yaw), yaw), "strafing right still faces the crosshair")
	assert_true(is_equal_approx(Locomotion.heading(true, false, Vector3.ZERO, yaw), yaw))
	assert_true(is_equal_approx(Locomotion.heading(false, true, right, yaw), atan2(-1.0, 0.0)), "not aiming: faces the way it moves")
	assert_true(is_nan(Locomotion.heading(false, false, Vector3.ZERO, yaw)), "still and not aiming: holds its heading")


func test_a_strafe_picks_the_nearest_of_eight_ways() -> void:
	assert_eq(Locomotion.strafe_dir(Vector2(0, 1)), "forward")
	assert_eq(Locomotion.strafe_dir(Vector2(1, 0)), "right")
	assert_eq(Locomotion.strafe_dir(Vector2(-1, 0)), "left")
	assert_eq(Locomotion.strafe_dir(Vector2(0, -1)), "backward")
	assert_eq(Locomotion.strafe_dir(Vector2(0.7, 0.7)), "forward_right")
	assert_eq(Locomotion.strafe_dir(Vector2(-0.7, -0.7)), "backward_left")
	assert_eq(Locomotion.strafe_dir(Vector2(1, 0.3)), "right", "mostly sideways is sideways")
	assert_eq(Locomotion.strafe_dir(Vector2.ZERO), "")
