@tool
extends McpTestSuite

## In a choke or at a hold-E console the movement keys don't move the Operative: he is drawn into place (behind
## the guard, onto the console's stand spot) and turned to face it; letting go frees the guard.

const OPERATIVE := preload("res://actors/operative/operative.tscn")
const GUARD := preload("res://actors/guard/guard.tscn")
const CONSOLE := preload("res://areas/relay_station/relay_console.gd")
const DT := 1.0 / 60


func suite_name() -> String:
	return "grip_pull"


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _operative(at: Vector3) -> Node:
	var op: Node = OPERATIVE.instantiate()
	_root().add_child(op)
	op.set_physics_process(false)  # driven by hand below
	op.set_process(false)
	op.global_position = at
	return op


func _guard(at: Vector3) -> Guard:
	var g: Guard = GUARD.instantiate()
	_root().add_child(g)
	g.set_physics_process(false)
	g.global_position = at
	return g


func test_a_choke_draws_him_behind_the_guard() -> void:
	var g := _guard(Vector3.ZERO)  # facing -Z: his back is +Z
	var op := _operative(Vector3(0.8, 0, 1.5))
	op._choking = g
	op._pull(DT)
	var v: Vector3 = op.velocity
	assert_true(is_equal_approx(Vector2(v.x, v.z).length(), op.PULL_SPEED), "far off: drawn in at PULL_SPEED")
	var want: Vector3 = (Vector3(0, 0, op.GRIP_DIST) - op.global_position).normalized()
	assert_gt(Vector3(v.x, 0, v.z).normalized().dot(want), 0.99, "towards the spot behind him")
	op.global_position = Vector3(0, 0, op.GRIP_DIST + 0.01)
	for i in 60:
		op._pull(DT)
	assert_true(absf(op.velocity.z * DT + 0.01) < 0.001, "close: the last step lands on the spot")
	assert_true(absf(angle_difference(op.model.rotation.y, 0.0)) < 0.05, "facing the way the guard faces")
	op.free()
	g.free()


func test_letting_go_frees_the_guard() -> void:
	var g := _guard(Vector3.ZERO)
	var op := _operative(Vector3(0, 0, 1))
	op._choking = g
	g.held = true
	op._let_go()
	assert_true(op._choking == null and not g.held, "no grip, the guard is free to act")
	op.free()
	g.free()


func test_a_console_draws_him_onto_its_stand_spot_facing_it() -> void:
	var c: Area3D = CONSOLE.new()
	c.stand = Vector3(0, -CONSOLE.FLOOR_DROP, -0.8)
	_root().add_child(c)
	c.global_position = Vector3(10, CONSOLE.FLOOR_DROP, 10)
	var op := _operative(Vector3(10.5, 0, 10.4))
	op.using = c
	for i in 120:
		op._pull(DT)
		op.global_position += Vector3(op.velocity.x, 0, op.velocity.z) * DT
	assert_true(Vector2(op.global_position.x - 10, op.global_position.z - 9.2).length() < 0.01, "on the stand spot")
	assert_true(absf(angle_difference(op.model.rotation.y, 0.0)) < 0.05, "facing the console (north)")
	op.free()
	c.free()


func test_the_console_only_counts_while_he_is_using_it() -> void:
	var c: Area3D = CONSOLE.new()
	c.hold_time = 1.0
	_root().add_child(c)
	var op := _operative(Vector3.ZERO)
	c._operative = op
	op.using = c
	c._physics_process(0.6)
	op.using = null  # E released or RMB pressed
	c._physics_process(0.6)
	assert_eq(c.held, 0.0, "letting go resets the hold")
	op.using = c
	c._physics_process(0.6)
	c._physics_process(0.6)
	assert_true(c.done, "a full hold finishes it")
	op.free()
	c.free()


## The Hold-up keeps RMB down, then E chokes: that aim must not cancel the grip; a fresh press of RMB does.
func test_only_a_fresh_aim_lets_go() -> void:
	var g := _guard(Vector3.ZERO)
	var op := _operative(Vector3(0, 0, 1.0))  # behind him
	Input.action_press("aim")
	op._physics_process(DT)  # aiming, as in a Hold-up
	op._choking = g
	op._choke_left = 10.0
	g.held = true
	Input.action_press("interact")
	op._physics_process(DT)
	assert_true(op._choking == g, "the Hold-up's aim, still held, keeps the grip")
	Input.action_release("aim")
	op._physics_process(DT)
	Input.action_press("aim")
	op._physics_process(DT)
	assert_true(op._choking == null and not g.held, "pressing RMB again lets go")
	Input.action_release("aim")
	Input.action_release("interact")
	op.free()
	g.free()
