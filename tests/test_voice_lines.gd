@tool
extends McpTestSuite

## Voice lines: every key Aigis can speak exists in both languages; the post-Mission line by band and
## Lethality; the guards' warning / confirmation chatter.

const CSV := "res://text/lines.csv"


func suite_name() -> String:
	return "voice_lines"


func _keys() -> Dictionary:
	var f := FileAccess.open(CSV, FileAccess.READ)
	f.get_csv_line()
	var t := {}
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() >= 3 and r[0] != "":
			t[r[0]] = true
	return t


func _points(levels: Dictionary) -> Dictionary:
	return Aigis._level_points(levels)


# ----- briefing -----

func test_every_briefing_key_plan_mission_can_produce_is_keyed() -> void:
	var t := _keys()
	var seen := 0
	for ratio in [NAN, 0.0, 0.2, 0.6]:
		for m in 4:
			for h in Aigis.HABITS:
				for lvl in 4:
					var plan := Aigis.plan_mission(_points({h: lvl, "stealth": 3, "takedowns": 3, "combat": 3, "spoofing": 1}), ratio, m)
					for k: String in plan.briefing_keys:
						seen += 1
						assert_has_key(t, k)
	assert_gt(seen, 100)


func test_every_ladder_hint_is_keyed() -> void:
	var t := _keys()
	for h: String in Aigis.HABITS:
		assert_has_key(t, "brief.pallas.habit." + h)
		for i in 3:
			assert_has_key(t, "brief.%s.hint.%s.%d" % [Aigis.LADDERS[h][i][0], h, i + 1])


func test_mission_one_gets_only_the_close() -> void:
	var plan := Aigis.plan_mission(_points({"stealth": 3}), NAN, 0)
	assert_eq(plan.briefing_keys, ["brief.pallas.close"])


# ----- post-Mission -----

func test_post_mission_line_by_band_and_lethality() -> void:
	var t := _keys()
	for band in ["pallas", "nike", "gorgo"]:
		for zero in [true, false]:
			var k := VoiceLines.post_key(band, zero)
			assert_has_key(t, k)
	assert_ne(VoiceLines.post_key("nike", true), VoiceLines.post_key("nike", false))
	assert_ne(VoiceLines.post_key("nike", true), VoiceLines.post_key("gorgo", true))


func test_lethality_zero_means_no_kill_this_mission() -> void:
	assert_true(VoiceLines.lethality_zero({"kill": 0, "spawned": 9}))
	assert_false(VoiceLines.lethality_zero({"kill": 1}))
	assert_false(VoiceLines.lethality_zero({"target_kill": 1}))


# ----- chatter -----

func test_warns_at_fifty_points_before_a_level_and_confirms_once_deployed() -> void:
	assert_eq(VoiceLines.chatter_state(49, 0), "")
	assert_eq(VoiceLines.chatter_state(50, 0), "warn")
	assert_eq(VoiceLines.chatter_state(99, 0), "warn")
	assert_eq(VoiceLines.chatter_state(100, 1), "confirm")
	assert_eq(VoiceLines.chatter_state(0, 1), "confirm")


func test_two_variants_per_set_all_keyed() -> void:
	var t := _keys()
	for h: String in Aigis.HABITS:
		for s in ["warn", "confirm"]:
			var ks := {}
			for v in 2:
				var k := VoiceLines.chatter_key(h, s, v)
				assert_has_key(t, k)
				ks[k] = true
			assert_eq(ks.size(), 2, "%s %s needs 2 distinct variants" % [h, s])


func test_chatter_sets_lists_only_habits_with_something_to_say() -> void:
	var points := _points({})
	points.combat = 60
	points.stealth = 120
	var deployed: Dictionary = Aigis.plan_mission(points, NAN, 1).deployed
	var sets := VoiceLines.chatter_sets(points, deployed)
	assert_eq(sets, [["stealth", "confirm"], ["combat", "warn"]])


func test_guard_picks_a_keyed_line_from_its_sets() -> void:
	var rng := RandomNumberGenerator.new()
	var seen := {}
	for i in 40:
		seen[VoiceLines.pick([["combat", "warn"]], rng)] = true
	assert_eq(seen.size(), 2)
	assert_eq(VoiceLines.pick([], rng), "")


func test_heard_only_within_hearing_range() -> void:
	assert_true(VoiceLines.heard(Chat.HEARD))
	assert_false(VoiceLines.heard(Chat.HEARD + 0.1))
