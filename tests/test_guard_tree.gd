@tool
extends McpTestSuite

## The guard behaviour tree picks the branch for each alert state. A stub agent records the moves.

const TREE := "res://actors/guard/guard_tree.tres"


class StubGuard:
	extends Node
	var alert := GuardAlert.new()
	var calls: Array[String] = []

	func patrol(_delta: float) -> void:
		calls.append("patrol")

	func search(_delta: float, speed: float, _sweep: float) -> void:
		calls.append("search %.1f" % speed)

	func chase(_delta: float) -> void:
		calls.append("chase")

	func face(_pos: Vector3, _delta: float) -> void:
		calls.append("face")


func suite_name() -> String:
	return "guard_tree"


func _tree_for(state: GuardAlert.State) -> Array:
	var agent: StubGuard = track(StubGuard.new())
	agent.alert.state = state
	var bt: BehaviorTree = load(TREE)
	var inst = bt.instantiate(agent, Blackboard.new(), agent, agent)
	return [agent, inst]


func test_tree_loads_with_a_branch_per_state() -> void:
	var bt: BehaviorTree = load(TREE)
	assert_true(bt != null)
	assert_eq(bt.root_task.get_child_count(), 4)


func test_patrol_walks_the_route() -> void:
	var t := _tree_for(GuardAlert.State.PATROL)
	t[1].update(0.1)
	assert_eq(t[0].calls, ["patrol"])


func test_alert_chases() -> void:
	var t := _tree_for(GuardAlert.State.ALERT)
	t[1].update(0.1)
	assert_eq(t[0].calls, ["chase"])


func test_evasion_searches_fast() -> void:
	var t := _tree_for(GuardAlert.State.EVASION)
	t[1].update(0.1)
	assert_eq(t[0].calls, ["search 3.0"])


func test_suspicion_turns_for_1s_then_investigates_slowly() -> void:
	var t := _tree_for(GuardAlert.State.SUSPICION)
	var inst = t[1]
	for i in 9:
		inst.update(0.1)
	assert_false(t[0].calls.has("search 1.6"), "still turning: %s" % str(t[0].calls))
	assert_eq(t[0].calls[0], "face")
	for i in 4:
		inst.update(0.1)
	assert_eq(t[0].calls[-1], "search 1.6")


func test_bt_player_can_restart_on_state_change() -> void:
	assert_true(ClassDB.class_has_method("BTPlayer", "restart"))
