## Headless playthrough of the Harbour's three Encounters and the Core revisit (pw-feel 07): spawns, the
## navmesh route, patrol routes, designed sight lines, every Mission 1 step by its verb (eavesdrop, Hold-up,
## lift panel), Fulton outdoors and refused indoors, Extraction and the Rank page, the Alert chain (a stopped
## call; a completed one through Alert, Evasion and Caution, with Reinforcements from the bridge), every way a
## Hold-up ends (Alert, 6 m, a partner's sight, a choke), a guard looking at a balloon, a Game Over and
## Continue, and what the Core changes. Prints PASS/FAIL.
##   godot --headless --fixed-fps 60 --path . tools/play_harbour.tscn
## (a scene, not --script, so the autoloads exist). Guards' alert meters are reset every frame while the
## Operative is teleported about, so a check reads what a guard sees without the whole Area going to Alert.
extends Node

var fails := 0
var calm := true      # reset every guard's alert each frame
var _area: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await mission_1()
	await chain()
	await holdups()
	await continues()
	await core()
	print("play_harbour: %d failed" % fails)
	get_tree().quit(1 if fails else 0)


func _physics_process(_delta: float) -> void:
	if calm:
		for g: Guard in get_tree().get_nodes_in_group("guards"):
			if g.alert.state != GuardAlert.State.PATROL or g.alert.meter > 0.0:
				g.alert = GuardAlert.new()


func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func secs(s: float) -> void:
	await frames(int(s * 60))


func at(x: float, y: float, h := 0.0) -> Vector3:
	return Vector3(x - 40.0, h, y - 40.0)


func guard(n: String) -> Guard:
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		if g.name == n:
			return g
	return null


func load_area(path: String, mission: int) -> Node:
	var rec := Aigis.new_record()
	rec.mission = mission
	_area = load(path).instantiate()
	_area.get_node("MissionRun").record = rec
	add_child(_area)
	await frames(30)
	return _area


func place(op: Node3D, p: Vector3, crouch := false) -> void:
	op.global_position = p + Vector3.UP * 0.05
	op.velocity = Vector3.ZERO
	op.crouching = crouch
	op._apply_crouch()
	await frames(2)


## The most a guard's vision fills on the Operative at p over s seconds.
func seen(op: Node3D, who: String, p: Vector3, crouch: bool, s: float) -> float:
	await place(op, p, crouch)
	var g := guard(who)
	var most := 0.0
	for i in int(s * 60):
		await get_tree().physics_frame
		most = maxf(most, g.seen_rate)
	return most


func path_len(from: Vector3, to: Vector3) -> Array:
	var map := (_area as Node3D).get_world_3d().navigation_map
	var p := NavigationServer3D.map_get_path(map, from, to, true)
	var d := 0.0
	for i in p.size() - 1:
		d += p[i].distance_to(p[i + 1])
	var miss := Vector2(p[-1].x - to.x, p[-1].z - to.z).length() if p.size() else INF
	return [d, miss]


func aim_at(op: Node3D, g: Guard) -> void:
	var dir: Vector3 = (g.global_position + Vector3.UP * 1.2 - op.camera.global_position).normalized()
	op._yaw = atan2(-dir.x, -dir.z)
	op._pitch = asin(dir.y)


## Aim (RMB held) at g from 4 m behind and tap E. between: runs after 20 frames of aim, before the tap.
func hold_up(op: Node3D, g: Guard, between := Callable()) -> void:
	await place(op, g.global_position + g.global_basis.z * 4.0)
	Input.action_press("aim")
	for i in 20:
		aim_at(op, g)
		await get_tree().physics_frame
	if between.is_valid():
		between.call()
	for down in [true, false]:
		await key(op, g, &"interact", down)


