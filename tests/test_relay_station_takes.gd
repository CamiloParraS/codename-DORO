@tool
extends McpTestSuite

## The Relay Station's takes: "Up the Signal" (intro) and "Dead Air" (outro). Both are declared by Mission 2, short, one rail;
## the intro shows the antenna's signal sprites (the Spoofing look), has the Operative run in from the side and hands him over
## at the start spot with no guard able to see him; the outro starts where control stood and takes him up the Fulton line
## from the helipad (the Chief, if carried, held on his shoulder: never touched), killing the lamps in order and ending on black.

const SCENE := "res://areas/relay_station/relay_station.tscn"

var _area: Node


func suite_name() -> String:
	return "relay_station_takes"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()


func test_mission_two_declares_both_takes_and_their_text() -> void:
	assert_eq(Campaign.cine_of(1), {intro = "CineIntro", outro = "CineOutro"})
	for k: String in ["intro.m2.name", "intro.m2.area", "intro.m2.stamp", "outro.m2.title", "outro.m2.line"]:
		assert_true(TranslationServer.translate(k) != k, "%s has a line" % k)
	_area = _relay()
	for key in ["CineIntro", "CineOutro"]:
		var p := Cine.take_of(_area, key)
		assert_true(p != null, key)
		assert_true(CineLogic.length_ok(p), "within its own range")
		var len := p.get_animation("take").length
		assert_true(len >= 8.0 and len <= 11.0, "%s short: %.1f s" % [key, len])
		assert_eq(p.get_meta("pcams").size(), 1, "one continuous camera")


func test_the_intro_props_are_mesh_only_and_hidden_in_play() -> void:
	_area = _relay()
	var props: Node3D = _area.get_node("Cine/IntroProps")
	var p := Cine.take_of(_area, "CineIntro")
	p.play("take")
	p.seek(1.0, true)
	assert_true(props.visible, "the take shows them")
	p.seek(p.get_animation("take").length, true)
	assert_false(props.visible, "and hides them when control returns")
	p.stop()
	for n in ["Radio", "Pulse"]:
		var sprite := props.get_node(n) as Sprite3D
		assert_true(sprite != null and sprite.texture == RadioLook.SIGNAL_ICON, "%s is the Spoofing signal sprite" % n)
	assert_eq(props.find_children("*", "Guard", true, false).size(), 0)
	for n in props.find_children("*", "CollisionObject3D", true, false):
		assert_true(false, "no colliders: %s" % n.name)


func test_the_intro_ends_at_the_start_with_the_operative_running_in_from_the_side() -> void:
	_area = _relay()
	var p := Cine.take_of(_area, "CineIntro")
	var op: Node3D = _area.get_node("Operative")
	var start: Vector3 = _area.get_node("Spots/OperativeStart").position
	var clip := p.get_animation("take")
	var ot := clip.find_track(NodePath("../Operative:position"), Animation.TYPE_VALUE)
	assert_true(ot >= 0, "he comes in")
	var from: Vector3 = clip.track_get_key_value(ot, 0)
	assert_true(from.distance_to(start) > 5.0, "from off to the side, %.1f m out" % from.distance_to(start))
	assert_true(clip.track_get_key_value(ot, clip.track_get_key_count(ot) - 1).distance_to(start) < 0.1, "and stops on the start spot")
	assert_true(clip.track_get_key_time(ot, 0) > 6.0, "after the camera has come down, not before")
	assert_true(clip.find_track(NodePath("../Operative:moving"), Animation.TYPE_VALUE) >= 0, "he runs")
	assert_true(clip.track_get_key_time(ot, clip.track_get_key_count(ot) - 1) < clip.length - 0.4, "and is still before control")
	var pose := RelayCine.rig_pose(start, _area.get_node("Spots/OperativeStart").rotation.y)
	var ti := clip.find_track(NodePath("CineIntroRig/Dolly:position"), Animation.TYPE_VALUE)
	assert_true(clip.track_get_key_value(ti, clip.track_get_key_count(ti) - 1).distance_to(pose[0]) < 0.05, "ends on the rig's pose")


func test_no_guard_cone_can_reach_the_start_during_the_intro() -> void:
	_area = _relay()
	var start: Vector3 = _area.get_node("Spots/OperativeStart").position
	var checked := 0
	for post: Marker3D in _area.get_node("GuardPosts").get_children():
		checked += 1
		assert_true(post.position.distance_to(start) > GuardVision.FRONT_RANGE, "%s sees the start" % post.name)
		for wp: Marker3D in post.get_children():
			assert_true(wp.position.distance_to(start) > GuardVision.FRONT_RANGE, "%s's route sees the start" % post.name)
	assert_true(checked > 3)


func test_the_outro_fultons_him_from_the_helipad_and_never_touches_the_chief() -> void:
	_area = _relay()
	var ep: Vector3 = _area.get_node("Spots/Extraction").position
	var zone: Vector3 = _area.get_node("ExtractionPoint").position
	var p := Cine.take_of(_area, "CineOutro")
	var clip := p.get_animation("take")
	var ti := clip.find_track(NodePath("../Operative:position"), Animation.TYPE_VALUE)
	var from: Vector3 = clip.track_get_key_value(ti, 0)
	var end: Vector3 = clip.value_track_interpolate(ti, clip.length)
	assert_true(Vector2(from.x, from.z).distance_to(Vector2(zone.x, zone.z)) < 2.5, "starts where control stood (no jump back)")
	assert_true(Vector2(end.x, end.z).distance_to(Vector2(ep.x, ep.z)) < 4.0, "goes straight up from the helipad")
	assert_true(end.y > from.y + 30.0, "and out of the frame: %.1f m up" % (end.y - from.y))
	assert_eq(clip.value_track_interpolate(clip.find_track(NodePath("../Operative:cine_clip"), Animation.TYPE_VALUE), clip.length), "hang", "hanging from the line")
	for i in clip.get_track_count():
		var path := str(clip.track_get_path(i))
		assert_false("Chief" in path or "carrying" in path or "Operative:visible" in path, "untouched: %s" % path)
	assert_true(p.has_meta("third_at"))
	assert_eq(Cine.variant_key(_area, "CineOutro"), "CineOutro", "one take, carrying or not")


func test_the_lamps_die_in_order_and_the_red_one_last() -> void:
	_area = _relay()
	var p := Cine.take_of(_area, "CineOutro")
	var clip := p.get_animation("take")
	var last := 0.0
	for d in RelayCine.DEAD:
		assert_true(_area.get_node_or_null("Beacons/Lamp%d/Light" % d[0]) != null, "Lamp%d exists" % d[0])
		assert_true(d[1] > last, "in order")
		last = d[1]
	assert_true(RelayCine.FLICKER[1] > last and RelayCine.FLICKER[-1] < clip.length - 0.5, "the red lamp goes last, before the black")
	assert_true(_area.get_node("Beacons/Lamp0/Light").light_color.r > 0.9, "Lamp0 is the antenna's red")
	p.play("take")
	p.seek(clip.length, true)
	for i in 8:
		assert_eq(_area.get_node("Beacons/Lamp%d/Light" % i).light_energy, 0.0, "Lamp%d is out" % i)
	p.stop()


func _relay() -> Node:
	var a: Node = load(SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	return a
