@tool
extends McpTestSuite

## The Dossier: what Aigis keeps to cite back (seen, last), the Briefing's evidence, the Habit the Operative
## dropped, the Voices' dissent, the guards' evidence chatter, the trail and marks, and the save's cleaning.

const CSV := "res://text/lines.csv"
const DIR := "user://test_dossier_slots/"


func suite_name() -> String:
	return "dossier"


func _keys() -> Dictionary:
	var f := FileAccess.open(CSV, FileAccess.READ)
	var t := {}
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() >= 3 and r[0] != "":
			t[r[0]] = r[1]
	return t


func _record(mission: int, points := {}) -> Dictionary:
	var r := Aigis.new_record()
	r.mission = mission
	for h: String in points:
		r.points[h] = points[h]
	return r


# ----- seen and last -----

func test_complete_mission_keeps_the_last_tally_and_sums_the_campaign() -> void:
	var r := Aigis.complete_mission(_record(0), {"headshot": 4, "alert": 1, "spawned": 9})
	r = Aigis.complete_mission(r, {"headshot": 3, "takedown": 2})
	assert_eq(r.last.mission, 1)
	assert_eq(r.last.counts, {"headshot": 3, "takedown": 2}, "only this Mission's events, zeros left out")
	assert_eq(r.seen, {"headshot": 7, "alert": 1, "takedown": 2}, "spawned is not a cited event")


func test_shifted_names_the_strongest_habit_the_mission_earned_nothing_in() -> void:
	var gained := Aigis.mission_points({"alert": 1, "headshot": 2})
	assert_eq(Dossier.shifted({"headshots": 150, "takedowns": 200, "spoofing": 90}, gained), "takedowns")
	assert_eq(Dossier.shifted({"headshots": 150}, gained), "", "still aiming at heads")
	assert_eq(Dossier.shifted({"spoofing": 99}, gained), "", "under a level is not a habit yet")
	var r := Aigis.complete_mission(_record(2, {"combat": 120}), {"quiet_down": 3})
	assert_eq(r.last.shifted, "combat", "a quiet Mission after a loud one")


# ----- evidence -----

func test_evidence_cites_the_last_mission_then_the_campaign_then_nothing() -> void:
	var r := {"last": {"counts": {"headshot": 5}}, "seen": {"headshot": 9, "takedown": 3}}
	assert_eq(Dossier.evidence(r, "headshots"), ["brief.evidence.headshot.last", {n = 5}])
	assert_eq(Dossier.evidence(r, "takedowns"), ["brief.evidence.takedown.total", {n = 3}])
	assert_eq(Dossier.evidence(r, "spoofing"), [])
	r.last.counts = {"headshot": 1}
	assert_eq(Dossier.evidence(r, "headshots"), ["brief.evidence.headshot.total", {n = 9}], "one shot reads as chance")
	assert_eq(Dossier.evidence(Aigis.preset_record("butcher", 3), "combat"), [], "a Preset has no file")


func test_downs_evidence_picks_the_first_event_with_enough() -> void:
	var r := {"last": {"counts": {"fulton": 1, "down_found": 4}}}
	assert_eq(Dossier.evidence(r, "downs")[0], "brief.evidence.down_found.last")


func test_every_evidence_shift_and_dissent_line_is_keyed_with_its_number() -> void:
	var t := _keys()
	for h: String in Dossier.EVIDENCE:
		assert_has_key(t, "brief.pallas.shift." + h)
		for e: String in Dossier.EVIDENCE[h]:
			for when in ["last", "total"]:
				var k := "brief.evidence.%s.%s" % [e, when]
				assert_has_key(t, k)
				assert_true("{n}" in String(t.get(k, "")), k + " shows the count")
		for v in 2:
			assert_true("{n}" in String(t.get(VoiceLines.chatter_key(h, "evidence", v), "")))
		for step: Array in Aigis.LADDERS[h]:
			assert_has_key(t, "brief.%s.dissent.%s" % [step[0], h])
	for k in ["ui.post.saw"] + Dossier.MARKS.map(func(m: String) -> String: return "ui.post.saw." + m):
		assert_has_key(t, k)


# ----- dissent -----

