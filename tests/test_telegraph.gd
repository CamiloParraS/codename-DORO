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


# ----- Combat: reinforcements flank -----

func test_flank_share_follows_combat_level_with_the_same_clamp() -> void:
	for lvl in [1, 2, 3]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var n := 0
		for i in 2000:
			if Telegraph.flank(lvl, rng):
				n += 1
		assert_true(absf(n / 2000.0 - 0.25 * lvl) < 0.04, "level %d flanked %d/2000" % [lvl, n])
	assert_false(Telegraph.flank(0, RandomNumberGenerator.new()), "no Combat Countermeasure, no flank")


func test_flank_point_sits_to_one_side_of_the_target() -> void:
	var entry := Vector3(0, 0, 0)
	var target := Vector3(20, 0, 0)
	var seen := {}
	for s in 20:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var p := Telegraph.flank_point(entry, target, rng)
		assert_eq(p.x, 20.0, "beside the target along the approach")
		assert_eq(absf(p.z), Telegraph.FLANK_OFFSET)
		seen[signf(p.z)] = true
	assert_eq(seen.size(), 2, "both sides get used")


func test_flank_point_with_no_approach_stays_put() -> void:
	assert_eq(Telegraph.flank_point(Vector3.ONE, Vector3.ONE, RandomNumberGenerator.new()), Vector3.ONE)


func test_metis_and_briefing_name_the_flank() -> void:
	assert_ne(Telegraph.METIS.get("flank", ""), "")
	var plan := Aigis.plan_mission(Aigis.preset_profile("butcher"), 0.6, 3)
	assert_true(plan.briefing_keys.has("brief.promachos.flank"))
	assert_false(Aigis.plan_mission(Aigis.preset_profile("ghost"), 0.0, 3).briefing_keys.has("brief.promachos.flank"))
