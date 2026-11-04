@tool
extends McpTestSuite

## Aigis Voice (ADR 0002): the facts an LLM is given, the checks its reply must pass, the Dossier fallback, the
## Gemini request and reply shapes, and the comment surviving a save. No network: replies are literals.


func suite_name() -> String:
	return "aigis_voice"


func _facts() -> Dictionary:
	return {voice = "gorgo", counts = {takedown = 3, alert = 1}, hot = {place = "The container lanes", n = 3, secs = 40}}


## Mission 1 played as a strangler: 5 takedowns (L1 Takedowns), one alarm, the work done in the container lanes.
func _after() -> Dictionary:
	var after := Aigis.complete_mission(Aigis.new_record(), {takedown = 5, alert = 1, spawned = 9})
	after.last.hot = {enc = 2, n = 3, secs = 40}
	return after


func _plan(after: Dictionary) -> Dictionary:
	return Aigis.plan_mission(after.points, Aigis.lethality_ratio(after), after.mission)


# ----- facts: what the model is told -----

func test_facts_hold_what_aigis_decided_about_the_mission() -> void:
	TranslationServer.set_locale("en")
	var after := _after()
	var f := AigisVoice.facts(after, _plan(after))
	assert_eq(f.mission, "MISSION 1: HARBOUR")
	assert_eq(f.language, "en")
	assert_eq(f.voice, "pallas", "no kills: Pallas's band speaks")
	assert_eq(f.callsign, "the Strangler")
	assert_eq(f.events, ["1 alarms last time. You stayed to fight.", "5 of ours taken from behind last time."], "the Briefing's own lines, in Habit order")
	assert_eq(f.hotspot, "The container lanes: 3 of ours down in 40 seconds.", "a finished sentence: the model can't pair the wrong numbers")
	assert_eq(f.next_mission, "MISSION 2: RADIO RELAY STATION")
	assert_eq(f.next_countermeasures, [{countermeasure = "They will look behind them more often.", sponsor = "pallas"}])
	assert_eq(f.next_forecast, "at least 4 of ours taken from behind")
	assert_false(f.has("last_forecast"), "Mission 1 had no forecast to settle")
	assert_false(f.has("dropped_habit"), "nothing dropped")


func test_kills_and_a_long_hotspot_are_sentences_too() -> void:
	TranslationServer.set_locale("es")
	var after := Aigis.complete_mission(Aigis.new_record(), {kill = 3, quiet_down = 5, spawned = 9})
	after.last.hot = {enc = 3, n = 4, secs = 150}
	var f := AigisVoice.facts(after, _plan(after))
	TranslationServer.set_locale("en")
	assert_contains(f.events, "3 de los nuestros muertos.")
	assert_eq(f.hotspot, "El edificio de Operaciones: 4 de los nuestros caídos en 3 minutos.", "150 s rounds to 3 minutes, as the Briefing says it")


func test_facts_are_in_the_players_language() -> void:
	TranslationServer.set_locale("es")
	var after := _after()
	var f := AigisVoice.facts(after, _plan(after))
	TranslationServer.set_locale("en")
	assert_eq(f.language, "es")
	assert_contains(f.events, "5 de los nuestros atrapados por la espalda la última vez.")
	assert_eq(f.next_countermeasures[0].countermeasure, "Mirarán atrás más a menudo.")


func test_facts_carry_a_settled_forecast_and_a_dropped_habit() -> void:
	TranslationServer.set_locale("en")
	var after := _after()
	after.last.bet = {event = "takedown", n = 4, most = false, got = 1, won = false}
	after.last.shifted = "takedowns"
	var f := AigisVoice.facts(after, _plan(after))
	assert_eq(f.last_forecast, {forecast = "at least 4 of ours taken from behind", got = 1, came_true = false})
	assert_eq(f.dropped_habit, "takedowns")


# ----- fallback: the same read from Dossier lines -----

func test_the_fallback_cites_the_evidence_and_closes_in_the_dominant_voice() -> void:
	TranslationServer.set_locale("en")
	var after := _after()
	assert_eq(AigisVoice.fallback(after, _plan(after)), {voice = "pallas", lines = [
		"5 of ours taken from behind last time.",
		"Walk softly. We are watching.",
	]}, "the speaker's name is the panel's header, not the line's")


