@tool
extends McpTestSuite

## Harbour greybox: every spot a later Mission or Countermeasure needs exists, and the navmesh is baked.

const SCENE := "res://areas/harbour/harbour.tscn"


func suite_name() -> String:
	return "harbour"


func test_marker_counts() -> void:
	var h: Node = load(SCENE).instantiate()
	var counts := {"spot": 5, "sentry_high_point": 2, "camera_mount": 4, "spoof_place": 4}
	for g in counts:
		var n := 0
		for m in _nodes_in_group(h, g):
			n += 1
		assert_true(n >= counts[g], "%s: %d" % [g, n])
	assert_true(_nodes_in_group(h, "guard_post").size() >= 8)
	assert_true(_nodes_in_group(h, "guard_post_extra").size() >= 2)
	h.free()


func test_navmesh_baked_with_margin() -> void:
	var h: Node = load(SCENE).instantiate()
	var nm: NavigationMesh = (h.get_node("NavRegion") as NavigationRegion3D).navigation_mesh
	assert_true(nm.get_polygon_count() > 0)
	assert_true(nm.agent_radius > 0.35)
	h.free()


## Groups only work in a tree, so walk the children for the group name instead.
func _nodes_in_group(root: Node, group: String) -> Array:
	var out := []
	for n in root.find_children("*", "Marker3D", true, false):
		if n.is_in_group(group):
			out.append(n)
	return out
