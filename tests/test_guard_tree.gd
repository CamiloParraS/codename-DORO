@tool
extends McpTestSuite

## The guard behaviour tree picks the branch for each alert state. A stub agent records the moves.
## Also how closely a guard's NavAgent follows the path the tree walks.

const TREE := "res://actors/guard/guard_tree.tres"


class StubGuard:
	extends Node
	var alert := GuardAlert.new()
	var calls: Array[String] = []
	var order_left := 0  # frames of radio order left to carry out

	func follow_order(_delta: float) -> bool:
		if order_left <= 0:
			return false
		order_left -= 1
		calls.append("order")
		return true

	func patrol(_delta: float) -> void:
		calls.append("patrol")

	func search(_delta: float, speed: float, _sweep: float) -> void:
		calls.append("search %.1f" % speed)

	func chase(_delta: float) -> void:
		calls.append("chase")

	var close := false

	func too_close() -> bool:
		return close

	func retreat(_delta: float) -> bool:
		calls.append("retreat")
		return false

	var new_stop := false  # one fidget chance at a stop, then the stop is over
	var fidgets := 0

	func at_new_stop() -> bool:
		var was := new_stop
		new_stop = false
		return was

	func fidget() -> void:
		fidgets += 1
		calls.append("fidget")

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
	assert_eq(bt.root_task.get_child_count(), 5)


func test_patrol_walks_the_route() -> void:
	var t := _tree_for(GuardAlert.State.PATROL)
	t[1].update(0.1)
	assert_eq(t[0].calls, ["patrol"])


func test_patrol_may_fidget_at_a_stop_then_keeps_walking() -> void:
	seed(1)
	var fidgets := 0
	for n in 40:  # a 40% chance at each stop
		var t := _tree_for(GuardAlert.State.PATROL)
		t[0].new_stop = true
		t[1].update(0.1)
		fidgets += t[0].fidgets
		assert_eq(t[0].calls[-1], "patrol", "the walk goes on after the fidget")
	assert_true(fidgets > 0 and fidgets < 40, "fidgeted %d of 40 stops" % fidgets)


func test_a_fidget_is_on_cooldown_afterwards() -> void:
	seed(3)
	var t := _tree_for(GuardAlert.State.PATROL)
	var fidgets := 0
	for i in 150:  # a fresh stop every tick for 15 s, inside the 20 s cooldown
		t[0].new_stop = true
		t[1].update(0.1)
		fidgets += t[0].calls.count("fidget")
		t[0].calls.clear()
	assert_eq(fidgets, 1, "one fidget in the cooldown")


func test_running_path_names_the_branch_in_play() -> void:
	var t := _tree_for(GuardAlert.State.PATROL)
	t[1].update(0.1)
	assert_eq(BtTrace.running_path(t[1].get_root_task()), "Guard > Patrol > Walk route")


func test_patrol_carries_out_a_radio_order_first() -> void:
	var t := _tree_for(GuardAlert.State.PATROL)
	t[0].order_left = 2
	for i in 3:
		t[1].update(0.1)
	assert_eq(t[0].calls, ["order", "order", "patrol"])


func test_alert_chases() -> void:
	var t := _tree_for(GuardAlert.State.ALERT)
	t[1].update(0.1)
	assert_eq(t[0].calls, ["chase"])


func test_alert_retreats_while_the_operative_is_too_close_and_keeps_at_it() -> void:
	var t := _tree_for(GuardAlert.State.ALERT)
	t[0].close = true
	t[1].update(0.1)
	t[0].close = false  # nearer than it was, the retreat is not asked again: it runs on
	t[1].update(0.1)
	assert_eq(t[0].calls, ["retreat", "retreat"])


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


## Turning round a wall end into a 2 m doorway, a guard who drops the corner point 0.5 m early steers
## straight into the jamb and stops there (the Research annex's researcher did, at the lab door).
func test_guards_follow_the_path_closely_enough_to_turn_through_a_doorway() -> void:
	# from disk: the editor keeps the copy the Areas' scripts preloaded
	var g: Node = ResourceLoader.load("res://actors/guard/guard.tscn", "", ResourceLoader.CACHE_MODE_IGNORE).instantiate()
	assert_true((g.get_node("NavAgent") as NavigationAgent3D).path_desired_distance <= 0.25)
	g.free()


## A guard sent somewhere it can't reach (a rail edge, a deck above it) stops short with the path unfinished.
## WalkStall calls that arrived once it has gained nothing for AFTER s, so it searches from where it stands
## instead of standing there for good (play_harbour's stopped call: two responders froze by the port rail).
func test_a_walk_that_stops_gaining_counts_as_arrived() -> void:
	var w := WalkStall.new()
	var goal := Vector3(26, 2, 6)
	for d: float in [8.0, 6.0, 4.0, 2.0, 1.4]:  # closing in: never stuck
		w.step(goal, d, 0.25)
		assert_false(w.stuck(goal), "still gaining at %.1f m" % d)
	for i in 5:  # 1.25 s pinned at 1.33 m
		w.step(goal, 1.33, 0.25)
	assert_false(w.stuck(goal), "not yet: under AFTER")
	w.step(goal, 1.33, 0.5)
	assert_true(w.stuck(goal), "AFTER s without gaining GAIN: as close as it gets")


func test_a_stall_is_per_goal_and_a_nudged_goal_is_the_same_goal() -> void:
	var w := WalkStall.new()
	var goal := Vector3(26, 2, 6)
	w.step(goal, 5.0, 0.1)
	w.step(goal, 5.0, WalkStall.AFTER)
	assert_true(w.stuck(goal))
	assert_true(w.stuck(goal + Vector3(0, 0, 0.2)), "a sighting point nudged by footsteps is the same place")
	assert_false(w.stuck(goal + Vector3(6, 0, 0)), "another goal: not stuck there")
	w.step(goal + Vector3(6, 0, 0), 9.0, 0.1)  # walking to the new goal starts over
	assert_false(w.stuck(goal + Vector3(6, 0, 0)))
	w.step(goal + Vector3(6, 0, 0), 9.0 - WalkStall.GAIN * 0.5, WalkStall.AFTER)  # creeping by less than GAIN is no progress
	assert_true(w.stuck(goal + Vector3(6, 0, 0)))
