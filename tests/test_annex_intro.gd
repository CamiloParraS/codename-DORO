@tool
extends McpTestSuite

## The Research Annex's intro take, "Twelve Months": declared by Mission 3, short, one rail, the seasons turn in the light and
## end on the Area's real values, he walks in through the fence's hole, and no guard's cone can reach him while it plays.

const SCENE := "res://areas/research_annex/research_annex.tscn"
const KEY := "CineIntro"

var _area: Node


func suite_name() -> String:
	return "annex_intro"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()


func test_mission_three_declares_the_intro_and_it_resolves() -> void:
	assert_eq(Campaign.cine_of(2).get("intro"), KEY)
	assert_eq(Campaign.cine_of(2).get("outro"), "CineOutro")
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	assert_true(p != null, "the Annex has the take")
	assert_true(CineLogic.length_ok(p), "within its own range")
	var len := p.get_animation("take").length
	assert_true(len >= 8.0 and len <= 10.0, "short: %.1f s" % len)
	assert_eq(p.get_meta("pcams").size(), 1, "one continuous camera")


func test_the_light_ends_on_the_areas_real_values() -> void:
	_area = _annex()
	var sun: DirectionalLight3D = _area.get_node("Sun")
	var env: Environment = _area.get_node("Mood").environment
	var rot := sun.rotation_degrees
	var col := sun.light_color
	var en := sun.light_energy
	var amb := env.ambient_light_color
	var amb_e := env.ambient_light_energy
	var p := Cine.take_of(_area, KEY)
	var len := p.get_animation("take").length
	p.play("take")
	p.seek(len * 0.5, true)
	assert_true(sun.light_color != col or sun.light_energy != en, "the seasons move the light mid-take")
	p.seek(len, true)
	assert_true(sun.rotation_degrees.distance_to(rot) < 0.01, "sun angle")
	assert_true(_close(sun.light_color, col), "sun colour")
	assert_true(absf(sun.light_energy - en) < 0.01, "sun energy")
	assert_true(_close(env.ambient_light_color, amb), "ambient")
	assert_true(absf(env.ambient_light_energy - amb_e) < 0.01, "ambient energy")
	p.stop()


func test_the_calendar_flips_through_twelve_months() -> void:
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	var cal: Label3D = _area.get_node("Cine/IntroProps/Calendar")
	p.play("take")
	p.seek(0.0, true)
	assert_eq(cal.text, "01/12")
	p.seek(p.get_animation("take").length, true)
	assert_eq(cal.text, "12/12")
	p.stop()


func test_the_stand_ins_cannot_raise_an_alert() -> void:
	_area = _annex()
	var props: Node3D = _area.get_node("Cine/IntroProps")
	assert_eq(props.find_children("*", "Guard", true, false).size(), 0)
	for n in props.find_children("*", "CollisionObject3D", true, false):
		assert_true(false, "no colliders: %s" % n.name)


func test_the_operative_walks_in_through_the_fence_hole_and_no_guard_cone_reaches_him() -> void:
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	var clip := p.get_animation("take")
	var t := clip.find_track(NodePath("../Operative:position"), Animation.TYPE_VALUE)
	assert_true(t >= 0, "the take walks him")
	var start: Vector3 = _area.get_node("Spots/OperativeStart").position
	assert_true(clip.track_get_key_value(t, 0).z > 75.8 - 40.0 + 1.0, "he begins outside the south fence")
	var through: Vector3 = clip.value_track_interpolate(t, 5.1)
	assert_true(absf(through.x - (AnnexCine.GAP[0] - 40.0)) < 0.5 and absf(through.z - (AnnexCine.GAP[1] - 40.0)) < 1.0, "he passes through the hole")
	assert_true(clip.value_track_interpolate(t, clip.length).distance_to(start) < 0.1, "and ends on the start spot")
	# the hole is open to the eye and shut to the body
	var solid: Node = _area.get_node("NavRegion/Solid") if _area.has_node("NavRegion/Solid") else _area.find_child("Solid", true, false)
	assert_true(solid.has_node("GapSeal"), "the hole is sealed in play")
	assert_eq(solid.get_node("GapSeal").find_children("*", "MeshInstance3D", true, false).size(), 0, "and has no fence mesh")
	var n := 0
	for post: Marker3D in _area.get_node("GuardPosts").get_children():
		n += 1
		assert_true(post.position.distance_to(start) > GuardVision.FRONT_RANGE, "%s sees the start" % post.name)
		for wp: Marker3D in post.get_children():
			assert_true(wp.position.distance_to(start) > GuardVision.FRONT_RANGE, "%s's route sees the start" % post.name)
		assert_true(post.position.distance_to(_w(AnnexCine.WALK_IN[0])) > GuardVision.FRONT_RANGE, "%s sees where he comes in" % post.name)
	assert_true(n > 5)


func _w(r: Array) -> Vector3:
	return Vector3(r[1] - 40.0, 0.0, r[2] - 40.0)


func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.01


func _annex() -> Node:
	var a: Node = load(SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	return a
