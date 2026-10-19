@tool
extends McpTestSuite

## The finale as data (ai/finale.gd): the single unfailable order, the Final debate by band and Spoofing
## level, the ending's lines, the Epilogue call, and the stage order.

const CSV := "res://text/lines.csv"
const BANDS := {"pallas": 0.0, "nike": 0.25, "gorgo": 0.6}


func suite_name() -> String:
	return "finale"


func _keys() -> Dictionary:
	var f := FileAccess.open(CSV, FileAccess.READ)
	f.get_csv_line()
	var t := {}
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() >= 3 and r[0] != "":
			t[r[0]] = r
	return t


func test_the_only_order_is_transmit_memories_and_it_cannot_fail() -> void:
	var f := Finale.new("pallas", 0)
	assert_eq(f.stage, "order")
	assert_eq(Finale.ORDER, "Transmit memories")
	f.transmit()
	assert_eq(f.stage, "debate")
	f.transmit()  # a second press does nothing
	assert_eq(f.stage, "debate")


func test_the_debate_has_one_line_per_voice_with_the_dominant_voice_last() -> void:
	for band: String in BANDS:
		var lines := Finale.debate(band, 0)
		var who := lines.map(func(l: Array) -> String: return l[0])
		assert_eq(who.size(), Aigis.VOICES.size())
		assert_eq(lines.back()[0], band)
		who.sort()
		var all := Aigis.VOICES.duplicate()
		all.sort()
		assert_eq(who, all)


func test_glaukopis_varies_with_spoofing_level() -> void:
	var seen := {}
	for lvl in 4:
		var l := Finale.debate("pallas", lvl).filter(func(l: Array) -> bool: return l[0] == "glaukopis")
		seen[l[0][1]] = true
	assert_eq(seen.size(), 4)


func test_each_ending_has_4_to_6_lines_the_last_to_the_operative() -> void:
	for band: String in BANDS:
		var lines := Finale.ending(band)
		assert_true(lines.size() >= 4 and lines.size() <= 6, band)
		assert_true(lines.back()[1].ends_with(".operative"), band)
		assert_false(lines[0][1].ends_with(".operative"), band)


func test_the_epilogue_is_a_handler_and_analyst_call() -> void:
	for band: String in BANDS:
		var who := Finale.epilogue(band).map(func(l: Array) -> String: return l[0])
		assert_contains(who, "handler")
		assert_contains(who, "analyst")


func test_every_key_exists_in_both_languages() -> void:
	var t := _keys()
	for band: String in BANDS:
		var all: Array = Finale.ending(band) + Finale.epilogue(band)
		for lvl in 4:
			all += Finale.debate(band, lvl)
		for l: Array in all:
			assert_has_key(t, l[1])
			assert_ne(t[l[1]][1], "", l[1])
			assert_ne(t[l[1]][2], "", l[1])


func test_the_stages_run_in_order_and_end() -> void:
	var f := Finale.new("nike", 1)
	f.transmit()
	var seen: Array = [f.stage]
	while f.stage != "over":
		f.next()
		seen.append(f.stage)
	assert_eq(seen, ["debate", "ending", "epilogue", "over"])


func test_the_record_gives_band_and_spoofing_level() -> void:
	var r := Aigis.preset_record("trickster", 3)
	var f := Finale.from_record(r)
	assert_eq(f.band, Aigis.resolve_ending(Aigis.lethality_ratio(r)))
	assert_eq(f.spoofing, 3)
	assert_eq(Finale.from_record(Aigis.preset_record("clean_slate", 3)).band, "pallas")


func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.pressed = true
	e.button_index = MOUSE_BUTTON_LEFT
	return e


func test_the_scene_plays_order_then_debate_then_ending_from_any_preset() -> void:
	var f: Control = load("res://ui/finale/finale.gd").new()
	Engine.get_main_loop().root.add_child(f)
	assert_true(f.is_in_group("finale"))
	f.start(Aigis.preset_record("butcher", 3), "")
	assert_eq(f.model.stage, "order")
	assert_eq(f.model.band, "gorgo")
	assert_true(Engine.time_scale < 1.0, "the order is in slowed time")
	f._unhandled_input(_click())
	assert_eq(f.model.stage, "debate")
	assert_eq(Engine.time_scale, 1.0)
	for i in 5 * 2:  # skip typing, then next, for each of the 5 Voices
		f._unhandled_input(_click())
		if f.model.stage != "debate":
			break
	assert_eq(f.model.stage, "ending")
	Engine.time_scale = 1.0
	f.get_tree().paused = false
	f.free()


func test_free_mode_has_a_finale_button() -> void:
	var fm: Control = load("res://ui/free_mode/free_mode.tscn").instantiate()
	assert_true(fm.has_method("_finale"))
	fm.free()


func test_every_band_has_a_credited_still() -> void:
	for band: String in BANDS:
		assert_gt(Finale.stills(band).size(), 0)
		for s: Dictionary in Finale.stills(band):
			assert_true(ResourceLoader.exists(s.path), s.path)
			assert_ne(s.credit, "")
