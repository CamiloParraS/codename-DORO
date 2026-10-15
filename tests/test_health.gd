@tool
extends McpTestSuite

## Operative life and the odds of a guard's shot landing.


func suite_name() -> String:
	return "health"


func test_dies_after_4_hits() -> void:
	var h := Health.new()
	for i in 3:
		h.hit()
		assert_false(h.dead())
	h.hit()
	assert_true(h.dead())
	assert_eq(h.life(), 0.0)


func test_regenerates_only_after_5_s_without_damage() -> void:
	var h := Health.new()
	h.hit()
	h.tick(4.9)
	assert_eq(h.life(), 0.75, "no regeneration yet")
	h.tick(0.2)
	h.tick(1.0)
	assert_gt(h.life(), 0.75)
	h.tick(10.0)
	assert_eq(h.life(), 1.0)


func test_a_hit_restarts_the_regen_delay() -> void:
	var h := Health.new()
	h.hit()
	h.tick(4.0)
	h.hit()
	h.tick(4.0)
	assert_eq(h.life(), 0.5)


func test_the_dead_do_not_regenerate() -> void:
	var h := Health.new()
	for i in 4:
		h.hit()
	h.tick(60.0)
	assert_true(h.dead())


func test_hit_chance_falls_with_distance_and_when_running() -> void:
	assert_gt(Health.hit_chance(5.0, false), Health.hit_chance(20.0, false))
	assert_gt(Health.hit_chance(10.0, false), Health.hit_chance(10.0, true))
	assert_true(is_equal_approx(Health.hit_chance(500.0, false), Health.FAR))