func test_a_close_call_lets_the_outvoted_sponsor_object() -> void:
	var profile := Aigis._level_points({})
	profile.merge({"stealth": 180, "headshots": 120, "downs": 150}, true)
	assert_eq(Aigis.plan_mission(profile, 0.25, 1).dissent, "brief.gorgo.dissent.headshots", "helmets lost 120 to 150")
	assert_eq(Aigis.plan_mission(profile, 0.0, 1).dissent, "", "Pallas doubles the polls: not close")


func test_no_dissent_for_a_step_that_deploys_later_or_with_nothing_to_choose() -> void:
	assert_eq(Aigis.plan_mission(Aigis.preset_profile("clean_slate"), NAN, 3).dissent, "")
	var plan := Aigis.plan_mission(Aigis.preset_profile("ghost"), 0.0, 3)  # the budget covers every unlocked step
	for p: Dictionary in plan.picks:
		for c: Dictionary in p.candidates:
			if plan.dissent == "brief.%s.dissent.%s" % [c.sponsor, c.habit]:
				assert_true(plan.deployed[c.habit] < c.level, "the objection is to a step left out")


func test_every_dissent_plan_mission_can_produce_is_keyed() -> void:
	var t := _keys()
	var seen := 0
	for ratio in [NAN, 0.2, 0.6]:
		for m in 4:
			for a: String in Aigis.HABITS:  # three Habits at a level, more steps than Mission 2's budget
				for b: String in Aigis.HABITS:
					for c: String in Aigis.HABITS:
						if a == b or b == c or a == c:
							continue
						var p := Aigis._level_points({})
						p.merge({a: 290, b: 180, c: 150}, true)
						var d: String = Aigis.plan_mission(p, ratio, m).dissent
						if d != "":
							seen += 1
							assert_has_key(t, d)
	assert_gt(seen, 10)


# ----- chatter -----

func test_guards_cite_the_last_mission_for_a_deployed_habit() -> void:
	var points := Aigis._level_points({"headshots": 1})
	var deployed := {"headshots": 1}
	var rec := {"last": {"counts": {"headshot": 6, "takedown": 9}}}
	assert_eq(VoiceLines.chatter_sets(points, deployed, rec), [["headshots", "confirm"], ["headshots", "evidence", 6]],
		"takedowns not deployed: nothing to confirm, so nothing to cite")
	var line := VoiceLines.pick_line([["headshots", "evidence", 6]], RandomNumberGenerator.new())
	assert_true(line[0].begins_with("chatter.evidence.headshots."))
	assert_eq(line[1], {n = 6})
	assert_eq(VoiceLines.pick_line([], RandomNumberGenerator.new()), ["", {}])


# ----- trail -----

func test_the_log_keeps_a_path_and_marks_where_things_happened() -> void:
	var l := SessionLog.new()
	l.start_mission(1)
	for i in 10:
		l.place(Vector3(i, 2 * i, 0), 1)
		l.tick(1.0, false)
	l.mark("down", Vector2(50, 60))
	l.spotted("Kostas", "?")
	l.spotted("Dimos", "?")  # only the first counts
	l.alert(1)
	var m: Dictionary = l.missions[0]
	assert_eq(m.path.size(), 5, "one point per PATH_EVERY s")
	assert_eq(m.path[1], Vector2(2, 4))
	assert_eq(m.marks.map(func(k: Array) -> String: return k[0]), ["down", "spotted", "alert"])
	assert_eq(m.marks[1][2], Vector2(9, 18), "where the Operative last stood")


func test_trail_thins_a_long_path_for_the_save() -> void:
	var pts := []
	for i in Dossier.MAX_PATH * 2 + 1:
		pts.append(Vector2(i * 0.123, 1.0))
	var t := Dossier.trail({path = pts, marks = [["kill", 3.02, Vector2(1.49, 2.0)]]})
	assert_true(t.path.size() / 2.0 <= Dossier.MAX_PATH)
	assert_eq(t.every, SessionLog.PATH_EVERY * 3)
	assert_eq(t.marks, [["kill", 3.0, 1.5, 2.0]], "rounded to 0.1 m")


# ----- save -----

