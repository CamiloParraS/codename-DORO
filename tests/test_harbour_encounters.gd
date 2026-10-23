@tool
extends McpTestSuite

## The Harbour as three Encounters (pw-feel 07): every guard has a role and an Encounter it stands in, the
## rooms refuse a Fulton, and the verb steps (eavesdrop, Hold-up) complete from the guards' state.

const SCENE := "res://areas/harbour/harbour.tscn"
const ROLES := ["gatekeeper", "observer", "patroller", "interceptor", "investigator"]
const WATCH := preload("res://areas/objective_watch.gd")
const NO_FULTON := preload("res://areas/no_fulton.gd")


func suite_name() -> String:
	return "harbour_encounters"


func _data() -> Dictionary:
	return load("res://tools/build_harbour.gd").get_script_constant_map()


func test_every_post_has_a_role_and_stands_in_its_encounter() -> void:
	var rects := {}
	for e in _data().ENCOUNTERS:
		rects[e[0]] = Rect2(e[3][0] - 40.0, e[3][1] - 40.0, e[3][2], e[3][3])
	var h: Node = load(SCENE).instantiate()
	for p: Marker3D in h.get_node("GuardPosts").get_children():
		assert_true(p.get_meta("role", "") in ROLES, "%s role" % p.name)
		var enc: int = p.get_meta("enc", 0)
		assert_true(rects.has(enc), "%s Encounter" % p.name)
		if rects.has(enc):
			assert_true(rects[enc].has_point(Vector2(p.position.x, p.position.z)), "%s stands in Encounter %d" % [p.name, enc])
	h.free()


func test_11_guards_spawn_5_3_3() -> void:
	var h: Node = load(SCENE).instantiate()
	var per := {1: 0, 2: 0, 3: 0}
	for p: Marker3D in h.get_node("GuardPosts").get_children():
		per[p.get_meta("enc")] += 2 if p.has_meta("chat") else 1
	assert_eq(per, {1: 5, 2: 3, 3: 3})
	h.free()


func test_each_mission_1_step_is_a_verb_in_the_area() -> void:
	var h: Node = load(SCENE).instantiate()
	var steps: Array = Campaign.MISSIONS[0].steps
	assert_eq(steps.map(func(s: Dictionary) -> String: return s.intel), ["IntelSmokeBreak", "IntelForeman", "IntelLiftPanel"])
	assert_eq(h.get_node("Intel/IntelSmokeBreak").verb, "voiceprint")
	assert_eq(h.get_node("Intel/IntelForeman").verb, "answer")
	assert_eq(h.get_node("Intel/IntelLiftPanel").hold_time, 4.0)
	assert_false(h.get_node("Intel/IntelLiftPanel").sweeps, "no HQ sweep after the lift panel")
	assert_eq(h.get_node("GuardPosts/PostForeman").get_meta("holdup"), "lift_code")
	h.free()


## Buildings, the lift housing and the Crawlspaces refuse a balloon; the deck, lanes, roofs and slipway don't.
func test_fulton_needs_open_sky() -> void:
	var h: Node = load(SCENE).instantiate()
	var rooms: Node = h.get_node("NoFulton")
	h.remove_child(rooms)
	h.free()
	_root().add_child(rooms)
	var tree := rooms.get_tree()
	for indoors in [[21, 24, 0.5], [15.5, 30, 0.5], [8, 32, 0.5], [15, 56, 0.5], [42, 10, 0.5], [33, 33, 0.5], [33, 53, 0.5], [63, 64, 0.5]]:
		assert_false(NO_FULTON.open_sky(tree, _p(indoors)), "no Fulton at %s" % [indoors])
	for outdoors in [[70, 30, 2.5], [42.5, 50, 0.5], [48.5, 30, 0.5], [34, 31, 6.5], [20, 45, 0.5], [11, 74, 0.5], [22, 14, 0.5]]:
		assert_true(NO_FULTON.open_sky(tree, _p(outdoors)), "Fulton at %s" % [outdoors])
	rooms.free()


