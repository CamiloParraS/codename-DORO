@tool
extends McpTestSuite

## Where a shot is seen to start: at the muzzle, aimed at what the crosshair aims at.


func suite_name() -> String:
	return "shot_aim"


func test_aim_point_is_the_camera_ray_hit_else_the_far_end() -> void:
	assert_eq(Gun.aim_point(Vector3(0, 1, 0), Vector3.FORWARD, Vector3(0, 1, -7), 60.0), Vector3(0, 1, -7))
	assert_eq(Gun.aim_point(Vector3(0, 1, 0), Vector3.FORWARD, null, 60.0), Vector3(0, 1, -60))


func test_shot_leaves_the_muzzle_toward_the_aim_point() -> void:
	var d := Gun.muzzle_dir(Vector3(0.5, 1, 0), Vector3(0, 1, -10), Vector3.FORWARD)
	assert_true(d.x < 0.0 and d.z < 0.0, "angles in from the right-hand muzzle")
	assert_true(absf(d.length() - 1.0) < 0.0001, "unit")
	# the line from the muzzle passes through the aim point
	assert_true((Vector3(0.5, 1, 0) + d * (Vector3(0, 1, -10) - Vector3(0.5, 1, 0)).length()).distance_to(Vector3(0, 1, -10)) < 0.001)


func test_aim_point_behind_or_at_the_muzzle_falls_back_to_the_camera_heading() -> void:
	assert_eq(Gun.muzzle_dir(Vector3(0, 1, -2), Vector3(0, 1, -1), Vector3.FORWARD), Vector3.FORWARD, "point behind the muzzle")
	assert_eq(Gun.muzzle_dir(Vector3(0, 1, -2), Vector3(0, 1, -2.05), Vector3.FORWARD), Vector3.FORWARD, "point on the muzzle")
