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


## The Tanker berth's guard placements: a chatting pair, scanning posts, and look-ins at both Crawlspaces.
func test_posts_declare_idle_behaviours() -> void:
	var h: Node = load(SCENE).instantiate()
	var posts: Array = h.get_node("GuardPosts").get_children()
	assert_eq(posts.filter(func(p: Node) -> bool: return p.has_meta("chat")).size(), 1)
	assert_true(posts.filter(func(p: Node) -> bool: return p.has_meta("scan")).size() >= 3)  # the gangway, the roof, the south door
	var look_ins: Array = h.get_node("ExtraGuardPosts/PostExtra1").get_children()
	assert_true(look_ins.all(func(m: Node) -> bool: return m.has_meta("hold")), "Stealth L2 looks into the Crawlspaces")
	h.free()


func test_ladders_have_both_ends() -> void:
	var h: Node = load(SCENE).instantiate()
	var ladders: Array = h.get_node("Ladders").get_children()
	assert_eq(ladders.size(), 2)
	for l: Node3D in ladders:
		assert_true(l.is_in_group("ladders"))
		assert_true(l.get_node("Top").position.y > l.get_node("Bottom").position.y + 3.0, l.name)
	h.free()


## Guards never climb: a spot on a Ladder's roof sends them to its foot; the deck below it doesn't.
func test_a_roof_spot_sends_guards_to_the_ladder_foot() -> void:
	var l := Node3D.new()
	for end in [["Bottom", Vector3(0, 0, 0)], ["Top", Vector3(0, 6, -2)]]:
		var m := Marker3D.new()
		m.name = end[0]
		m.position = end[1]
		l.add_child(m)
	Engine.get_main_loop().root.add_child(l)
	assert_eq(Guard.ladder_foot(Vector3(-8, 6, -5), [l]), Vector3.ZERO)
	assert_eq(Guard.ladder_foot(Vector3(-8, 2, -5), [l]), Vector3(-8, 2, -5))
	assert_eq(Guard.ladder_foot(Vector3(-30, 6, -5), [l]), Vector3(-30, 6, -5))
	l.free()


## Each Crawlspace has a 1.2 m ceiling and a carry block at both mouths, solid only on the carry layer.
func test_crawlspaces_refuse_a_carried_body() -> void:
	var h: Node = load(SCENE).instantiate()
	var crawls: Array = h.get_node("NavRegion/Crawlspaces").get_children()
	assert_eq(crawls.size(), 3)
	for c: Node in crawls:
		var blocks := c.get_children().filter(func(b: Node) -> bool: return b.name.begins_with("CarryBlock"))
		assert_eq(blocks.size(), 2, c.name)
		for b: StaticBody3D in blocks:
			assert_eq(b.collision_layer, 1 << 3, "only an Operative carrying a body collides")
		var ceiling: StaticBody3D = c.get_node("Ceiling")
		var size: Vector3 = (ceiling.get_node("Shape") as CollisionShape3D).shape.size
		assert_true(is_equal_approx(ceiling.position.y - size.y / 2, 1.2), c.name)
	h.free()