func test_eavesdrop_step_completes_on_the_pairs_voiceprint() -> void:
	var op := _operative()
	var w := _watch("voiceprint", ["GuardPA", "GuardPB"])
	assert_false(w.done())
	op.voiceprints.held.append("GuardY1")
	assert_false(w.done(), "someone else's voice")
	op.voiceprints.held.append("GuardPB")
	assert_true(w.done())
	w.free()
	op.free()


## The Foreman's step: his answer, his body searched, or him gone up on a balloon.
func test_holdup_step_completes_on_the_answer_the_body_or_a_fulton() -> void:
	var op := _operative()
	var w := _watch("answer", ["GuardForeman"])
	var g: Guard = load("res://actors/guard/guard.tscn").instantiate()
	g.name = "GuardForeman"
	g.holdup_answer = "lift_code"
	_root().add_child(g)
	assert_false(w.done())
	g.answer(op)
	assert_true(w.done(), "answered")
	g.answered = false
	g.dead = true
	g.global_position = Vector3(10, 0, 0)
	assert_false(w.done(), "dead, but the Operative isn't over him")
	g.global_position = Vector3(1, 0, 0)
	assert_true(w.done(), "the code is on the body")
	g.remove_from_group("guards")
	g.dead = false
	assert_true(w.done(), "Fultoned: gone from the Area")
	g.free()
	w.free()
	op.free()


func test_a_held_up_guard_answers_once_then_is_let_go_suspicious() -> void:
	var op := _operative()
	var g: Guard = load("res://actors/guard/guard.tscn").instantiate()
	_root().add_child(g)
	assert_true(g.can_be_held_up(g.global_position + g.global_basis.z * 4.0), "from behind")
	assert_false(g.can_be_held_up(g.global_position - g.global_basis.z * 4.0), "not in front of it")
	g.hold_up()
	assert_false(g.can_radio(), "hands up, no radio")
	g.answer(op)
	assert_true(str(g.name) in op.voiceprints.held, "no objective to give: its Voiceprint")
	g.answer(op)
	assert_eq(op.voiceprints.held.size(), 1, "one answer only")
	g.release(Vector3(0, 0, 5))
	assert_false(g.held_up)
	assert_eq(g.alert.state, GuardAlert.State.SUSPICION)
	g.neutralize()
	g.hold_up()
	g.return_to_post()
	assert_false(g.held_up or g.answered, "a Checkpoint restore clears it")
	g.free()
	op.free()


func _watch(verb: String, guards: Array) -> Area3D:
	var w: Area3D = WATCH.new()
	w.verb = verb
	w.guards = PackedStringArray(guards)
	_root().add_child(w)
	return w


func _operative() -> Node3D:
	var s := GDScript.new()
	s.source_code = "extends Node3D\nvar voiceprints := Voiceprints.new()\nfunc _enter_tree() -> void:\n\tadd_to_group(\"operative\")\n"
	s.reload()
	var n := Node3D.new()
	n.set_script(s)
	_root().add_child(n)
	return n


func _p(v: Array) -> Vector3:
	return Vector3(v[0] - 40.0, v[2], v[1] - 40.0)


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


## Spoofing with the Voiceprint of a guard since Fultoned out of the Area: Glaukopis judges it without him.
func test_a_fultoned_speakers_voice_can_still_be_spoofed() -> void:
	var radio := load("res://ui/radio/radio.gd")
	assert_eq(radio.speaker_facts(null), {speaker_known_down = false, speaker_busy = false})
	var g: Guard = load("res://actors/guard/guard.tscn").instantiate()
	_root().add_child(g)
	g.neutralize()
	g.known_down = true
	assert_true(radio.speaker_facts(g).speaker_known_down, "a known Down speaker still counts")
	g.free()
