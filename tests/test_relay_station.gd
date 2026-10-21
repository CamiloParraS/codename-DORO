@tool
extends McpTestSuite

## Relay station greybox (tools/build_relay_station.gd): the Area's template spots and navmesh across the
## terraces, its Ladders and Crawlspace, Mission 2's data, and the console's sabotage and sweep.

const SCENE := "res://areas/relay_station/relay_station.tscn"
const CONSOLE := preload("res://areas/relay_station/relay_console.gd")


func suite_name() -> String:
	return "relay_station"


func test_marker_counts() -> void:
	var a: Node = load(SCENE).instantiate()
	var counts := {"spot": 5, "sentry_high_point": 2, "camera_mount": 4, "spoof_place": 4, "guard_post": 9,
		"guard_post_extra": 3, "resupply_crate": 1, "extraction": 1, "target_post": 1}
	for g in counts:
		var n := 0
		for m in a.find_children("*", "", true, false):
			if m.is_in_group(g) or (g == "extraction" and m is Area3D and m.get_script() and m.get_script().resource_path.ends_with("extraction_point.gd")):
				n += 1
		assert_true(n >= counts[g], "%s: %d" % [g, n])
	a.free()


func test_navmesh_baked_with_margin() -> void:
	var a: Node = load(SCENE).instantiate()
	var nm: NavigationMesh = (a.get_node("NavRegion") as NavigationRegion3D).navigation_mesh
	assert_true(nm.get_polygon_count() > 0)
	assert_true(nm.agent_radius > 0.35)
	a.free()


## The Target's route points, the safe room, the Operative start, the console, every terrace, the office
## roof and the catwalk are all on the navmesh at their own height.
func test_route_spots_and_every_level_are_on_the_navmesh() -> void:
	var a: Node = load(SCENE).instantiate()
	var post: Marker3D = a.get_node("TargetPosts/TargetPost1")
	var points: Array[Vector3] = [post.position]  # not in a tree, so local; every parent is at the origin
	for wp: Marker3D in post.get_children():
		points.append(post.transform * wp.position)
	for s in ["SafeRoom", "OperativeStart", "RelayConsole", "Extraction"]:
		points.append((a.get_node("Spots/" + s) as Marker3D).position)
	# motor pool, barracks terrace, summit, office roof, catwalk (diagram metres, less 40)
	points.append_array([Vector3(-10, 0, 34), Vector3(0, 3, 14), Vector3(-12, 6, -14), Vector3(18, 10, -28), Vector3(5, 10, -29.2)])
	var nm: NavigationMesh = (a.get_node("NavRegion") as NavigationRegion3D).navigation_mesh
	for p in points:
		assert_true(_on_mesh(nm, p), "%s is on the navmesh" % p)
	a.free()


## Both Ladders land on ground guards walk to, so a guard follows the Operative up instead of waiting at the foot.
func test_ladders_are_walkable_and_guards_go_to_the_spot() -> void:
	var a: Node = load(SCENE).instantiate()
	var ladders: Array = a.get_node("Ladders").get_children()
	assert_eq(ladders.size(), 2)
	for l: Node3D in ladders:
		assert_true(l.is_in_group("ladders"))
		assert_true(l.has_meta("walkable"), l.name)
	a.free()
	var l := Node3D.new()
	for end in [["Bottom", Vector3(0, 0, 0)], ["Top", Vector3(0, 3, -2)]]:
		var m := Marker3D.new()
		m.name = end[0]
		m.position = end[1]
		l.add_child(m)
	l.set_meta("walkable", true)
	_root().add_child(l)
	assert_eq(Guard.ladder_foot(Vector3(-8, 3, -5), [l]), Vector3(-8, 3, -5))
	l.free()


## The stilted barracks' Crawlspace stands on the 3 m terrace: a 1.2 m ceiling and a carry block at both mouths.
func test_barracks_crawlspace_refuses_a_carried_body() -> void:
	var a: Node = load(SCENE).instantiate()
	var c: Node = a.get_node("NavRegion/Crawlspaces/BarracksCrawl")
	var blocks := c.get_children().filter(func(b: Node) -> bool: return b.name.begins_with("CarryBlock"))
	assert_eq(blocks.size(), 2)
	for b: StaticBody3D in blocks:
		assert_eq(b.collision_layer, 1 << 3, "only an Operative carrying a body collides")
	var ceiling: StaticBody3D = c.get_node("Ceiling")
	var size: Vector3 = (ceiling.get_node("Shape") as CollisionShape3D).shape.size
	assert_true(is_equal_approx(ceiling.position.y - size.y / 2, 3.0 + 1.2))
	a.free()


func test_mission_2_plays_here_with_the_console_as_its_step_and_the_chief_as_target() -> void:
	var m: Dictionary = Campaign.MISSIONS[1]
	assert_eq(m.area, SCENE)
	assert_eq(m.targets, ["RELAY CHIEF"])
	var a: Node = load(SCENE).instantiate()
	for s: Dictionary in m.steps:
		assert_true(a.get_node("Intel/" + s.intel) is Area3D, s.intel)
	assert_eq(m.steps[1].intel, "RelayConsole", "the sabotage is the middle step")
	a.free()


func test_holding_for_5_s_sabotages_and_releasing_starts_over() -> void:
	var c: Area3D = CONSOLE.new()
	var done := [false]
	c.reached.connect(func() -> void: done[0] = true)
	_root().add_child(c)
	c.tick(4.0, true)
	c.tick(1.0, false)
	assert_eq(c.held, 0.0, "released")
	c.tick(4.9, true)
	assert_false(done[0])
	c.tick(0.2, true)
	assert_true(done[0])
	c.free()


## Guard scripts are not @tool, so the editor runs this against a stand-in with a real GuardAlert.
func test_sweep_sends_every_patrolling_guard_to_suspicion_and_never_alerts() -> void:
	var c: Area3D = CONSOLE.new()
	_root().add_child(c)
	var patrol := _guard()
	var alerted := _guard()
	alerted.alert.state = GuardAlert.State.ALERT
	c.sweep()
	assert_eq(patrol.alert.state, GuardAlert.State.SUSPICION)
	assert_eq(alerted.alert.state, GuardAlert.State.ALERT, "an alerted guard is left alone")
	patrol.free()
	alerted.free()
	c.free()


class StandInGuard:
	extends Node3D
	var alert := GuardAlert.new()

	func on_noise(pos: Vector3, what: String) -> void:
		alert.hear(pos, what)


func _guard() -> StandInGuard:
	var g := StandInGuard.new()
	g.add_to_group("guards")
	_root().add_child(g)
	return g


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


## Is p inside one of the navmesh's polygons (a fan of triangles each), within 1 m of its height?
func _on_mesh(nm: NavigationMesh, p: Vector3) -> bool:
	var v := nm.get_vertices()
	for i in nm.get_polygon_count():
		var poly := nm.get_polygon(i)
		for k in range(1, poly.size() - 1):
			var t := [v[poly[0]], v[poly[k]], v[poly[k + 1]]]
			if absf((t[0].y + t[1].y + t[2].y) / 3.0 - p.y) < 1.0 and _in_triangle(p, t[0], t[1], t[2]):
				return true
	return false


func _in_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> bool:
	var d1 := (p.x - b.x) * (a.z - b.z) - (a.x - b.x) * (p.z - b.z)
	var d2 := (p.x - c.x) * (b.z - c.z) - (b.x - c.x) * (p.z - c.z)
	var d3 := (p.x - a.x) * (c.z - a.z) - (c.x - a.x) * (p.z - a.z)
	return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))
