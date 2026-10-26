@tool
extends McpTestSuite

## Fulton rules (pw-feel 05): who can go up, the rooms that refuse a balloon in every Area, the guards who
## see it, what Aigis makes of it and HQ's poll roster keeping the guards it took.

const GUARD := preload("res://actors/guard/guard.tscn")
const NO_FULTON := preload("res://areas/no_fulton.gd")
const DT := 0.1


func suite_name() -> String:
	return "fulton"


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _guard(n: String, x: float, z: float) -> Guard:
	var g: Guard = GUARD.instantiate()
	g.name = n
	_root().add_child(g)
	g.global_position = Vector3(x, 0, z)
	return g


func _free(nodes: Array) -> void:
	for n: Node in nodes:
		if is_instance_valid(n) and n.is_inside_tree():
			_root().remove_child(n)
			n.queue_free()


func test_only_a_neutralized_or_kneeling_guard_can_go_up() -> void:
	AlertChain.area = AlertChain.new()
	var g := _guard("Kostas", 0, 0)
	assert_false(g.can_be_fultoned(), "up")
	g.hold_up()
	assert_true(g.can_be_fultoned(), "held up, kneeling")
	g.neutralize()
	assert_true(g.can_be_fultoned(), "Neutralized")
	g.kill()
	assert_false(g.can_be_fultoned(), "dead")
	_free([g])


## For 6 s a guard within 20 m with a line of sight to the balloon goes "?"; one 25 m off doesn't.
func test_the_balloon_is_seen_within_20_m_for_6_s() -> void:
	AlertChain.area = AlertChain.new()
	var up := _guard("Nikos", 0, 0)
	var near := _guard("Kostas", 0, 15)
	var far := _guard("Petros", 0, -25)
	up.neutralize()
	up.remove_from_group("guards")
	up.fulton()
	for i in roundi(1.0 / DT):
		up._physics_process(DT)
	assert_eq(near.alert.state, GuardAlert.State.SUSPICION, "15 m: comes to look")
	assert_eq(far.alert.state, GuardAlert.State.PATROL, "25 m: too far")
	for i in roundi(5.5 / DT):
		up._physics_process(DT)
	var late := _guard("Yannis", 10, 0)
	up._physics_process(DT)
	assert_eq(late.alert.state, GuardAlert.State.PATROL, "arrived after 6 s: nothing to see")
	assert_true(up.is_queued_for_deletion(), "gone after 6 s")
	_free([near, far, late])
	_root().remove_child(up)


func test_a_fulton_feeds_downs_and_a_target_fulton_nothing() -> void:
	assert_eq(Aigis.mission_points({fulton = 1}).get("downs", 0), 15)
	assert_eq(Aigis.mission_points({target_fulton = 1}), Aigis.mission_points({}), "a Fultoned Target")


## A Fultoned guard stays on HQ's roster: polled (L1 and L3), can't answer, and a Report in settles it.
func test_a_fultoned_guard_stays_on_the_poll_roster() -> void:
	for targeted in [false, true]:
		var hq := HqRadio.new()
		hq.gone["GuardForeman"] = Vector3(2, 0, 3)
		var info: Array = hq._info([])
		assert_eq(info.size(), 1)
		assert_false(info[0].can_answer)
		var e := hq.poll.tick(HqPoll.INTERVAL + 1.0, info, targeted, 0.0)
		assert_eq(e.get("who", ""), "GuardForeman", "polled (targeted %s)" % targeted)
		assert_eq(hq.who(), "GuardForeman", "HQ waits on him")
		hq.answer()
		assert_eq(hq.who(), "", "Report in accepted")
		hq.reset()
		assert_true(hq.gone.has("GuardForeman"), "a Checkpoint doesn't bring him back")
		hq.free()


## The "no Fulton" rooms of each Area: indoors refuses, the yard accepts.
func test_no_fulton_rooms_in_every_area() -> void:
	var cases := {
		"res://areas/harbour/harbour.tscn": [[[21, 24, 0.5], [15, 56, 0.5], [42, 10, 0.5]], [[42.5, 50, 0.5], [11, 74, 0.5]]],
		"res://areas/research_annex/research_annex.tscn": [[[36, 36, 0.5], [24, 37, 0.5], [12, 43.5, 0.5]], [[26, 70, 0.5], [60, 20, 0.5]]],
		"res://areas/core/core.tscn": [[[-24, 32, 0.5], [-6, 32, 0.5], [21, 24, 0.5]], [[42.5, 50, 0.5], [22, 14, 0.5]]],
	}
	for path in cases:
		var a: Node = load(path).instantiate()
		var rooms: Node = a.get_node_or_null("NoFulton")
		assert_true(rooms != null, "%s has rooms" % path)
		if rooms == null:
			a.free()
			continue
		a.remove_child(rooms)
		a.free()
		_root().add_child(rooms)
		for p in cases[path][0]:
			assert_false(NO_FULTON.open_sky(rooms.get_tree(), _p(p)), "%s: no Fulton at %s" % [path.get_file(), p])
		for p in cases[path][1]:
			assert_true(NO_FULTON.open_sky(rooms.get_tree(), _p(p)), "%s: Fulton at %s" % [path.get_file(), p])
		_root().remove_child(rooms)
		rooms.free()


func _p(v: Array) -> Vector3:
	return Vector3(v[0] - 40.0, v[2], v[1] - 40.0)


## Mission 2's Relay Chief is ill: a Fulton would kill him, so he is carried out on foot (Campaign `carry_only`).
func test_a_carry_only_target_is_never_fultoned_but_still_a_valid_state() -> void:
	AlertChain.area = AlertChain.new()
	var g := _guard("Chief", 0, 0)
	g.carry_only = true
	g.neutralize()
	assert_false(g.can_be_fultoned(), "carry only")
	assert_true(g.fulton_state_ok(), "he is Neutralized, so the Operative is told why")
	_free([g])


func test_only_the_relay_chief_and_researcher_missions_are_carry_only() -> void:
	var flags := Campaign.MISSIONS.map(func(m: Dictionary) -> bool: return m.get("carry_only", false))
	assert_eq(flags, [false, true, true, false])
