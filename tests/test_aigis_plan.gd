@tool
extends "res://tests/support/aigis_suite.gd"

## Aigis plan_mission: weights and budget, the pin, the greedy fill, briefing keys, and determinism.


func suite_name() -> String:
	return "aigis_plan"


# ----- plan_mission: weights and budget -----

func test_dominant_voice_weighs_2_and_the_others_1() -> void:
	for case: Array in [[NAN, "pallas"], [0.05, "pallas"], [0.25, "nike"], [0.7, "gorgo"]]:
		var plan := Aigis.plan_mission(_profile({}), case[0], CORE)
		assert_eq(plan.dominant, case[1])
		assert_eq(plan.weights.keys(), Aigis.VOICES)
		for v in Aigis.VOICES:
			assert_eq(plan.weights[v], 2.0 if v == case[1] else 1.0, "%s under %s" % [v, case[1]])


func test_budget_is_0_2_4_6() -> void:
	for i in 4:
		assert_eq(Aigis.plan_mission(_profile({}), NAN, i).budget, [0, 2, 4, 6][i])


func test_campaign_done_reads_as_the_core() -> void:
	var done := Aigis.complete_mission(_record(CORE, {"stealth": 399}), {})
	assert_eq(done.mission, 4)
	assert_eq(Aigis.cap(4), Aigis.cap(CORE))
	assert_eq(Aigis.level(399, 4), 3)
	assert_eq(Aigis.plan_mission(done.points, NAN, 4), Aigis.plan_mission(done.points, NAN, CORE))
	assert_eq(Aigis.complete_mission(done, {}).points.stealth, 399)  # still the Core's clamp


func test_mission_1_deploys_nothing_even_for_a_maxed_profile() -> void:
	var maxed := _profile({})
	for h in Aigis.HABITS:
		maxed[h] = 399
	var plan := Aigis.plan_mission(maxed, 0.5, 0)
	assert_eq(plan.picks, [])
	assert_eq(plan.pinned, "")
	for h in Aigis.HABITS:
		assert_eq(plan.unlocked[h], 0)
		assert_eq(plan.deployed[h], 0)


func test_the_cap_holds_unlocked_levels_by_mission() -> void:
	var plan := Aigis.plan_mission(_profile({"stealth": 399}), NAN, 1)
	assert_eq(plan.unlocked.stealth, 1)
	assert_eq(_steps(plan), ["stealth.1"])
	plan = Aigis.plan_mission(_profile({"stealth": 399}), NAN, 2)
	assert_eq(_steps(plan), ["stealth.1", "stealth.2"])


func test_spending_never_exceeds_the_budget_and_unspent_budget_is_fine() -> void:
	var all3 := _profile({})
	for h in Aigis.HABITS:
		all3[h] = 300
	for i in 4:
		var plan := Aigis.plan_mission(all3, NAN, i)
		assert_eq(plan.picks.size(), plan.budget, "full profile spends the whole budget at %d" % i)
	var plan := Aigis.plan_mission(_profile({"downs": 100}), NAN, CORE)
	assert_eq(_steps(plan), ["downs.1"])
	assert_eq(plan.budget, 6)


func test_deployed_matches_the_picks() -> void:
	var plan := Aigis.plan_mission(Aigis.preset_profile("ghost"), 0.0, CORE)
	var count := {}
	for p: Dictionary in plan.picks:
		count[p.habit] = count.get(p.habit, 0) + 1
	for h in Aigis.HABITS:
		assert_eq(plan.deployed[h], count.get(h, 0), h)


# ----- plan_mission: pin -----

func test_strongest_habit_is_pinned_and_answered_in_full_first() -> void:
	# Headshots is the strongest by level, so all three of its steps go first.
	var plan := Aigis.plan_mission(_profile({"headshots": 310, "combat": 290}), 0.6, CORE)
	assert_eq(plan.pinned, "headshots")
	assert_eq(_steps(plan).slice(0, 3), ["headshots.1", "headshots.2", "headshots.3"])
	for p: Dictionary in plan.picks.slice(0, 3):
		assert_eq(p.candidates, [], "pinned steps aren't scored against anything")


