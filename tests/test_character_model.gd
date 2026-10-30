@tool
extends McpTestSuite

## Which clip each actor shows, and that the baked clips bind to the Quaternius skeleton.


func suite_name() -> String:
	return "character_model"


func test_operative_clip_priority() -> void:
	var clip := CharacterModel.operative_clip
	assert_eq(clip.call(true, true, true, true, true, false), "takedown", "a choke beats everything")
	assert_eq(clip.call(false, true, true, true, true, true), "carry", "carrying beats aim and crouch")
	assert_eq(clip.call(false, true, false, false, false, false), "carry_idle", "carrying but standing still")
	assert_eq(clip.call(false, false, true, true, true, false), "crouch_aim", "aiming crouched keeps it low")
	assert_eq(clip.call(false, false, true, false, true, false), "aim")
	assert_eq(clip.call(false, false, false, true, true, false), "crouch_walk")
	assert_eq(clip.call(false, false, false, true, false, false), "crouch_idle")
	assert_eq(clip.call(false, false, false, false, true, true), "walk")
	assert_eq(clip.call(false, false, false, false, true, false), "run")
	assert_eq(clip.call(false, false, false, false, false, false), "idle")
	assert_eq(clip.call(false, false, true, false, true, false, "climb"), "climb", "a task beats aim and movement")
	assert_eq(clip.call(true, false, false, false, false, false, "use"), "takedown", "but not a choke")


func test_guard_clip_by_speed() -> void:
	assert_eq(CharacterModel.guard_clip(true, 5.0), "down")
	assert_eq(CharacterModel.guard_clip(false, 0.0), "idle")
	assert_eq(CharacterModel.guard_clip(false, 2.0), "walk")
	assert_eq(CharacterModel.guard_clip(false, 5.0), "run")
	assert_eq(CharacterModel.guard_clip(true, 0.0, true), "dead", "killed on its feet: it falls")


func test_dead_falls_back_to_down_without_the_mixamo_bake() -> void:
	var m := CharacterModel.new()
	_root().add_child(m)
	var anim: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
	m.play("dead")
	assert_eq(anim.current_animation, "dead" if anim.has_animation("dead") else "down")
	m.free()


func test_every_clip_the_game_asks_for_is_baked() -> void:
	for c in ["idle", "walk", "run", "crouch_idle", "crouch_walk", "aim", "takedown", "down", "carry", "hit"]:
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
	assert_eq(anim.current_animation, "hg_pistol_run", "the pistol has its own run take")
	m.play("crouch_walk")
	assert_eq(anim.current_animation, "crouch_walk", "no pistol crouch-walk take: the shared one covers")
	m.free()


func test_walk_is_paced_to_ground_speed() -> void:
	if not ResourceLoader.exists(CharacterModel.MIXAMO):
		return
	var m := CharacterModel.new()
	_root().add_child(m)
	var anim: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
	m.hold("rifle")
	var natural: float = anim.get_animation("walk").get_meta("speed")
	m.play("walk", natural * 1.2)
	assert_true(is_equal_approx(anim.speed_scale, 1.2), "feet keep up with the body")
	m.play("walk", natural * 10.0)
	assert_true(is_equal_approx(anim.speed_scale, 1.5), "clamped")
	m.play("idle", 3.0)
	assert_true(is_equal_approx(anim.speed_scale, 1.0), "in-place clips play as made")
	m.free()


func test_a_radio_call_puts_the_hand_at_the_ear_without_a_spasm() -> void:
	if not ResourceLoader.exists(CharacterModel.MIXAMO):
		return
	var m := CharacterModel.new()
	_root().add_child(m)
	var anim: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
	var call_time := AlertChain.CALL_TIME - GuardAlert.FLINCH
	m.react("hand_to_ear", call_time, CharacterModel.EAR_SPEED)
	var head := m.skeleton.get_bone_global_pose(m.skeleton.find_bone("Head")).origin
	for i in int(call_time * 60):  # frame by frame, as the game advances it
		anim.advance(1.0 / 60)
	var hand := m.skeleton.get_bone_global_pose(m.skeleton.find_bone("hand_r")).origin
	assert_true(hand.distance_to(head) < 0.3, "right hand at the ear when the call ends (%.2f m)" % hand.distance_to(head))
	m.free()


func test_bone_axis_picks_the_axis_a_direction_follows() -> void:
	assert_eq(CharacterModel._bone_axis(Vector3(0.9, 0.1, 0)), 0, "+X")
	assert_eq(CharacterModel._bone_axis(Vector3(-0.9, 0.1, 0)), 1, "-X")
	assert_eq(CharacterModel._bone_axis(Vector3(0.1, 0.8, 0.2)), 2, "+Y")
	assert_eq(CharacterModel._bone_axis(Vector3(0, 0.1, -1)), 5, "-Z")


func test_a_guard_gets_a_head_look_at_that_starts_off() -> void:
	var m := CharacterModel.new()
	_root().add_child(m)
	assert_true(m._look != null, "a LookAtModifier3D on the head")
	assert_eq(m._look.influence, 0.0)
	m.free()
