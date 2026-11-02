@tool
extends McpTestSuite

## Takes: the rules (CineLogic), and a Mission that declares `cine` playing one over the live Area (the test room's 3 s rail):
## input and clocks held while it runs, GameplayCam the camera of record after it (skipped or not), and a Mission
## without `cine` still playing its card.

const ROOM := "res://areas/test_room/test_room.tscn"
const KEY := "CineTest"

var _area: Node
var _done := 0


func suite_name() -> String:
	return "cine"


func teardown() -> void:
	if is_instance_valid(_area):
		_area.free()
	(Engine.get_main_loop() as SceneTree).paused = false


func test_a_tap_never_skips_and_a_hold_does() -> void:
	assert_false(CineLogic.skip_done(0.1))
	assert_true(CineLogic.skip_done(CineLogic.SKIP_HOLD))
	assert_eq(CineLogic.skip_progress(CineLogic.SKIP_HOLD / 2.0), 0.5)
	assert_false(CineLogic.ring_shown(0.0), "no ring until the key is down")
	assert_true(CineLogic.ring_shown(1.0 / 60.0), "the ring answers within a frame of the press")


func test_the_lower_third_is_in_during_the_first_two_seconds_and_gone_before_the_end() -> void:
	assert_eq(CineLogic.lower_third(0.0, 8.0), 0.0)
	assert_eq(CineLogic.lower_third(1.0, 8.0), 1.0)
	assert_true(CineLogic.lower_third(CineLogic.LOWER_THIRD_AT + 0.2, 8.0) > 0.0)
	assert_eq(CineLogic.lower_third(7.9, 8.0), 0.0)
	assert_eq(CineLogic.lower_third(2.9, 3.0), 0.0, "a short take clears it before the end")


func test_an_outro_goes_to_black_only_at_its_end() -> void:
	assert_eq(CineLogic.black(1.0, 8.0), 0.0)
	assert_true(CineLogic.black(8.0, 8.0) > 0.999)


func test_bars_frame_to_239_and_a_wider_window_has_none() -> void:
	assert_true(absf(CineLogic.bar_height(Vector2(1920, 1080)) - (1080.0 - 1920.0 / 2.39) / 2.0) < 0.01)
	assert_eq(CineLogic.bar_height(Vector2(2800, 1080)), 0.0)


func test_a_takes_length_range_is_its_own_data() -> void:
	var p := _player()
	assert_true(CineLogic.length_ok(p), "default range 2 to 10 s")
	p.get_animation("take").length = 14.0
	assert_false(CineLogic.length_ok(p), "past the default cap")
	p.set_meta("max_s", 16.0)
	assert_true(CineLogic.length_ok(p), "this take says it may run to 16 s")
	p.free()


func test_the_session_log_line_says_who_skipped_what() -> void:
	assert_eq(CineLogic.log_line("CineIntro", true, 4.24), "cine CineIntro skipped at 4.2s")
	assert_eq(CineLogic.log_line("CineIntro", false, 8.0), "cine CineIntro played at 8.0s")


func test_the_test_room_take_is_within_its_range_and_names_its_pcams() -> void:
	_area = _room()
	var p := Cine.take_of(_area, KEY)
	assert_true(p != null and CineLogic.length_ok(p), "a 3 s rail")
	assert_eq(p.get_meta("pcams").size(), 1)
	var pcam := p.get_node(p.get_meta("pcams")[0]) as PhantomCamera3D
	assert_eq(pcam.follow_mode, PhantomCamera3D.FollowMode.PATH)
	assert_eq(pcam.priority, 0, "idle until the take raises it")


func test_the_operative_has_a_gameplay_pcam_above_idle_takes() -> void:
	_area = _room()
	var op = _area.get_node("Operative")
	assert_true(op.gameplay_cam != null)
	assert_true(op.gameplay_cam.priority > 0, "a take's idle pcams sit at 0, below it")
	assert_true(OperativeCam.host_of(op.camera) != null)
	assert_eq(OperativeCam.host_of(op.camera).interpolation_mode, PhantomCameraHost.InterpolationMode.IDLE)
	assert_eq(op.gameplay_cam.camera_3d_resource, null, "no resource: the host leaves fov to operative.gd")


