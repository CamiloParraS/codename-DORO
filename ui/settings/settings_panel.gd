## The settings screen (main menu and pause): sensitivity, invert Y, language, fullscreen, master volume.
## Every change applies live and is written to the settings file at once. BACK emits `closed`.
## Rows are HudPalette menu buttons: a toggle shows [X] or [ ], the language cycles on press.
extends VBoxContainer

signal closed

const LANGUAGE_NAMES := {en = "ENGLISH", es = "ESPAÑOL"}

var _values: Dictionary = GameSettings.current.duplicate()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 4)
	var title := HudPalette.label("ui.settings.title", HudPalette.TITLE_SIZE, HudPalette.WHITE)
	title.custom_minimum_size.y = 28
	add_child(title)
	_slider("ui.settings.sensitivity", GameSettings.SENS_RANGE.x, GameSettings.SENS_RANGE.y, "sensitivity")
	_check("ui.settings.invert_y", "invert_y")
	var lang := HudPalette.menu_button(LANGUAGE_NAMES[_values.language])
	lang.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	lang.pressed.connect(func() -> void:
		var next: String = GameSettings.LANGUAGES[(GameSettings.LANGUAGES.find(_values.language) + 1) % GameSettings.LANGUAGES.size()]
		lang.text = LANGUAGE_NAMES[next]
		_put("language", next))
	_row("ui.settings.language", lang)
	_check("ui.settings.fullscreen", "fullscreen")
	_slider("ui.settings.volume", 0.0, 1.0, "volume")
	var back := HudPalette.menu_button("ui.back", func() -> void:
		Mixer.click()
		closed.emit()
		queue_free())
	add_child(back)
	back.grab_focus.call_deferred()
	HudPalette.fade(self)


func _put(key: String, v: Variant) -> void:
	_values[key] = v
	GameSettings.apply(_values)
	GameSettings.save_file(_values)


func _row(text: String, control: Control) -> void:
	var r := HBoxContainer.new()
	var l := HudPalette.label(text)
	l.custom_minimum_size.x = 160
	r.add_child(l)
	r.add_child(control)
	add_child(r)


func _slider(text: String, lo: float, hi: float, key: String) -> void:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = (hi - lo) / 20.0
	s.value = _values[key]
	s.custom_minimum_size = Vector2(120, 16)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.mouse_entered.connect(s.grab_focus)
	s.value_changed.connect(func(v: float) -> void: _put(key, v))
	_row(text, s)


func _check(text: String, key: String) -> void:
	var c := HudPalette.menu_button("")
	c.toggle_mode = true
	c.button_pressed = _values[key]
	c.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	c.text = "[X]" if c.button_pressed else "[ ]"
	c.toggled.connect(func(on: bool) -> void:
		c.text = "[X]" if on else "[ ]"
		_put(key, on))
	_row(text, c)
