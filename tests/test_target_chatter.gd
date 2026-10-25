@tool
extends McpTestSuite

## Target / escort chatter: keys per Mission, earshot gating, once per Mission.


func suite_name() -> String:
	return "target_chatter"


func test_keys_exist_for_every_mission_with_a_target() -> void:
	for m in range(1, Campaign.MISSIONS.size()):
		for k in TargetChatter.new(m).keys:
			assert_true(TranslationServer.translate(k) != k, "%s has no line" % k)


func test_target_opens_then_escort_then_target() -> void:
	var c := TargetChatter.new(1)
	assert_eq(c.keys[0], "target.m2.1")
	assert_eq(c.tick(0.1, true).seat, 0)
	assert_eq(c.tick(TargetChatter.TURN, true).seat, 1)
	assert_eq(c.tick(TargetChatter.TURN, true).seat, 0)


func test_silent_out_of_earshot_and_resumes_in_it() -> void:
	var c := TargetChatter.new(2)
	assert_true(c.tick(100.0, false).is_empty())
	assert_eq(c.tick(0.1, true).key, "target.m3.1")


func test_once_per_mission() -> void:
	var c := TargetChatter.new(3)
	for i in c.keys.size():
		assert_false(c.tick(TargetChatter.TURN, true).is_empty())
	assert_true(c.tick(1000.0, true).is_empty())
