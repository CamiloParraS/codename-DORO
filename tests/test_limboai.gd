@tool
extends McpTestSuite

## LimboAI smoke test: a trivial behaviour tree ticks on this Godot version.
## Built through ClassDB so a missing extension fails the test instead of the parse.

const SUCCESS := 3  # BT.SUCCESS (FRESH 0, RUNNING 1, FAILURE 2)


func suite_name() -> String:
	return "limboai"


func test_trivial_tree_ticks_to_success() -> void:
	for cls in ["BehaviorTree", "BTSequence", "BTAlwaysSucceed", "Blackboard"]:
		assert_true(ClassDB.class_exists(cls), "LimboAI class %s missing" % cls)
		if not ClassDB.class_exists(cls):
			return
	var seq = ClassDB.instantiate("BTSequence")
	seq.add_child(ClassDB.instantiate("BTAlwaysSucceed"))
	var tree = ClassDB.instantiate("BehaviorTree")
	tree.root_task = seq
	var agent := track(Node.new())
	var root = tree.instantiate(agent, ClassDB.instantiate("Blackboard"), agent, agent)
	assert_eq(root.update(0.016), SUCCESS)
