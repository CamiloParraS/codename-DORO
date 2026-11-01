@tool
extends McpTestSuite

## Mission 1's tutorial: each verb's tip shows once, the first time it is relevant in the Encounter that
## teaches it, only in the campaign's Mission 1, one at a time (it stays until done or WAIT_MAX, the next follows a
## BEAT after it is done, never before MIN_SHOW), paced by place, the Hold-up before the magazine, the Scanner last; a verb done unprompted is spent;
## the first sighting on the deck is a lesson with a grace; the Harbour has an eavesdrop spot beside a guard's
## check-in route.

const NOTHING := {}


func suite_name() -> String:
	return "tutorial"


func _world(over := {}) -> Dictionary:
	var w := {guard = INF, down = INF, spot = INF, holdup = INF, fulton = false, enc = 1}
	w.merge(over, true)
	return w


## Does `verb` the moment its tip shows, then lets the beat pass: the next tip may come.
func _do(t: Tutorial, verb: String) -> void:
	t.done(verb, 0, true)
	t.update(0, true, {}, maxf(Tutorial.MIN_SHOW, Tutorial.BEAT))


func test_the_start_teaches_aiming_then_crouch_then_switching_weapons() -> void:
	var t := Tutorial.new()
	var start := Tutorial.relevant(_world({guard = 19.0}))
	assert_eq(t.update(0, true, start), "tranq", "O1 in view from the start: no walking up to him first")
	_do(t, "tranq")
	assert_eq(t.update(0, true, start), "crouch")
	_do(t, "crouch")
	assert_eq(t.update(0, true, start), "weapons")
	_do(t, "weapons")
	assert_eq(t.update(0, true, start), "", "nothing else from the start: the magazine waits until he is close")


func test_closing_on_a_guard_teaches_the_holdup_then_the_magazine_then_up_close_the_takedown() -> void:
	var t := Tutorial.new()
	for v in ["tranq", "crouch", "weapons"]:
		t.done(v, 0, true)
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 12.0}))), "", "the magazine waits for the Hold-up")
	var closing := Tutorial.relevant(_world({guard = 8.0}))
	assert_eq(t.update(0, true, closing), "holdup")
	_do(t, "holdup")
	assert_eq(t.update(0, true, closing), "magazine")
	_do(t, "magazine")
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 3.0}))), "takedown")


func test_a_tip_stays_until_done_then_the_next_follows_a_beat_later() -> void:
	var t := Tutorial.new()
	var near := Tutorial.relevant(_world({guard = 19.0}))
	assert_eq(t.update(0, true, near), "tranq")
	assert_eq(t.update(0, true, near, Tutorial.WAIT_MAX / 2.0), "", "not done: it stays up")
	assert_false(t.cleared())
	t.done("tranq", 0, true)
	assert_true(t.cleared(), "done: the HUD fades it")
	assert_false(t.cleared(), "once")
	assert_eq(t.update(0, true, near, Tutorial.BEAT - 0.1), "", "a beat before the next")
	assert_eq(t.update(0, true, near, 0.1), "crouch")


func test_a_tip_done_at_once_is_still_up_for_min_show() -> void:
	var t := Tutorial.new()
	var near := Tutorial.relevant(_world({guard = 19.0}))
	assert_eq(t.update(0, true, near), "tranq")
	t.done("tranq", 0, true)
	assert_eq(t.update(0, true, near, Tutorial.BEAT), "", "the beat is over but the tip was barely up")
	assert_eq(t.update(0, true, near, Tutorial.MIN_SHOW - Tutorial.BEAT), "crouch")


func test_a_tip_never_done_gives_way_after_wait_max() -> void:
	var t := Tutorial.new()
	var near := Tutorial.relevant(_world({guard = 19.0}))
	assert_eq(t.update(0, true, near), "tranq")
	assert_eq(t.update(0, true, near, Tutorial.WAIT_MAX), "crouch", "the player who never fires still gets the next tip")


