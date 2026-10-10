@tool
extends McpTestSuite

## Tranq pistol rules: load, reserve, reload.


func suite_name() -> String:
	return "tranq"


func test_starts_4_in_load_8_total() -> void:
	var t := Tranq.new()
	assert_eq(t.loaded + t.reserve, 8)
	assert_eq(t.loaded, 4)


func test_empty_load_reloads_automatically_and_silently_refills() -> void:
	var t := Tranq.new()
	for i in 4:
		assert_true(t.fire(false))
	assert_true(t.reloading())
	assert_false(t.can_fire())
	t.tick(Tranq.RELOAD_TIME + 0.01, false)
	assert_eq(t.loaded, 4)
	assert_eq(t.reserve, 0)


func test_early_reload_moves_only_what_fits() -> void:
	var t := Tranq.new()
	t.fire(false)
	assert_true(t.reload(false))
	t.tick(2.0, false)
	assert_eq(t.loaded, 4)
	assert_eq(t.reserve, 3)


func test_no_reload_while_carrying_and_it_resumes_after() -> void:
	var t := Tranq.new()
	t.fire(false)
	assert_false(t.reload(true))
	for i in 3:
		t.fire(true)
	assert_false(t.reloading())
	t.tick(0.1, true)
	assert_false(t.reloading())
	t.tick(0.1, false)
	assert_true(t.reloading())


func test_picking_up_mid_reload_cancels_it() -> void:
	var t := Tranq.new()
	t.fire(false)
	assert_true(t.reload(false))
	t.tick(Tranq.RELOAD_TIME + 1.0, true)
	assert_eq(t.loaded, 3, "no reload completes while carrying")
	assert_eq(t.reserve, 4)
	assert_true(t.can_fire(), "the darts left still fire one-handed")


func test_an_empty_load_reload_cut_by_a_pickup_restarts_on_drop() -> void:
	var t := Tranq.new()
	for i in 4:
		t.fire(false)
	t.tick(0.5, false)
	t.tick(Tranq.RELOAD_TIME, true)
	assert_eq(t.loaded, 0)
	t.tick(0.1, false)
	assert_true(t.reloading())
	t.tick(Tranq.RELOAD_TIME, false)
	assert_eq(t.loaded, 4)


func test_full_load_or_no_reserve_does_not_reload() -> void:
	var t := Tranq.new()
	assert_false(t.reload(false))
	t.reserve = 0
	t.fire(false)
	assert_false(t.reload(false))


func test_one_handed_is_less_accurate() -> void:
	assert_true(Tranq.spread(true) > Tranq.spread(false))
