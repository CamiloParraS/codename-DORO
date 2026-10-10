@tool
extends McpTestSuite

## Aigis campaign module: complete_mission, plan_mission, resolve_ending, the Presets, a campaign
## simulation of the trigger tuning, and the Preset × Mission deployment tables for the write-up.

const TABLES_PATH := "res://docs/deployment-tables.md"
const MISSION_NAMES := ["Mission 1 (Harbour)", "Mission 2 (Relay station)", "Mission 3 (Research annex)", "Core"]
const CORE := 3


func suite_name() -> String:
	return "aigis"


## A record about to play `mission` with the given points (missing Habits = 0).
func _record(mission: int, points := {}) -> Dictionary:
	var r := Aigis.new_record()
	r.mission = mission
	r.points.merge(points, true)
	return r


func _profile(points: Dictionary) -> Dictionary:
	var p: Dictionary = Aigis.new_record().points
	p.merge(points, true)
	return p


func _steps(plan: Dictionary) -> Array:
	return plan.picks.map(func(p: Dictionary) -> String: return p.step)


## A tally with an alert, so the no-alert Stealth rule stays out of the way.
func _loud(extra := {}) -> Dictionary:
	var t := {"alert": 1}
	t.merge(extra, true)
	return t


# ----- complete_mission: record, cap and clamp -----

func test_new_record_is_empty() -> void:
	var r := Aigis.new_record()
	assert_eq(r.mission, 0)
	assert_eq(r.lethality, 0)
	assert_eq(r.denominator, 0)
	assert_eq(r.points.keys(), Aigis.HABITS)
	for h in Aigis.HABITS:
		assert_eq(r.points[h], 0)


func test_complete_mission_advances_the_mission_index() -> void:
	var r := Aigis.new_record()
	for i in 4:
		r = Aigis.complete_mission(r, {})
		assert_eq(r.mission, i + 1)


func test_mission_1_carries_at_most_199_points_into_mission_2() -> void:
	var r := Aigis.complete_mission(Aigis.new_record(), _loud({"headshot": 20, "alert": 10, "spoof": 20}))
	assert_eq(r.points.headshots, 199)
	assert_eq(r.points.combat, 199)
	assert_eq(r.points.spoofing, 199)
	for h in ["headshots", "combat", "spoofing"]:
		assert_eq(Aigis.level(r.points[h], 1), 1, "%s reaches L1 for Mission 2" % h)


func test_points_clamp_to_the_next_missions_cap_times_100_plus_99() -> void:
	var most := [199, 299, 399, 399]  # the Core has no next Mission and keeps its own cap
	for mission in 4:
		var r := Aigis.complete_mission(_record(mission), _loud({"headshot": 50}))
		assert_eq(r.points.headshots, most[mission], "Mission index %d" % mission)
	assert_eq(Aigis.CAPS, [0, 1, 2, 3])


func test_points_never_go_below_zero() -> void:
	var r := Aigis.complete_mission(_record(2, {"headshots": 30, "stealth": 20}), _loud({"alert": 5}))
	assert_eq(r.points.headshots, 0)
	assert_eq(r.points.stealth, 0)


func test_level_is_points_over_100_held_to_the_mission_cap() -> void:
	assert_eq(Aigis.level(99, CORE), 0)
	assert_eq(Aigis.level(100, CORE), 1)
	assert_eq(Aigis.level(299, CORE), 2)
	assert_eq(Aigis.level(399, CORE), 3)
	assert_eq(Aigis.level(399, 1), 1)
	assert_eq(Aigis.level(399, 0), 0)


func test_complete_mission_leaves_the_input_untouched_so_an_abort_applies_nothing() -> void:
	var r := _record(2, {"stealth": 150, "headshots": 120})
	var before := r.duplicate(true)
	var tally := {"alert": 3, "headshot": 4, "kill": 2, "spawned": 10}
	var tally_before := tally.duplicate(true)
	var after := Aigis.complete_mission(r, tally)
	assert_eq(r, before, "the record was changed in place")
	assert_eq(tally, tally_before, "the tally was changed in place")
	assert_ne(after, before)


