@tool
extends McpTestSuite

## The loading screen stays over a new Area until its frames come steadily (the first ones compile its shaders).


func suite_name() -> String:
	return "loading"


func test_it_settles_on_a_run_of_quick_frames_after_a_minimum() -> void:
	assert_false(Loading.settled(2, 10, 0.1), "never before MIN_FRAMES")
	assert_false(Loading.settled(Loading.MIN_FRAMES, Loading.STEADY_RUN - 1, 0.5), "frames still hitching")
	assert_true(Loading.settled(Loading.MIN_FRAMES, Loading.STEADY_RUN, 0.5), "a run of quick frames")
	assert_true(Loading.settled(Loading.MIN_FRAMES, 0, Loading.MAX_SETTLE), "or the wait runs out on a slow machine")
