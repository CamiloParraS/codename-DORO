@tool
extends McpTestSuite

## Campaign save slots and the settings file: node-free, against a scratch directory.

const DIR := "user://test_saves"


func suite_name() -> String:
	return "save_slots"


func setup() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func _record(mission := 2) -> Dictionary:
	var r := Aigis.new_record()
	r.mission = mission
	r.points.stealth = 250
	r.lethality = 7
	r.denominator = 20
	return r


func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)


func test_a_slot_round_trips_a_record() -> void:
	SaveSlots.write(1, _record(), 1000, DIR)
	var s := SaveSlots.read(1, DIR)
	assert_eq(s.record, _record())
	assert_eq(s.saved, 1000)
	assert_false(s.complete)
	assert_eq(typeof(s.record.points.stealth), TYPE_INT, "JSON floats come back as ints")


func test_cleared_missions_round_trip() -> void:
	var missions := {"0": {pre = _record(0), best = {rank = "A", time = 312.5, kills = 0, alerts = 1}}}
	SaveSlots.write(1, _record(), 1000, DIR, missions)
	var back: Dictionary = SaveSlots.read(1, DIR).missions
	assert_eq(back, missions)
	assert_eq(typeof(back["0"].best.kills), TYPE_INT)


func test_an_old_slot_file_loads_with_no_mission_record() -> void:
	_write_raw(SaveSlots.path(0, DIR), JSON.stringify({record = _record(), saved = 5}))
	var s := SaveSlots.read(0, DIR)
	assert_eq(s.record, _record())
	assert_eq(s.missions, {})
	_write_raw(SaveSlots.path(0, DIR), JSON.stringify({record = _record(), saved = 5, missions = {"0": {pre = 3}, "1": "x"}}))
	assert_eq(SaveSlots.read(0, DIR).missions, {}, "a malformed cleared Mission is dropped, the slot still loads")


func test_missing_and_unreadable_files_are_empty_slots() -> void:
	assert_eq(SaveSlots.read(0, DIR), {})
	_write_raw(SaveSlots.path(0, DIR), "{not json")
	assert_eq(SaveSlots.read(0, DIR), {})
	_write_raw(SaveSlots.path(2, DIR), '{"saved": 5}')
	assert_eq(SaveSlots.read(2, DIR), {}, "valid JSON missing the record")


func test_past_the_core_marks_the_slot_complete() -> void:
	SaveSlots.write(0, _record(Campaign.MISSIONS.size()), 5, DIR)
	assert_true(SaveSlots.read(0, DIR).complete)


func test_continue_is_the_latest_unfinished_slot_or_none() -> void:
	assert_eq(SaveSlots.continue_slot(DIR), -1)
	SaveSlots.write(0, _record(1), 100, DIR)
	SaveSlots.write(1, _record(2), 300, DIR)
	SaveSlots.write(2, _record(Campaign.MISSIONS.size()), 900, DIR)
	assert_eq(SaveSlots.continue_slot(DIR), 1, "slot 2 is newer but complete")


func test_slot_label_shows_next_mission_or_complete() -> void:
	assert_eq(SaveSlots.label({}), "EMPTY")
	SaveSlots.write(0, _record(1), 0, DIR)
	assert_true(SaveSlots.label(SaveSlots.read(0, DIR)).begins_with("MISSION 2: RADIO RELAY STATION"))
	SaveSlots.write(0, _record(Campaign.MISSIONS.size()), 0, DIR)
	assert_true(SaveSlots.label(SaveSlots.read(0, DIR)).begins_with("COMPLETE"))


func test_settings_default_clamp_and_survive_a_round_trip() -> void:
	var path := DIR.path_join("settings.json")
	assert_eq(GameSettings.load_file(path), GameSettings.DEFAULTS)
	var s := GameSettings.DEFAULTS.duplicate()
	s.sensitivity = 0.004
	s.invert_y = true
	s.language = "es"
	s.volume = 5.0
	GameSettings.save_file(s, path)
	var back := GameSettings.load_file(path)
	assert_eq(back.sensitivity, 0.004)
	assert_true(back.invert_y)
	assert_eq(back.language, "es")
	assert_eq(back.volume, 1.0, "volume is clamped to 0..1")


func test_settings_ignore_bad_values_and_new_game_leaves_them() -> void:
	var path := DIR.path_join("settings.json")
	_write_raw(path, '{"language": "fr", "sensitivity": "fast", "fullscreen": true}')
	var s := GameSettings.load_file(path)
	assert_eq(s.language, "en")
	assert_eq(s.sensitivity, GameSettings.DEFAULTS.sensitivity)
	assert_true(s.fullscreen)
	Campaign.start()  # a separate file: New game cannot touch it
	assert_true(GameSettings.load_file(path).fullscreen)


func test_menu_screens_build() -> void:
	for p in ["res://ui/main_menu/main_menu.tscn", "res://ui/settings/settings_panel.gd", "res://ui/pause/pause.gd"]:
		var r: Resource = load(p)
		var n: Node = r.instantiate() if r is PackedScene else (r as GDScript).new()
		(Engine.get_main_loop() as SceneTree).root.add_child(n)
		assert_true(n.get_child_count() > 0, p)
		n.free()
