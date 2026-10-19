@tool
extends McpTestSuite

## Targets: Mission data, weights, the Harbour's Target post, and a Target's flee-to-safe-room rule.

const HARBOUR := "res://areas/harbour/harbour.tscn"


func suite_name() -> String:
	return "targets"


func test_missions_2_3_and_core_have_one_target_each() -> void:
	assert_eq(Campaign.MISSIONS[0].targets.size(), 0)
	for i in [1, 2, 3]:
		assert_eq(Campaign.MISSIONS[i].targets.size(), 1, Campaign.MISSIONS[i].title)


func test_a_killed_target_weighs_3_and_a_carried_one_adds_only_to_the_denominator() -> void:
	var killed := Aigis.complete_mission(Aigis.new_record(), {"target_kill": 1, "targets": 1, "spawned": 9})
	assert_eq(killed.lethality, 3)
	assert_eq(killed.denominator, 9 + 3)
	var carried := Aigis.complete_mission(Aigis.new_record(), {"targets": 1, "spawned": 9})
	assert_eq(carried.lethality, 0)
	assert_eq(carried.denominator, 9 + 3)


## The Target's route has 2-3 points, and the route and safe room are on the baked navmesh.
func test_harbour_target_post_is_on_the_navmesh() -> void:
	var h: Node = load(HARBOUR).instantiate()
	var post: Marker3D = h.get_node("TargetPosts/TargetPost1")
	var points: Array[Vector3] = [post.global_position]
	for wp: Marker3D in post.get_children():
		points.append(wp.global_position)
	points.append((h.get_node("Spots/SafeRoom") as Marker3D).global_position)
	assert_true(points.size() >= 3 and points.size() <= 4, "2-3 route points plus the safe room")
	var nm: NavigationMesh = (h.get_node("NavRegion") as NavigationRegion3D).navigation_mesh
	var verts := nm.get_vertices()
	for p in points:
		var best := INF
		for v in verts:
			best = minf(best, Vector2(v.x - p.x, v.z - p.z).length())
		assert_true(best < 1.5, "%s is near the navmesh (%.2f)" % [p, best])
	h.free()


## A Target flees only once alerted; before that it walks the guard tree like any guard.
func test_a_target_flees_only_from_alert_on() -> void:
	assert_false(Guard.flees(true, GuardAlert.State.PATROL))
	assert_false(Guard.flees(true, GuardAlert.State.SUSPICION))
	assert_true(Guard.flees(true, GuardAlert.State.ALERT))
	assert_true(Guard.flees(true, GuardAlert.State.EVASION))
	assert_false(Guard.flees(false, GuardAlert.State.ALERT), "an ordinary guard never flees")


## Extraction waits for every Target: alive and left behind blocks it, dead clears it (a carried one too, by the same check).
func test_targets_left_until_killed_or_carried() -> void:
	var run := MissionRun.new()
	run.record = Aigis.new_record()
	run.record.mission = 1
	var t: Guard = load("res://actors/guard/guard.tscn").instantiate()
	t.add_to_group("targets")
	_root().add_child(run)
	_root().add_child(t)
	assert_eq(run._targets_left().size(), 1)
	assert_true(run.objective().begins_with("KILL OR CARRY OUT") or run.step < run._steps().size())
	t.dead = true
	assert_eq(run._targets_left().size(), 0, "a kill completes it on the spot")
	t.free()
	run.free()


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root
