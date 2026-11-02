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


func test_the_launch_is_textured_and_has_a_bow() -> void:
	_area = _harbour()
	var boat: Node3D = _area.get_node("Cine/IntroProps/Boat")
	var hull := boat.get_node("Hull") as MeshInstance3D
	assert_true((hull.material_override as StandardMaterial3D).albedo_texture != null, "textured")
	assert_true(boat.get_node("Bow") != null and boat.get_node("Windscreen") != null, "more than a box")


## The freighter's outline in diagram metres (build_harbour.gd Hull, Bow, BowTip; the front rail at y -2.7): [x, y, w, h].
const SHIP := [[65.0, 5.0, 16.0, 55.0], [69.5, -1.0, 7.0, 6.0], [71.5, -2.7, 3.0, 1.7]]


## How far a world point is from the freighter's outline, across the water.
static func _off_ship(at: Vector3) -> float:
	var x := at.x + 40.0
	var y := at.z + 40.0
	var best := INF
	for r in SHIP:
		var dx := maxf(maxf(r[0] - x, x - (r[0] + r[2])), 0.0)
		var dy := maxf(maxf(r[1] - y, y - (r[1] + r[3])), 0.0)
		best = minf(best, Vector2(dx, dy).length())
	return best


func test_the_launch_comes_in_from_the_sea_and_slips_close_past_the_bow() -> void:
	_area = _harbour()
	var p := Cine.take_of(_area, KEY)
	var clip := p.get_animation("take")
	var ti := clip.find_track(NodePath("IntroProps/Boat:position"), Animation.TYPE_VALUE)
	var first: Vector3 = clip.track_get_key_value(ti, 0)
	assert_true(first.z < _start().z - 15.0 and first.x > _start().x + 15.0, "out past the bow, off in the open water: %s" % first)
	var nearest := INF
	var t := 0.0
	while t <= clip.track_get_key_time(ti, clip.track_get_key_count(ti) - 1):
		var at: Vector3 = clip.value_track_interpolate(ti, t)
		var off := _off_ship(at)
		assert_true(off > 0.9, "never into the hull (half its beam clear) at %.1f s: %.2f m off" % [t, off])
		assert_true(at.x + 40.0 > 65.0, "never in the basin between the ship and the quay at %.1f s" % t)
		nearest = minf(nearest, off)
		t += 0.1
	assert_true(nearest < 2.5, "close alongside: %.2f m at its nearest" % nearest)
	var boarding: Vector3 = clip.value_track_interpolate(ti, 3.0)
	assert_true(boarding.distance_to(_start()) < 7.0, "under the bow as he steps aboard: %s" % boarding)
	var yi := clip.find_track(NodePath("IntroProps/Boat:rotation:y"), Animation.TYPE_VALUE)
	var bow := Basis(Vector3.UP, clip.track_get_key_value(yi, 0)) * Vector3.FORWARD
	assert_true(bow.x < -0.5 and bow.z > 0.5, "bow toward the ship, heading in: %s" % bow)


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
	a.get_node("MissionRun").campaign = true  # the campaign plays the take; Free mode does not
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	return a
