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


func test_custom_reaches_the_steps_no_preset_deploys() -> void:
	var r := Aigis.custom_record({"takedowns": 3, "downs": 3}, NAN, CORE)
	assert_true(is_nan(Aigis.lethality_ratio(r)))
	var d: Dictionary = Aigis.plan_mission(r.points, Aigis.lethality_ratio(r), CORE).deployed
	assert_eq(Deployment.choke_time(d), 3.0, "Takedowns L3")
	assert_true(Deployment.instant_alert_on_down(d), "Downs L2")
	assert_eq(Deployment.hq_poll(d), "targeted", "Downs L3")


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


func test_combat_ladder_on_the_core() -> void:
	var d := _deployed("butcher", CORE)
	assert_true(Deployment.vests(d))
	assert_eq(Deployment.extra_guards(d), 2)
	assert_eq(Deployment.squad_size(d), 5)
	assert_eq(Deployment.body_hits_to_kill(d), 4)


func test_combat_ladder_steps() -> void:
	assert_false(Deployment.vests({"combat": 0}))
	assert_eq(Deployment.body_hits_to_kill({"combat": 0}), 2)
	assert_true(Deployment.vests({"combat": 1}))
	assert_eq(Deployment.extra_guards({"combat": 1}), 0)
	assert_eq(Deployment.extra_guards({"combat": 2}), 2)
	assert_eq(Deployment.squad_size({"combat": 2}), 3, "every Alert brings a squad of 3")
	assert_eq(Deployment.squad_size({"combat": 3}), 5)
	assert_false(Deployment.flanks({"combat": 2}))
	assert_true(Deployment.flanks({"combat": 3}))


func test_sentries_from_stealth_3() -> void:
	assert_false(Deployment.sentries({"stealth": 2}))
	assert_true(Deployment.sentries({"stealth": 3}))


func test_takedown_ladder_steps() -> void:
	assert_eq(Deployment.turn_around_every({}), 0.0, "never at L0")
	assert_true(Deployment.turn_around_every({"takedowns": 1}) > 0.0)
	assert_false(Deployment.pairs({"takedowns": 1}))
	assert_true(Deployment.pairs({"takedowns": 2}))
	assert_eq(Deployment.choke_time({"takedowns": 2}), 2.0)
	assert_eq(Deployment.choke_noise({"takedowns": 2}), 0.0)
	assert_eq(Deployment.choke_time({"takedowns": 3}), 3.0)
	assert_eq(Deployment.choke_noise({"takedowns": 3}), 6.0)


func test_ghost_on_the_core_gets_sentries_pairs_and_no_vests() -> void:
	var d := _deployed("ghost", CORE)
	assert_true(Deployment.sentries(d))
	assert_true(Deployment.pairs(d))
	assert_false(Deployment.vests(d))


func test_downs_ladder_steps() -> void:
	assert_eq(Deployment.hq_poll({}), "")
	assert_eq(Deployment.hq_poll({"downs": 1}), "random")
	assert_eq(Deployment.hq_poll({"downs": 2}), "random")
	assert_eq(Deployment.hq_poll({"downs": 3}), "targeted")
	assert_false(Deployment.instant_alert_on_down({"downs": 1}))
	assert_true(Deployment.instant_alert_on_down({"downs": 2}))
	assert_true(Deployment.instant_alert_on_down({"downs": 3}))


func test_spoofing_ladder_steps() -> void:
	assert_eq(Deployment.expose_at({}), 40)
	assert_eq(Deployment.expose_at({"spoofing": 1}), 25, "Spoofing L1")
	assert_false(Deployment.radio_callback({"spoofing": 1}))
	assert_true(Deployment.radio_callback({"spoofing": 2}), "Spoofing L2")
	assert_false(Deployment.single_use_voiceprints({"spoofing": 2}))
	assert_true(Deployment.single_use_voiceprints({"spoofing": 3}), "Spoofing L3")
