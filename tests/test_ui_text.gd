@tool
extends McpTestSuite

## The shared UI kit's text rules: word wrap to a pixel width, and key prompts read from the InputMap.


func suite_name() -> String:
	return "ui_text"


func setup() -> void:
	InputMap.load_from_project_settings()  # the editor's runtime InputMap starts without project actions
	TranslationServer.set_locale("en")


func _w(s: String) -> float:
	return HudPalette.BODY.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.BODY_SIZE).x


func test_wrap_breaks_between_words_inside_the_width() -> void:
	var lines := HudPalette.wrap("aaa bbb ccc", _w("aaa bbb"))
	assert_eq(Array(lines), ["aaa bbb", "ccc"])


func test_a_line_that_fits_stays_whole() -> void:
	assert_eq(Array(HudPalette.wrap("one two", 400)), ["one two"])
	assert_eq(Array(HudPalette.wrap("", 400)), [])


func test_a_word_wider_than_the_width_gets_its_own_line() -> void:
	var lines := HudPalette.wrap("a supercalifragilistic b", _w("a sup"))
	assert_eq(Array(lines), ["a", "supercalifragilistic", "b"])


func test_explicit_newlines_start_a_new_line() -> void:
	assert_eq(Array(HudPalette.wrap("one\ntwo", 400)), ["one", "two"])


func test_the_longest_hint_fits_the_live_call_column_in_both_languages() -> void:
	for loc in ["en", "es"]:
		TranslationServer.set_locale(loc)
		var lines := HudPalette.wrap(tr("hint.m1.s2.2"), HudPalette.COLUMN)
		assert_true(lines.size() <= 4, "%s: %d lines" % [loc, lines.size()])
		for l in lines:
			assert_true(_w(l) <= HudPalette.COLUMN, "%s overflows: %s" % [loc, l])
	TranslationServer.set_locale("en")


func test_prompt_keys_come_from_the_input_map() -> void:
	assert_eq(Prompts.key("interact"), "E")
	assert_eq(Prompts.key("fulton"), "G")
	assert_eq(Prompts.key("kill_takedown"), "X")
	assert_eq(Prompts.key("fire"), "LMB")
	assert_eq(Prompts.key("aim"), "RMB")
	assert_eq(Prompts.key("item_next"), "WHEEL")
	assert_eq(Prompts.key("walk"), "SHIFT")
	assert_eq(Prompts.key("shoulder_swap"), "TAB")
	assert_eq(Prompts.key("pause"), "ESC")
	assert_eq(Prompts.key("crouch"), "C")
	assert_eq(Prompts.key("codec_advance"), "LMB")


func test_a_prompt_is_the_key_in_brackets_then_the_translated_verb() -> void:
	assert_eq(Prompts.verb("interact", "ui.prompt.carry"), "[E] CARRY")
	assert_eq(Prompts.hold("fulton", "ui.prompt.fulton"), "HOLD [G] FULTON")
	TranslationServer.set_locale("es")
	assert_eq(Prompts.verb("interact", "ui.prompt.carry"), "[E] CARGAR")
	TranslationServer.set_locale("en")