func test_the_fallback_settles_the_last_forecast() -> void:
	TranslationServer.set_locale("en")
	var after := _after()
	after.last.bet = {event = "takedown", n = 4, most = false, got = 5, won = true}
	var lines: Array = AigisVoice.fallback(after, _plan(after)).lines
	assert_eq(lines[1], "I forecast at least 4 of ours taken from behind. You gave me 5. You are easy to read.")


func test_the_fallback_is_never_empty() -> void:
	var quiet := Aigis.complete_mission(Aigis.new_record(), {})
	var got := AigisVoice.fallback(quiet, _plan(quiet))
	assert_true(got.voice in Aigis.VOICES)
	assert_eq(got.lines.size(), 1, "nothing to cite: the close alone")


# ----- prompt and the Gemini adapter -----

func test_the_prompt_gives_the_model_every_fact_and_names_the_voice() -> void:
	var p := AigisVoice.prompt(_facts())
	assert_eq(JSON.parse_string(p.user), JSON.parse_string(JSON.stringify(_facts())), "the facts, as JSON")
	assert_contains(p.system, "Gorgo")
	assert_contains(p.system, str(AigisVoice.MAX_CHARS))


func test_the_gemini_body_asks_for_the_schema_as_json() -> void:
	var body := LlmClient.gemini_body({system = "Be Aigis.", user = "{}"}, AigisVoice.SCHEMA)
	assert_eq(body.systemInstruction, {parts = [{text = "Be Aigis."}]})
	assert_eq(body.contents, [{role = "user", parts = [{text = "{}"}]}])
	assert_eq(body.generationConfig.responseMimeType, "application/json")
	assert_eq(body.generationConfig.responseJsonSchema, AigisVoice.SCHEMA)


## Trimmed from a real gemini-3.1-flash-lite generateContent reply (2026-11-03).
const GEMINI_REPLY := '{"candidates": [{"content": {"parts": [{"text": "{\\"voice\\": \\"gorgo\\", \\"lines\\": [\\"Target count: 3.\\"]}", "thoughtSignature": "EnMK"}], "role": "model"}, "finishReason": "STOP", "index": 0}], "modelVersion": "gemini-3.1-flash-lite"}'


func test_the_gemini_reply_text_is_its_answer_part() -> void:
	assert_eq(LlmClient.gemini_text(GEMINI_REPLY), '{"voice": "gorgo", "lines": ["Target count: 3."]}')
	var thought := '{"candidates": [{"content": {"parts": [{"text": "thinking...", "thought": true}, {"text": "{}"}]}}]}'
	assert_eq(LlmClient.gemini_text(thought), "{}", "a thought part is not the answer")
	for bad: String in ["", "nope", '{"error": {"code": 429}}', '{"candidates": []}', '{"candidates": [{"finishReason": "SAFETY"}]}']:
		assert_eq(LlmClient.gemini_text(bad), "", "no answer in %s" % bad)


# ----- the saw page's panel -----

const SAW := preload("res://ui/post_mission/post_mission_saw.gd")


func test_the_panel_keeps_whole_lines_that_fit() -> void:
	var row := SAW.row_h(24)
	var lines := ["One short line.", "Another short line.", "A third."]
	assert_eq(SAW.said_rows(lines, 2000.0, 24, row * 3).size(), 3, "room for all three")
	var two := SAW.said_rows(lines, 2000.0, 24, row * 2.5)
	assert_eq(two.map(func(r: Array) -> int: return r[1]), [0, 1], "the third line is dropped whole")
	var long := SAW.said_rows(["word ".repeat(60)], 200.0, 24, row * 2)
	assert_eq(long.size(), 2, "the first line always shows, cut to what fits")


# ----- the next Briefing -----