func test_mission_points_follow_the_trigger_table() -> void:
	var pts := Aigis.mission_points(_loud({
		"quiet_down": 2, "loud_shot": 3, "alert_kill": 1, "headshot": 2, "takedown": 3,
		"down_found": 1, "woken": 2, "spoof": 2, "spoof_exposed": 1,
	}))
	assert_eq(pts, {
		"stealth": 30, "combat": 30 + 15 + 15, "headshots": 40, "takedowns": 60,
		"downs": 25 + 30, "spoofing": 40 + 20,
	})


func test_an_exposed_spoof_weighs_more() -> void:
	var clean := Aigis.mission_points(_loud({"spoof": 1}))
	var exposed := Aigis.mission_points(_loud({"spoof": 1, "spoof_exposed": 1}))
	assert_gt(exposed.spoofing, clean.spoofing)


# ----- complete_mission: Stealth and Combat tug of war -----

func test_a_mission_with_no_alert_counts_as_stealth() -> void:
	# Loud shots and no Downs at all: still a Stealth Mission, because nobody raised an alert.
	var r := Aigis.complete_mission(_record(CORE, {"stealth": 100, "combat": 200}), {"loud_shot": 10})
	assert_eq(r.points.stealth, 100 + Aigis.NO_ALERT_POINTS)
	assert_eq(r.points.combat, 200 - Aigis.TUG_LOSS)


func test_stealth_lead_wins_and_pulls_combat_down() -> void:
	# 8 quiet Downs (120) against one alert (30): Stealth leads by 90 >= 30% of 150.
	var r := Aigis.complete_mission(_record(CORE, {"stealth": 100, "combat": 200}), _loud({"quiet_down": 8}))
	assert_eq(r.points.stealth, 100 + 120)
	assert_eq(r.points.combat, 200 - Aigis.TUG_LOSS)


func test_combat_lead_wins_and_pulls_stealth_down() -> void:
	# Two alerts and 4 kills in them (120) against 2 quiet Downs (30).
	var r := Aigis.complete_mission(_record(CORE, {"stealth": 200, "combat": 100}),
			{"alert": 2, "alert_kill": 4, "quiet_down": 2})
	assert_eq(r.points.combat, 100 + 120)
	assert_eq(r.points.stealth, 200 - Aigis.TUG_LOSS)


func test_a_close_mission_is_a_draw_and_both_sides_keep_their_points() -> void:
	# Stealth 90, Combat 120: a 30 lead is under 30% of 210 (63), so neither side pulls.
	var r := Aigis.complete_mission(_record(CORE, {"stealth": 100, "combat": 100}),
			{"alert": 3, "quiet_down": 6, "loud_shot": 6})
	assert_eq(r.points.stealth, 100 + 90)
	assert_eq(r.points.combat, 100 + 120)


func test_a_side_must_lead_by_30_percent_of_both() -> void:
	var start := {"stealth": 100, "combat": 100}
	# Combat 55 (an alert, 5 loud shots) vs Stealth 30: a 25 lead is under 30% of 85 (25.5), a draw.
	var r := Aigis.complete_mission(_record(CORE, start), {"alert": 1, "loud_shot": 5, "quiet_down": 2})
	assert_eq(r.points.combat, 155)
	assert_eq(r.points.stealth, 130)
	# Two more loud shots: 65 vs 30, a 35 lead over 30% of 95 (28.5), so Combat wins.
	r = Aigis.complete_mission(_record(CORE, start), {"alert": 1, "loud_shot": 7, "quiet_down": 2})
	assert_eq(r.points.combat, 165)
	assert_eq(r.points.stealth, 100 - Aigis.TUG_LOSS)


# ----- complete_mission: decay -----

func test_unused_habits_decay_half_a_level() -> void:
	var start := {"headshots": 260, "takedowns": 120, "downs": 340, "spoofing": 100}
	var r := Aigis.complete_mission(_record(CORE, start), {})
	for h: String in start:
		assert_eq(r.points[h], start[h] - Aigis.DECAY, h)
	assert_eq(Aigis.DECAY, 50, "at most half a level")


func test_decay_stops_at_zero() -> void:
	var r := Aigis.complete_mission(_record(CORE, {"headshots": 30}), {})
	assert_eq(r.points.headshots, 0)


