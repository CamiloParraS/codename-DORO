@tool
extends McpTestSuite

## PSX look: shaders compile, no snapping/affine, textures are 128 px, scale gives 480 lines.


func suite_name() -> String:
	return "psx_look"


func test_surface_has_no_snap_or_affine() -> void:
	var code: String = load("res://assets/shaders/psx_surface.gdshader").code
	assert_false(code.contains("POSITION"))
	assert_true(code.contains("filter_nearest"))


func test_post_is_31_levels_without_dither() -> void:
	var code: String = load("res://assets/shaders/psx_post.gdshader").code
	assert_true(code.contains("levels = 31.0"))
	assert_false(code.to_lower().contains("bayer"))


func test_textures_are_128() -> void:
	for n in ["brick_07", "dirt_03", "metal_05", "stone_07", "wood_07"]:
		assert_eq((load("res://assets/textures/%s_128.png" % n) as Texture2D).get_size(), Vector2(128, 128))


func test_internal_height_is_480() -> void:
	var look := load("res://ui/psx_look/psx_look.gd")
	assert_eq(look.INTERNAL_HEIGHT, 480)
	assert_eq(look.FOG_BEGIN, 20.0)
	assert_eq(look.FOG_END, 60.0)
