@tool
extends McpTestSuite

## A Target's hitbox follows its own body: the capsule is as tall as the model and the headshot line sits at its
## skull, where a guard's stays at Nikita's.

const GUARD := preload("res://actors/guard/guard.tscn")


func suite_name() -> String:
	return "target_hitbox"


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func _guard(target: bool, female := false) -> Guard:
	var g: Guard = GUARD.instantiate()
	g.target = target
	if target:
		g.get_node("Model").kind = CharacterModel.Kind.TARGET
		g.get_node("Model").female = female
	_root().add_child(g)
	return g


func test_a_target_capsule_is_as_tall_as_its_model() -> void:
	for female in [false, true]:
		var t := _guard(true, female)
		var capsule := t.get_node("Shape").shape as CapsuleShape3D
		assert_true(absf(capsule.height - t.model.crown_height(0.0)) < 0.01, "the capsule reaches the crown, no further")
		assert_true(absf(t.get_node("Shape").position.y - capsule.height / 2.0) < 0.01, "and stands on the floor")
		assert_true(capsule.height < 1.79, "not the guard's 1.8 m")
		t.free()


func test_the_headshot_line_is_at_the_targets_skull() -> void:
	var t := _guard(true)
	assert_true(absf(t.head_height - t.model.skull_height(0.0)) < 0.001)
	assert_true(t.head_height < t.model.crown_height(0.0) - 0.1, "below the crown: a face shot counts")
	t.free()


func test_a_guard_keeps_the_default_hitbox() -> void:
	var g := _guard(false)
	assert_true(absf((g.get_node("Shape").shape as CapsuleShape3D).height - 1.8) < 0.001)
	assert_eq(g.head_height, Guard.HEAD_HEIGHT)
	g.free()


func test_a_targets_hitbox_does_not_reshape_the_guards_sharing_the_scene() -> void:
	var t := _guard(true)
	var g := _guard(false)
	assert_true(absf((g.get_node("Shape").shape as CapsuleShape3D).height - 1.8) < 0.001, "the scene's shared capsule is left alone")
	t.free()
	g.free()
