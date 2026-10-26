@tool
extends McpTestSuite

## Guard conversations have sound: a caution clip where a line's text matches it, else a mumble blip
## pitched per guard and never louder than the barks.


func suite_name() -> String:
	return "chatter_voice"


func test_every_clip_exists_and_its_line_is_keyed_in_both_languages() -> void:
	var f := FileAccess.open("res://text/lines.csv", FileAccess.READ)
	f.get_csv_line()
	var rows := {}
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() >= 3 and r[0] != "":
			rows[r[0]] = r
	for k: String in ChatterVoice.CLIPS:
		assert_true(FileAccess.file_exists(ChatterVoice.clip_path(k)), k)
		assert_true(rows.has(k) and rows[k][1] != "" and rows[k][2] != "", k)
		assert_eq(String(rows[k][1]).trim_suffix(".").trim_suffix("!").to_lower(), ChatterVoice.CLIPS[k].get_basename().trim_suffix(".").trim_suffix("!").to_lower(), k + " says what its clip says")


func test_clip_for_is_empty_for_a_blip_line() -> void:
	assert_eq(ChatterVoice.clip_for("chat.idle.1.a"), "")
	assert_ne(ChatterVoice.clip_for("chat.idle.3.a"), "")


func test_every_exchange_of_every_set_is_keyed() -> void:
	for set: Array in [Chat.LINES, Chat.SMOKE]:
		assert_eq(set[0].size(), set[1].size())


func test_pitch_is_per_guard_and_in_range() -> void:
	assert_eq(ChatterVoice.pitch("Guard3"), ChatterVoice.pitch("Guard3"))
	var seen := {}
	for i in 12:
		var p := ChatterVoice.pitch("Guard%d" % i)
		assert_true(p >= ChatterVoice.PITCH_MIN and p <= ChatterVoice.PITCH_MAX)
		seen[p] = true
	assert_true(seen.size() > 4)


func test_mumble_is_never_louder_than_the_barks() -> void:
	assert_true(ChatterVoice.MUMBLE_DB <= GuardVoice.BARK_DB)


func test_a_guard_voice_blips_at_its_own_base_pitch() -> void:
	var b := VoiceBlip.new("ab", "", 1.5)
	assert_false(b.done())
	var p := b.advance(1.0)
	assert_eq(p.size(), 2)
	assert_true(absf(p[0] - 1.5) <= 1.5 * 0.13)