func test_pin_beats_a_higher_score() -> void:
	# Mission 2, budget 2, all three at L1. Scored alone, Combat (Gorgo 2.0 × 150 = 300) and Headshots
	# (240) would beat Stealth (Glaukopis 1.0 × 199) and leave it unanswered; the pin answers it first.
	var plan := Aigis.plan_mission(_profile({"stealth": 199, "combat": 150, "headshots": 120}), 0.6, 1)
	assert_eq(plan.pinned, "stealth")
	assert_eq(_steps(plan), ["stealth.1", "combat.1"])


func test_pin_tie_on_level_goes_to_more_points() -> void:
	var plan := Aigis.plan_mission(_profile({"combat": 210, "spoofing": 280}), NAN, CORE)
	assert_eq(plan.pinned, "spoofing")


func test_pin_tie_on_level_and_points_goes_to_habit_table_order() -> void:
	var plan := Aigis.plan_mission(_profile({"spoofing": 250, "headshots": 250}), NAN, CORE)
	assert_eq(plan.pinned, "headshots")
	assert_eq(_steps(plan).slice(0, 2), ["headshots.1", "headshots.2"])


func test_nothing_is_pinned_without_a_level() -> void:
	var plan := Aigis.plan_mission(_profile({"stealth": 99, "headshots": 50}), NAN, CORE)
	assert_eq(plan.pinned, "")
	assert_eq(plan.picks, [])


# ----- plan_mission: greedy fill -----

func test_greedy_scores_are_sponsor_weight_times_points() -> void:
	# Stealth pinned at L1; then the candidates are Headshots L1 (Gorgo) and Downs L1 (Pallas).
	var plan := Aigis.plan_mission(_profile({"stealth": 180, "headshots": 120, "downs": 150}), 0.0, 1)
	var fill: Dictionary = plan.picks[1]
	assert_eq(fill.candidates, [
		{"step": "headshots.1", "habit": "headshots", "level": 1, "sponsor": "gorgo", "score": 120.0},
		{"step": "downs.1", "habit": "downs", "level": 1, "sponsor": "pallas", "score": 300.0},
	])
	assert_eq(fill.step, "downs.1")
	assert_eq(fill.sponsor, "pallas")
	assert_eq(fill.score, 300.0)


func test_the_dominant_voice_changes_the_pick() -> void:
	var profile := _profile({"stealth": 180, "headshots": 120, "downs": 150})
	assert_eq(_steps(Aigis.plan_mission(profile, 0.0, 1)), ["stealth.1", "downs.1"], "Pallas favours polls")
	assert_eq(_steps(Aigis.plan_mission(profile, 0.6, 1)), ["stealth.1", "headshots.1"], "Gorgo favours helmets")
	assert_eq(_steps(Aigis.plan_mission(profile, 0.25, 1)), ["stealth.1", "downs.1"], "Nike: raw points")


func test_greedy_ties_go_to_habit_table_order() -> void:
	# Takedowns L1 and Downs L1 are both Pallas steps at the same points.
	var plan := Aigis.plan_mission(_profile({"stealth": 300, "takedowns": 100, "downs": 100}), NAN, 2)
	assert_eq(_steps(plan), ["stealth.1", "stealth.2", "takedowns.1", "downs.1"])


func test_steps_deploy_in_ladder_order() -> void:
	var plan := Aigis.plan_mission(_profile({"combat": 300, "headshots": 300, "spoofing": 200}), 0.6, CORE)
	var seen := {}
	for p: Dictionary in plan.picks:
		assert_eq(p.level, seen.get(p.habit, 0) + 1, "%s skipped a step" % p.step)
		seen[p.habit] = p.level


func test_candidates_are_each_habits_next_unlocked_step() -> void:
	var plan := Aigis.plan_mission(_profile({"combat": 300, "takedowns": 200, "spoofing": 100}), NAN, CORE)
	# Combat pinned (3 steps); the 4th pick weighs Takedowns L1 against Spoofing L1.
	var fourth: Dictionary = plan.picks[3]
	assert_eq(fourth.candidates.map(func(c: Dictionary) -> String: return c.step), ["takedowns.1", "spoofing.1"])
	var fifth: Dictionary = plan.picks[4]
	assert_eq(fifth.candidates.map(func(c: Dictionary) -> String: return c.step), ["takedowns.2", "spoofing.1"])


