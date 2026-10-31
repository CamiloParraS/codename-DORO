@tool
extends McpTestSuite

## The Research Annex's intro take, "Twelve Months": declared by Mission 3, short, one rail; the Mission's steps light up in
## order through the walls under a dim, everything ends on the Area's real values, he walks in through the fence's hole, and
## no guard's cone can reach him while it plays.

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
	assert_true(len >= 8.0 and len <= 11.0, "short: %.1f s" % len)
	assert_eq(p.get_meta("pcams").size(), 1, "one continuous camera")


func test_the_world_ends_on_the_areas_real_values() -> void:
	_area = _annex()
	var env: Environment = _area.get_node("Mood").environment
	var begin := env.fog_depth_begin
	var end := env.fog_depth_end
	var p := Cine.take_of(_area, KEY)
	var dim: ShaderMaterial = _area.get_node("Cine/IntroProps/Dim").material_override
	var len := p.get_animation("take").length
	p.play("take")
	p.seek(3.0, true)
	assert_true(env.fog_depth_begin > begin, "the fog pulls back while the camera is high")
	assert_true(float(dim.get_shader_parameter("amount")) > 0.9, "and the world dims for the marks")
	p.seek(len, true)
	assert_true(absf(env.fog_depth_begin - begin) < 0.01 and absf(env.fog_depth_end - end) < 0.01, "fog back to the Area's")
	assert_true(float(dim.get_shader_parameter("amount")) < 0.01, "no dim at control")
	p.stop()


func test_the_marks_light_the_missions_steps_in_order_and_go_before_control() -> void:
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	var len := p.get_animation("take").length
	var last := 0.0
	for m: Array in AnnexCine.MARKS:
		assert_true(m[4] > last, "%s lights after the one before" % m[0])
		last = m[4]
		assert_true(TranslationServer.translate(m[3]) != m[3], "%s has a tag line" % m[0])
	assert_eq(AnnexCine.MARKS[3][2], Campaign.MISSIONS[2].targets[0], "the target mark follows Mission 3's Target")
	p.play("take")
	p.seek(last + 0.1, true)
	for m: Array in AnnexCine.MARKS:
		assert_true((_area.get_node("Cine/IntroProps/" + m[0]) as CineMark).lit, "%s is lit" % m[0])
	p.seek(len, true)
	for m: Array in AnnexCine.MARKS:
		assert_false((_area.get_node("Cine/IntroProps/" + m[0]) as CineMark).lit, "%s is off at control" % m[0])
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
	var through: Vector3 = clip.value_track_interpolate(t, AnnexCine.WALK_IN[1][0])
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
