## Headless playthrough of the Research annex's three Encounters (level-pass): spawns, patrol routes, the sight
## lines the map was tuned to, the Hold-up that gives the vault code, the spoof walk and the Encounter markers.
## Prints PASS/FAIL.
##   godot --headless --fixed-fps 60 --path . tools/play_annex.tscn
## Same harness as tools/play_harbour.gd: guards' alert meters are reset every frame while the Operative is
## teleported about, so a check reads what a guard sees without the whole Area going to Alert.
extends Node

var fails := 0
var calm := true
var _area: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TranslationServer.set_locale("en")
	await mission_3()
	print("play_annex: %d failed" % fails)
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


func mission_3() -> void:
	print("--- Mission 3: the Research annex")
	var rec := Aigis.new_record()
	rec.mission = 2
	_area = load("res://areas/research_annex/research_annex.tscn").instantiate()
	_area.get_node("MissionRun").record = rec
	add_child(_area)
	await frames(30)
	var run: MissionRun = _area.get_node("MissionRun")
	var op: Node3D = _area.get_node("Operative")
	var guards := get_tree().get_nodes_in_group("guards")
	check(guards.size() == 10, "8 guards (a chatting pair), the escort and the researcher spawn (got %d)" % guards.size())
	var map := (_area as Node3D).get_world_3d().navigation_map
	var off := guards.filter(func(g: Guard) -> bool: return NavigationServer3D.map_get_closest_point(map, g.global_position).distance_to(g.global_position) > 0.6)
	check(off.is_empty(), "every guard spawns on the navmesh %s" % [off.map(func(g): return g.name)])

	# Encounters and exits: the markers the session log reads
	check(get_tree().get_nodes_in_group("encounter").size() == 3, "three Encounter markers")
	check(get_tree().get_nodes_in_group("encounter_exit").size() == 8, "eight exit markers")
	check(run.encounter_at(at(30, 66)) == 1 and run.encounter_at(at(30, 29.5)) == 2 and run.encounter_at(at(27, 50)) == 3, "the yard, the core and the Archive are Encounters 1, 2 and 3")
	check(guard("GuardA1").encounter == 1 and guard("GuardA3").encounter == 2 and guard("GuardA8").encounter == 3, "guards carry their Encounter")
	# playtest 6: in Caution E2's patrollers detoured to each other's posts and bunched by the Extraction;
	# the strip (y < 18) and the core search apart
	var on_strip := func(p: Vector3) -> bool: return p.z + 40.0 < 18.0
	for n in ["GuardV1", "GuardA5"]:
		check(not guard(n).detours.is_empty() and guard(n).detours.all(on_strip), "%s's Caution detours stay on the strip %s" % [n, guard(n).detours.map(func(p): return Vector2(p.x + 40, p.z + 40))])
	check(not guard("GuardA3").detours.is_empty() and not guard("GuardA3").detours.any(on_strip), "A3's Caution detours stay in the core %s" % [guard("GuardA3").detours.map(func(p): return Vector2(p.x + 40, p.z + 40))])

	# traversal
	var start: Vector3 = _area.get_node("Spots/OperativeStart").global_position
	var legs := [["start → behind A9 (the Hold-up)", start, at(58.5, 63)], ["yard → along the lab wall → Archive back door", at(20, 57), at(32, 55)],
		["start → west lane → west door", start, at(7.5, 36)], ["strip → office north door", at(30, 14), at(22, 21)],
		["office → server room → the vault's front door", at(25, 23), at(47, 34)],
		["south corridor → clean room → the vault's back door", at(36, 42.5), at(46, 37)],
		["start → the front door", start, at(14, 52)], ["Archive → the files", at(31, 45.5), at(27, 50)]]
	for l in legs:
		var r := path_len(l[1], l[2])
		check(r[1] < 0.6, "walkable: %s, %.1f m" % [l[0], r[0]])
	# the way in by the hall's east door runs past the dock guard
	var way := NavigationServer3D.map_get_path(map, start, at(55, 49), true)
	var a9_at := at(57, 62)
	var near: float = Array(way).map(func(p: Vector3) -> float: return Vector2(p.x - a9_at.x, p.z - a9_at.z).length()).min()
	check(near < 8.0, "start → the hall's east door passes the dock guard (%.1f m)" % near)
	# the vault's back door is the short way from the south corridor: through the clean room, not round the ring
	var back := path_len(at(36, 42.5), at(46, 37))
	check(back[0] < 16.0, "the back door is direct (%.1f m)" % back[0])

	# A8's spoof walk to SpoofHall stays in the south row: it never crosses a corridor the Operative uses
	var spoof := NavigationServer3D.map_get_path(map, guard("GuardA8").global_position, _area.get_node("SpoofPlaces/SpoofHall").global_position, true)
	check(spoof.size() > 0 and Array(spoof).all(func(p: Vector3) -> bool: return p.z + 40.0 > 44.0), "A8's walk to SpoofHall stays south of the south corridor (min y %.1f)" % (Array(spoof).map(func(p): return p.z + 40.0).min() if spoof.size() else 0.0))

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
	for n in ["GuardA1", "GuardA9", "GuardV1"]:
		check(await seen(op, n, start, false, 25.0) == 0.0, "the start is out of %s's cones" % n)
	check(await seen(op, "GuardA9", at(59.5, 66), true, 10.0) == 0.0, "A9 never sees the Hold-up approach behind him")
	check(await seen(op, "GuardV1", at(5, 17), false, 20.0) > 0.0, "V1's west stop sees the west lane's mouth")
	# the security room's pair: recorded through the north wall from the strip, never seen there
	for n in ["GuardP1A", "GuardP1B"]:
		var d := Vector2(guard(n).global_position.x + 40.0 - 50.0, guard(n).global_position.z + 40.0 - 16.8).length()
		check(d < Voiceprints.RANGE, "%s is %.1f m from the eavesdrop spot (record within %.0f)" % [n, d, Voiceprints.RANGE])
		check(await seen(op, n, at(50, 16.8), true, 10.0) == 0.0, "%s never sees the eavesdrop spot through the wall" % n)
	check(await seen(op, "GuardA8", at(32, 52.5), true, 8.0) > 0.0, "A8 sees the Archive back door")
	check(await seen(op, "GuardA8", at(31, 45.5), true, 8.0) > 0.0, "A8 sees the Archive's corridor door")

	# step 1: hold up A9 from behind, question him: the vault code
	var a9 := guard("GuardA9")
	await place(op, a9.global_position + a9.global_basis.z * 4.0)
	Input.action_press("aim")
	for i in 20:
		aim_at(op, a9)
		await get_tree().physics_frame
	for down in [true, false]:
		await key(op, a9, &"interact", down)
	check(a9.held_up, "A9 is held up at 4 m from behind")
	Input.action_press("interact")
	for i in int(2.3 * 60):
		aim_at(op, a9)
		await get_tree().physics_frame
	Input.action_release("interact")
	Input.action_release("aim")
	check(a9.answered and run.step == 1, "holding E 2 s gets the code: step 1 done")

	# step 2: the vault, by its back door
	await place(op, at(47, 36))
	check(await until(func() -> bool: return run.step == 2, 2.0), "into the vault: step 2 done")
	# step 3: the files
	await place(op, at(27, 50))
	check(await until(func() -> bool: return run.step == 3, 2.0), "the research files: step 3 done")

	print("play_annex: step %d, %d failed" % [run.step, fails])
	_area.queue_free()