func test_a_slot_round_trips_the_dossier_and_drops_a_bad_one() -> void:
	var r := Aigis.complete_mission(_record(0), {"headshot": 4})
	r.last.merge(Dossier.trail({path = [Vector2(1, 2), Vector2(3, 4)], marks = [["alert", 2.0, Vector2(3, 4)]]}))
	DirAccess.make_dir_recursive_absolute(DIR)
	SaveSlots.write(0, r, 10, DIR)
	var back: Dictionary = SaveSlots.read(0, DIR).record
	assert_eq(back.seen, {"headshot": 4})
	assert_eq(back.last.counts, {"headshot": 4})
	assert_eq(back.last.path, [1.0, 2.0, 3.0, 4.0])
	assert_eq(back.last.marks, [["alert", 2.0, 3.0, 4.0]])
	assert_eq(Dossier.clean_last({"mission": 1.0, "path": [1.0, "x"]}).has("path"), false, "a bad path is dropped")
	assert_eq(Dossier.clean_last({"mission": 1.0, "path": [1.0, 2.0], "marks": [["nuke", 1.0, 1.0, 1.0]]}).marks, [])
	assert_eq(Dossier.clean_last("x"), {})
	assert_eq(Dossier.clean_seen({"headshot": -2.0, "bogus": 3.0, "spoof": 2.0}), {"spoof": 2})
	DirAccess.remove_absolute(SaveSlots.path(0, DIR))


# ----- floor plan -----

func test_floor_plan_fills_the_navmesh_and_outlines_only_its_edge() -> void:
	# two triangles sharing the 1-2 edge make a 2 x 2 m square at the diagram origin
	var verts := PackedVector3Array([Vector3(-40, 0, -40), Vector3(-38, 0, -40), Vector3(-40, 0, -38), Vector3(-38, 0, -38)])
	var polys: Array[PackedInt32Array] = [PackedInt32Array([0, 1, 2]), PackedInt32Array([1, 3, 2])]
	var plan := FloorPlan.from_mesh(verts, polys)
	assert_eq(plan.tris.size(), 6, "two triangles, one fill")
	assert_eq(plan.edges.size(), 8, "four outline edges: the shared diagonal is left out")
	assert_eq(plan.lo, Vector2.ZERO)
	assert_eq(plan.hi, Vector2(2, 2))
	assert_eq(FloorPlan.from_mesh(PackedVector3Array(), []), {})
	assert_eq(FloorPlan.of_area(null), {})


# ----- the bet, the callsign and the hotspot -----

func _last(counts: Dictionary) -> Dictionary:
	var r := _record(1)
	r.last = {mission = 0, counts = counts, shifted = ""}
	return r


func test_aigis_bets_on_what_the_operative_did_most_last_time() -> void:
	assert_eq(Dossier.bet(_record(0)), {}, "no last Mission: nothing to bet on")
	assert_eq(Dossier.bet(_last({"takedown": 4, "headshot": 2})), {event = "takedown", n = 3, most = false}, "3/4 of 4, rounded up")
	assert_eq(Dossier.bet(_last({"takedown": 2, "headshot": 2})), {event = "takedown", n = 2, most = false}, "a tie goes to BET_EVENTS order")
	assert_eq(Dossier.bet(_last({"spoof": 1})), {event = "alert", n = 0, most = true}, "nothing citable and no alarm: no alarm again")
	assert_eq(Dossier.bet(_last({"alert": 1})), {}, "one alarm is nothing to bet on")


func test_a_settled_bet_says_what_the_operative_gave() -> void:
	assert_eq(Dossier.settle({}, {"takedown": 9}), {})
	assert_true(Dossier.settle({event = "takedown", n = 3, most = false}, {"takedown": 3}).won)
	assert_false(Dossier.settle({event = "takedown", n = 3, most = false}, {"takedown": 2}).won)
	assert_true(Dossier.settle({event = "alert", n = 0, most = true}, {}).won, "a ceiling of 0 and no alarm")
	var s := Dossier.settle({event = "alert", n = 0, most = true}, {"alert": 2})
	assert_eq([s.got, s.won], [2, false])


