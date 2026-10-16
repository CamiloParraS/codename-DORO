@tool
extends McpTestSuite

## Research annex: the Area's template spots and navmesh, and Mission 3's data.

const SCENE := "res://areas/research_annex/research_annex.tscn"


func suite_name() -> String:
	return "research_annex"


func test_marker_counts() -> void:
	var a: Node = load(SCENE).instantiate()
	var counts := {"spot": 5, "sentry_high_point": 2, "camera_mount": 4, "spoof_place": 4, "guard_post": 10,
		"guard_post_extra": 3, "resupply_crate": 1, "extraction": 1, "target_post": 1}
	for g in counts:
		var n := 0
		for m in a.find_children("*", "", true, false):
			if m.is_in_group(g) or (g == "extraction" and m is Area3D and m.get_script() and m.get_script().resource_path.ends_with("extraction_point.gd")):
				n += 1
		assert_true(n >= counts[g], "%s: %d" % [g, n])
	a.free()


func test_ground_is_80_by_80_and_navmesh_baked() -> void:
	var a: Node = load(SCENE).instantiate()
	assert_eq(((a.get_node("NavRegion/Geometry/Ground") as MeshInstance3D).mesh as BoxMesh).size, Vector3(80, 1, 80))
	var nm: NavigationMesh = (a.get_node("NavRegion") as NavigationRegion3D).navigation_mesh
	assert_true(nm.get_polygon_count() > 0)
	assert_true(nm.agent_radius > 0.35)
	a.free()


## The Target's route points, the safe room, the Operative start and the files are all on the navmesh.
func test_route_safe_room_and_files_are_on_the_navmesh() -> void:
	var a: Node = load(SCENE).instantiate()
	var post: Marker3D = a.get_node("TargetPosts/TargetPost1")
	var points: Array[Vector3] = [post.position]  # not in a tree, so local; every parent is at the origin
	for wp: Marker3D in post.get_children():
		points.append(post.position + wp.position)
	for s in ["SafeRoom", "OperativeStart", "ResearchFiles", "Extraction"]:
		points.append((a.get_node("Spots/" + s) as Marker3D).position)
	var nm: NavigationMesh = (a.get_node("NavRegion") as NavigationRegion3D).navigation_mesh
	for p in points:
		assert_true(_on_mesh(nm, p), "%s is on the navmesh" % p)
	a.free()


func test_mission_3_plays_here_with_the_research_files_as_its_step_and_the_researcher_as_target() -> void:
	var m: Dictionary = Campaign.MISSIONS[2]
	assert_eq(m.area, SCENE)
	assert_eq(m.targets, ["LEAD RESEARCHER"])
	var a: Node = load(SCENE).instantiate()
	var files: Area3D = a.get_node("Intel/" + m.steps[0].intel)
	assert_true(files.get_script().resource_path.ends_with("intel_pickup.gd"), "an intel pickup: MissionRun treats it as the step")
	a.free()


## Is p (x, z) inside one of the navmesh's polygons (a fan of triangles each)?
func _on_mesh(nm: NavigationMesh, p: Vector3) -> bool:
	var v := nm.get_vertices()
	for i in nm.get_polygon_count():
		var poly := nm.get_polygon(i)
		for k in range(1, poly.size() - 1):
			if _in_triangle(p, v[poly[0]], v[poly[k]], v[poly[k + 1]]):
				return true
	return false


func _in_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> bool:
	var d1 := (p.x - b.x) * (a.z - b.z) - (a.x - b.x) * (p.z - b.z)
	var d2 := (p.x - c.x) * (b.z - c.z) - (b.x - c.x) * (p.z - c.z)
	var d3 := (p.x - a.x) * (c.z - a.z) - (c.x - a.x) * (p.z - a.z)
	return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))
