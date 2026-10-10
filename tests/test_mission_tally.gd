@tool
extends McpTestSuite

## Mission tally edges and the post-Mission strip.


func suite_name() -> String:
	return "mission_tally"


func test_alert_counts_once_per_rise() -> void:
	var t := MissionTally.new()
	t.set_alert(true)
	t.set_alert(true)
	t.set_alert(false)
	t.set_alert(true)
	assert_eq(t.counts.alert, 2)


func test_down_is_quiet_only_without_alert() -> void:
	var t := MissionTally.new()
	t.guard_down()
	t.set_alert(true)
	t.guard_down()
	assert_eq(t.counts.quiet_down, 1)


func test_points_feed_aigis() -> void:
	var t := MissionTally.new()
	t.guard_down()
	t.add("headshot", 2)
	var p := t.points()
	assert_eq(p.stealth, 15 + Aigis.NO_ALERT_POINTS)
	assert_eq(p.headshots, 40)


func test_strip_levels_and_arrows() -> void:
	var before := Aigis.new_record()
	before.mission = 1
	before.points.combat = 100
	var after := Aigis.complete_mission(before, {"headshot": 1})
	var s := MissionTally.strip(before, after)
	assert_eq(s.size(), 6)
	assert_eq(s[0].habit, "stealth")
	assert_eq(s[0].arrow, 1)      # no alert: +50 Stealth
	assert_eq(s[1].arrow, -1)     # tug of war took 50 from Combat
	assert_eq(s[2].arrow, 1)
	assert_eq(s[3].arrow, 0)      # unused at 0 points: nothing to decay
	assert_true(s.all(func(e): return e.level >= 0 and e.level <= Aigis.CAPS[2]))


func test_preset_points_cut_by_the_clamp_do_not_show_as_a_fall() -> void:
	var before := Aigis.preset_record("butcher", 0)  # combat and headshots 300: above Mission 1's 199
	var after := Aigis.complete_mission(before, {"alert": 1, "headshot": 1})
	var s := MissionTally.strip(before, after)
	assert_eq(s[1].arrow, 0)   # combat 300 -> 199: the clamp, not the player
	assert_eq(s[2].arrow, 0)   # headshots likewise
	assert_eq(s[3].arrow, -1)  # takedowns 100 -> 50: a real decay still shows


func test_strip_uses_the_clamps_cap_so_mission_1_shows_at_most_level_1() -> void:
	var before := Aigis.new_record()
	var after := Aigis.complete_mission(before, {"alert": 3, "headshot": 5, "spoof": 20})
	var s := MissionTally.strip(before, after)
	assert_eq(s[2].level, 1)  # 100 Headshot points: L1, which Mission 2 answers
	assert_eq(s[5].level, 1)  # 400 Spoofing points, held to 199
	assert_true(s.all(func(e): return e.level <= 1))
