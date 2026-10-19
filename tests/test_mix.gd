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
