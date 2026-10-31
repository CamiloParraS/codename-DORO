@tool
extends McpTestSuite

## The Research Annex's outro take, "Memory Loss": declared by Mission 3, short, one rail, he goes up the Fulton line from
## the Extraction point (the Researcher held on his shoulder) while the vault's mark dies; the line arrives late, it ends on
## black, and drives nothing of the Operative but his position, heading, gait and pose.

const SCENE := "res://areas/research_annex/research_annex.tscn"
const KEY := "CineOutro"

var _area: Node


func suite_name() -> String:
	return "annex_outro"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()


func test_mission_three_declares_the_outro_and_it_resolves() -> void:
	assert_eq(Campaign.cine_of(2).get("outro"), KEY)
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	assert_true(p != null, "the Annex has the take")
	assert_true(CineLogic.length_ok(p), "within its own range")
	var len := p.get_animation("take").length
	assert_true(len >= 8.0 and len <= 11.0, "short: %.1f s" % len)
	assert_eq(p.get_meta("pcams").size(), 1, "one continuous camera")
	var pcam := p.get_node(p.get_meta("pcams")[0]) as PhantomCamera3D
	assert_eq(pcam.follow_mode, PhantomCamera3D.FollowMode.PATH)
	assert_eq(pcam.priority, 0, "no pcam is live until the take starts")


func test_he_goes_up_the_line_from_the_extraction_point() -> void:
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	var clip := p.get_animation("take")
	var t := clip.find_track(NodePath("../Operative:position"), Animation.TYPE_VALUE)
	var zone: Vector3 = _area.get_node("ExtractionPoint").position
	var from: Vector3 = clip.track_get_key_value(t, 0)
	var end: Vector3 = clip.value_track_interpolate(t, clip.length)
	assert_true(Vector2(from.x, from.z).distance_to(Vector2(zone.x, zone.z)) < 2.5, "starts where control stood")
	assert_true(Vector2(end.x, end.z).distance_to(Vector2(from.x, from.z)) < 0.1, "straight up")
	assert_true(end.y > from.y + 30.0, "and out of the frame")
	assert_eq(_area.get_node("Cine/OutroProps").find_children("*", "CollisionObject3D", true, false).size(), 0, "stand-ins are mesh only")
	var balloon: Node3D = _area.get_node("Cine/OutroProps/Balloon")
	p.play("take")
	p.seek(clip.length * 0.7, true)
	assert_true(absf(balloon.position.y - clip.value_track_interpolate(t, clip.length * 0.7).y - CineFulton.TIE) < 0.3, "the balloon rides over him")
	p.stop()


func test_the_vault_mark_goes_dark_before_the_black() -> void:
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	var clip := p.get_animation("take")
	var mark: CineMark = _area.get_node("Cine/OutroProps/MarkVault")
	p.play("take")
	p.seek(AnnexCine.VAULT_LIT[0] + 0.1, true)
	assert_true(mark.lit, "lit as the ship passes over")
	p.seek(clip.length - CineLogic.FADE_OUT, true)
	assert_false(mark.lit, "dark before the black")
	p.stop()


func test_the_line_arrives_late_and_leaves_before_the_black() -> void:
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	var at: float = p.get_meta("third_at")
	var len := p.get_animation("take").length
	assert_true(at > 4.0)
	assert_eq(CineLogic.lower_third(at + 1.0, len, at), 1.0)
	assert_eq(CineLogic.lower_third(len - CineLogic.FADE_OUT, len, at), 0.0, "gone before the fade")


func test_the_take_only_walks_the_operative() -> void:
	_area = _annex()
	var clip := Cine.take_of(_area, KEY).get_animation("take")
	for i in clip.get_track_count():
		var path := str(clip.track_get_path(i))
		if path.begins_with("../Operative"):
			assert_true(path.get_slice(":", 1) in ["position", "cine_face", "moving", "velocity", "cine_clip"], "he is only moved: %s" % path)
		assert_false(path.contains("carry") or path.contains("Researcher"), "her carry state is untouched: %s" % path)


func test_black_is_total_at_the_end() -> void:
	assert_true(CineLogic.black(9.0, 9.0) > 0.999)


func _annex() -> Node:
	var a: Node = load(SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	return a
