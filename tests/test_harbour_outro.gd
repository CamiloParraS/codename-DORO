@tool
extends McpTestSuite

## The Harbour's outro take, "Gap in the Fog": declared by Mission 1, short, one rail, ends on black into the post-Mission
## screen (shown once), hides the Operative, runs on stand-in rigs that cannot raise an Alert, and shows the extraction line late.

const SCENE := "res://areas/harbour/harbour.tscn"
const KEY := "CineOutro"

var _area: Node
var _shown := 0


func suite_name() -> String:
	return "harbour_outro"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()


func test_mission_one_declares_the_outro_and_it_resolves() -> void:
	assert_eq(Campaign.cine_of(0).get("outro"), KEY)
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
	assert_eq(pcam.priority, 0)
	assert_true(pcam.look_at_damping)


func test_the_line_arrives_late_and_leaves_before_the_black() -> void:
	_area = _harbour()
	var p := Cine.take_of(_area, KEY)
	var at: float = p.get_meta("third_at")
	var len := p.get_animation("take").length
	assert_true(at > 4.0, "after the empty spot is shown")
	assert_eq(CineLogic.lower_third(at - 0.1, len, at), 0.0)
	assert_eq(CineLogic.lower_third(at + 1.0, len, at), 1.0)
	assert_eq(CineLogic.lower_third(len - CineLogic.FADE_OUT, len, at), 0.0, "gone before the fade")
	assert_eq(CineLogic.lower_third(1.0, 8.0), 1.0, "default timing unchanged")


func test_the_stand_ins_cannot_raise_an_alert() -> void:
	_area = _harbour()
	var cine := _area.get_node("Cine")
	assert_eq(cine.find_children("*", "Guard", true, false).size(), 0, "no Guard node: no vision, no alert, no Radio")
	assert_eq(cine.find_children("*", "SecurityCamera", true, false).size(), 0)
	assert_false(cine.get_node("OutroProps").visible, "hidden in play")
	for n in cine.get_node("OutroProps").find_children("*", "CollisionObject3D", true, false):
		assert_true(false, "no colliders: %s" % n.name)


func test_the_operative_is_gone_from_the_first_frame_and_the_black_is_total_at_the_end() -> void:
	_area = _harbour()
	var p := Cine.take_of(_area, KEY)
	var op: Node3D = _area.get_node("Operative")
	p.play("take")
	p.seek(0.0, true)
	assert_false(op.visible, "no pop: the Operative is hidden at t 0")
	assert_true(_area.get_node("Cine/OutroProps").visible)
	p.stop()
	op.visible = true
	assert_true(CineLogic.black(p.get_animation("take").length, p.get_animation("take").length) > 0.999)


func test_skipping_shows_the_screen_exactly_once_on_black() -> void:
	_area = _harbour()
	_shown = 0
	var c := Cine.new()
	c.fade_out = true
	_area.add_child(c)
	c.play(_area, KEY, func() -> void: _shown += 1)
	c.skip()
	c.skip()
	assert_eq(_shown, 1)
	assert_eq(c._overlay.black, 1.0, "fully black")
	assert_true(_area.get_node("Operative").cine, "locked: the Mission is over")


func _harbour() -> Node:
	var a: Node = load(SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	return a