func test_complete_mission_settles_the_bet_and_files_the_old_callsign() -> void:
	var r := Aigis.complete_mission(_record(0), {"takedown": 4, "spawned": 9})
	assert_eq(r.last.bet, {}, "Mission 1 had no bet")
	assert_eq(r.last.called, "callsign.none")
	r = Aigis.complete_mission(r, {"takedown": 1, "spawned": 9})
	assert_eq(r.last.bet, {event = "takedown", n = 3, most = false, got = 1, won = false})
	assert_eq(r.last.called, "callsign.takedowns", "what Aigis called the Operative going into Mission 2")


func test_the_callsign_is_the_top_habit_or_the_butcher() -> void:
	assert_eq(Dossier.callsign(_record(1)), "callsign.none")
	assert_eq(Dossier.callsign(_record(1, {"headshots": 40, "takedowns": 60})), "callsign.takedowns")
	assert_eq(Dossier.callsign(_record(1, {"headshots": 50, "takedowns": 50})), "callsign.headshots", "ties in Habit order")
	var r := _record(1, {"stealth": 90})
	r.lethality = 5
	r.denominator = 10
	assert_eq(Dossier.callsign(r), "callsign.butcher", "Gorgo's band outranks any Habit")


func test_the_hotspot_is_the_encounter_with_the_most_downs() -> void:
	var enc := func(p: Vector2) -> int: return 1 if p.x < 10 else 2
	var marks := [["down", 10.0, Vector2(1, 0)], ["kill", 40.0, Vector2(2, 0)], ["down", 50.0, Vector2(20, 0)],
		["alert", 60.0, Vector2(21, 0)], ["spotted", 61.0, Vector2(21, 0)], ["down", 99.0, Vector2(3, 0)]]
	assert_eq(Dossier.hotspot(marks, enc), {enc = 1, n = 3, secs = 89}, "alerts and spottings aren't the Operative's work")
	assert_eq(Dossier.hotspot([["down", 1.0, Vector2(1, 0)]], enc), {}, "one down is chance")
	assert_eq(Dossier.hotspot([["down", 1.0, Vector2(1, 0)], ["down", 2.0, Vector2(1, 0)]], func(_p: Vector2) -> int: return 0), {}, "outside every Encounter")


func test_a_slot_keeps_the_bet_callsign_and_hotspot_and_drops_bad_ones() -> void:
	var good := {"mission": 1.0, "bet": {"event": "takedown", "n": 3.0, "most": false, "got": 4.0, "won": true},
		"called": "callsign.takedowns", "hot": {"enc": 2.0, "n": 4.0, "secs": 90.0}}
	var c := Dossier.clean_last(good)
	assert_eq(c.bet, {event = "takedown", n = 3, most = false, got = 4, won = true})
	assert_eq(c.called, "callsign.takedowns")
	assert_eq(c.hot, {enc = 2, n = 4, secs = 90})
	var bad := Dossier.clean_last({"mission": 1.0, "bet": {"event": "nuke", "n": 3.0, "most": false, "got": 4.0, "won": true},
		"called": "callsign.god", "hot": {"enc": "x"}})
	assert_eq([bad.has("bet"), bad.has("called"), bad.has("hot")], [false, false, false])


func test_every_new_dossier_line_has_text() -> void:
	var t := _keys()
	for e: String in Dossier.BET_EVENTS:
		assert_true(t.has("bet." + e), e)
	assert_true(t.has("bet.alert.most"))
	for h: String in Aigis.HABITS + Dossier.CALLSIGNS:
		assert_true(t.has("callsign." + h), h)
	for v: String in ["pallas", "nike", "gorgo"]:
		for k: String in ["bet", "bet.won", "bet.lost"]:
			assert_true(t.has("brief.%s.%s" % [v, k]), "%s %s" % [v, k])
	for m: int in Campaign.MISSIONS.size():
		for e: int in range(1, Campaign.MISSIONS[m].encounters + 1):
			assert_true(t.has("place.%d.%d" % [m, e]), "place %d %d" % [m, e])
	for k: String in ["brief.pallas.callsign", "brief.pallas.callsign.renamed", "brief.pallas.hot.s", "brief.pallas.hot.m", "caught.contact"]:
		assert_true(t.has(k), k)
