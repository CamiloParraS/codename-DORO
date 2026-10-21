@tool
extends McpTestSuite

## Research annex greybox (tools/build_research_annex.gd): the Area's template spots, the navmesh through
## the lab's rooms and doorways, its Crawlspace, and Mission 3's data.

const SCENE := "res://areas/research_annex/research_annex.tscn"


func suite_name() -> String:
	return "research_annex"


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


## The Target's route points, the safe room, the Operative start, the files, every interior doorway and
## both tower tops are all on the navmesh at their own height.
func test_route_spots_doorways_and_towers_are_on_the_navmesh() -> void:
	var a: Node = load(SCENE).instantiate()
	var post: Marker3D = a.get_node("TargetPosts/TargetPost1")
	var points: Array[Vector3] = [post.position]  # not in a tree, so local; every parent is at the origin
	for wp: Marker3D in post.get_children():
		points.append(post.transform * wp.position)
	for s in ["SafeRoom", "OperativeStart", "ResearchFiles", "Extraction"]:
		points.append((a.get_node("Spots/" + s) as Marker3D).position)
	# the corridor's doorways to N1, the office, the lab, the vault, the lobby, the Archive and the hall
	for x in [13, 25, 37, 49]:
		points.append(Vector3(x - 40, 0, 2))
	for x in [11, 31, 45]:
		points.append(Vector3(x - 40, 0, 5))
	points.append_array([Vector3(-5, 5, -34), Vector3(5, 5, 35)])  # gate and yard tower tops
	var nm: NavigationMesh = (a.get_node("NavRegion") as NavigationRegion3D).navigation_mesh
	for p in points:
		assert_true(_on_mesh(nm, p), "%s is on the navmesh" % p)
	a.free()


func test_the_area_has_no_ladders() -> void:
	var a: Node = load(SCENE).instantiate()
	assert_eq(a.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n.is_in_group("ladders")).size(), 0)
	a.free()


## The stilted pump house's Crawlspace runs from the yard to the Archive's back door: a 1.2 m ceiling
## and a carry block at both mouths.
func test_pump_house_crawlspace_refuses_a_carried_body() -> void:
	var a: Node = load(SCENE).instantiate()
	var c: Node = a.get_node("NavRegion/Crawlspaces/PumpCrawl")
	var blocks := c.get_children().filter(func(b: Node) -> bool: return b.name.begins_with("CarryBlock"))
	assert_eq(blocks.size(), 2)
	for b: StaticBody3D in blocks:
		assert_eq(b.collision_layer, 1 << 3, "only an Operative carrying a body collides")
	var ceiling: StaticBody3D = c.get_node("Ceiling")
	var size: Vector3 = (ceiling.get_node("Shape") as CollisionShape3D).shape.size
	assert_true(is_equal_approx(ceiling.position.y - size.y / 2, 1.2))
	a.free()


func test_mission_3_plays_here_with_the_research_files_as_its_step_and_the_researcher_as_target() -> void:
	var m: Dictionary = Campaign.MISSIONS[2]
	assert_eq(m.area, SCENE)
	assert_eq(m.targets, ["LEAD RESEARCHER"])
	var a: Node = load(SCENE).instantiate()
	var files: Area3D = a.get_node("Intel/" + m.steps[-1].intel)
	assert_true(files.get_script().resource_path.ends_with("intel_pickup.gd"), "an intel pickup: MissionRun treats it as the step")
	a.free()


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
