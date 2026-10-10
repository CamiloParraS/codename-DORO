@tool
extends McpTestSuite

## Guard vision: the two cones, half-rate peripheral, and the stance / motion / distance multipliers.

const FWD := Vector3(0, 0, -1)


func suite_name() -> String:
	return "guard_vision"


## Offset at `deg` off the guard's forward, `dist` metres away (chest a bit below the eye).
func _at(deg: float, dist: float) -> Vector3:
	var a := deg_to_rad(deg)
	return Vector3(sin(a) * dist, -0.3, -cos(a) * dist)


## Running, standing.
func _run_rate(offset: Vector3) -> float:
	return GuardVision.fill_rate(offset, FWD, false, true, false)


func test_front_cone_is_30_degrees_by_16m() -> void:
	assert_gt(_run_rate(_at(29, 15.9)), 0.0)
	assert_gt(_run_rate(_at(-29, 15.9)), 0.0, "both sides")
	assert_eq(_run_rate(_at(0, 16.1)), 0.0, "beyond 16 m")
	assert_eq(_run_rate(_at(31, 10)), 0.0, "outside 30 degrees past the peripheral range")


func test_peripheral_cone_is_60_degrees_by_6m() -> void:
	assert_gt(_run_rate(_at(59, 5.9)), 0.0)
	assert_gt(_run_rate(_at(-45, 4)), 0.0)
	assert_eq(_run_rate(_at(45, 6.1)), 0.0, "beyond 6 m")
	assert_eq(_run_rate(_at(61, 2)), 0.0, "outside 60 degrees")
	assert_eq(_run_rate(_at(180, 1)), 0.0, "right behind")


func test_peripheral_fills_at_half_rate() -> void:
	# Same distance, same 1.2 - d/reach falloff for both cones, isolates the 0.5.
	var front := GuardVision.BASE_RATE * clampf(1.2 - 5.0 / GuardVision.SIDE_RANGE, 0.15, 1.0) * 1.5
	assert_true(is_equal_approx(_run_rate(_at(45, 5)), front * 0.5), "%f" % _run_rate(_at(45, 5)))


func test_crouching_halves_the_rate() -> void:
	var o := _at(0, 8)
	var stand := GuardVision.fill_rate(o, FWD, false, true, true)
	var crouch := GuardVision.fill_rate(o, FWD, true, true, false)
	assert_true(is_equal_approx(crouch, stand * 0.5))


func test_motion_still_06_walk_1_run_15() -> void:
	var o := _at(0, 8)
	var walk := GuardVision.fill_rate(o, FWD, false, true, true)
	var still := GuardVision.fill_rate(o, FWD, false, false, false)
	var run := GuardVision.fill_rate(o, FWD, false, true, false)
	assert_true(is_equal_approx(still, walk * 0.6))
	assert_true(is_equal_approx(run, walk * 1.5))
	assert_true(is_equal_approx(GuardVision.fill_rate(o, FWD, false, false, true), still), "walk key held but still")


func test_closer_than_3m_fills_x4() -> void:
	var near := _run_rate(_at(0, 2.9))
	var base := GuardVision.BASE_RATE * clampf(1.2 - 2.9 / GuardVision.FRONT_RANGE, 0.15, 1.0) * 1.5
	assert_true(is_equal_approx(near, base * 4.0))
	assert_gt(near, _run_rate(_at(0, 3.1)) * 3.0, "a jump at 3 m")


func test_closer_than_3m_fills_x4_in_the_peripheral_cone_too() -> void:
	var near := _run_rate(_at(50, 2.9))
	var base := GuardVision.BASE_RATE * clampf(1.2 - 2.9 / GuardVision.SIDE_RANGE, 0.15, 1.0) * 1.5 * 0.5
	assert_true(is_equal_approx(near, base * 4.0), "%f" % near)


func test_faster_with_less_distance() -> void:
	var prev := 0.0
	for d in [15.0, 12.0, 9.0, 6.0, 3.5]:
		var r := _run_rate(_at(0, d))
		assert_gt(r, prev, "%d m" % d)
		prev = r


func test_far_edge_still_fills_a_little() -> void:
	assert_gt(_run_rate(_at(0, 15.9)), 0.1, "the falloff is clamped, not zero")


func test_height_doesnt_matter_only_the_flat_distance() -> void:
	var low := GuardVision.fill_rate(Vector3(0, -1.0, -8), FWD, false, true, false)
	var high := GuardVision.fill_rate(Vector3(0, 2.0, -8), FWD, false, true, false)
	assert_true(is_equal_approx(low, high))


func test_facing_rotates_the_cones() -> void:
	var east := Vector3(1, 0, 0)
	assert_gt(GuardVision.fill_rate(Vector3(10, 0, 0), east, false, true, false), 0.0)
	assert_eq(GuardVision.fill_rate(Vector3(0, 0, -10), east, false, true, false), 0.0)


func test_describe_names_motion_distance_and_cone() -> void:
	assert_eq(GuardVision.describe(_at(0, 9), FWD, false, true, false), "running, 9 m, in front")
	assert_eq(GuardVision.describe(_at(50, 4), FWD, true, true, false), "crouch-walking, 4 m, corner of the eye")
	assert_eq(GuardVision.describe(_at(0, 5), FWD, true, false, false), "still, crouched, 5 m, in front")
	assert_eq(GuardVision.describe(_at(0, 5), FWD, false, true, true), "walking, 5 m, in front")


func test_in_front_matches_the_front_cone() -> void:
	var fwd := Vector3(0, 0, -1)
	assert_true(GuardVision.in_front(Vector3(0, 0, -1.0), fwd))
	assert_false(GuardVision.in_front(Vector3(0, 0, 1.0), fwd), "behind")
	assert_false(GuardVision.in_front(Vector3(1.0, 0, 0), fwd), "beside")
