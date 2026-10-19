@tool
extends McpTestSuite

## Voice text blips: one pitch per Voice, a blip per visible character, skip stops them.


func suite_name() -> String:
	return "voice_blip"


func test_each_voice_has_its_own_pitch_band() -> void:
	var bands := []
	for v in Aigis.VOICES:
		var ps := []
		for c in "abcdefghij":
			ps.append(VoiceBlip.pitch(v, c))
		bands.append([ps.min(), ps.max()])
	bands.sort_custom(func(a, b): return a[0] < b[0])
	for i in bands.size() - 1:
		assert_true(bands[i][1] < bands[i + 1][0], "bands %d and %d overlap" % [i, i + 1])


func test_spaces_are_silent() -> void:
	assert_eq(VoiceBlip.pitch("nike", " "), 0.0)


func test_voice_of_briefing_key() -> void:
	assert_eq(VoiceBlip.voice_of("brief.gorgo.close"), "gorgo")
	assert_eq(VoiceBlip.voice_of("OBJECTIVES"), "")


func test_advance_gives_one_pitch_per_new_character_and_stops_at_the_end() -> void:
	var b := VoiceBlip.new("ab c", "nike")
	var p := b.advance(2.01 / VoiceBlip.CPS)  # 2 chars: "a", "b"
	assert_eq(p.size(), 2)
	p = b.advance(10.0)                       # " " is silent, "c" blips
	assert_eq(p.size(), 1)
	assert_true(b.done())
	assert_eq(b.advance(10.0).size(), 0)


func test_no_voice_shows_at_once_silently() -> void:
	var b := VoiceBlip.new("OBJECTIVES", "")
	assert_true(b.done())
	assert_eq(b.advance(1.0).size(), 0)


func test_skip_reveals_everything_and_blips_no_more() -> void:
	var b := VoiceBlip.new("hello there", "pallas")
	b.advance(0.05)
	b.skip()
	assert_true(b.done())
	assert_eq(b.shown(), "hello there")
	assert_eq(b.advance(1.0).size(), 0)