func test_the_scanner_comes_last_once_the_eavesdrop_is_spent() -> void:
	var t := Tutorial.new()
	for v in ["tranq", "crouch", "weapons", "magazine", "takedown", "carry"]:
		t.done(v, 0, true)
	var deck := Tutorial.relevant(_world({guard = 19.0}))
	assert_eq(t.update(0, true, deck), "", "no Scanner tip before the smoke break")
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 19.0, spot = 4.0}))), "eavesdrop")
	_do(t, "eavesdrop")
	assert_eq(t.update(0, true, deck), "scanner", "the exits are watched: now the Scanner")
	var left := Tutorial.new()
	left.done("eavesdrop", 0, true)
	assert_eq(left.update(0, true, Tutorial.relevant(_world({guard = 19.0, enc = 2}))), "scanner", "off the ship without it: in the yard")


func test_the_holdup_cuts_in_on_the_first_guard_and_the_tip_it_cut_off_comes_back() -> void:
	var t := Tutorial.new()
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 19.0}))), "tranq")
	var closing := Tutorial.relevant(_world({guard = 8.0}))
	assert_eq(t.update(0, true, closing, 1.0), "", "not before the aim tip has had MIN_SHOW")
	assert_eq(t.update(0, true, closing, Tutorial.MIN_SHOW), "holdup", "closing on O1: the chance is now")
	t.done("holdup", 0, true)
	assert_eq(t.update(0, true, closing, Tutorial.MIN_SHOW), "tranq", "the aim tip comes back")


func test_a_tip_done_before_the_cut_does_not_come_back() -> void:
	var t := Tutorial.new()
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 19.0}))), "tranq")
	t.done("tranq", 0, true)
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 8.0})), Tutorial.MIN_SHOW), "holdup")
	t.done("holdup", 0, true)
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 19.0})), Tutorial.MIN_SHOW), "crouch", "not the aim tip again")


func test_nothing_relevant_nothing_shown() -> void:
	var t := Tutorial.new()
	assert_eq(t.update(0, true, Tutorial.relevant(_world())), "")


func test_carry_waits_until_a_way_to_put_a_guard_down_was_spent() -> void:
	var t := Tutorial.new()
	var body := Tutorial.relevant(_world({down = 1.0}))
	assert_eq(t.update(0, true, body), "", "no carry tip before the takedown or a tranq")
	t.done("tranq", 0, true)
	assert_eq(t.update(0, true, body), "carry")


func test_each_encounter_teaches_only_its_verbs() -> void:
	assert_true(Tutorial.relevant(_world({guard = 3.0})).takedown, "the deck teaches the takedown")
	assert_false(Tutorial.relevant(_world({guard = 3.0, enc = 2})).takedown, "not in the yard")
	assert_false(Tutorial.relevant(_world({guard = 3.0, enc = 2})).magazine, "nor the magazine")
	assert_true(Tutorial.relevant(_world({guard = 8.0})).holdup, "the deck teaches the Hold-up on any guard close by")
	assert_false(Tutorial.relevant(_world({guard = 8.0, enc = 2})).holdup, "in the yard only the Foreman")
	assert_true(Tutorial.relevant(_world({holdup = 10.0, enc = 2})).holdup, "the yard teaches it on him if the deck did not")
	assert_false(Tutorial.relevant(_world({fulton = true})).fulton, "no Fulton tip on the deck")
	assert_true(Tutorial.relevant(_world({fulton = true, enc = 2})).fulton)
	for over in [{guard = 3.0}, {down = 1.0}, {spot = 1.0}, {holdup = 1.0}, {fulton = true}]:
		over.enc = 3
		assert_false(Tutorial.relevant(_world(over)).values().has(true), "no tips in Operations: %s" % [over])
		over.enc = 0
		assert_false(Tutorial.relevant(_world(over)).values().has(true), "none between Encounters: %s" % [over])


func test_every_verb_is_tipped_by_an_encounter_or_is_line_only() -> void:
	var tipped := {}
	for enc: int in Tutorial.BY_ENCOUNTER:
		for v: String in Tutorial.BY_ENCOUNTER[enc]:
			tipped[v] = true
	for v: String in Tutorial.LINE_ONLY:
		tipped[v] = true
	var got := tipped.keys()
	got.sort()
	var all := Tutorial.VERBS.duplicate()
	all.sort()
	assert_eq(got, all)
	var cases := {tranq = {guard = 20.0}, crouch = {guard = 20.0}, weapons = {guard = 20.0}, magazine = {guard = 12.0},
		takedown = {guard = 3.0}, carry = {down = 1.5}, eavesdrop = {spot = 4.0}, scanner = {guard = 20.0},
		holdup = {guard = 8.0}, fulton = {fulton = true, enc = 2}}
	for verb: String in cases:
		assert_true(Tutorial.relevant(_world(cases[verb]))[verb], verb)