func test_a_mission_with_cine_plays_its_take_and_holds_input_and_the_clock() -> void:
	var run := _mission_in_room({intro = KEY})
	var op = _area.get_node("Operative")
	assert_true(run.take_playing)
	assert_true(op.cine, "input off")
	assert_false(run.get_tree().paused, "the tree runs: guards idle, fog moves")
	assert_eq(run.find_children("*", "MissionCard", true, false).size(), 0, "no title card")
	assert_eq(_take_pcam().priority, AreaCine.LIVE, "the take's pcam is raised on the first frame")
	var before: float = run.rank.seconds
	run._physics_process(0.5)
	assert_eq(run.rank.seconds, before, "the Rank clock holds")
	assert_eq(SessionLog.current.idle_seconds(), 0.0, "a take is not idling")
	assert_eq(run.get_node("CineRunner").lines.size(), 3, "the intro card's text rides along as the lower-third")


func test_a_take_that_ends_hands_control_back_to_the_gameplay_pcam() -> void:
	var run := _mission_in_room({intro = KEY})
	var runner: Cine = run.get_node("CineRunner")
	runner._on_finished(&"take")
	_assert_back(run)
	assert_false(runner.skipped)
	assert_eq(_done, 1, "then ran once")
	assert_true(_log_has("cine CineTest played at"), "the Session log says it played")


func test_skipping_lands_in_the_same_state_as_the_natural_end() -> void:
	var run := _mission_in_room({intro = KEY})
	var runner: Cine = run.get_node("CineRunner")
	runner.skip()
	runner.skip()  # twice is once
	_assert_back(run)
	assert_true(runner.skipped)
	assert_eq(_done, 1)
	assert_true(_log_has("cine CineTest skipped at"))
	assert_eq(runner._at, _take_player().get_animation("take").length, "the clip was sought to its end")


func test_an_outro_ends_on_black_and_leaves_the_operative_locked() -> void:
	var run := _mission_in_room({})
	var c := Cine.new()
	c.fade_out = true
	run.add_child(c)
	c.finished.connect(func(_s: bool) -> void: _done += 1)
	c.play(_area, KEY, func() -> void: pass)
	assert_true(run.take_playing)
	c.skip()
	assert_eq(_done, 1, "the next screen follows")
	assert_true(_area.get_node("Operative").cine, "the Mission is over: nobody walks off")
	assert_false(run.take_playing)
	assert_eq(c._overlay.black, 1.0)


func test_a_mission_without_cine_still_plays_its_card() -> void:
	var run := _mission_in_room({}, false)
	assert_false(run.take_playing)
	assert_false(_area.get_node("Operative").cine)
	assert_eq(run.find_children("*", "MissionCard", true, false).size(), 1, "Mission 1's intro card")
	assert_true(run.get_tree().paused, "the old card holds the tree")


func test_a_missing_take_does_not_trap_the_player() -> void:
	var run := _mission_in_room({})
	run.get_tree().paused = false
	var c := Cine.new()
	run.add_child(c)
	assert_false(c.play(_area, "NoSuchTake", func() -> void: _done += 1))
	assert_eq(_done, 1, "then still runs")
	assert_false(_area.get_node("Operative").cine)


func test_the_campaign_and_replays_play_takes_and_free_mode_does_not() -> void:
	assert_true(CineLogic.plays(true, false))
	assert_true(CineLogic.plays(false, true))
	assert_false(CineLogic.plays(false, false), "Free mode skips: the Preset is the point")
	var run := _mission_in_room({intro = KEY}, false, true)
	assert_true(run.take_playing, "a replay plays it")
	_area.free()
	run = _mission_in_room({intro = KEY}, false, false)
	assert_false(run.take_playing, "Free mode: no take")
	assert_false(_area.get_node("Operative").cine)
	assert_false(run.has_node("CineRunner"))
	assert_eq(run.find_children("*", "MissionCard", true, false).size(), 0, "and no card either")


func test_the_key_that_skips_does_not_reach_the_first_frame_of_play() -> void:
	var run := _mission_in_room({intro = KEY})
	var op = _area.get_node("Operative")
	var runner: Cine = run.get_node("CineRunner")
	Input.action_press("ui_accept")
	runner.skip()
	assert_true(op.cine, "still locked while the skip key is down")
	assert_false(run.take_playing, "the clocks run")
	runner._process(0.016)
	assert_true(op.cine, "held on")
	Input.action_release("ui_accept")
	runner._process(0.016)
	assert_false(op.cine, "unlocked once the key is up")
	assert_true(runner.is_queued_for_deletion())


