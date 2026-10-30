@tool
extends McpTestSuite

## The UI motion kit: wipe step counts, the cut's flicker, and that a wipe finishes under slowed time.


func suite_name() -> String:
	return "ui_motion"


## A Control inside the tree, so its tweens can run.
func _live() -> Control:
	var c := Control.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(c)
	return c


func test_wipe_levels_are_hard_steps_ending_at_one() -> void:
	var l := UiMotion.levels(8)
	assert_eq(l.size(), 8)
	assert_eq(l[0], 0.125)
	assert_eq(l[7], 1.0)


func test_wipe_levels_never_empty() -> void:
	assert_eq(UiMotion.levels(0), [1.0])


func test_cut_is_six_steps_of_forty_ms() -> void:
	assert_eq(UiMotion.flicker().size(), 6)
	assert_eq(UiMotion.flicker().size() * UiMotion.CUT_STEP, 0.24)


func test_wipe_calls_back_once_per_step() -> void:
	var c := _live()
	var seen := []
	var t := UiMotion.wipe(c, true, 6, 0.3, func(p: float) -> void: seen.append(p))
	assert_true(t.is_valid())
	assert_true(c.material is ShaderMaterial)
	t.custom_step(1.0)
	assert_eq(seen.size(), 6)
	assert_eq(seen[5], 1.0)
	assert_true(c.material == null)
	c.free()


func test_cut_settles_fully_lit() -> void:
	var c := _live()
	var t := UiMotion.cut(c)
	assert_eq(c.modulate.a, 0.0)
	t.custom_step(1.0)
	assert_eq(c.modulate.a, 1.0)
	c.free()


func test_stagger_holds_later_controls_dark() -> void:
	var a := _live()
	var b := _live()
	UiMotion.stagger([a, b])
	assert_eq(a.modulate.a, 0.0)
	assert_eq(b.modulate.a, 0.0)
	a.free()
	b.free()