func test_used_habits_add_their_points_and_do_not_decay() -> void:
	var r := Aigis.complete_mission(_record(CORE, {"headshots": 200, "takedowns": 200}), _loud({"headshot": 1}))
	assert_eq(r.points.headshots, 220)
	assert_eq(r.points.takedowns, 150)


# ----- complete_mission: Lethality -----

func test_lethality_weighs_guards_1_and_targets_3() -> void:
	var r := Aigis.complete_mission(_record(1), {"kill": 4, "target_kill": 1})
	assert_eq(r.lethality, 4 + 3)


func test_denominator_adds_guards_spawned_and_3_per_target() -> void:
	var r := Aigis.complete_mission(_record(1), {"spawned": 12, "targets": 1})
	assert_eq(r.denominator, 12 + 3)


func test_lethality_and_denominator_accumulate_across_missions() -> void:
	var r := Aigis.new_record()
	r = Aigis.complete_mission(r, {"spawned": 9, "kill": 1})
	r = Aigis.complete_mission(r, {"spawned": 11, "targets": 1, "kill": 2, "target_kill": 1})
	r = Aigis.complete_mission(r, {"spawned": 10, "targets": 1})
	assert_eq(r.lethality, 1 + 2 + 3)
	assert_eq(r.denominator, 9 + 14 + 13)


func test_lethality_stays_apart_from_the_profile() -> void:
	var r := Aigis.complete_mission(_record(CORE), _loud({"kill": 5, "target_kill": 1}))
	var quiet := Aigis.complete_mission(_record(CORE), _loud())
	assert_eq(r.points, quiet.points)


func test_lethality_ratio() -> void:
	assert_true(is_nan(Aigis.lethality_ratio(Aigis.new_record())), "undefined before Mission 1")
	var r := Aigis.new_record()
	r.lethality = 3
	r.denominator = 12
	assert_eq(Aigis.lethality_ratio(r), 0.25)


# ----- resolve_ending -----

func test_bands() -> void:
	assert_eq(Aigis.resolve_ending(0.0), "pallas")
	assert_eq(Aigis.resolve_ending(0.099), "pallas")
	assert_eq(Aigis.resolve_ending(0.2), "nike")
	assert_eq(Aigis.resolve_ending(0.399), "nike")
	assert_eq(Aigis.resolve_ending(0.6), "gorgo")
	assert_eq(Aigis.resolve_ending(1.0), "gorgo")


func test_a_value_on_a_threshold_goes_to_the_higher_band() -> void:
	assert_eq(Aigis.resolve_ending(0.10), "nike")
	assert_eq(Aigis.resolve_ending(0.40), "gorgo")
	var r := Aigis.new_record()
	r.lethality = 1
	r.denominator = 10
	assert_eq(Aigis.resolve_ending(Aigis.lethality_ratio(r)), "nike", "1/10 computed")
	r.lethality = 4
	assert_eq(Aigis.resolve_ending(Aigis.lethality_ratio(r)), "gorgo", "4/10 computed")


func test_an_undefined_ratio_gives_pallas() -> void:
	assert_eq(Aigis.resolve_ending(NAN), "pallas")
	assert_eq(Aigis.resolve_ending(Aigis.lethality_ratio(Aigis.new_record())), "pallas")


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
		"brief.gorgo.close",
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


# ----- Presets -----

func test_presets_are_habit_levels_and_a_ratio() -> void:
	assert_eq(Aigis.PRESETS.keys(), ["clean_slate", "ghost", "trickster", "butcher"])
	assert_eq(Aigis.preset_profile("clean_slate"), _profile({}))
	assert_eq(Aigis.preset_profile("ghost"), _profile({"stealth": 300, "takedowns": 200, "downs": 200}))
	assert_eq(Aigis.preset_profile("trickster"), _profile({"spoofing": 300, "stealth": 100, "headshots": 200}))
	assert_eq(Aigis.preset_profile("butcher"), _profile({"combat": 300, "headshots": 300, "takedowns": 100}))
	assert_true(is_nan(Aigis.PRESETS.clean_slate.ratio))
	assert_eq(Aigis.PRESETS.ghost.ratio, 0.0)
	assert_eq(Aigis.PRESETS.trickster.ratio, 0.25)
	assert_eq(Aigis.PRESETS.butcher.ratio, 0.6)


