@tool
extends McpTestSuite

## The main menu's backdrop slideshow: which picture is in front, how it fades in, and that its push and pan
## never uncover an edge. Node-free.


func suite_name() -> String:
	return "menu_backdrop"


func test_each_picture_holds_then_the_next_is_in_front() -> void:
	assert_eq(MenuBackdrop.front(0.0), 0)
	assert_eq(MenuBackdrop.front(MenuBackdrop.HOLD - 0.01), 0)
	assert_eq(MenuBackdrop.front(MenuBackdrop.HOLD), 1)


func test_the_first_is_there_at_once_the_rest_fade_in() -> void:
	assert_eq(MenuBackdrop.opacity(0, 0.0), 1.0)
	assert_eq(MenuBackdrop.opacity(1, 0.0), 0.0)
	assert_eq(MenuBackdrop.opacity(1, MenuBackdrop.FADE), 1.0)


func test_the_fade_is_smooth_and_monotonic() -> void:
	var last := -1.0
	var levels := {}
	for i in 101:
		var o := MenuBackdrop.opacity(1, MenuBackdrop.FADE * i / 100.0)
		assert_true(o >= last)
		last = o
		levels[o] = true
	assert_true(levels.size() > 50, "no hard steps")


func test_the_pose_is_continuous_across_the_handover() -> void:
	# a picture leaves the front at age HOLD and is still drawn beneath the next: no jump in scale or place
	var before := MenuBackdrop.pose(2, MenuBackdrop.HOLD)
	var after := MenuBackdrop.pose(2, MenuBackdrop.HOLD + 0.016)
	assert_true(absf(before.scale - after.scale) < 0.001)
	assert_true(before.shift.distance_to(after.shift) < 0.001)


func test_the_pan_never_shows_an_edge() -> void:
	for i in MenuBackdrop.DIRS.size():
		for age in [0.0, 5.0, MenuBackdrop.HOLD, MenuBackdrop.HOLD + MenuBackdrop.FADE, 99.0]:
			var p := MenuBackdrop.pose(i, age)
			var spare: float = (p.scale - 1.0) / 2.0
			assert_true(absf(p.shift.x) <= spare and absf(p.shift.y) <= spare, "slide %d at %.1f s" % [i, age])


func test_every_picture_names_its_area_and_keeps_its_people_inside_it() -> void:
	for s: Dictionary in MenuBackdrop.SLIDES:
		assert_true(s.area != "" and TranslationServer.translate(s.area) != s.area, "%s has a translated name" % s.area)
		for m: Vector3 in s.marks:
			assert_true(m.x > 0.0 and m.x < 1.0 and m.y > 0.0 and m.y < 1.0 and m.z > 0.0, "%s mark %s" % [s.area, m])


func test_a_mark_follows_the_picture_it_sits_on() -> void:
	var view := Vector2(1920, 1080)
	var tex := Vector2(1280, 720)
	var r := MenuBackdrop.place(Vector3(0.5, 0.5, 0.1), 0, 0.0, view, tex)
	var p := MenuBackdrop.pose(0, 0.0)
	assert_true(r.get_center().distance_to(view / 2.0 + p.shift * view) < 0.5, "the centre rides the pan")
	assert_true(absf(r.size.y - 0.1 * 1080 * p.scale) < 0.5, "and the size the push")
	var later := MenuBackdrop.place(Vector3(0.8, 0.5, 0.1), 0, 6.0, view, tex)
	var sooner := MenuBackdrop.place(Vector3(0.8, 0.5, 0.1), 0, 0.0, view, tex)
	assert_true(later.size.y > sooner.size.y, "the push grows it")


func test_the_feed_types_in_after_the_dissolve_and_locks_in_steps() -> void:
	assert_eq(MenuFeed.typed(10, MenuBackdrop.FADE, MenuBackdrop.FADE), 0)
	assert_eq(MenuFeed.typed(10, MenuBackdrop.FADE + MenuFeed.TYPE_SECS, MenuBackdrop.FADE), 10)
	assert_eq(MenuFeed.lock(0, 0.0, MenuBackdrop.FADE), 0.0, "hidden before")
	var seen := {}
	for i in 200:
		var s := MenuFeed.lock(0, i * 0.01, MenuBackdrop.FADE)
		if s > 0.0:
			seen[s] = true
	assert_eq(seen.size(), MenuFeed.LOCK_STEPS + 1, "hard steps, ending at 1")
	assert_true(seen.has(1.0))


func test_the_feed_clock_runs_on_from_its_time_of_day() -> void:
	assert_eq(MenuFeed.clock("19:42", 0.0), "19:42:00")
	assert_eq(MenuFeed.clock("23:59", 75.0), "00:00:15")
