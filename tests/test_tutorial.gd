@tool
extends McpTestSuite

## Mission 1's tutorial: each verb's tip shows once, the first time it is relevant in the Encounter that
## teaches it, only in the campaign's Mission 1; a verb done unprompted is spent; the Harbour has an
## eavesdrop spot beside a guard's check-in route.

const NOTHING := {}


func suite_name() -> String:
	return "tutorial"


func _world(over := {}) -> Dictionary:
	var w := {guard = INF, down = INF, spot = INF, holdup = INF, fulton = false, enc = 1}
	w.merge(over, true)
	return w


func test_a_guard_nearby_teaches_crouch_first() -> void:
	var t := Tutorial.new()
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 10.0}))), "crouch")


func test_nothing_relevant_nothing_shown() -> void:
	var t := Tutorial.new()
	assert_eq(t.update(0, true, Tutorial.relevant(_world())), "")


func test_each_tip_shows_once_and_the_next_follows_without_a_timer() -> void:
	var t := Tutorial.new()
	var near := Tutorial.relevant(_world({guard = 3.0}))
	assert_eq(t.update(0, true, near), "crouch")
	assert_eq(t.update(0, true, near), "takedown", "crouch is spent, the next verb follows")
	assert_eq(t.update(0, true, near), "")


func test_each_encounter_teaches_only_its_verbs() -> void:
	assert_true(Tutorial.relevant(_world({guard = 3.0})).takedown, "the deck teaches the takedown")
	assert_false(Tutorial.relevant(_world({guard = 3.0, enc = 2})).takedown, "not in the yard")
	assert_false(Tutorial.relevant(_world({holdup = 10.0})).holdup, "no Hold-up tip on the deck")
	assert_true(Tutorial.relevant(_world({holdup = 10.0, enc = 2})).holdup, "the yard teaches the Hold-up")
	assert_false(Tutorial.relevant(_world({fulton = true})).fulton, "no Fulton tip on the deck")
	assert_true(Tutorial.relevant(_world({fulton = true, enc = 2})).fulton)
	for over in [{guard = 3.0}, {down = 1.0}, {spot = 1.0}, {holdup = 1.0}, {fulton = true}]:
		over.enc = 3
		assert_false(Tutorial.relevant(_world(over)).values().has(true), "no tips in Operations: %s" % [over])
		over.enc = 0
		assert_false(Tutorial.relevant(_world(over)).values().has(true), "none between Encounters: %s" % [over])


func test_every_verb_is_tipped_by_one_encounter_or_is_line_only() -> void:
	var tipped := []
	for enc: int in Tutorial.BY_ENCOUNTER:
		tipped.append_array(Tutorial.BY_ENCOUNTER[enc])
	tipped.append_array(Tutorial.LINE_ONLY)
	tipped.sort()
	var all := Tutorial.VERBS.duplicate()
	all.sort()
	assert_eq(tipped, all)
	var cases := {crouch = {guard = 10.0}, takedown = {guard = 3.0}, carry = {down = 1.5}, eavesdrop = {spot = 4.0},
		holdup = {holdup = 10.0, enc = 2}, fulton = {fulton = true, enc = 2}}
	for verb: String in cases:
		assert_true(Tutorial.relevant(_world(cases[verb]))[verb], verb)


func test_a_verb_done_unprompted_never_gets_its_tip() -> void:
	var t := Tutorial.new()
	assert_eq(t.done("takedown", 0, true), "", "a tipped verb gets no line when done")
	var near := Tutorial.relevant(_world({guard = 3.0}))
	assert_eq(t.update(0, true, near), "crouch")
	assert_eq(t.update(0, true, near), "", "takedown was already done")


func test_a_line_only_verb_gets_metis_once_on_first_use() -> void:
	var t := Tutorial.new()
	assert_eq(t.done("tranq", 0, true), "tranq")
	assert_eq(t.done("tranq", 0, true), "", "once")
	assert_eq(Tutorial.new().done("tranq", 1, true), "", "Mission 2")
	assert_eq(Tutorial.new().done("radio", 0, false), "", "Free mode")


func test_only_the_campaigns_mission_1_teaches() -> void:
	var near := Tutorial.relevant(_world({guard = 3.0}))
	assert_eq(Tutorial.new().update(1, true, near), "", "Mission 2")
	assert_eq(Tutorial.new().update(0, false, near), "", "Free mode")


func test_every_verb_has_a_prompt_and_a_metis_line_in_both_languages() -> void:
	for lang in ["en", "es"]:
		TranslationServer.set_locale(lang)
		for verb: String in Tutorial.VERBS:
			for key: String in [Tutorial.prompt_key(verb), Tutorial.line_key(verb)]:
				assert_ne(tr(key), key, key + " " + lang)
	TranslationServer.set_locale("en")


func test_harbour_has_an_eavesdrop_spot_near_a_check_in_route() -> void:
	var h: Node = load("res://areas/harbour/harbour.tscn").instantiate()
	var spots := h.find_children("*", "Marker3D", true, false).filter(func(m: Marker3D) -> bool: return m.is_in_group("eavesdrop_spot"))
	assert_eq(spots.size(), 1, "one eavesdrop spot")
	if spots.size() == 1:
		var at: Vector3 = spots[0].position
		var best := INF
		for post: Marker3D in h.get_node("GuardPosts").get_children():
			var points := [post.position]
			for p: Marker3D in post.get_children():
				points.append(post.transform * p.position)
			if points.size() == 1:  # a guard that stands (a chatting pair's post)
				best = minf(best, Vector2(points[0].x - at.x, points[0].z - at.z).length())
			for i in points.size() - 1:  # the route is a polyline the guard walks
				var q := Geometry2D.get_closest_point_to_segment(Vector2(at.x, at.z), Vector2(points[i].x, points[i].z), Vector2(points[i + 1].x, points[i + 1].z))
				best = minf(best, q.distance_to(Vector2(at.x, at.z)))
		assert_true(best < Voiceprints.RANGE, "within Voiceprint range of a guard route point")
	h.free()
