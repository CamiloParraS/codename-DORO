@tool
extends McpTestSuite

## The shared Aigis telegraph and the Stealth head-check trigger: share clamp, seeded RNG, first sighting.


func suite_name() -> String:
	return "telegraph"


func test_share_rises_with_level_and_is_clamped_25_to_75() -> void:
	assert_eq(Telegraph.head_check_share(1), 0.25)
	assert_eq(Telegraph.head_check_share(2), 0.5)
	assert_eq(Telegraph.head_check_share(3), 0.75)
	assert_eq(Telegraph.head_check_share(0), 0.25, "never below the floor")
	assert_eq(Telegraph.head_check_share(9), 0.75, "never above the ceiling")


func test_fires_on_roughly_its_share_of_turns() -> void:
	for lvl in [1, 2, 3]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var n := 0
		for i in 2000:
			if Telegraph.head_check(lvl, rng):
				n += 1
		assert_true(absf(n / 2000.0 - 0.25 * lvl) < 0.04, "level %d fired %d/2000" % [lvl, n])


func test_same_seed_same_turns() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	for i in 20:
		assert_eq(Telegraph.head_check(2, a), Telegraph.head_check(2, b))


func test_no_head_check_without_a_stealth_countermeasure() -> void:
	var rng := RandomNumberGenerator.new()
	for i in 50:
		assert_false(Telegraph.head_check(0, rng))


func test_metis_calls_a_kind_once_per_mission() -> void:
	var seen := {}
	assert_true(Telegraph.first_sighting(seen, "head_check"))
	assert_false(Telegraph.first_sighting(seen, "head_check"))
	assert_true(Telegraph.first_sighting(seen, "other"))
	assert_ne(Telegraph.METIS.get("head_check", ""), "")


func test_deployment_reads_the_stealth_level() -> void:
	assert_eq(Deployment.head_check_level({"stealth": 2}), 2)
	assert_eq(Deployment.head_check_level({}), 0)


func test_briefing_names_the_head_check_when_stealth_is_deployed() -> void:
	var plan := Aigis.plan_mission(Aigis.preset_profile("ghost"), 0.0, 3)
	assert_true(plan.briefing_keys.has("brief.glaukopis.head_check"))
	assert_false(Aigis.plan_mission(Aigis.preset_profile("ghost"), 0.0, 0).briefing_keys.has("brief.glaukopis.head_check"), "Mission 1 stays clean")