func test_the_briefing_opens_with_the_models_comment_in_its_language() -> void:
	var r := {last = {analysis = {voice = "gorgo", lines = ["We will be ready.", "Bring more."], source = "llm", language = "en"}}}
	assert_eq(AigisVoice.briefing_lines(r, "en"), [["gorgo", "We will be ready."], ["gorgo", "Bring more."]])
	assert_eq(AigisVoice.briefing_lines(r, "es"), [], "written in English: a Spanish Briefing says its own lines")
	r.last.analysis.source = "fallback"
	assert_eq(AigisVoice.briefing_lines(r, "en"), [], "the fallback repeats what the Briefing already says")
	assert_eq(AigisVoice.briefing_lines({}, "en"), [], "no Mission played yet")
	assert_eq(AigisVoice.briefing_lines({last = {analysis = {voice = "gorgo", lines = ["x"], source = "llm"}}}, "en"), [], "no language: never shown")


# ----- the outcome log -----

func test_each_outcome_is_appended_to_the_log() -> void:
	var path := "user://test_aigis_voice_log.txt"
	DirAccess.remove_absolute(path)
	AigisComment.log_line("asked", path)
	AigisComment.log_line("fallback after 12000 ms (no reply)", path)
	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	DirAccess.remove_absolute(path)
	assert_eq(lines.size(), 2)
	assert_true(lines[1].ends_with("  fallback after 12000 ms (no reply)"), lines[1])


# ----- the save -----

func test_the_comment_survives_a_save_and_a_bad_one_is_dropped() -> void:
	var last := {mission = 0, counts = {}, shifted = "", analysis = {voice = "gorgo", lines = ["We will be ready."], source = "llm", language = "es", pending = true}}
	var back := Dossier.clean_last(JSON.parse_string(JSON.stringify(last)))
	assert_eq(back.analysis, {voice = "gorgo", lines = ["We will be ready."], source = "llm", language = "es"}, "the language kept, pending never saved")
	for bad: Variant in [{voice = "metis", lines = ["x"], source = "llm"}, {voice = "gorgo", lines = [3], source = "llm"},
			{voice = "gorgo", lines = ["x"], source = "oracle"}, {voice = "gorgo", lines = [], source = "llm"}, "gorgo"]:
		last.analysis = bad
		assert_false(Dossier.clean_last(JSON.parse_string(JSON.stringify(last))).has("analysis"), "dropped: %s" % [bad])


# ----- parse: the reply's checks -----

func test_a_good_reply_is_taken() -> void:
	var got := AigisVoice.parse('{"voice": "gorgo", "lines": ["Three of ours from behind.", "3 in 40 seconds."]}', _facts())
	assert_eq(got, {voice = "gorgo", lines = ["Three of ours from behind.", "3 in 40 seconds."]})


func test_a_reply_that_breaks_a_rule_is_refused() -> void:
	var long := "x".repeat(AigisVoice.MAX_CHARS + 1)
	for case: Array in [
		["not json", "broken JSON"],
		['["gorgo"]', "not an object"],
		['{"voice": "metis", "lines": ["Hello."]}', "not one of the five Voices"],
		['{"voice": "gorgo", "lines": []}', "no lines"],
		['{"voice": "gorgo", "lines": ["a", "b", "c", "d"]}', "more than three lines"],
		['{"voice": "gorgo", "lines": ["%s"]}' % long, "a line too long for the panel"],
		['{"voice": "gorgo", "lines": [7]}', "a line that isn't text"],
		['{"voice": "gorgo", "lines": "Hello."}', "lines not a list"],
		['{"voice": "gorgo", "lines": ["   "]}', "a blank line"],
	]:
		assert_eq(AigisVoice.parse(case[0], _facts()), {}, case[1])


func test_a_number_the_facts_dont_hold_is_refused() -> void:
	assert_eq(AigisVoice.parse('{"voice": "gorgo", "lines": ["5 of ours from behind."]}', _facts()), {}, "5 was never counted")
	assert_eq(AigisVoice.parse('{"voice": "gorgo", "lines": ["Down in 4.5 seconds."]}', _facts()), {}, "a decimal is a number too")
	var ok := AigisVoice.parse('{"voice": "gorgo", "lines": ["1 alarm. 3 taken in 40 seconds."]}', _facts())
	assert_eq(ok.get("lines", []).size(), 1, "every number is one of the facts' (nested ones too)")