func test_gameplay_sfx_duck_under_a_take_and_come_back_even_after_a_skip() -> void:
	var run := _mission_in_room({intro = KEY})
	assert_eq(Mixer._sfx_duck_to, MusicState.TAKE_DUCK_DB, "ducked while it plays")
	var music_duck: float = Mixer._duck_to
	run.get_node("CineRunner").skip()
	assert_eq(Mixer._sfx_duck_to, 0.0, "restored on a skip")
	Mixer.advance_duck(10.0)
	assert_eq(Mixer._sfx_duck, 0.0, "and the bus is back at full")
	assert_eq(Mixer._duck_to, music_duck, "the music's own duck is untouched")
	_area.free()
	run = _mission_in_room({intro = KEY})
	_area.free()  # a scene change mid-take
	assert_eq(Mixer._sfx_duck_to, 0.0, "no stuck duck when the take is freed")


func test_every_declared_take_exists_in_its_area() -> void:
	var missing := []
	for k in Campaign.MISSIONS.size():
		var keys: Dictionary = Campaign.cine_of(k)
		if keys.is_empty():
			continue
		var area: Node = load(Campaign.MISSIONS[k].area).instantiate()
		for which in keys:
			var p := Cine.take_of(area, keys[which])
			if p == null or not CineLogic.length_ok(p):
				missing.append("%d %s %s" % [k, which, keys[which]])
		area.free()
	assert_eq(missing, [], "each Mission's cine keys resolve to takes within their length range")


## ---- helpers ----

func _assert_back(run: MissionRun) -> void:
	var op = _area.get_node("Operative")
	assert_false(op.cine, "input back")
	assert_false(run.take_playing, "clocks run")
	assert_true(_take_pcam().priority < op.gameplay_cam.priority, "the take's pcam is below GameplayCam: the host lands on the rig")
	assert_false(op.moving)
	var before: float = run.rank.seconds
	run._physics_process(0.5)
	assert_true(run.rank.seconds > before, "the Rank clock runs again")


func _log_has(text: String) -> bool:
	return SessionLog.current.missions.back().notes.any(func(n: Array) -> bool: return String(n[1]).begins_with(text))


func _room() -> Node:
	var a: Node = load(ROOM).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(a)
	return a


## A MissionRun for Mission 1 in the test room with `cine` as given (the real Mission 1 declares none yet).
func _mission_in_room(cine: Dictionary, campaign := true, replay := false) -> MissionRun:
	_done = 0
	_area = _room()
	var run := MissionRun.new()
	run.name = "MissionRun"
	run.cine = cine if not cine.is_empty() else {none = true}  # empty would fall back to Mission 1's own takes
	run.campaign = campaign
	run.replay = replay
	_area.add_child(run)
	if run.has_node("CineRunner"):
		run.get_node("CineRunner").finished.connect(func(_s: bool) -> void: _done += 1)
	return run


func _take_player() -> AnimationPlayer:
	return Cine.take_of(_area, KEY)


func _take_pcam() -> PhantomCamera3D:
	var p := _take_player()
	return p.get_node(p.get_meta("pcams")[0]) as PhantomCamera3D


func _player() -> AnimationPlayer:
	var p := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = 7.0
	lib.add_animation("take", clip)
	p.add_animation_library("", lib)
	return p


func test_a_take_line_that_fits_keeps_its_size_and_a_long_one_shrinks_to_fit() -> void:
	assert_eq(CineLogic.fit(22, 900.0, 1700.0), 22, "fits: unchanged")
	assert_eq(CineLogic.fit(52, 3400.0, 1700.0), 26, "twice too wide: half the size")
	assert_true(CineLogic.fit(52, 1800.0, 1700.0) * 1800.0 / 52.0 <= 1700.0, "the shrunk line fits the room")
	assert_true(CineLogic.TITLE_SIZE < 64 and CineLogic.LINE_SIZE < 26, "smaller than the first cut (64 / 26)")
