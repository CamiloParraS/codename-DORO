@tool
extends McpTestSuite

## Checkpoint snapshots: MissionRun.copy gives a deep, independent copy of a node-free state object.


func suite_name() -> String:
	return "checkpoint"


func test_a_gun_copy_keeps_its_ammo_and_suppressor() -> void:
	var r := Rifle.new()
	for i in 2:
		r.fire(false)
		r.tick(Rifle.INTERVAL, false)
	var c: Rifle = MissionRun.copy(r)
	assert_eq(c.loaded, 10)
	assert_eq(c.suppressor, 1)
	c.fire(false)
	assert_eq(r.loaded, 10, "firing the copy leaves the original alone")


func test_voiceprints_copy_is_deep() -> void:
	var v := Voiceprints.new()
	v.held.append("Guard01")
	v.progress["Guard02"] = 1.0
	var c: Voiceprints = MissionRun.copy(v)
	c.held.append("Guard03")
	c.progress["Guard02"] = 2.0
	assert_eq(v.held, ["Guard01"] as Array[String])
	assert_eq(v.progress["Guard02"], 1.0)
	assert_eq(c.held, ["Guard01", "Guard03"] as Array[String])


func test_tally_and_flags_roll_back() -> void:
	var t := MissionTally.new()
	t.add("kill")
	var g := Glaukopis.new()
	g.flagged.append("Guard01")
	var saved_t: MissionTally = MissionRun.copy(t)
	var saved_g: Glaukopis = MissionRun.copy(g)
	t.add("kill")
	g.flagged.append("Guard02")
	assert_eq(saved_t.counts, {"kill": 1})
	assert_eq(saved_g.flagged, ["Guard01"] as Array[String])


## A guard Neutralized at the Checkpoint stays Down where it lay with the time it had left; the Checkpoint's
## return_to_post alone would stand it up at its post.
func test_a_guard_neutralized_at_the_checkpoint_stays_down_after_a_restore() -> void:
	var g: Guard = load("res://actors/guard/guard.tscn").instantiate()
	_root().add_child(g)
	g.global_position = Vector3(3, 0, 4)
	g.post = Transform3D(Basis.IDENTITY, Vector3(10, 0, 0))
	g.neutralize()
	g.neutral_left = 40.0
	var lay := g.global_transform
	g.return_to_post()
	assert_false(g.is_down(), "return_to_post stands it up at its post")
	g.stay_down(lay, 40.0, false)
	assert_true(g.is_down() and not g.dead, "Down again, not dead")
	assert_eq(g.neutral_left, 40.0)
	assert_eq(g.global_position, Vector3(3, 0, 4), "where it lay")
	assert_eq(g.collision_layer, 0, "a body, not solid")
	g.free()


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root