func test_every_pick_names_its_sponsor_from_the_ladder() -> void:
	var plan := Aigis.plan_mission(Aigis.preset_profile("butcher"), 0.6, CORE)
	for p: Dictionary in plan.picks:
		assert_eq(p.sponsor, Aigis.LADDERS[p.habit][p.level - 1][0], p.step)


# ----- plan_mission: briefing keys -----

func test_mission_1_briefing_is_only_the_close() -> void:
	assert_eq(Aigis.plan_mission(Aigis.preset_profile("butcher"), 0.6, 0).briefing_keys, ["brief.gorgo.close"])


func test_briefing_names_the_top_answered_habits_and_their_sponsor_hints() -> void:
	var plan := Aigis.plan_mission(Aigis.preset_profile("butcher"), 0.6, CORE)
	assert_eq(plan.briefing_keys, [
		"brief.pallas.habit.combat", "brief.promachos.hint.combat.3",
		"brief.pallas.habit.headshots", "brief.gorgo.hint.headshots.3",
		"brief.promachos.flank", "brief.gorgo.close",
	])


func test_briefing_names_at_most_two_habits() -> void:
	var plan := Aigis.plan_mission(Aigis.preset_profile("ghost"), 0.0, CORE)
	var named: Array = plan.briefing_keys.filter(func(k: String) -> bool: return k.begins_with("brief.pallas.habit."))
	assert_eq(named, ["brief.pallas.habit.stealth", "brief.pallas.habit.takedowns"])


func test_briefing_with_nothing_answered_is_only_the_close() -> void:
	assert_eq(Aigis.plan_mission(_profile({"stealth": 99}), NAN, 1).briefing_keys, ["brief.pallas.close"])


func test_nike_speaks_up_when_the_noisy_choke_is_deployed() -> void:
	var plan := Aigis.plan_mission(_profile({"takedowns": 300}), 0.25, CORE)
	assert_eq(plan.briefing_keys, [
		"brief.pallas.habit.takedowns", "brief.nike.hint.takedowns.3", "brief.nike.noisy_choke", "brief.nike.close",
	])
	plan = Aigis.plan_mission(_profile({"takedowns": 300}), 0.25, 2)
	assert_false(plan.briefing_keys.has("brief.nike.noisy_choke"), "only at L3")


# ----- determinism -----

func test_same_inputs_give_the_same_plan() -> void:
	for preset: String in Aigis.PRESETS:
		for i in 4:
			var a := Aigis.plan_mission(Aigis.preset_profile(preset), Aigis.PRESETS[preset].ratio, i)
			var b := Aigis.plan_mission(Aigis.preset_profile(preset), Aigis.PRESETS[preset].ratio, i)
			assert_eq(a, b, "%s at %d" % [preset, i])


func test_key_order_of_the_profile_does_not_matter() -> void:
	var forward := {"stealth": 200, "takedowns": 200, "downs": 200}
	var backward := {"downs": 200, "takedowns": 200, "stealth": 200}
	assert_eq(Aigis.plan_mission(backward, 0.0, CORE), Aigis.plan_mission(forward, 0.0, CORE))


func test_same_record_and_tally_give_the_same_record() -> void:
	var tally := {"alert": 2, "headshot": 3, "takedown": 1, "spoof": 2, "kill": 1, "spawned": 10}
	assert_eq(Aigis.complete_mission(_record(2, {"stealth": 120}), tally),
			Aigis.complete_mission(_record(2, {"stealth": 120}), tally))


func test_plan_does_not_touch_the_profile() -> void:
	var profile := Aigis.preset_profile("trickster")
	var before := profile.duplicate(true)
	Aigis.plan_mission(profile, 0.25, CORE)
	assert_eq(profile, before)
