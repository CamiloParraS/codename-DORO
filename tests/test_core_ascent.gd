@tool
extends McpTestSuite

## The Core's Ascent (tools/cine/core_ascent.gd, areas/core/ascent_set.gd): the finale's Epilogue plays over the lift
## rising out of the shaft; three variants of one set, picked by the Dominant Voice.

const SCENE := "res://areas/core/core.tscn"

var _area: Node


func suite_name() -> String:
	return "core_ascent"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()
	(Engine.get_main_loop() as SceneTree).paused = false


func _load(in_tree := false) -> Node:
	_area = load(SCENE).instantiate()
	if in_tree:
		(Engine.get_main_loop() as SceneTree).root.add_child(_area)
	return _area


func test_there_is_a_variant_for_every_ending() -> void:
	for ratio in [0.0, 0.25, 0.6, 1.0]:
		assert_true(Aigis.resolve_ending(ratio) in AscentLogic.VARIANTS, "ending at %.2f has a set" % ratio)
	assert_eq(AscentLogic.VARIANTS, Finale.STILLS.keys())


func test_the_shake_and_the_lamp_grow_with_lethality() -> void:
	assert_eq(AscentLogic.trauma("pallas"), 0.0)
	assert_true(AscentLogic.trauma("nike") > 0.0 and AscentLogic.trauma("gorgo") > AscentLogic.trauma("nike"))
	var steady := true
	var nike := {}
	for i in 40:
		steady = steady and AscentLogic.flicker("pallas", i * 0.1) == 1.0
		nike[snappedf(AscentLogic.flicker("nike", i * 0.1), 0.01)] = true
		assert_true(AscentLogic.flicker("gorgo", i * 0.1) >= 0.0)
	assert_true(steady, "the quiet ending's light never moves")
	assert_true(nike.size() > 1, "Nike's light flickers")


func test_only_the_chosen_set_is_visible() -> void:
	_load()
	var set: Node = _area.get_node(AscentLogic.SET)
	assert_false(set.visible, "the whole Ascent is dark until a variant is picked")
	for v in AscentLogic.VARIANTS:
		set.show_variant(v)
		assert_true(set.visible)
		for other: String in AscentLogic.VARIANTS:
			assert_eq(set.get_node("Ascent" + other.capitalize()).visible, other == v, "%s while %s" % [other, v])
		var cam: PhantomCamera3D = _area.get_node("Cine/CineAscentRig/Cam")
		assert_true(cam.environment != null, "%s has its own sky" % v)
		assert_eq(cam.noise.get("_trauma"), AscentLogic.trauma(v))


func test_the_skies_differ() -> void:
	_load()
	var set: Node = _area.get_node(AscentLogic.SET)
	var seen := {}
	for v in AscentLogic.VARIANTS:
		set.show_variant(v)
		var e: Environment = _area.get_node("Cine/CineAscentRig/Cam").environment
		seen[((e.sky.sky_material as ShaderMaterial).get_shader_parameter("horizon") as Color).to_html()] = true
	assert_eq(seen.size(), 3)


func test_the_ascent_is_a_short_take_on_the_descents_car() -> void:
	_load()
	var p := Cine.take_of(_area, AscentLogic.KEY)
	assert_true(p != null and CineLogic.length_ok(p), "inside its declared range")
	assert_true(p.get_animation("take").length <= 10.0, "a short take")
	assert_eq(p.get_meta("pcams").size(), 1, "one rail, no cut")
	assert_eq(_area.find_children("DescentCab", "Node3D", true, false).size(), 1, "the one car and shaft serve both takes")
	assert_true(_area.has_node("Cine/CineAscentRig/Path"))
	assert_true(_area.has_node("Cine/CineDescentRig/Path"))
	var clip := p.get_animation("take")
	var t := clip.find_track(NodePath("../Operative:position"), Animation.TYPE_VALUE)
	assert_true((clip.track_get_key_value(t, 0) as Vector3).distance_to(CoreCine.stand()) < 0.01, "the Operative stands in the car")


func test_the_finale_runs_the_epilogue_over_a_held_take() -> void:
	_load(true)
	var finale: Control
	for c in _area.get_children():
		if c is Control and c.is_in_group("finale"):
			finale = c
	assert_true(finale != null)
	finale.model = Finale.new("gorgo", 0)
	(Engine.get_main_loop() as SceneTree).paused = true
	Engine.time_scale = 0.3
	var take: Cine = finale._ascend()
	assert_true(take != null)
	assert_false((Engine.get_main_loop() as SceneTree).paused, "the world runs under the take")
	assert_eq(Engine.time_scale, 1.0)
	assert_true(_area.get_node(AscentLogic.SET + "/AscentGorgo").visible)
	var held := []
	take.held.connect(func(s: bool) -> void: held.append(s))
	take._on_finished(&"take")
	assert_false(take.done, "the last frame is held while the Epilogue is read")
	assert_eq(held, [false])


func test_a_skip_holds_the_last_frame_and_tells_the_finale_to_leave() -> void:
	_load(true)
	_area.get_node(AscentLogic.SET).show_variant("nike")
	var take := Cine.new()
	take.hold = true
	var held := []
	take.held.connect(func(s: bool) -> void: held.append(s))
	assert_true(take.play(_area, AscentLogic.KEY, func() -> void: pass))
	take.skip()
	assert_eq(held, [true])
	assert_false(take.done)
	take.release()
	assert_true(take.done)


func test_the_camera_faces_the_operative_in_the_car_from_its_gate() -> void:
	_load()
	var p := Cine.take_of(_area, AscentLogic.KEY)
	var clip := p.get_animation("take")
	assert_true(clip.length >= 8.0 and clip.length <= 9.0, "8 to 9 s")
	var op := CoreCine.stand() + Vector3(0, 1.5, 0)
	var rig := _area.get_node("Cine/CineAscentRig") as Node3D
	for key in [&"Dolly", &"LookTarget"]:
		var t := clip.find_track(NodePath("CineAscentRig/%s:position" % key), Animation.TYPE_VALUE)
		for i in clip.track_get_key_count(t):
			var v: Vector3 = rig.transform * clip.track_get_key_value(t, i)
			if key == &"Dolly":
				assert_true(v.distance_to(op) < 3.5, "never pulls back from him: %s" % v)
				assert_true(v.z < CoreCine.CAB.z - 2.0, "stands outside the gate, facing in")
			else:
				assert_true(v.distance_to(op) < 0.5, "aimed at him")
	assert_false(_area.has_node("Cine/AscentSkyline"), "no skyline to model")
	_area.get_node(AscentLogic.SET).show_variant("gorgo")
	assert_true(_area.get_node("DescentCab/CabRoof").visible and _area.get_node("DescentCab/CabBack").visible, "the car stays shut")
