@tool
extends McpTestSuite

## In-world feedback (ticket 15): shot effects free themselves, the balloon inflates on a cable, a guard
## shows its Radio call and Caution on its body.

const GUARD := preload("res://actors/guard/guard.tscn")


func suite_name() -> String:
	return "fx"


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func test_puff_is_a_one_shot_burst_that_frees_itself() -> void:
	var p := Fx.puff(_root(), Vector3(1, 2, 3), Color.WHITE)
	assert_true(p.one_shot, "one shot")
	assert_true(p.emitting, "emitting")
	assert_eq(p.global_position, Vector3(1, 2, 3))
	assert_true(p.finished.is_connected(p.queue_free), "frees itself")
	_root().remove_child(p)
	p.queue_free()


func test_the_balloon_starts_small_inflates_and_hangs_on_a_cable() -> void:
	var b := Fx.balloon()
	assert_true(b.scale.x < 0.2, "starts deflated")
	assert_eq(b.get_child_count(), 2, "a cable and the pixel balloon")
	assert_true(b.get_child(0).mesh.height >= 3.0, "reaches the guard")
	b.free()


func test_a_flash_is_dimmer_when_suppressed() -> void:
	var loud := Fx.flash(_root(), Vector3.ZERO, false)
	var quiet := Fx.flash(_root(), Vector3.ZERO, true)
	assert_true(loud.get_child(0).light_energy > quiet.get_child(0).light_energy, "suppressed is dimmer")
	for f: Node in [loud, quiet]:
		_root().remove_child(f)
		f.free()


func test_a_guard_shows_its_radio_call_and_caution() -> void:
	AlertChain.area = AlertChain.new()
	var g: Guard = GUARD.instantiate()
	g.name = "Kostas"
	_root().add_child(g)
	g._voice_tick(0.1)
	assert_false(g._glint.visible, "no call")
	assert_false(g._vest.visible, "no Caution")
	AlertChain.area.start_call(g, Vector3.ZERO)
	g._voice_tick(0.1)
	assert_true(g._glint.visible, "red glint while calling")
	AlertChain.area = AlertChain.new()
	AlertChain.area.caution()
	g._voice_tick(0.1)
	assert_true(g._vest.visible, "amber vest light in Caution")
	g.neutralize()
	g._voice_tick(0.1)
	assert_false(g._vest.visible, "dark when Down")
	_root().remove_child(g)
	g.queue_free()
