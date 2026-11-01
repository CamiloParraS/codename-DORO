@tool
extends McpTestSuite

## What a guard with a scripted Hold-up answer leaves behind (DroppedItem): once, whether killed or questioned.

const GUARD := preload("res://actors/guard/guard.tscn")


func suite_name() -> String:
	return "dropped_item"


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _drops() -> Array:
	return _root().get_children().filter(func(n: Node) -> bool: return n is DroppedItem)


func _guard(answer: String) -> Guard:
	AlertChain.area = AlertChain.new()
	var g: Guard = GUARD.instantiate()
	g.name = "Foreman"
	g.holdup_answer = answer
	_root().add_child(g)
	g.global_position = Vector3(0, 0, 0)
	return g


func _clear(g: Guard) -> void:
	for d: Node in _drops():
		d.free()
	g.free()


func test_a_killed_guard_with_a_scripted_answer_drops_it() -> void:
	var g := _guard("lift_code")
	g.kill()
	assert_eq(_drops().size(), 1, "one drop")
	g.kill()
	g.frisk(null)
	assert_eq(_drops().size(), 1, "still one")
	_clear(g)


func test_a_guard_with_no_scripted_answer_drops_nothing() -> void:
	var g := _guard("")
	g.kill()
	assert_eq(_drops().size(), 0)
	_clear(g)


func test_a_neutralized_guard_drops_it_too() -> void:
	var g := _guard("lift_code")
	g.neutralize()
	assert_eq(_drops().size(), 1)
	_clear(g)
