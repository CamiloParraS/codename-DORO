@tool
extends McpTestSuite

## Radar rules: north-up blip placement, range pinning, jamming, placement clear of the life bar.


func suite_name() -> String:
	return "radar_model"


func test_north_up_world_minus_z_is_up() -> void:
	assert_eq(RadarModel.unit(Vector2(0, -15)), Vector2(0, -0.5))
	assert_eq(RadarModel.unit(Vector2(30, 0)), Vector2(1, 0))


func test_beyond_range_pins_to_the_edge_keeping_direction() -> void:
	assert_eq(RadarModel.unit(Vector2(60, -30)), Vector2(1, -0.5))
	assert_eq(RadarModel.unit(Vector2(0, 300)), Vector2(0, 1))


func test_guards_show_only_inside_range() -> void:
	assert_true(RadarModel.in_range(Vector2(29, -29)))
	assert_false(RadarModel.in_range(Vector2(31, 0)))


func test_alert_and_evasion_jam_the_radar() -> void:
	assert_true(RadarModel.jammed("ALERT"))
	assert_true(RadarModel.jammed("EVASION"))
	assert_false(RadarModel.jammed(""))


func test_radar_clear_of_life_bar_and_its_label() -> void:
	var canvas := Vector2(640, 360)
	var r := RadarModel.rect(canvas)
	var life_bar := Rect2(10, canvas.y - 104, 7, 86)
	var label := Rect2(20, canvas.y - 104, 14, 86)  # OPERATIVE, rotated, from the bar's foot
	assert_false(r.intersects(life_bar))
	assert_false(r.intersects(label))
	assert_true(Rect2(Vector2.ZERO, canvas).encloses(r))