func test_preset_dominant_voices() -> void:
	var expected := {"clean_slate": "pallas", "ghost": "pallas", "trickster": "nike", "butcher": "gorgo"}
	for preset: String in expected:
		assert_eq(Aigis.resolve_ending(Aigis.PRESETS[preset].ratio), expected[preset], preset)


func test_presets_on_the_core_show_their_countermeasures() -> void:
	assert_eq(_steps(Aigis.plan_mission(Aigis.preset_profile("clean_slate"), NAN, CORE)), [])
	assert_eq(_steps(Aigis.plan_mission(Aigis.preset_profile("ghost"), 0.0, CORE)),
			["stealth.1", "stealth.2", "stealth.3", "takedowns.1", "downs.1", "takedowns.2"])
	assert_eq(_steps(Aigis.plan_mission(Aigis.preset_profile("trickster"), 0.25, CORE)),
			["spoofing.1", "spoofing.2", "spoofing.3", "headshots.1", "headshots.2", "stealth.1"])
	assert_eq(_steps(Aigis.plan_mission(Aigis.preset_profile("butcher"), 0.6, CORE)),
			["combat.1", "combat.2", "combat.3", "headshots.1", "headshots.2", "headshots.3"])


func test_presets_on_mission_2_show_only_l1_steps() -> void:
	for preset: String in Aigis.PRESETS:
		var plan := Aigis.plan_mission(Aigis.preset_profile(preset), Aigis.PRESETS[preset].ratio, 1)
		for p: Dictionary in plan.picks:
			assert_eq(p.level, 1, "%s on Mission 2: %s" % [preset, p.step])
	assert_eq(_steps(Aigis.plan_mission(Aigis.preset_profile("ghost"), 0.0, 1)), ["stealth.1", "takedowns.1"])


# ----- campaign simulation (trigger tuning) -----

## Plays the four Missions with one tally each; returns the record before each Mission plus the end.
func _campaign(tallies: Array) -> Array:
	var records := [Aigis.new_record()]
	for t: Dictionary in tallies:
		records.append(Aigis.complete_mission(records[-1], t))
	return records


func test_simulated_ghost_campaign_reaches_the_cap_every_mission() -> void:
	# Six quiet Downs a Mission, a few chokes, never an alert, nobody killed.
	var ghost := {"quiet_down": 6, "takedown": 3, "spawned": 9, "targets": 1}
	var rs := _campaign([ghost, ghost, ghost, ghost])
	assert_gt(rs[1].points.stealth, 49, "enough for the warning chatter in Mission 2")
	for i in [1, 2, 3]:
		assert_eq(Aigis.level(rs[i].points.stealth, i), i, "Stealth at the cap before Mission index %d" % i)
	var core := Aigis.plan_mission(rs[3].points, Aigis.lethality_ratio(rs[3]), CORE)
	assert_eq(core.pinned, "stealth")
	assert_eq(core.dominant, "pallas")
	assert_eq(rs[4].mission, 4)
	assert_eq(Aigis.resolve_ending(Aigis.lethality_ratio(rs[4])), "pallas")


func test_simulated_loud_campaign_turns_gorgo_and_answers_combat() -> void:
	# Two alerts, a dozen loud shots and kills in each; Targets killed on the spot.
	var loud := {"alert": 2, "loud_shot": 12, "alert_kill": 4, "kill": 4, "target_kill": 1, "spawned": 10, "targets": 1}
	var rs := _campaign([loud, loud, loud, loud])
	assert_eq(Aigis.level(rs[3].points.combat, CORE), 3, "Combat at the cap before the Core")
	var core := Aigis.plan_mission(rs[3].points, Aigis.lethality_ratio(rs[3]), CORE)
	assert_eq(core.pinned, "combat")
	assert_eq(core.dominant, "gorgo")
	assert_eq(_steps(core).slice(0, 3), ["combat.1", "combat.2", "combat.3"])
	assert_eq(rs[3].points.stealth, 0, "the tug of war keeps Stealth down")
	assert_eq(Aigis.resolve_ending(Aigis.lethality_ratio(rs[4])), "gorgo")


