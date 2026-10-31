## Headless playthrough of the Core (level-pass): the south-pier start, both ways into Ops, the lift panel and
## the lift, the plant room's stair up to the gallery and the ladder down behind Core1, the sight lines the
## map was tuned to, the Encounter markers and where reinforcements come from. Prints PASS/FAIL.
##   godot --headless --fixed-fps 60 --path . tools/play_core.tscn
## Same harness as tools/play_annex.gd: guards' alert meters are reset every frame while the Operative is
## teleported about, so a check reads what a guard sees without the whole Area going to Alert.
extends Node

var fails := 0
var calm := true
var _area: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TranslationServer.set_locale("en")
	await core()
	print("play_core: %d failed" % fails)
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




func core() -> void:
	print("--- Mission 4: the Core")
	var rec := Aigis.new_record()
	rec.mission = 3
	_area = load("res://areas/core/core.tscn").instantiate()
	_area.get_node("MissionRun").record = rec
	add_child(_area)
	await frames(30)
	var run: MissionRun = _area.get_node("MissionRun")
	var op: Node3D = _area.get_node("Operative")
	var guards := get_tree().get_nodes_in_group("guards")
	check(guards.size() == 8, "6 guards, the escort and the director spawn (got %d)" % guards.size())
	var map := (_area as Node3D).get_world_3d().navigation_map
	var off := guards.filter(func(g: Guard) -> bool: return NavigationServer3D.map_get_closest_point(map, g.global_position).distance_to(g.global_position) > 0.6)
	check(off.is_empty(), "every guard spawns on the navmesh %s" % [off.map(func(g): return g.name)])
	check(guards.all(func(g: Guard) -> bool: return g.global_position.x + 40.0 < 61.0), "nobody on the freighter")

	# Encounters and exits: the markers the session log reads
	check(get_tree().get_nodes_in_group("encounter").size() == 3, "three Encounter markers")
	check(get_tree().get_nodes_in_group("encounter_exit").size() == 5, "five exit markers")
	check(run.encounter_at(at(44, 60)) == 1 and run.encounter_at(at(20, 32)) == 2 and run.encounter_at(at(-24, 32)) == 3, "the yard, Ops and the room are Encounters 1, 2 and 3")
	check(guard("GuardY1").encounter == 1 and guard("GuardLiftHall").encounter == 2 and guard("GuardCore1").encounter == 3, "guards carry their Encounter")

	# reinforcements: from the road while the Operative is up top, down the lift once he is below
	check(_area._entry_for(at(44, 60)).name == "SurfaceEntry" and _area._entry_for(at(20, 32)).name == "SurfaceEntry", "a surface Alert's squad comes down the road")
	check(_area._entry_for(at(-24, 32)).name == "RoadEntry", "a squad for the room comes down the corridor")

	# Countermeasure mounts off the empty freighter (playtest 1): a camera at the pier mouth, a sentry on Warehouse A
	check(_area.has_node("CameraMounts/CamPier") and not _area.has_node("CameraMounts/CamGangway"), "the gangway camera moved to the pier mouth")
	check(_area.has_node("SentryHighPoints/SentryWarehouseA") and not _area.has_node("SentryHighPoints/SentryBridge"), "the bridge sentry moved to Warehouse A's roof")
	check(_area.get_node("ExtraGuardPosts").get_children().all(func(p: Node3D) -> bool: return p.position.x + 40.0 < 61.0), "no extra guard post on the freighter")

	# traversal
	var start: Vector3 = _area.get_node("Spots/OperativeStart").global_position
	var legs := [["start → the stack (west)", start, at(30, 66)], ["start → the alley (east)", start, at(25.4, 39.4)],
		["the east door → the panel", at(23.2, 32), at(21.5, 22.6)], ["the panel → behind LiftHall", at(21.5, 22.6), at(16.4, 23)],
		["the forecourt → the south door", at(28, 46.8), at(20, 41)], ["the lift → up the plant room's stair → the gallery", at(8, 32), at(-26, 23.8, 3.5)],
		["the corridor → the room", at(-6, 32), at(-24, 32)], ["the gallery ladder's foot → the director", at(-20, 25), at(-26, 28)]]
	for l in legs:
		var r := path_len(l[1], l[2])
		check(r[1] < 0.6, "walkable: %s, %.1f m" % [l[0], r[0]])
	check(path_len(start, at(8, 32))[0] < 80.0, "start → the lift is short: %.1f m (Mission 1's was 118 m)" % path_len(start, at(8, 32))[0])

	# patrols: park the Operative out of sight and watch 60 s go by
	await place(op, at(52, 77), true)
	var routed := guards.filter(func(g: Guard) -> bool: return g.route.size() > 1)
	var best := {}
	for g: Guard in routed:
		best[g] = []
		for p in g.route:
			best[g].append(INF)
	for i in 60 * 60:
		await get_tree().physics_frame
		for g: Guard in routed:
			for k in g.route.size():
				best[g][k] = minf(best[g][k], Vector2(g.global_position.x - g.route[k].x, g.global_position.z - g.route[k].z).length())
	for g: Guard in routed:
		check(best[g].all(func(d: float) -> bool: return d < 1.5), "%s walks its whole route (closest per point %s)" % [g.name, best[g].map(func(d): return snappedf(d, 0.1))])

	# sight lines as drawn
	for n in ["GuardY1", "GuardLaneW", "GuardObserver"]:
		check(await seen(op, n, start, false, 15.0) == 0.0, "the start is out of %s's cones" % n)
	check(await seen(op, "GuardGate", at(28, 46.8), true, 8.0) > 0.0, "Gate sees the forecourt's low cover (the west way needs him handled)")
	check(await seen(op, "GuardLiftHall", at(16.4, 23), true, 8.0) == 0.0, "LiftHall never sees the control room's side door behind him")
	check(await seen(op, "GuardLiftHall", at(15.5, 32), true, 8.0) > 0.0, "LiftHall sees the lift mouth's approach")
	for n in ["GuardCore1", "SECURITY DIRECTOR", "Escort1"]:
		check(await seen(op, n, at(-26, 23.8, 3.5), true, 10.0) == 0.0, "%s never sees a crouched Operative on the gallery" % n)

	# walk (not teleport) up the plant room's stair and through the high door onto the gallery (playtest 1: the
	# stair's top stopped short of the mezzanine and the Operative couldn't get up)
	await place(op, at(-12.75, 29.9))
	op._yaw = 0.0  # north
	Input.action_press("move_forward")
	await secs(5.0)
	var top: Vector3 = op.global_position
	check(top.y > 3.3 and top.z + 40.0 < 25.0, "up the stair onto the mezzanine (%.1f, %.1f, h %.1f)" % [top.x + 40.0, top.z + 40.0, top.y])
	op._yaw = PI / 2.0  # west
	await secs(4.0)
	Input.action_release("move_forward")
	await frames(10)
	var gal: Vector3 = op.global_position
	check(gal.y > 3.3 and gal.x + 40.0 < -16.0, "through the high door onto the gallery (%.1f, %.1f, h %.1f)" % [gal.x + 40.0, gal.z + 40.0, gal.y])
	# off the gallery through the parapet's gap (no ladder: playtest 2), landing behind the crates
	await place(op, at(-20, 24, 3.5))
	op._yaw = PI  # south
	Input.action_press("move_forward")
	await secs(0.6)
	Input.action_release("move_forward")
	await secs(1.5)
	var land: Vector3 = op.global_position
	check(land.y < 0.3 and absf(land.x + 40.0 + 20.0) < 1.0 and land.z + 40.0 > 25.2 and land.z + 40.0 < 27.2, "dropped through the gap, behind the crates (%.1f, %.1f, h %.1f)" % [land.x + 40.0, land.z + 40.0, land.y])
	for n in ["GuardCore1", "SECURITY DIRECTOR", "Escort1"]:
		check(await seen(op, n, at(-20, 26.2), true, 10.0) == 0.0, "%s never sees the landing behind the crates" % n)

	# the corridor turns the camera to the lit stair the first time the Operative passes the plant room's door
	await place(op, at(-4, 32))
	op._yaw = PI / 2.0  # west
	await frames(5)
	await place(op, at(-7, 32))
	await secs(1.2)
	check(op._yaw > 0.2 and op._yaw < 1.3, "the camera turns toward the plant room's stair (yaw %.2f)" % op._yaw)

	# step 1: the lift panel, hold E 4 s
	await place(op, at(22, 22.4))
	await frames(5)
	check("enter the code" in op.prompt.to_lower(), "beside the lift panel, its prompt shows (%s)" % op.prompt)
	Input.action_press("interact")
	await secs(4.3)
	Input.action_release("interact")
	check(run.step == 1, "holding E 4 s at the lift panel: step 1 done")
	# step 2: the lift, which opens the door to the corridor
	await place(op, at(8, 32))
	check(await until(func() -> bool: return run.step == 2, 2.0), "into the lift: step 2 done")
	await frames(5)
	check(not _area.has_node("LiftDoor"), "the lift door opens")

	# the director down in the room: entering the room no longer ends the Mission (playtest 2), the terminal does
	var director := guard("SECURITY DIRECTOR")
	director.global_position = at(-26, 30)  # earlier checks walk the Operative through the room and he flees
	director.neutralize()
	await place(op, at(-24, 34))
	await frames(20)
	check(not run.ended, "entering the room with the director down doesn't end the Mission")
	check(_area.get_node("ExtractionPoint/Beacon").visible, "the Extraction column stands over the terminal")
	await place(op, at(-31, 32))
	check(await until(func() -> bool: return run.ended, 2.0), "at the terminal, with the director left lying in the room: the Mission ends")
	await frames(5)
	check(not _area.get_node("ExtractionPoint/Beacon").visible, "the Extraction column goes once the Mission is over")
	get_tree().paused = false

	print("play_core: step %d, %d failed" % [run.step, fails])
	_area.queue_free()