func test_a_verb_done_unprompted_never_gets_its_tip() -> void:
	var t := Tutorial.new()
	assert_eq(t.done("crouch", 0, true), "", "a tipped verb gets no line when done")
	t.done("tranq", 0, true)
	assert_eq(t.update(0, true, Tutorial.relevant(_world({guard = 19.0}))), "weapons", "crouch was already done: straight to the next")


func test_a_line_only_verb_gets_metis_once_on_first_use() -> void:
	var t := Tutorial.new()
	assert_eq(t.done("radio", 0, true), "radio")
	assert_eq(t.done("radio", 0, true), "", "once")
	assert_eq(Tutorial.new().done("radio", 1, true), "", "Mission 2")
	assert_eq(Tutorial.new().done("caution", 0, false), "", "Free mode")


func test_only_the_campaigns_mission_1_teaches() -> void:
	var near := Tutorial.relevant(_world({guard = 3.0}))
	assert_eq(Tutorial.new().update(1, true, near), "", "Mission 2")
	assert_eq(Tutorial.new().update(0, false, near), "", "Free mode")
	assert_eq(Tutorial.new().sighted(1, true, 1, true), "", "no sighting lesson in Mission 2")
	assert_eq(Tutorial.new().sight_scale(0, false, 1), 1.0, "nor a grace in Free mode")


func test_the_first_sighting_on_the_deck_is_a_lesson_with_a_grace() -> void:
	var t := Tutorial.new()
	assert_eq(t.sight_scale(0, true, 1), Tutorial.GRACE, "the deck fills slower at first")
	assert_eq(t.sight_scale(0, true, 2), 1.0, "only the deck")
	assert_eq(t.sighted(0, true, 2, true), "", "a sighting in the yard teaches nothing")
	assert_eq(t.sighted(0, true, 1, true), Tutorial.SPOTTED, "the first one on the deck does")
	assert_eq(t.sighted(0, true, 1, true), "", "once")
	assert_eq(t.sight_scale(0, true, 1), Tutorial.GRACE, "the grace holds while he is still seen")
	t.sighted(0, true, 1, false)
	assert_eq(t.sight_scale(0, true, 1), 1.0, "and ends once the sighting is over")
	assert_true(t.cleared(), "its tip fades once the sighting is over")
	assert_eq(t.sighted(0, true, 1, true), "", "never again")


func test_the_sighting_tip_takes_the_screen_and_the_next_waits_until_it_is_shaken_off() -> void:
	var t := Tutorial.new()
	var near := Tutorial.relevant(_world({guard = 19.0}))
	assert_eq(t.update(0, true, near), "tranq")
	assert_eq(t.sighted(0, true, 1, true), Tutorial.SPOTTED, "whatever was up")
	t.done("tranq", 0, true)
	assert_eq(t.update(0, true, near, Tutorial.MIN_SHOW), "", "still seen: the sighting tip stays")
	t.sighted(0, true, 1, false)
	assert_eq(t.update(0, true, near, Tutorial.BEAT), "crouch", "shaken off: the next a beat later")


func test_every_verb_has_a_prompt_a_title_and_a_metis_line_in_both_languages() -> void:
	for lang in ["en", "es"]:
		TranslationServer.set_locale(lang)
		for verb: String in Tutorial.VERBS + [Tutorial.SPOTTED]:
			for key: String in [Tutorial.prompt_key(verb), Tutorial.title_key(verb), Tutorial.line_key(verb)]:
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


func test_prompts_name_actions_that_exist_so_they_show_the_real_binding() -> void:
	for lang in ["en", "es"]:
		TranslationServer.set_locale(lang)
		for verb: String in Tutorial.VERBS + [Tutorial.SPOTTED]:
			var text := tr(Tutorial.prompt_key(verb))
			var at := text.find("[")
			while at >= 0:
				var token := text.substr(at + 1, text.find("]", at) - at - 1)
				assert_true(InputMap.has_action(token), "%s %s: [%s] is an action" % [verb, lang, token])
				at = text.find("[", at + 1)
	TranslationServer.set_locale("en")
