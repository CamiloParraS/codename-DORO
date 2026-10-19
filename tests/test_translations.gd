@tool
extends McpTestSuite

## The CSV translation table (keys, en, es) and the Codec calls in Campaign that read it.

const CSV := "res://text/lines.csv"


func suite_name() -> String:
	return "translations"


func teardown() -> void:
	TranslationServer.set_locale("en")


## key -> {en, es}, read straight from the file.
func _table() -> Dictionary:
	var f := FileAccess.open(CSV, FileAccess.READ)
	var head := f.get_csv_line()
	assert_eq(Array(head).slice(0, 3), ["keys", "en", "es"])
	var t := {}
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() >= 3 and r[0] != "":
			assert_false(t.has(r[0]), "duplicate key " + r[0])
			t[r[0]] = {en = r[1], es = r[2]}
	return t


func test_every_key_is_namespaced_and_has_both_languages() -> void:
	var t := _table()
	assert_gt(t.size(), 10)
	for k: String in t:
		assert_true("." in k, k + " is not namespaced")
		assert_ne(t[k].en, "", k + " has no English")
		assert_ne(t[k].es, "", k + " has no Spanish")


func test_only_proper_names_are_slotted() -> void:
	for k: String in _table():
		var line: Dictionary = _table()[k]
		for l: String in [line.en, line.es]:
			assert_false("%s" in l or "%d" in l, k + " assembles a sentence")


func _all_calls() -> Array:
	var calls := []
	for m: Dictionary in Campaign.MISSIONS:
		calls.append(m.codec)
		for s: Dictionary in m.steps:
			calls.append(s.call)
	return calls


func test_every_call_line_exists_with_a_known_speaker() -> void:
	var t := _table()
	for c: Array in _all_calls():
		for line: Array in c:
			assert_contains(["handler", "analyst", "operative"], line[0])
			assert_has_key(t, line[1])
	for sp in ["handler", "analyst", "operative"]:
		assert_has_key(t, "codec.speaker." + sp)


func test_each_mission_opens_with_a_handler_and_an_analyst_call() -> void:
	for m: Dictionary in Campaign.MISSIONS:
		var who: Array = m.codec.map(func(l: Array) -> String: return l[0])
		assert_contains(who, "handler", m.title)
		assert_contains(who, "analyst", m.title)


func test_every_intel_pickup_triggers_a_live_call() -> void:
	for m: Dictionary in Campaign.MISSIONS:
		for s: Dictionary in m.steps:
			assert_gt(s.call.size(), 0, s.intel)


func test_tr_follows_the_language() -> void:
	var key: String = Campaign.MISSIONS[0].codec[0][1]
	var t := _table()
	TranslationServer.set_locale("en")
	assert_eq(TranslationServer.translate(key), t[key].en)
	TranslationServer.set_locale("es")
	assert_eq(TranslationServer.translate(key), t[key].es)