func test_simulated_style_change_moves_aigis_away() -> void:
	# Headshots for three Missions, then a quiet ghost Mission with no headshots before the Core.
	var shooter := {"headshot": 6, "alert": 1, "loud_shot": 2, "spawned": 9}
	var ghost := {"quiet_down": 6, "spawned": 9}
	var rs := _campaign([shooter, shooter, shooter])
	assert_eq(Aigis.level(rs[3].points.headshots, CORE), 3)
	var changed := Aigis.complete_mission(rs[2], ghost)
	assert_eq(changed.points.headshots, rs[2].points.headshots - Aigis.DECAY, "decays half a level, no more")
	assert_gt(changed.points.stealth, rs[3].points.stealth)


func test_simulated_light_habits_never_reach_a_level() -> void:
	# One headshot and one spoof a Mission: noticed (points) but never answered.
	var light := {"headshot": 1, "spoof": 1, "quiet_down": 2, "alert": 1, "loud_shot": 1, "spawned": 9}
	var rs := _campaign([light, light, light, light])
	for i in [1, 2, 3]:
		var plan := Aigis.plan_mission(rs[i].points, Aigis.lethality_ratio(rs[i]), i)
		assert_eq(plan.deployed.headshots, 0, "helmets before Mission index %d" % i)
		assert_eq(plan.deployed.spoofing, 0, "Spoofing steps before Mission index %d" % i)


func test_simulated_mercy_and_lethality_pick_three_endings() -> void:
	var base := {"quiet_down": 4, "spawned": 10, "targets": 1}
	var cases := {"pallas": [0, 0], "nike": [3, 0], "gorgo": [3, 1]}  # [kills per Mission, Targets killed]
	for band: String in cases:
		var t := base.duplicate()
		t.kill = cases[band][0]
		t.target_kill = cases[band][1]
		var rs := _campaign([t, t, t, t])
		assert_eq(Aigis.resolve_ending(Aigis.lethality_ratio(rs[4])), band)


# ----- write-up evidence -----

func test_writes_the_preset_by_mission_deployment_tables() -> void:
	var md := _deployment_tables()
	var f := FileAccess.open(TABLES_PATH, FileAccess.WRITE)
	assert_true(f != null, "can't write %s" % TABLES_PATH)
	if f == null:
		return
	f.store_string(md)
	f.close()
	assert_eq(FileAccess.get_file_as_string(TABLES_PATH), md)
	assert_eq(_deployment_tables(), md, "the tables are deterministic")
	assert_contains(md, "| Core | Gorgo | 6 | Combat | vests [Gorgo, pinned]")
	assert_contains(md, "| Mission 1 (Harbour) | Pallas | 0 | none | none |")


func _deployment_tables() -> String:
	var lines := [
		"# Deployment tables",
		"",
		"Generated by `tests/test_aigis.gd` from `ai/aigis.gd`: `plan_mission` for each Preset on each Mission.",
		"Do not edit by hand; rerun the tests after tuning. Each step reads `what [sponsor Voice, score]`, in",
		"deploy order; the pinned Habit's steps come first.",
	]
	for preset: String in Aigis.PRESETS:
		var p: Dictionary = Aigis.PRESETS[preset]
		var levels := []
		for h: String in p.levels:
			levels.append("%s %d" % [h.capitalize(), p.levels[h]])
		var ratio := "undefined" if is_nan(p.ratio) else "%.2f" % p.ratio
		lines.append_array([
			"",
			"## %s" % preset.capitalize(),
			"",
			"Habit levels: %s. Lethality ratio: %s." % [", ".join(levels) if levels else "all 0", ratio],
			"",
			"| Mission | Dominant Voice | Budget | Pinned | Deployed |",
			"|---|---|---|---|---|",
		])
		for i in 4:
			var plan := Aigis.plan_mission(Aigis.preset_profile(preset), p.ratio, i)
			var steps := []
			for pick: Dictionary in plan.picks:
				var why := "pinned" if pick.habit == plan.pinned else "%d" % pick.score
				steps.append("%s [%s, %s]" % [Aigis.LADDERS[pick.habit][pick.level - 1][1], pick.sponsor.capitalize(), why])
			lines.append("| %s | %s | %d | %s | %s |" % [
				MISSION_NAMES[i], plan.dominant.capitalize(), plan.budget,
				plan.pinned.capitalize() if plan.pinned else "none", "; ".join(steps) if steps else "none",
			])
	return "\n".join(lines) + "\n"
