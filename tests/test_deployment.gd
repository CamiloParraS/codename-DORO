@tool
extends McpTestSuite

## Free mode's chain: a Preset becomes a record, plan_mission plans it (the cap still applies by
## Mission index), and Deployment says what the Area puts in the world.

const CORE := 3


func suite_name() -> String:
	return "deployment"


func _deployed(preset: String, mission: int) -> Dictionary:
	var r := Aigis.preset_record(preset, mission)
	return Aigis.plan_mission(r.points, Aigis.lethality_ratio(r), mission).deployed


func _count(flags: Array[bool]) -> int:
	return flags.count(true)


func test_preset_record_keeps_the_ratio_and_the_mission_index() -> void:
	var b := Aigis.preset_record("butcher", 2)
	assert_eq(b.mission, 2)
	assert_eq(b.points.combat, 300)
	assert_true(is_equal_approx(Aigis.lethality_ratio(b), 0.6))
	assert_true(is_nan(Aigis.lethality_ratio(Aigis.preset_record("clean_slate", 0))), "undefined stays undefined")
	assert_eq(Aigis.lethality_ratio(Aigis.preset_record("ghost", 0)), 0.0)


func test_nothing_deploys_on_mission_1_whatever_the_preset() -> void:
	for p: String in Aigis.PRESETS:
		var d := _deployed(p, 0)
		assert_false(Deployment.cameras(d), p)
		assert_eq(Deployment.extra_patrols(d), 0, p)
		assert_eq(_count(Deployment.helmets(d, 10)), 0, p)


func test_clean_slate_deploys_nothing_on_the_core() -> void:
	var d := _deployed("clean_slate", CORE)
	assert_false(Deployment.cameras(d))
	assert_eq(Deployment.extra_patrols(d), 0)
	assert_eq(_count(Deployment.helmets(d, 10)), 0)


func test_ghost_on_the_core_gets_cameras_and_the_extra_patrol() -> void:
	var d := _deployed("ghost", CORE)
	assert_true(Deployment.cameras(d))
	assert_eq(Deployment.extra_patrols(d), 1)
	assert_eq(_count(Deployment.helmets(d, 11)), 0)


func test_ghost_on_mission_2_gets_cameras_only() -> void:
	var d := _deployed("ghost", 1)
	assert_true(Deployment.cameras(d))
	assert_eq(Deployment.extra_patrols(d), 0)


func test_butcher_on_the_core_helmets_everyone() -> void:
	var d := _deployed("butcher", CORE)
	assert_eq(Deployment.helmets(d, 10), [true, true, true, true, true, true, true, true, true, true])
	assert_false(Deployment.cameras(d))


func test_helmet_shares_by_level() -> void:
	assert_eq(_count(Deployment.helmets({"headshots": 1}, 10)), 3)
	assert_eq(_count(Deployment.helmets({"headshots": 2}, 10)), 7)
	assert_eq(_count(Deployment.helmets({"headshots": 3}, 10)), 10)
	assert_eq(_count(Deployment.helmets({"headshots": 1}, 11)), 4)


func test_helmets_are_spread_out() -> void:
	assert_eq(Deployment.helmets({"headshots": 1}, 10), [false, false, false, true, false, false, true, false, false, true])
