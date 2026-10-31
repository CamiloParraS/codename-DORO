@tool
extends McpTestSuite

## The Core's intro take (tools/cine/core_intro.gd): the Operative comes up out of the sea and climbs onto the south pier.

const SCENE := "res://areas/core/core.tscn"

var _area: Node


func suite_name() -> String:
	return "core_intro"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()


func test_the_core_declares_and_has_an_intro_take() -> void:
	assert_eq(Campaign.cine_of(3).get("intro"), CoreIntro.KEY)
	_area = load(SCENE).instantiate()
	var p := Cine.take_of(_area, CoreIntro.KEY)
	assert_true(p != null and CineLogic.length_ok(p), "inside its range")
	assert_true(absf(p.get_animation("take").length - 8.0) < 1.0, "about 8 s")


func test_he_starts_under_the_surface_and_ends_on_the_pier() -> void:
	_area = load(SCENE).instantiate()
	var clip := Cine.take_of(_area, CoreIntro.KEY).get_animation("take")
	var t := clip.find_track(NodePath("../Operative:position"), Animation.TYPE_VALUE)
	var first: Vector3 = clip.track_get_key_value(t, 0)
	var last: Vector3 = clip.track_get_key_value(t, clip.track_get_key_count(t) - 1)
	var start: Vector3 = _area.get_node("Spots/OperativeStart").position
	assert_true(first.y < -1.6 - 1.7, "head under the water (-1.6) at the start")
	assert_true(first.z > start.z + 2.0, "out in the water past the pier's tip")
	assert_true(last.distance_to(start) < 0.1, "ends on the start spot")
	var cam := clip.find_track(NodePath("CineIntroRig/Dolly:position"), Animation.TYPE_VALUE)
	assert_true((clip.track_get_key_value(cam, 0) as Vector3).y < -0.8, "the camera starts at the waterline")


func test_the_sea_does_not_kill_him_on_the_way_up_and_is_live_after() -> void:
	_area = load(SCENE).instantiate()
	var clip := Cine.take_of(_area, CoreIntro.KEY).get_animation("take")
	var t := clip.find_track(NodePath("../Sea:monitoring"), Animation.TYPE_VALUE)
	assert_true(t >= 0)
	assert_false(clip.track_get_key_value(t, 0))
	assert_true(clip.track_get_key_value(t, clip.track_get_key_count(t) - 1), "a skip leaves the trigger on")
