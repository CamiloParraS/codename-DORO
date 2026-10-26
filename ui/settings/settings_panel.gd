## The settings screen (main menu and pause): sensitivity, invert Y, language, fullscreen, master volume.
## Every change applies live and is written to the settings file at once. BACK emits `closed`.
extends PanelContainer

signal closed

var _values: Dictionary = GameSettings.current.duplicate()


func _ready() -> void:
	add_to_group("settings_open")  # story motion holds still (StoryMotion.still)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	add_child(box)
	_title(box, "SETTINGS")
	_slider(box, "SENSITIVITY", GameSettings.SENS_RANGE.x, GameSettings.SENS_RANGE.y, "sensitivity")
	_check(box, "INVERT Y", "invert_y")
	var lang := OptionButton.new()
	for l: String in GameSettings.LANGUAGES:
		lang.add_item(l.to_upper())
	lang.selected = GameSettings.LANGUAGES.find(_values.language)
	lang.item_selected.connect(func(i: int) -> void: _put("language", GameSettings.LANGUAGES[i]))
	_row(box, "LANGUAGE", lang)
	_check(box, "FULLSCREEN", "fullscreen")
	_slider(box, "MASTER VOLUME", 0.0, 1.0, "volume")
	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(func() -> void:
		Mixer.click()
		closed.emit()
		queue_free())
	box.add_child(back)
	back.grab_focus()


func _put(key: String, v: Variant) -> void:
	_values[key] = v
	GameSettings.apply(_values)
	GameSettings.save_file(_values)


func _title(box: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	box.add_child(l)


func _row(box: Control, text: String, control: Control) -> void:
	var r := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 120
	r.add_child(l)
	r.add_child(control)
	box.add_child(r)


func _slider(box: Control, text: String, lo: float, hi: float, key: String) -> void:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = (hi - lo) / 20.0
	s.value = _values[key]
	s.custom_minimum_size.x = 120
	s.value_changed.connect(func(v: float) -> void: _put(key, v))
	_row(box, text, s)


func _check(box: Control, text: String, key: String) -> void:
	var c := CheckBox.new()
	c.button_pressed = _values[key]
	c.toggled.connect(func(on: bool) -> void: _put(key, on))
	_row(box, text, c)