## Press or release an action as an event (what _unhandled_input wants), keeping the aim on g.
func key(op: Node3D, g: Guard, action: StringName, down: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = down
	Input.parse_input_event(e)
	aim_at(op, g)
	await get_tree().physics_frame


## Keep the aim on g for s seconds.
func aim_for(op: Node3D, g: Guard, s: float) -> void:
	for i in int(s * 60):
		aim_at(op, g)
		await get_tree().physics_frame


## Wait up to s seconds for cond; true once it holds.
func until(cond: Callable, s: float) -> bool:
	for i in int(s * 60):
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


## Put g d m from `of` on the navmesh, facing it with a clear line (the first of 16 bearings that gives one).
func in_view(g: Guard, of: Node3D, d: float) -> bool:
	var map := (_area as Node3D).get_world_3d().navigation_map
	for i in 16:
		var p: Vector3 = of.global_position + Vector3.FORWARD.rotated(Vector3.UP, i * TAU / 16) * d
		var eye := p + Vector3.UP * Guard.EYE
		var on := NavigationServer3D.map_get_closest_point(map, p)
		if Vector2(on.x - p.x, on.z - p.z).length() < 0.3 and g._clear(eye, of.global_position + Vector3.UP * 1.3, of):
			g.global_position = p
			g.look_at(Vector3(of.global_position.x, p.y, of.global_position.z), Vector3.UP)
			return true
	return false


## Out of every guard's sight: the Operative frozen far off the map.
func away(op: Node3D) -> void:
	op.global_position = Vector3(400, 50, 400)
	op.process_mode = Node.PROCESS_MODE_DISABLED
	await frames(2)


var harbour_north_door := 0.0


func mission_1() -> void:
	print("--- Mission 1: the Harbour")
	var area := await load_area("res://areas/harbour/harbour.tscn", 0)
	var run: MissionRun = area.get_node("MissionRun")
	var op: Node3D = area.get_node("Operative")
	var guards := get_tree().get_nodes_in_group("guards")
	check(guards.size() == 11, "11 guards spawn (got %d)" % guards.size())
	var map := (area as Node3D).get_world_3d().navigation_map
	var off := guards.filter(func(g: Guard) -> bool: return NavigationServer3D.map_get_closest_point(map, g.global_position).distance_to(g.global_position) > 0.6)
	check(off.is_empty(), "every guard spawns on the navmesh %s" % [off.map(func(g): return g.name)])

	# traversal: the navmesh joins the start to each Encounter's way through and on to the Extraction point
	var start: Vector3 = area.get_node("Spots/OperativeStart").global_position
	var legs := [["E1 smoke break", start, at(75.9, 53, 2)], ["E1 → E2 gangway foot", at(75.9, 53, 2), at(60, 46)],
		["E2 lane W (the Foreman)", at(60, 46), at(42.5, 50)], ["E2 → E3 alley", at(42.5, 50), at(24.6, 37.5)],
		["E3 lift panel", at(24.6, 37.5), at(22, 22.2)], ["E3 → slipway", at(22, 22.2), at(11, 74)]]
	var total := 0.0
	for l in legs:
		var r := path_len(l[1], l[2])
		total += r[0]
		check(r[1] < 0.6, "walkable: %s, %.1f m" % [l[0], r[0]])
	print("      route bow → three steps → Extraction: %.0f m" % total)
	harbour_north_door = path_len(at(22, 14), at(20, 24))[0]

	# patrols: park the Operative out of sight and watch a minute go by
	await place(op, at(52, 77), true)
	var routed := guards.filter(func(g: Guard) -> bool: return g.route.size() > 1)
	var best := {}
	for g: Guard in routed:
		best[g] = []
		for p in g.route:
			best[g].append(INF)
	for i in 70 * 60:
		await get_tree().physics_frame
		for g: Guard in routed:
			for k in g.route.size():
				best[g][k] = minf(best[g][k], Vector2(g.global_position.x - g.route[k].x, g.global_position.z - g.route[k].z).length())
	for g: Guard in routed:
		check(best[g].all(func(d: float) -> bool: return d < 1.5), "%s walks its whole route (closest per point %s)" % [g.name, best[g].map(func(d): return snappedf(d, 0.1))])

	# sight lines as drawn
	check(await seen(op, "GuardO1", at(67.2, 15, 2), true, 3.0) == 0.0, "E1: the hatches hide a crouched Operative from O1")
	check(await seen(op, "GuardO1", at(65.7, 30, 2), true, 3.0) == 0.0, "E1: O1 never sees the port rail behind him")
	check(await seen(op, "GuardO5", at(66, 38, 2), false, 6.0) > 0.0, "E1: O5's sweep covers the port rail north of him")
	check(await seen(op, "GuardO2", at(66.5, 25, 2), false, 20.0) == 0.0, "E1: O2 never sees a Hold-up behind O1 (20 s)")
	check(await seen(op, "GuardObserver", at(42.5, 42), false, 6.0) > 0.0, "E2: the roof Observer covers lane W's north end")
	check(await seen(op, "GuardObserver", at(30, 39.3), false, 6.0) == 0.0, "E2: Warehouse B's south wall is dead ground under the roof edge")
	check(await seen(op, "GuardGate", at(26.5, 46.6), false, 6.0) > 0.0, "E3: the Gatekeeper covers the way in from the yard")
	check(await seen(op, "GuardGate", at(15.5, 30), false, 6.0) == 0.0, "E3: the Gatekeeper can't see into the lift hall")

	# step 1: eavesdrop the smoke break, unseen
	await place(op, at(75.9, 53, 2), true)
	var pair_saw := 0.0
	for i in 40 * 60:
		await get_tree().physics_frame
		pair_saw = maxf(pair_saw, maxf(guard("GuardPA").seen_rate, guard("GuardPB").seen_rate))
		if run.step >= 1:
			break
	check(run.step == 1, "step 1 done by eavesdropping (Voiceprints %s)" % [op.voiceprints.held])
	check(pair_saw == 0.0, "the pair never see the eavesdrop spot")

	# step 2: hold up the Foreman from behind and question him
	var fm := guard("GuardForeman")
	var obs := guard("GuardObserver")
	for i in 60 * 60:  # the roof Observer sweeps lane W's north end: a Hold-up he sees frees the Foreman (Partner reaction)
		if obs._flat_dist(fm.global_position) > GuardAlert.PARTNER_RANGE:
			break
		await get_tree().physics_frame
	await hold_up(op, fm, func() -> void: check(not fm.held_up, "aiming alone holds nobody up"))
	check(fm.held_up, "the Foreman is held up at 4 m from behind")
	var froze := fm.global_position
	for i in 60:
		aim_at(op, fm)
		await get_tree().physics_frame
	check(fm.global_position.distance_to(froze) < 0.05, "a held-up guard stays put")
	Input.action_press("interact")
	for i in int(2.3 * 60):
		aim_at(op, fm)
		await get_tree().physics_frame
	Input.action_release("interact")
	check(fm.answered and run.step == 2, "holding E 2 s gets the lift code: step 2 done")
	Input.action_release("aim")
	await secs(4.5)
	check(not fm.held_up, "with the gun off him for 4 s he's free")

	# Fulton outdoors (the lanes), refused indoors (the control room)
	calm = true
	fm.neutralize()
	await place(op, fm.global_position + Vector3(1.0, 0, 0))
	Input.action_press("fulton")
	await secs(1.5)
	Input.action_release("fulton")
	await frames(2)
	check(fm.is_in_group("guards") and op.fultons == 3, "releasing G early cancels and spends no balloon")
	Input.action_press("fulton")
	await secs(3.3)
	Input.action_release("fulton")
	check(not fm.is_in_group("guards") and op.fultons == 2 and run.tally.counts.get("fulton", 0) == 1, "Fulton in the open lifts the Foreman out (3 s, a balloon spent)")
	# the radio after a Fulton: spoof with the voice of a guard who has left the Area (the crash of 2026-10-23)
	var radio: Node = get_tree().get_first_node_in_group("radio")
	radio._open()
	radio.close()
	var judged: int = radio.glaukopis.history.size()
	radio._send({speaker = "GuardForeman", recipients = ["GuardY1"], all_units = false, order = "go", place = "Dock"}, "Go check the Dock.")
	await secs(2.0)
	check(radio.glaukopis.history.size() == judged + 1, "a Spoof in a Fultoned guard's voice is judged, not a crash (Y1's order: %s)" % [guard("GuardY1").order])
	var ops := guard("GuardOps")
	ops.global_position = at(20.5, 32)  # the lobby: by the lift panel its "hold E" prompt would take the line
	ops.neutralize()
	await place(op, ops.global_position + Vector3(0.8, 0, 0))
	await frames(2)
	check("no Fulton indoors" in op.prompt, "indoors the prompt says no Fulton (%s)" % op.prompt)
	Input.action_press("fulton")
	await secs(4.0)
	Input.action_release("fulton")
	check(ops.is_in_group("guards") and op.fultons == 2, "Fulton refused inside the Operations building")
	var hq: HqRadio = radio.hq
	check(hq.gone.has("GuardForeman") and hq._info(get_tree().get_nodes_in_group("guards")).any(func(i: Dictionary) -> bool: return i.name == "GuardForeman" and not i.can_answer),
		"the Fultoned Foreman stays on HQ's poll roster, unable to answer")

	# step 3: the lift panel, then out by the slipway
	ops.global_position = at(22.8, 22.4)
	await place(op, at(22, 22.4))
	await frames(5)
	check("hold E to enter the code" in op.prompt and "E carry" in op.prompt, "beside the lift panel and a body, both prompts show (%s)" % op.prompt)
	Input.action_press("interact")
	await secs(4.3)
	Input.action_release("interact")
	check(run.step == 3, "holding E 4 s at the lift panel: step 3 done")
	check(area.get_node("ExtractionPoint/Beacon").visible, "the Extraction beacon shows once every step is done")
	await place(op, at(11, 74))
	await frames(10)
	check(run.ended, "the slipway's Extraction point ends the Mission")
	var page := run.find_children("*", "Control", true, false).filter(func(c: Node) -> bool: return c.has_signal("committed"))
	check(page.size() == 1 and page[0].rank_only and page[0].stats()[2] == ["ALERTS", str(run.rank.alerts)] and page[0].rank.grade(page[0].par) != "",
		"the Rank page shows: grade %s, %s" % [page[0].rank.grade(page[0].par) if page.size() else "-", page[0].stats() if page.size() else []])
	if page.size():
		page[0].advance()  # any key: a replay's single page commits
		await frames(2)
		check(not get_tree().paused and not is_instance_valid(page[0]), "a key on the Rank page commits and closes it")
	get_tree().paused = false
	area.queue_free()
	await frames(5)


## The Alert chain (pw-feel 03): a dart stops a Radio call (no Alert; Caution once the search ends); a call
## that completes is an Alert (Rank counts it, a squad comes out of the bridge for an Operative on the deck),
## drains to Evasion unseen, then Caution, then Normal, and the squad leaves.
func chain() -> void:
	print("--- The Alert chain")
	calm = false
	var area := await load_area("res://areas/harbour/harbour.tscn", 0)
	var run: MissionRun = area.get_node("MissionRun")
	var op: Node3D = area.get_node("Operative")
	var ch := AlertChain.area
	var o5 := guard("GuardO5")
	await place(op, at(66, 38, 2))
	check(await until(func() -> bool: return ch.calling(o5), 8.0), "O5 sees the Operative on the port rail and radios it in")
	o5.tranquilize(true, op.global_position)  # a dart to the head
	await away(op)
	await secs(AlertChain.CALL_TIME + 1.0)
	check(ch.alerts == 0 and ch.phase != AlertChain.Phase.ALERT and run.rank.alerts == 0, "a dart stops the call: no Alert, nothing on the Rank")
	check(await until(func() -> bool: return ch.phase == AlertChain.Phase.CAUTION, 60.0), "the stopped call's local search ends in Caution (%s)" % AlertChain.Phase.keys()[ch.phase])
	area.queue_free()
	await frames(5)

	area = await load_area("res://areas/harbour/harbour.tscn", 0)
	run = area.get_node("MissionRun")
	op = area.get_node("Operative")
	ch = AlertChain.area
	await place(op, at(66, 38, 2))
	check(await until(func() -> bool: return ch.alerts == 1, 10.0), "left alone, O5's call completes")
	check(ch.phase == AlertChain.Phase.ALERT and run.rank.alerts == 1, "a completed call is an Alert, counted for Rank")
	await frames(5)
	var squad := get_tree().get_nodes_in_group("reinforcements")
	var deck: Vector3 = area.get_node("Spots/DeckEntry").global_position
	check(squad.size() == Reinforcements.SQUAD and squad.all(func(g: Guard) -> bool: return g.global_position.distance_to(deck) < 4.0),
		"%d Reinforcements come out of the bridge (DeckEntry) for an Operative on the deck" % squad.size())
	check(get_tree().get_nodes_in_group("guards").all(func(g: Guard) -> bool: return g.is_down() or g.alert.state == GuardAlert.State.ALERT), "every guard hunts")
	await away(op)
	check(await until(func() -> bool: return ch.phase == AlertChain.Phase.EVASION, AlertChain.ALERT_TIME + 5.0), "unseen, the Alert drains to Evasion")
	check(await until(func() -> bool: return ch.phase == AlertChain.Phase.CAUTION, AlertChain.EVASION_TIME + 5.0), "Evasion ends in Caution")
	check(get_tree().get_nodes_in_group("guards").all(func(g: Guard) -> bool: return g.alert.state < GuardAlert.State.ALERT), "in Caution the guards are back on patrol")
	check(await until(func() -> bool: return ch.phase == AlertChain.Phase.NORMAL, AlertChain.CAUTION_TIME + 5.0), "Caution ends in Normal")
	await frames(5)
	check(get_tree().get_nodes_in_group("reinforcements").is_empty(), "the Reinforcements leave once Caution ends")
	check(ch.alerts == 1 and run.rank.alerts == 1, "one Alert in all")
	area.queue_free()
	await frames(5)
	calm = true


## How a Hold-up ends besides the aim (pw-feel 06): an Alert, leaving 6 m, a partner's sight, a choke; and a
## guard in view of the Fulton balloon comes to look.
func holdups() -> void:
	print("--- Hold-ups and the balloon")
	var area := await load_area("res://areas/harbour/harbour.tscn", 0)
	var op: Node3D = area.get_node("Operative")
	var fm := guard("GuardForeman")
	var y1 := guard("GuardY1")
	var obs := guard("GuardObserver")
	await until(func() -> bool: return obs._flat_dist(fm.global_position) > GuardAlert.PARTNER_RANGE + 3.0, 60.0)

	await hold_up(op, fm)
	check(fm.held_up, "held up")
	calm = false
	AlertChain.area.start_call(guard("GuardGate"), op.global_position)  # someone else's call completes
	await aim_for(op, fm, AlertChain.CALL_TIME + 0.5)
	check(AlertChain.area.phase == AlertChain.Phase.ALERT and not fm.held_up, "an Alert frees a held-up guard")
	Input.action_release("aim")
	AlertChain.area.stand_down()
	calm = true
	await frames(2)

	await hold_up(op, fm)
	check(fm.held_up, "held up again")
	op.global_position = fm.global_position + fm.global_basis.z * (Holdup.RANGE + 1.0)
	await aim_for(op, fm, 0.2)
	check(not fm.held_up, "stepping back past %d m frees him, gun still on him" % Holdup.RANGE)
	Input.action_release("aim")
	AlertChain.area.stand_down()  # his own call on being freed
	await frames(2)

	await hold_up(op, fm)
	check(fm.held_up, "held up a third time")
	check(in_view(y1, fm, 8.0), "Y1 placed 8 m off, facing the kneeling Foreman")
	await aim_for(op, fm, 0.1)
	check(not fm.held_up, "Y1 sees him kneeling: he is freed")
	Input.action_release("aim")
	y1.global_position = at(58, 24)  # back to his post, out of the way
	AlertChain.area.stand_down()
	await frames(2)

	await hold_up(op, fm)
	Input.action_press("interact")
	await aim_for(op, fm, Holdup.ASK_TIME + 0.3)
	Input.action_release("interact")
	check(fm.held_up and fm.answered, "questioned")
	await place(op, fm.global_position + fm.global_basis.z * 1.0)
	await key(op, fm, &"interact", true)
	await aim_for(op, fm, op.choke_time + 0.3)
	await key(op, fm, &"interact", false)
	Input.action_release("aim")
	check(fm.is_down() and not fm.dead and not fm.held_up and op.held_up == null, "E after his answer chokes him out")

	calm = false
	await away(op)
	check(in_view(y1, fm, 10.0), "Y1 placed 10 m off, facing the downed Foreman")
	op.launch_fulton(fm)
	check(await until(func() -> bool: return y1.alert.state == GuardAlert.State.SUSPICION and y1.alert.last_known.distance_to(fm._balloon_spot) < 0.5, 3.0),
		"Y1, 10 m off, sees the balloon go up and comes to look")
	calm = true
	area.queue_free()
	await frames(5)


## Rank vs Checkpoint (pw-feel 04): a death opens Game Over; CONTINUE rolls the tally back but the kill,
## the Continue and the time stay on the Rank; a pause-menu restart is a Continue too.
func continues() -> void:
	print("--- Continue: Rank counters outlive a Checkpoint")
	var area := await load_area("res://areas/harbour/harbour.tscn", 0)
	var run: MissionRun = area.get_node("MissionRun")
	var op: Node3D = area.get_node("Operative")
	guard("GuardForeman").kill()
	run.event("takedown")  # a Habit-relevant action
	for i in Health.HITS_TO_DIE:
		op.take_hit()
	await frames(2)
	var screen := area.find_children("*", "Control", true, false).filter(func(c: Node) -> bool: return c.has_signal("continued"))
	check(screen.size() == 1 and get_tree().paused, "death opens the Game Over screen over a paused Area")
	var t := run.rank.seconds
	await frames(30)
	check(run.rank.seconds > t, "Rank time runs through Game Over")
	screen[0].continued.emit()
	await frames(2)
	check(not get_tree().paused and not is_instance_valid(screen[0]), "CONTINUE closes it")
	check(run.rank.kills == 1 and run.rank.continues == 1, "the kill and the Continue stay on the Rank (kills %d, continues %d)" % [run.rank.kills, run.rank.continues])
	check(not run.tally.counts.has("kill") and not run.tally.counts.has("takedown"), "the tally (Habits, Lethality) rolls back: %s" % [run.tally.counts])
	get_tree().call_group("checkpoint", "restore_checkpoint")  # the pause menu's restart
	check(run.rank.continues == 2, "a pause-menu restart is a Continue")
	var y1 := guard("GuardY1")
	y1.neutralize()
	op.launch_fulton(y1)
	check(op.fultons == op.get_script().FULTONS - 1 and run.fultoned() == 1, "a Fulton spends a balloon and counts a guard Fultoned")
	get_tree().call_group("checkpoint", "restore_checkpoint")
	check(op.fultons == op.get_script().FULTONS and run.fultoned() == 0, "a Continue returns to the Checkpoint's balloons and Fultoned count")
	area.queue_free()
	await frames(5)


func core() -> void:
	print("--- Core: the Harbour re-crossed")
	var area := await load_area("res://areas/core/core.tscn", 3)
	var run: MissionRun = area.get_node("MissionRun")
	var op: Node3D = area.get_node("Operative")
	var names := get_tree().get_nodes_in_group("guards").map(func(g: Guard) -> String: return str(g.name))
	check(not names.has("GuardPA") and not names.has("GuardPB") and not names.has("GuardForeman"), "the pair and the Foreman are gone")
	check(names.has("GuardStern") and names.has("GuardLiftHall"), "a stern Patroller and a lift-hall Interceptor are posted")
	var north: float = path_len(at(22, 14), at(20, 24))[0]
	check(north > harbour_north_door + 10.0, "the Ops north door is sealed: north yard to control room %.0f m (Mission 1: %.0f m)" % [north, harbour_north_door])
	var lift := path_len(area.get_node("Spots/OperativeStart").global_position, at(8, 32))
	check(lift[1] < 0.6, "bow to lift mouth is walkable, %.0f m" % lift[0])
	check(await seen(op, "GuardStern", at(66, 56, 2), false, 12.0) > 0.0, "the stern Patroller covers the way round the bridge")
	await place(op, at(19.5, 32))
	await frames(10)
	check(run.step == 1, "step 1: reaching the Operations building")
	await place(op, at(8, 32))
	await frames(10)
	check(run.step == 2 and area.get_node_or_null("LiftDoor") == null, "step 2: the lift opens")
	var director: Guard = get_tree().get_nodes_in_group("targets")[0]
	director.neutralize()
	op.launch_fulton(director)
	check(run._targets_left().is_empty() and not run.tally.counts.has("target_kill") and run.fultoned() == 0,
		"a Fultoned Target is delivered, weighs nothing in Lethality and isn't a Recruit")
	area.queue_free()
	await frames(5)
