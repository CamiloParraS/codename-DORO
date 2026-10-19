@tool
extends McpTestSuite

## The English column: no placeholder text outside the Voice keys (ticket 36 writes those), and the
## whole column stays inside the 3,500-word budget.

const CSV := "res://text/lines.csv"
const VOICE_KEYS := ["brief.", "post.", "finale.debate.", "finale.end."]  # written by hand, not drafted
const WORD_CAP := 3500


func suite_name() -> String:
	return "english_lines"


func _en() -> Dictionary:
	var f := FileAccess.open(CSV, FileAccess.READ)
	f.get_csv_line()
	var t := {}
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() >= 3 and r[0] != "":
			t[r[0]] = r[1]
	return t


func _is_voice(k: String) -> bool:
	for p: String in VOICE_KEYS:
		if k.begins_with(p):
			return true
	return false


func test_drafted_lines_are_not_placeholders() -> void:
	var rx := RegEx.create_from_string("\\(\\d\\)$|^\\[[A-Za-z]{4,}\\]|(Debate|Ending|Epilogue) line")
	var t := _en()
	for k: String in t:
		if _is_voice(k):
			continue
		assert_ne(String(t[k]).strip_edges(), "", k + " is empty")
		assert_true(rx.search(t[k]) == null, k + " is a placeholder: " + t[k])


func test_english_stays_inside_the_word_cap() -> void:
	var words := 0
	for v: String in _en().values():
		words += v.split(" ", false).size()
	assert_true(words < WORD_CAP, "%d words" % words)
