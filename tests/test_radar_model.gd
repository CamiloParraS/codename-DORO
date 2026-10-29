@tool
extends McpTestSuite

## Radar rules: north-up blip placement, range pinning to the disc, jamming, top-right placement on the 1920x1080 HUD canvas.


func suite_name() -> String:
	return "radar_model"


func test_north_up_world_minus_z_is_up() -> void:
	assert_eq(RadarModel.unit(Vector2(0, -15)), Vector2(0, -0.5))
	assert_eq(RadarModel.unit(Vector2(30, 0)), Vector2(1, 0))


func test_beyond_range_pins_to_the_disc_edge_keeping_direction() -> void:
	var u := RadarModel.unit(Vector2(60, -30))
	assert_true(is_equal_approx(u.length(), 1.0), "on the rim")
	assert_true(is_equal_approx(u.angle(), Vector2(2, -1).angle()), "same bearing")
	assert_eq(RadarModel.unit(Vector2(0, 300)), Vector2(0, 1))
	assert_true(is_equal_approx(RadarModel.unit(Vector2(25, 25)).length(), 1.0), "a diagonal past range is pinned too, not left in a square corner")


func test_a_far_blip_sits_inside_the_border_on_the_edge() -> void:
	assert_eq(RadarModel.blip(Vector2(500, 0), 2.0), Vector2(RadarModel.HALF - 2.0, 0))
	assert_eq(RadarModel.blip(Vector2(0, -15), 4.0), Vector2(0, -0.5 * (RadarModel.HALF - 4.0)))


func test_flat_and_facing_drop_height() -> void:
	assert_eq(RadarModel.flat(Vector3(3, 9, -4)), Vector2(3, -4))
	assert_eq(RadarModel.facing(Basis.IDENTITY), Vector2(0, -1), "-Z is north, up the screen")
	assert_eq(RadarModel.facing(Basis(Vector3.UP, PI / 2)).snapped(Vector2(0.01, 0.01)), Vector2(-1, 0))


func test_alert_and_evasion_jam_the_radar() -> void:
	assert_true(RadarModel.jammed("ALERT"))
	assert_true(RadarModel.jammed("EVASION"))
	assert_false(RadarModel.jammed(""))


func test_only_alert_and_evasion_jam_by_the_chain_phase() -> void:
	var chain := AlertChain.new()
	assert_false(RadarModel.jammed(HudModel.phase(chain)[0]))
	chain.start_call("g", Vector3.ZERO)
	assert_false(RadarModel.jammed(HudModel.phase(chain)[0]), "a pending Radio call leaves it on")
	chain.stop_call("g")
	chain.caution()
	assert_false(RadarModel.jammed(HudModel.phase(chain)[0]), "Caution leaves it on")
	chain.start_call("g", Vector3.ZERO)
	chain.tick(AlertChain.CALL_TIME + 0.1, false)
	assert_true(RadarModel.jammed(HudModel.phase(chain)[0]), "ALERT")
	chain.tick(AlertChain.ALERT_TIME + 0.1, false)
	assert_true(RadarModel.jammed(HudModel.phase(chain)[0]), "EVASION")
	chain.tick(AlertChain.EVASION_TIME + 0.1, false)
	assert_false(RadarModel.jammed(HudModel.phase(chain)[0]), "Caution after Evasion")


func test_a_pending_call_flashes_the_blip_and_stops_with_the_call() -> void:
	var chain := AlertChain.new()
	chain.start_call("g", Vector3.ZERO)
	assert_true(RadarModel.call_flash(chain.calling("g"), 0))
	assert_false(RadarModel.call_flash(chain.calling("g"), 150), "off half of the cycle")
	chain.stop_call("g")
	assert_false(RadarModel.call_flash(chain.calling("g"), 0), "no flash once stopped")
	assert_false(RadarModel.call_flash(chain.calling("camera"), 0), "only callers flash")


func test_radar_sits_top_right_inside_the_canvas_at_any_aspect() -> void:
	for canvas: Vector2 in [Vector2(1920, 1080), Vector2(2560, 1080)]:
		var r := RadarModel.rect(canvas)
		assert_eq(r.size, Vector2.ONE * RadarModel.HALF * 2)
		assert_eq(r.end.x, canvas.x - RadarModel.MARGIN, "64 px in from the right edge")
		assert_eq(r.position.y, RadarModel.TOP)
		assert_true(Rect2(Vector2.ZERO, canvas).encloses(r))
		assert_true(r.position.x > canvas.x / 2 + 300, "clear of the centred phase plate")


func test_noise_ring_spreads_to_its_range_and_goes() -> void:
	assert_eq(RadarModel.ping_radius(6.0, 0.0), 0.0)
	assert_true(RadarModel.ping_radius(6.0, 0.25) < RadarModel.ping_radius(6.0, 0.4))
	assert_true(RadarModel.ping_radius(10.0, 0.25) > RadarModel.ping_radius(6.0, 0.25), "a louder noise spreads wider")
	assert_true(RadarModel.ping_radius(60.0, 0.4) <= RadarModel.HALF, "pinned inside the disc")
	assert_eq(RadarModel.ping_radius(6.0, RadarModel.PING_TIME), -1.0)


func test_a_guard_shows_only_while_his_noise_is_young_or_the_scanner_runs() -> void:
	assert_eq(RadarModel.guard_alpha(0.0, false), 1.0)
	assert_true(RadarModel.guard_alpha(0.75, false) < 1.0)
	assert_eq(RadarModel.guard_alpha(RadarModel.GUARD_PING_SHOW, false), 0.0)
	assert_eq(RadarModel.guard_alpha(99.0, false), 0.0, "a silent guard is off the Radar")
	assert_eq(RadarModel.guard_alpha(99.0, true), 1.0, "the Scanner shows him")
