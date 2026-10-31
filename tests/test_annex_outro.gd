@tool
extends McpTestSuite

## The Research Annex's outro take, "Memory Loss": declared by Mission 3, short, one rail, the memory rack's lights die and
## the next rack's follow, the line arrives late, ends on black, and drives nothing of the Operative but his walk.

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
	assert_true(len >= 8.0 and len <= 10.0, "short: %.1f s" % len)
	assert_eq(p.get_meta("pcams").size(), 1, "one continuous camera")
	var pcam := p.get_node(p.get_meta("pcams")[0]) as PhantomCamera3D
	assert_eq(pcam.follow_mode, PhantomCamera3D.FollowMode.PATH)
	assert_eq(pcam.priority, 0, "no pcam is live until the take starts")


func test_the_memory_rack_is_built() -> void:
	_area = _annex()
	var racks: Node = _area.get_node("Cine/OutroProps/Racks")
	assert_true(racks.has_node(AnnexCine.MEMORY_RACK))
	assert_true(racks.has_node(AnnexCine.NEXT_RACK))


func test_the_memory_rack_goes_dark_then_the_next_while_the_rest_stay_green() -> void:
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	var len := p.get_animation("take").length
	var racks: Node = _area.get_node("Cine/OutroProps/Racks")
	p.play("take")
	p.seek(1.0, true)
	for r in racks.get_children():
		assert_eq(_led(r).emission, AnnexCine.GREEN, "%s starts green" % r.name)
	p.seek(7.2, true)
	assert_eq(_led(racks.get_node(AnnexCine.MEMORY_RACK)).emission, AnnexCine.BLACK, "the memory rack is dark")
	assert_eq(_led(racks.get_node(AnnexCine.NEXT_RACK)).emission, AnnexCine.GREEN, "the next is not yet")
	p.seek(len, true)
	assert_eq(_led(racks.get_node(AnnexCine.NEXT_RACK)).emission, AnnexCine.BLACK, "the row beside it follows")
	for r in racks.get_children():
		if r.name != AnnexCine.MEMORY_RACK and r.name != AnnexCine.NEXT_RACK:
			assert_eq(_led(r).emission, AnnexCine.GREEN, "%s is untouched" % r.name)
	p.stop()


func test_the_line_arrives_late_and_leaves_before_the_black() -> void:
	_area = _annex()
	var p := Cine.take_of(_area, KEY)
	var at: float = p.get_meta("third_at")
	var len := p.get_animation("take").length
	assert_true(at > 4.0)
	assert_eq(CineLogic.lower_third(at + 1.0, len, at), 1.0)
	assert_eq(CineLogic.lower_third(len - CineLogic.FADE_OUT, len, at), 0.0, "gone before the fade")


func test_the_stand_ins_cannot_raise_an_alert_and_the_take_only_walks_the_operative() -> void:
	_area = _annex()
	var props: Node = _area.get_node("Cine/OutroProps")
	assert_false(props.visible, "hidden in play")
	assert_eq(props.find_children("*", "Guard", true, false).size(), 0)
	for n in props.find_children("*", "CollisionObject3D", true, false):
		assert_true(false, "no colliders: %s" % n.name)
	var clip := Cine.take_of(_area, KEY).get_animation("take")
	for i in clip.get_track_count():
		var path := str(clip.track_get_path(i))
		if path.begins_with("../Operative"):
			assert_true(path.get_slice(":", 1) in ["position", "cine_face", "moving", "velocity"], "he is only moved: %s" % path)
		assert_false(path.contains("carry") or path.contains("Researcher"), "her carry state is untouched: %s" % path)


func test_black_is_total_at_the_end() -> void:
	assert_true(CineLogic.black(9.6, 9.6) > 0.999)


func _led(rack: Node) -> StandardMaterial3D:
	return (rack.get_node("Led0") as MeshInstance3D).material_override as StandardMaterial3D


func _annex() -> Node:
	var a: Node = load(SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	return a
