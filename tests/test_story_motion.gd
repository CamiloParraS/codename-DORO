@tool
extends McpTestSuite

## Story motion (ui/codec/story_motion.gd): the Codec tune-in, the portrait flap and blink, the glyph pulse,
## and the clip a speaking body plays. Every motion is short and the player's key skips it.


func suite_name() -> String:
	return "story_motion"


func test_the_tune_in_settles_on_the_frequency_and_never_outlasts_a_third_of_a_second() -> void:
	assert_true(StoryMotion.TUNE <= 0.3)
	assert_true(StoryMotion.tuning(0.0))
	assert_ne(StoryMotion.frequency(0.05, "140.85"), "140.85", "digits still wander")
	assert_eq(StoryMotion.frequency(0.05, "140.85").length(), 6)
	assert_eq(StoryMotion.frequency(0.05, "140.85")[3], ".", "the point stays put")
	assert_false(StoryMotion.tuning(StoryMotion.TUNE))
	assert_eq(StoryMotion.frequency(StoryMotion.TUNE, "140.85"), "140.85")


func test_the_speaking_portrait_flips_frames_while_typing_and_rests_on_frame_zero_otherwise() -> void:
	assert_eq(StoryMotion.frame(0.0, true, true), 0)
	assert_eq(StoryMotion.frame(StoryMotion.FLAP + 0.01, true, true), 1)
	assert_eq(StoryMotion.frame(2 * StoryMotion.FLAP + 0.01, true, true), 0)
	assert_eq(StoryMotion.frame(StoryMotion.FLAP + 0.01, false, true), 0, "a listener does not flap")
	assert_eq(StoryMotion.frame(StoryMotion.FLAP + 0.01, true, false), 0, "a finished line rests")


func test_a_blink_is_a_brief_flip_now_and_then_on_a_resting_speaker() -> void:
	assert_eq(StoryMotion.frame(StoryMotion.BLINK_EVERY + 0.01, true, false), 1)
	assert_eq(StoryMotion.frame(StoryMotion.BLINK_EVERY + StoryMotion.BLINK + 0.01, true, false), 0)


func test_the_glyph_pulse_swells_and_returns_inside_a_third_of_a_second() -> void:
	assert_true(StoryMotion.PULSE <= 0.3)
	assert_eq(StoryMotion.pulse(0.0), 1.0)
	assert_gt(StoryMotion.pulse(StoryMotion.PULSE / 2.0), 1.1)
	assert_eq(StoryMotion.pulse(StoryMotion.PULSE), 1.0)
	assert_eq(StoryMotion.pulse(5.0), 1.0, "nothing loops")


func test_motion_is_off_while_settings_are_open() -> void:
	var node := Node.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(node)
	assert_false(StoryMotion.still(node))
	var panel := Node.new()
	panel.add_to_group("settings_open")
	tree.root.add_child(panel)
	assert_true(StoryMotion.still(node))
	panel.free()
	node.free()


func test_a_speaker_alternates_talking_clips_line_by_line() -> void:
	var g := Gesture.new()
	assert_eq(g.next(), Gesture.CLIPS[0])
	assert_eq(g.next(), Gesture.CLIPS[1])
	assert_eq(g.next(), Gesture.CLIPS[0])
