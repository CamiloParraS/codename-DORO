@tool
extends McpTestSuite

## The mix: bus layout, bitcrush on SFX only, per-bus volume setters, music duck.


func suite_name() -> String:
	return "mix"


func _mix() -> Mix:
	var m := Mix.new()
	m.setup_buses()
	return m


func test_buses_send_to_master() -> void:
	_mix()
	for b in [Mix.MUSIC, Mix.SFX, Mix.UI, Mix.AMBIENCE]:
		var i := AudioServer.get_bus_index(b)
		assert_true(i >= 0, "%s exists" % b)
		assert_eq(AudioServer.get_bus_send(i), &"Master")


func test_bitcrush_on_sfx_only() -> void:
	_mix()
	for b in [Mix.MUSIC, Mix.UI, Mix.AMBIENCE]:
		assert_eq(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(b)), 0)
	var sfx := AudioServer.get_bus_index(Mix.SFX)
	var fx := AudioServer.get_bus_effect(sfx, 0) as AudioEffectDistortion
	assert_true(fx != null and fx.mode == AudioEffectDistortion.MODE_LOFI)


func test_setup_twice_adds_no_extra_buses() -> void:
	var m := _mix()
	var n := AudioServer.bus_count
	m.setup_buses()
	assert_eq(AudioServer.bus_count, n)
	assert_eq(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(Mix.SFX)), 1)


func test_volume_setter_round_trips_per_bus() -> void:
	var m := _mix()
	m.set_volume(Mix.SFX, 0.5)
	assert_eq(m.volume(Mix.SFX), 0.5)
	assert_eq(m.volume(Mix.UI), 1.0)
	assert_true(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Mix.SFX)) - linear_to_db(0.5)) < 0.01)
	m.set_volume(Mix.SFX, 1.0)


func test_codec_call_ducks_music_bus_six_db_and_recovers() -> void:
	var m := _mix()
	m.codec_call(true)
	m.advance_duck(10.0)
	var i := AudioServer.get_bus_index(Mix.MUSIC)
	assert_true(absf(AudioServer.get_bus_volume_db(i) - -6.0) < 0.01)
	m.codec_call(false)
	m.advance_duck(10.0)
	assert_true(absf(AudioServer.get_bus_volume_db(i)) < 0.01)


func test_blips_share_one_ui_player() -> void:
	var m := _mix()
	m.blip(1.0)
	m.blip(1.4)
	assert_eq(m.get_child_count(), 1)
	var p := m.get_child(0) as AudioStreamPlayer
	assert_eq(p.bus, Mix.UI)
	assert_true(absf(p.pitch_scale - 1.4) < 0.001)
	m.stop_blips()
	m.free()


func test_voice_and_radio_buses_send_to_sfx_and_radio_is_filtered() -> void:
	_mix()
	for b in [Mix.VOICE, Mix.RADIO]:
		assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(b)), Mix.SFX)
	assert_eq(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(Mix.RADIO)), 3)
	assert_eq(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(Mix.VOICE)), 0)


func test_pick_returns_a_variant_of_the_sound() -> void:
	assert_true(Mix.pick(&"footstep") in Mix.STREAMS[&"footstep"])
	assert_eq(Mix.pick(&"takedown"), Mix.STREAMS[&"takedown"])


func test_master_has_a_volume_setter_like_the_others() -> void:
	var m := _mix()
	m.set_volume(Mix.MASTER, 0.5)
	assert_eq(m.volume(Mix.MASTER), 0.5)
	assert_true(absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.5)) < 0.01)
	m.set_volume(Mix.MASTER, 1.0)


func test_time_scale_is_left_alone_unless_a_hit_stop_is_on_or_ending() -> void:
	var m := _mix()
	Engine.time_scale = 0.5  # someone elses
	m.apply_scale(1.0)
	assert_eq(Engine.time_scale, 0.5)
	m.apply_scale(AlertBeat.STOP_SCALE)
	assert_eq(Engine.time_scale, AlertBeat.STOP_SCALE)
	m.apply_scale(1.0)
	assert_eq(Engine.time_scale, 1.0, "restored when the stop ends")


func test_every_stream_loads() -> void:
	for k in Mix.STREAMS:
		var v: Variant = Mix.STREAMS[k]
		for path in ([v] if v is String else v):
			assert_true(load(path) is AudioStream, "%s loads" % k)


func test_each_wanted_sound_has_a_stream() -> void:
	for k in [&"shot_quiet", &"shot_quiet_rifle", &"shot_loud", &"takedown", &"body_fall", &"dart_hit", &"dart_vest", &"choke",
			&"mag_land", &"footstep", &"ladder", &"fulton_launch", &"fulton_lift", &"radio_on", &"radio_off", &"patrol", &"ui_click", &"radio_static"]:
		assert_true(Mix.STREAMS.has(k), "%s mapped" % k)


func test_step_sound_follows_the_floor_and_crouching_is_quieter() -> void:
	assert_eq(Mix.step_sound(&"metal"), &"footstep_metal")
	assert_eq(Mix.step_sound(&""), &"footstep")
	assert_true(Mix.step_db(true) < Mix.step_db(false))
	assert_true(Mix.step_db(false) < 0.0, "standing steps are trimmed")
	assert_true(Mix.step_db(false) - Mix.step_db(true) >= 10.0, "crouch cut is far bigger than the standing one")
	assert_eq(Mix.step_db(true, true), Mix.CARRY_STEP_DB)  # carrying wins over crouching
	assert_true(Mix.STREAMS.has(&"footstep_metal"))


func test_crickets_sit_well_under_the_music() -> void:
	assert_true(Mix.OUTDOOR_DB <= -24.0)


func test_guard_voice_is_louder_than_unity() -> void:
	var v := GuardVoice.new()
	assert_true(v.volume_db > 0.0)
	v.free()


func test_shot_sound_follows_the_suppressor() -> void:
	assert_eq(Mix.shot_sound(true), &"shot_quiet")
	assert_eq(Mix.shot_sound(true, true), &"shot_quiet_rifle")
	assert_eq(Mix.shot_sound(false), &"shot_loud")


func test_ui_click_plays_on_the_ui_bus() -> void:
	var m := _mix()
	m.click()
	var p := m.get_child(0) as AudioStreamPlayer
	assert_eq(p.bus, Mix.UI)
	m.free()
