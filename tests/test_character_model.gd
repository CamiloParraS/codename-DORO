@tool
extends McpTestSuite

## Which clip each actor shows, and that the baked clips bind to the Quaternius skeleton.


func suite_name() -> String:
	return "character_model"


func test_operative_clip_priority() -> void:
	var clip := CharacterModel.operative_clip
	assert_eq(clip.call(true, true, true, true, true, false), "takedown", "a choke beats everything")
	assert_eq(clip.call(false, true, true, true, true, true), "carry", "carrying beats aim and crouch")
	assert_eq(clip.call(false, true, false, false, false, false), "idle", "carrying but standing still")
	assert_eq(clip.call(false, false, true, true, true, false), "aim")
	assert_eq(clip.call(false, false, false, true, true, false), "crouch_walk")
	assert_eq(clip.call(false, false, false, true, false, false), "crouch_idle")
	assert_eq(clip.call(false, false, false, false, true, true), "walk")
	assert_eq(clip.call(false, false, false, false, true, false), "run")
	assert_eq(clip.call(false, false, false, false, false, false), "idle")


func test_guard_clip_by_speed() -> void:
	assert_eq(CharacterModel.guard_clip(true, 5.0), "down")
	assert_eq(CharacterModel.guard_clip(false, 0.0), "idle")
	assert_eq(CharacterModel.guard_clip(false, 2.0), "walk")
	assert_eq(CharacterModel.guard_clip(false, 5.0), "run")


func test_every_clip_the_game_asks_for_is_baked() -> void:
	for c in ["idle", "walk", "run", "crouch_idle", "crouch_walk", "aim", "takedown", "down", "carry"]:
		assert_true(CharacterModel.CLIPS.has_animation(c), c)


func test_tracks_bind_to_the_skeleton() -> void:
	var m := CharacterModel.new()
	_root().add_child(m)
	var anim: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
	var walk := CharacterModel.CLIPS.get_animation("walk")
	var missing := 0
	for i in walk.get_track_count():
		if anim.get_node(anim.root_node).get_node_or_null(NodePath(walk.track_get_path(i).get_concatenated_names())) == null:
			missing += 1
	m.free()
	assert_eq(missing, 0, "tracks without a node")


func test_countermeasure_gear_shows_only_once_worn() -> void:
	var m := CharacterModel.new()
	_root().add_child(m)
	var helmet: Node3D = m.skeleton.find_child("Helmet", true, false)
	assert_false(helmet.visible)
	assert_false((m.skeleton.find_child("Vest", true, false) as Node3D).visible)
	m.wear("Helmet")
	assert_true(helmet.visible)
	assert_true((m.skeleton.find_child("Chest_rig", true, false) as Node3D).visible, "a guard's own rig")
	m.free()


func test_carry_mount_hangs_on_a_bone() -> void:
	var m := CharacterModel.new()
	_root().add_child(m)
	assert_true(m.carry_mount().get_parent() is BoneAttachment3D)
	m.free()


func test_a_ridden_model_goes_home_when_dropped() -> void:
	var home := Node3D.new()
	var carrier := CharacterModel.new()
	var m := CharacterModel.new()
	_root().add_child(home)
	_root().add_child(carrier)
	home.add_child(m)
	m.ride(carrier.carry_mount())
	assert_eq(m.get_parent(), carrier.carry_mount())
	m.ride(null)
	assert_eq(m.get_parent(), home)
	home.free()
	carrier.free()


func test_target_uses_the_psx_body_and_ignores_countermeasures() -> void:
	var m := CharacterModel.new()
	m.kind = CharacterModel.Kind.TARGET
	_root().add_child(m)
	m.wear("Helmet")  # no such part on this body: must not crash
	assert_true(m.skeleton.find_bone("mixamorig_Hips") >= 0)
	m.free()


func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root


func test_hold_swaps_the_weapon_in_the_hand() -> void:
	var m := CharacterModel.new()
	_root().add_child(m)
	m.hold("rifle")
	var at: BoneAttachment3D = m.skeleton.find_children("*", "BoneAttachment3D", true, false)[0]
	assert_eq(at.bone_name, "hand_r")
	m.hold("tranq")
	assert_eq(m._gun.get_child_count(), CharacterModel.GUNS.tranq.scene.instantiate().get_child_count() + 1, "the pistol wears its suppressor")
	m.hold("")
	assert_true(m._gun == null, "an unknown name empties the hand")


func test_the_pistol_plays_its_own_clips() -> void:
	if not ResourceLoader.exists(CharacterModel.MIXAMO):
		return  # the Mixamo bake is gitignored; the Quaternius clips cover for it
	var m := CharacterModel.new()
	_root().add_child(m)
	var anim: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
	m.hold("rifle")
	m.play("idle")
	assert_eq(anim.current_animation, "idle")
	m.hold("tranq")
	m.play("idle")
	assert_eq(anim.current_animation, "pistol_idle", "the pistol idle, not the rifle's")
	m.play("run")
	assert_eq(anim.current_animation, "run", "no pistol run take: the shared one covers")
	m.free()
