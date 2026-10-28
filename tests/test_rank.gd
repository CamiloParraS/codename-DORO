@tool
extends McpTestSuite

## Rank (pw-feel 04): the grade from the run-wide counters, par, the bonuses, and the Mission Record's
## four independent bests. Node-free.

const PAR := 360.0


func suite_name() -> String:
	return "rank"


func teardown() -> void:
	Campaign.start()


func _run(kills := 0, alerts := 0, found := 0, continues := 0, seconds := 100.0) -> Rank:
	var r := Rank.new()
	r.kills = kills
	r.alerts = alerts
	r.found = found
	r.continues = continues
	r.seconds = seconds
	return r


func test_a_clean_run_within_par_is_s() -> void:
	assert_eq(_run().grade(PAR), "S")
	assert_eq(_run(0, 0, 1).grade(PAR), "S", "one Down guard found is allowed")


func test_one_alert_is_a_two_is_b_and_a_kill_is_c() -> void:
	assert_eq(_run(0, 1).grade(PAR), "A")
	assert_eq(_run(0, 2).grade(PAR), "B")
	assert_eq(_run(1).grade(PAR), "C")
	assert_eq(_run(3, 5, 4, 6, 9999.0).grade(PAR), "C")


func test_over_par_drops_one_letter() -> void:
	assert_eq(_run(0, 0, 0, 0, PAR + 1).grade(PAR), "A")
	assert_eq(_run(0, 1, 0, 0, PAR + 1).grade(PAR), "B")
	assert_eq(_run(0, 0, 0, 0, PAR).grade(PAR), "S", "par itself is within par")


func test_each_continue_drops_a_letter_but_never_below_b() -> void:
	assert_eq(_run(0, 0, 0, 1).grade(PAR), "A")
	assert_eq(_run(0, 0, 0, 2).grade(PAR), "B")
	assert_eq(_run(0, 0, 0, 5).grade(PAR), "B")


func test_two_found_drop_a_letter_from_s_or_a() -> void:
	assert_eq(_run(0, 0, 2).grade(PAR), "A")
	assert_eq(_run(0, 1, 2).grade(PAR), "B")
	assert_eq(_run(0, 2, 3).grade(PAR), "B")


func test_par_is_two_minutes_an_encounter() -> void:
	assert_eq(Rank.par(0), 360.0, "the Harbour: three Encounters")
	for m in Campaign.MISSIONS.size():
		assert_eq(Rank.par(m), 120.0 * Campaign.MISSIONS[m].encounters)


func test_bonuses() -> void:
	assert_eq(_run().bonuses(), ["NO TRACES", "NO KILLS"])
	assert_eq(_run(0, 0, 1).bonuses(), ["NO KILLS"], "a found guard is a trace")
	assert_eq(_run(1, 0, 0).bonuses(), ["NO TRACES"])
	assert_eq(_run(1, 1).bonuses(), [])


func test_the_mission_record_keeps_four_independent_bests() -> void:
	var first := Rank.best({}, {rank = "B", time = 300.0, kills = 0, alerts = 2})
	assert_eq(first, {rank = "B", time = 300.0, kills = 0, alerts = 2})
	var r := Rank.best(first, {rank = "C", time = 200.0, kills = 4, alerts = 1})
	assert_eq(r, {rank = "B", time = 200.0, kills = 0, alerts = 1})
	r = Rank.best(r, {rank = "S", time = 400.0, kills = 0, alerts = 0})
	assert_eq(r, {rank = "S", time = 200.0, kills = 0, alerts = 0})


func test_a_first_clear_stores_the_pre_mission_profile_and_a_replay_keeps_it() -> void:
	var pre := Aigis.new_record()
	pre.points.stealth = 40
	assert_false(Campaign.commit_record(0, pre, {rank = "A", time = 300.0, kills = 0, alerts = 1}))
	var later := pre.duplicate(true)
	later.points.stealth = 400
	assert_true(Campaign.commit_record(0, later, {rank = "S", time = 350.0, kills = 0, alerts = 0}), "first S on Mission 1")
	assert_eq(Campaign.missions["0"].pre, pre, "the pre-Mission Profile is the first clear's")
	assert_eq(Campaign.missions["0"].best.rank, "S")
	assert_false(Campaign.commit_record(0, pre, {rank = "S", time = 340.0, kills = 0, alerts = 0}), "a second S is not a first")


func test_the_post_mission_screen_is_rank_then_aigis_and_replays_stop_at_rank() -> void:
	for rank_only in [false, true]:
		var s: Control = preload("res://ui/post_mission/post_mission.gd").new()
		s.rank_only = rank_only
		var commits := [0]
		s.committed.connect(func() -> void: commits[0] += 1)
		s.advance()
		assert_eq(commits[0], 1 if rank_only else 0)
		if not rank_only:
			assert_eq(s.page, 1, "page 2: AIGIS HAS LEARNED")
			s.advance()
			assert_eq(commits[0], 1)
		assert_true(s.is_queued_for_deletion(), "committing frees the screen")


func test_every_letter_has_a_codename() -> void:
	for l in Rank.LETTERS:
		assert_true(Rank.TITLES.has(l), "codename for " + l)
