@tool
extends McpTestSuite

## Checkpoint snapshots: MissionRun.copy gives a deep, independent copy of a node-free state object.


func suite_name() -> String:
	return "checkpoint"


func test_a_gun_copy_keeps_its_ammo_and_suppressor() -> void:
	var r := Rifle.new()
	for i in 3:
		r.fire(false)
		r.tick(Rifle.INTERVAL, false)
	var c: Rifle = MissionRun.copy(r)
	assert_eq(c.loaded, 27)
	assert_eq(c.suppressor, 7)
	c.fire(false)
	assert_eq(r.loaded, 27, "firing the copy leaves the original alone")


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
