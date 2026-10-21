@tool
extends McpTestSuite

## Rifle rules: load, reserve, suppressor, resupply.


func suite_name() -> String:
	return "rifle"


func test_starts_12_in_load_36_total_suppressed() -> void:
	var r := Rifle.new()
	assert_eq(r.loaded, 12)
	assert_eq(r.loaded + r.reserve, 36)
	assert_true(r.suppressed())


func test_suppressor_breaks_after_3_shots() -> void:
	var r := Rifle.new()
	for i in 3:
		assert_true(r.suppressed(), "shot %d is quiet" % (i + 1))
		assert_true(r.fire(false))
		r.tick(Rifle.INTERVAL, false)
	assert_false(r.suppressed(), "the 4th shot is loud")
	assert_eq(r.suppressor, 0)
	r.fire(false)
	assert_eq(r.suppressor, 0)


func test_a_dry_click_does_not_wear_the_suppressor() -> void:
	var r := Rifle.new()
	r.loaded = 0
	r.reload_left = 1.0
	assert_false(r.fire(false))
	assert_eq(r.suppressor, 3)


func test_empty_load_reloads_12_from_reserve() -> void:
	var r := Rifle.new()
	for i in 12:
		r.fire(false)
		r.tick(Rifle.INTERVAL, false)
	assert_true(r.reloading())
	r.tick(Tranq.RELOAD_TIME + 0.01, false)
	assert_eq(r.loaded, 12)
	assert_eq(r.reserve, 12)


func test_refill_adds_12_capped_at_36_and_restores_the_suppressor() -> void:
	var r := Rifle.new()
	for i in 20:
		r.fire(false)
		r.tick(2.0, false)
	assert_eq(r.loaded + r.reserve, 16)
	r.refill()
	assert_eq(r.loaded + r.reserve, 28, "adds 12")
	assert_eq(r.suppressor, 3)
	r.refill()
	assert_eq(r.loaded + r.reserve, 36, "capped at the 36 maximum")
	assert_false(r.reloading())


func test_tranq_refill_and_its_suppressor_never_breaks() -> void:
	var t := Tranq.new()
	for i in 4:
		t.fire(false)
	t.refill()
	assert_eq(t.loaded, 4)
	assert_eq(t.reserve, 4)
	assert_true(t.suppressed())


func test_rifle_is_automatic_and_paced() -> void:
	var r := Rifle.new()
	assert_true(r.automatic)
	assert_true(r.fire(false))
	assert_false(r.can_fire(), "the next round waits for the interval")
	r.tick(Rifle.INTERVAL + 0.01, false)
	assert_true(r.can_fire())
	assert_eq(r.loaded, 11)


func test_a_gated_shot_does_not_wear_the_suppressor() -> void:
	var r := Rifle.new()
	r.fire(false)
	r.fire(false)
	assert_eq(r.suppressor, 2)


func test_pistol_is_semi_auto_without_recoil_and_the_weapons_differ_on_screen() -> void:
	var t := Tranq.new()
	assert_false(t.automatic)
	assert_eq(t.kick, 0.0)
	assert_true(Rifle.new().crosshair != t.crosshair)


func test_the_rifle_is_one_handed_less_accurate_too() -> void:
	var r := Rifle.new()
	assert_eq(r.spread(false), 0.0)
	assert_eq(r.spread(true), Gun.SPREAD_ONE_HAND)


func test_two_body_hits_kill_the_first_does_not() -> void:
	assert_false(Guard.bullet_kills(false, false, 1))
	assert_true(Guard.bullet_kills(false, false, 2))


func test_a_headshot_kills_at_once() -> void:
	assert_true(Guard.bullet_kills(true, false, 1))


func test_a_helmet_turns_a_headshot_into_a_body_hit() -> void:
	assert_false(Guard.bullet_kills(true, true, 1))
	assert_true(Guard.bullet_kills(true, true, 2))
	assert_false(Guard.bullet_kills(false, false, 3, 4), "a vest takes 4 body hits")
	assert_true(Guard.bullet_kills(false, false, 4, 4))
