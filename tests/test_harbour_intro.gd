@tool
extends McpTestSuite

## The Harbour's intro take, "Fog Level": declared by Mission 1, short, one rail from the water up to the bow, hands the
## Operative over at the start spot facing the start way, and no guard's cone can reach him while it plays.

const SCENE := "res://areas/harbour/harbour.tscn"
const KEY := "CineIntro"

var _area: Node


func suite_name() -> String:
	return "harbour_intro"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()


func test_mission_one_declares_the_intro_and_it_resolves() -> void:
	assert_eq(Campaign.cine_of(0).get("intro"), KEY)
	assert_eq(Campaign.cine_of(0).get("outro"), "CineOutro", "the outro is still there")
	_area = _harbour()
	var p := Cine.take_of(_area, KEY)
	assert_true(p != null, "the Harbour has the take")
	assert_true(CineLogic.length_ok(p), "within its own range")
	var len := p.get_animation("take").length
	assert_true(len >= 8.0 and len <= 10.0, "short: %.1f s" % len)


func test_one_rail_and_no_pcam_is_live_until_the_take_starts() -> void:
	_area = _harbour()
	var p := Cine.take_of(_area, KEY)
	assert_eq(p.get_meta("pcams").size(), 1, "one continuous camera")
	var pcam := p.get_node(p.get_meta("pcams")[0]) as PhantomCamera3D
	assert_eq(pcam.follow_mode, PhantomCamera3D.FollowMode.PATH)
	assert_eq(pcam.priority, AreaCine.LIVE, "Mission 1 plays it as the Area loads")
	assert_true(pcam.look_at_damping)


func test_the_lower_third_keeps_the_frameworks_timing() -> void:
	_area = _harbour()
	var p := Cine.take_of(_area, KEY)
	assert_false(p.has_meta("third_at"), "the default: in over the first 2 s, out before the end")


func test_the_stand_ins_cannot_raise_an_alert_and_sit_on_the_water() -> void:
	_area = _harbour()
	var props: Node3D = _area.get_node("Cine/IntroProps")
	assert_true(props.visible, "the take shows them")
	assert_eq(props.find_children("*", "Guard", true, false).size(), 0)
	for n in props.find_children("*", "CollisionObject3D", true, false):
		assert_true(false, "no colliders: %s" % n.name)
	var boat: Node3D = props.get_node("Boat")
	assert_true(boat.position.z < _start().z - 4.0, "off the bow, in the water, outside the playable deck")
	assert_true(boat.position.y < 0.0, "below the quay")


func test_the_take_ends_with_the_operative_at_the_start_facing_the_start_way() -> void:
	_area = _harbour()
	var p := Cine.take_of(_area, KEY)
	var op: Node3D = _area.get_node("Operative")
	var start: Marker3D = _area.get_node("Spots/OperativeStart")
	p.play("take")
	p.seek(0.0, true)
	assert_true(op.visible and _area.get_node("Cine/IntroProps").visible)
	assert_true(op.position.distance_to(start.position) > 1.0, "he comes aboard from the bow tip")
	p.seek(p.get_animation("take").length, true)
	assert_true(op.position.distance_to(start.position) < 0.1, "at the start: %s" % op.position)
	var want := start.rotation.y
	assert_true(absf(angle_difference(op.cine_face, want)) < deg_to_rad(5.0), "facing the start way")
	p.stop()


func test_no_guard_cone_can_reach_the_operative_on_his_way_in() -> void:
	_area = _harbour()
	var path := []
	for post: Marker3D in _area.get_node("GuardPosts").get_children():
		path.append(post.position)
		for wp: Marker3D in post.get_children():
			path.append(wp.position)
	assert_true(path.size() > 5)
	var p := Cine.take_of(_area, KEY)
	var clip := p.get_animation("take")
	var ti := clip.find_track(NodePath("../Operative:position"), Animation.TYPE_VALUE)
	assert_true(ti >= 0)
	for k in clip.track_get_key_count(ti):
		var at: Vector3 = clip.track_get_key_value(ti, k)
		for g: Vector3 in path:
			assert_true(at.distance_to(g) > GuardVision.FRONT_RANGE, "a post at %s sees %s" % [g, at])


func _start() -> Vector3:
	return _area.get_node("Spots/OperativeStart").position


func _harbour() -> Node:
	var a: Node = load(SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	return a
