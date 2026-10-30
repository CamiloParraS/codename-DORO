## Headless playthrough of the Relay station's three Encounters (level-pass): spawns, patrol routes, the sight
## lines the map was tuned to, the Hold-up that gives the garage keys, the console and the Encounter markers.
## Prints PASS/FAIL.
##   godot --headless --fixed-fps 60 --path . tools/play_relay.tscn
## Same harness as tools/play_harbour.gd: guards' alert meters are reset every frame while the Operative is
## teleported about, so a check reads what a guard sees without the whole Area going to Alert.
extends Node

var fails := 0
var calm := true
var _area: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TranslationServer.set_locale("en")
	await mission_2()
	print("play_relay: %d failed" % fails)
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


func key(op: Node3D, g: Guard, action: StringName, down: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = down
	Input.parse_input_event(e)
	aim_at(op, g)
	await get_tree().physics_frame


func until(cond: Callable, s: float) -> bool:
	for i in int(s * 60):
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


func mission_2() -> void:
	print("--- Mission 2: the Relay station")
	var rec := Aigis.new_record()
	rec.mission = 1
	_area = load("res://areas/relay_station/relay_station.tscn").instantiate()
	_area.get_node("MissionRun").record = rec
	add_child(_area)
	await frames(30)
	var run: MissionRun = _area.get_node("MissionRun")
	var op: Node3D = _area.get_node("Operative")
	var guards := get_tree().get_nodes_in_group("guards")
	check(guards.size() == 9, "9 guards spawn (got %d)" % guards.size())
	var map := (_area as Node3D).get_world_3d().navigation_map
	var off := guards.filter(func(g: Guard) -> bool: return NavigationServer3D.map_get_closest_point(map, g.global_position).distance_to(g.global_position) > 0.6)
	check(off.is_empty(), "every guard spawns on the navmesh %s" % [off.map(func(g): return g.name)])

	# Encounters and exits: the markers the session log reads
	check(get_tree().get_nodes_in_group("encounter").size() == 3, "three Encounter markers")
	check(get_tree().get_nodes_in_group("encounter_exit").size() == 5, "five exit markers")
	check(run.encounter_at(at(40, 66)) == 1 and run.encounter_at(at(40, 20, 6)) == 2 and run.encounter_at(at(40, 44, 3)) == 3, "the pool, the summit and the terrace are Encounters 1, 2 and 3")
	check(guard("GuardA1").encounter == 1 and guard("GuardC3").encounter == 2 and guard("GuardB3").encounter == 3, "guards carry their Encounter")

	# traversal
	var start: Vector3 = _area.get_node("Spots/OperativeStart").global_position
	var legs := [["start → garage east door", start, at(60, 67)], ["garage → Ladder foot", at(60, 67), at(20, 57)],
		["terrace → scree foot", at(20, 55, 3), at(7, 46, 3)], ["scree → console", at(6.5, 32, 6), at(40, 22, 6)],
		["mess S door", at(58, 50, 3), at(58, 43, 3)], ["console → helipad", at(40, 22, 6), at(9, 14, 6)],
		["terrace → the eavesdrop by the gate", at(66, 52, 3), at(74.5, 44, 3)],
		["back lane: east of the office", at(68, 22, 6), at(66, 6, 6)], ["back lane: behind the office", at(66, 6, 6), at(42, 6, 6)],
		["back lane: behind the mast", at(42, 6, 6), at(30, 10, 6)]]
	for l in legs:
		var r := path_len(l[1], l[2])
		check(r[1] < 0.6, "walkable: %s, %.1f m" % [l[0], r[0]])
		if l[0].begins_with("back lane"):  # no detour round the dish or the mast: the lane is straight
			check(r[0] < l[1].distance_to(l[2]) * 1.2, "%s runs straight (%.1f m for %.1f m)" % [l[0], r[0], l[1].distance_to(l[2])])

	# patrols: park the Operative out of sight and watch 70 s go by
	await place(op, at(8, 75), true)
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
	for n in ["GuardA1", "GuardA2", "GuardB3"]:
		check(await seen(op, n, start, false, 25.0) == 0.0, "the start is out of %s's cones" % n)
	check(await seen(op, "GuardA2", at(44, 67.5), true, 6.0) > 0.0, "A2 sees the west door")
	check(await seen(op, "GuardA2", at(56, 67.8), true, 10.0) == 0.0, "A2 never sees the east door behind him")
	for n in ["GuardB1A", "GuardB1B"]:
		check(await seen(op, n, at(74.5, 44, 3), true, 20.0) == 0.0, "%s never sees the eavesdrop spot beside him" % n)
	check(await seen(op, "GuardB3", at(27, 39, 3), false, 16.0) == 0.0, "B3 looks up at the summit, not along the west carry line")
	check(await seen(op, "GuardC3", at(40, 20, 6), true, 25.0) > 0.0, "C3's hold looks at the console")

	# step 1: hold up A2 from behind (the east door), question him: the keys
	var a2 := guard("GuardA2")
	await place(op, a2.global_position + a2.global_basis.z * 4.0)
	Input.action_press("aim")
	for i in 20:
		aim_at(op, a2)
		await get_tree().physics_frame
	for down in [true, false]:
		await key(op, a2, &"interact", down)
	check(a2.held_up, "A2 is held up at 4 m from behind")
	Input.action_press("interact")
	for i in int(2.3 * 60):
		aim_at(op, a2)
		await get_tree().physics_frame
	Input.action_release("interact")
	Input.action_release("aim")
	check(a2.answered and run.step == 1, "holding E 2 s gets the keys: step 1 done")

	# step 2: the console, 5 s still
	var console: Area3D = _area.get_node("Intel/RelayConsole")
	await place(op, at(40, 20, 6))
	console.tick(5.1, true)
	await frames(2)
	check(console.done and run.step == 2, "holding 5 s at the console: step 2 done")

	print("play_relay: step %d, %d failed" % [run.step, fails])
	_area.queue_free()
