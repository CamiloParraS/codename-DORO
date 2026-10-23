@tool
extends McpTestSuite

## Mission 1's tutorial: each verb's tip shows once, the first time it is relevant, only in the
## campaign's Mission 1; the Harbour has an eavesdrop spot beside a guard's check-in route.

const NOTHING := {}


func suite_name() -> String:
	return "tutorial"


func _world(over := {}) -> Dictionary:
	var w := {guard = INF, down = INF, spot = INF, prints = 0, scanner = 3, magazines = 4, tranq = false}
	w.merge(over, true)
	return w


func test_a_guard_nearby_teaches_crouch_first() -> void:
	var t := Tutorial.new()
	assert_eq(t.update(0.1, 0, true, Tutorial.relevant(_world({guard = 10.0}))), "crouch")


func test_nothing_relevant_nothing_shown() -> void:
	var t := Tutorial.new()
	assert_eq(t.update(0.1, 0, true, Tutorial.relevant(_world())), "")


func test_each_tip_shows_once() -> void:
	var t := Tutorial.new()
	var near := Tutorial.relevant(_world({guard = 3.0}))
	assert_eq(t.update(0.1, 0, true, near), "crouch")
	assert_eq(t.update(Tutorial.GAP + 0.1, 0, true, near), "takedown", "crouch is spent, the next verb follows")
	assert_true(t.seen.has("crouch"))


func test_tips_are_spaced_apart() -> void:
	var t := Tutorial.new()
	var near := Tutorial.relevant(_world({guard = 3.0}))
	t.update(0.1, 0, true, near)
	assert_eq(t.update(1.0, 0, true, near), "", "still in the gap")


func test_every_verb_has_a_trigger() -> void:
	var cases := {
		crouch = {guard = 10.0}, takedown = {guard = 3.0}, carry = {down = 1.5}, tranq = {guard = 10.0, tranq = true},
		eavesdrop = {spot = 4.0}, radio = {prints = 1}, scanner = {guard = 20.0}, magazine = {guard = 8.0},
	}
	assert_eq(cases.keys().map(str), Tutorial.VERBS)
	for verb: String in cases:
		assert_true(Tutorial.relevant(_world(cases[verb]))[verb], verb)
		assert_false(Tutorial.relevant(_world())[verb], verb + " with nothing around")


func test_no_scanner_charges_no_scanner_tip() -> void:
	assert_false(Tutorial.relevant(_world({guard = 20.0, scanner = 0})).scanner)


func test_only_the_campaigns_mission_1_teaches() -> void:
	var near := Tutorial.relevant(_world({guard = 3.0}))
	assert_eq(Tutorial.new().update(0.1, 1, true, near), "", "Mission 2")
	assert_eq(Tutorial.new().update(0.1, 0, false, near), "", "Free mode")


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
