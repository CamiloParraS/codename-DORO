@tool
extends McpTestSuite

## The Codec call player: an ordered list of [speaker, key], typed out, advanced by presses (paused
## full-screen) or by a timer (live call). Text comes from tr() on the key.


func suite_name() -> String:
	return "codec_call"


func setup() -> void:
	TranslationServer.set_locale("en")


func teardown() -> void:
	TranslationServer.set_locale("en")


func _call() -> CodecCall:
	return CodecCall.new([["handler", "codec.m1.01"], ["operative", "codec.m1.02"]])


func test_a_call_is_data_and_starts_on_its_first_line() -> void:
	var c := _call()
	assert_false(c.done())
	assert_eq(c.speaker(), "handler")
	assert_eq(c.text(), TranslationServer.translate("codec.m1.01"))
	assert_ne(c.text(), "codec.m1.01", "the key resolves to a line")


func test_the_line_types_out_with_a_beep_per_character() -> void:
	var c := _call()
	assert_eq(c.shown(), "")
	var pitches := c.advance(3.0 / VoiceBlip.CPS + 0.001)
	assert_eq(c.shown(), c.text().substr(0, 3))
	assert_gt(pitches.size(), 0)


func test_a_press_skips_the_typing_then_goes_to_the_next_line() -> void:
	var c := _call()
	c.advance(0.1)
	assert_true(c.typing())
	c.press()
	assert_eq(c.shown(), c.text(), "first press reveals the line")
	assert_eq(c.speaker(), "handler")
	c.press()
	assert_eq(c.speaker(), "operative", "second press moves on")
	c.press()
	c.press()
	assert_true(c.done())


func test_a_live_call_moves_on_by_itself_after_a_hold() -> void:
	var c := _call()
	c.advance(10.0, true)
	assert_eq(c.speaker(), "handler", "typed but still held")
	c.advance(CodecCall.HOLD + 0.1, true)
	assert_eq(c.speaker(), "operative")
	c.advance(10.0, true)
	c.advance(CodecCall.HOLD + 0.1, true)
	assert_true(c.done())


func test_a_paused_call_waits_for_the_player() -> void:
	var c := _call()
	c.advance(60.0)
	assert_eq(c.speaker(), "handler")


func test_an_empty_call_is_done() -> void:
	assert_true(CodecCall.new([]).done())


func test_speaker_names_follow_the_language() -> void:
	var c := CodecCall.new([["analyst", "codec.m1.03"]])
	assert_eq(c.speaker_name(), "METIS ANALYST")
	TranslationServer.set_locale("es")
	assert_eq(c.speaker_name(), "METIS ANALISTA")


func test_a_dossier_line_shows_its_targets_face() -> void:
	var c := CodecCall.new([["analyst", "codec.m2.03", "chief"], ["handler", "codec.m2.01"]])
	assert_eq(c.portrait(), "chief")
	assert_eq(c.speaker(), "analyst")
	c.press()
	c.press()
	assert_eq(c.portrait(), "handler", "no third entry: the speaker's own face")
	for id in ["operative", "handler", "analyst", "chief", "researcher", "director"]:
		assert_true(ResourceLoader.exists(CodecScreen.PORTRAITS % id), id + " has a portrait")
