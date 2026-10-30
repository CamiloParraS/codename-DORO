## The settings screen (main menu and pause): language, master volume, sensitivity, invert Y, fullscreen, reduced
## motion. A UiMenu list on the left, one large icon on the right that wipes in (7 steps) whenever the highlighted
## option changes. Left/right change the highlighted value, press toggles or cycles it. Every change applies live
## and is written to the settings file at once. BACK emits `closed`, then the panel frees itself.
## Drawn in design px (1080 tall) under a scaled stage; the caller hides what it covers.
extends Control

signal closed

const LANGUAGE_NAMES := {en = "EN", es = "ES"}
const ICONS := "res://assets/ui/icons/%s.svg"
const ICON_SIZE := 420.0
const WIDTH := 900.0
const CTL_W := 340.0

var _values: Dictionary = GameSettings.current.duplicate()
var _stage := Control.new()
var _list := UiMenu.new(WIDTH)
var _icon := TextureRect.new()
var _icons := {}  # row button -> icon texture


func _ready() -> void:
	add_to_group("settings_open")  # story motion holds still (StoryMotion.still)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	var title := Label.new()
	title.text = "ui.settings.title"
	title.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, 64, 0.14))
	title.add_theme_font_size_override("font_size", 64)
	title.position = Vector2(100, 120)
	_stage.add_child(title)
	_stage.add_child(_list)
	_list.position = Vector2(100, 260)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_icon.size = Vector2.ONE * ICON_SIZE
	_icon.modulate = HudPalette.LIGHT
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_icon)
	_list.clear()
	_slider("ui.settings.language", "lang", func() -> float: return GameSettings.LANGUAGES.find(_values.language), Vector2(0, 1), "language")
	_slider("ui.settings.volume", "vol", func() -> float: return _values.volume, Vector2(0.0, 1.0), "volume")
	_slider("ui.settings.sensitivity", "sens", func() -> float: return _values.sensitivity, GameSettings.SENS_RANGE, "sensitivity")
	_toggle("ui.settings.invert_y", "inv", "invert_y")
	_toggle("ui.settings.fullscreen", "fs", "fullscreen")
	_toggle("ui.settings.reduce_motion", "motion", "reduce_motion")
	var back := _list.add_row("ui.back", func() -> void:
		Mixer.click()
		closed.emit()
		queue_free())
	back.focus_entered.connect(func() -> void: _icon.visible = false)
	resized.connect(_layout)
	_layout()
	_list.focus_first()
	_list.open()
	HudPalette.fade(self)


func _layout() -> void:
	var k := size.y / HudPalette.DESIGN_H
	_stage.scale = Vector2(k, k)
	_stage.size = size / k
	_icon.position = Vector2(_stage.size.x - 220 - ICON_SIZE, 300)


func _put(key: String, v: Variant) -> void:
	_values[key] = v
	GameSettings.apply(_values)
	GameSettings.save_file(_values)


## Shows `icon` for the row that just took focus, wiping it in.
func _show_icon(icon: String) -> void:
	if not _icons.has(icon):
		_icons[icon] = load(ICONS % icon)
	_icon.texture = _icons[icon]
	_icon.visible = true
	UiMotion.wipe(_icon, true, 7, 0.3)


func _row(text: String, icon: String, ctl: SettingCtl) -> Button:
	var b := _list.add_row(text)
	b.focus_entered.connect(_show_icon.bind(icon))
	ctl.row = b
	ctl.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	ctl.offset_left = -CTL_W - 20
	ctl.offset_right = -20
	ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ctl)
	return b


## A slider row (language is a two-step one, drawn as EN / ES pills). `get_v` reads the live value.
func _slider(text: String, icon: String, get_v: Callable, range_: Vector2, key: String) -> void:
	var ctl := SettingCtl.new()
	var step := (range_.y - range_.x) / 20.0
	if key == "language":
		ctl.options = GameSettings.LANGUAGES.map(func(l: String) -> String: return LANGUAGE_NAMES[l])
		step = 1.0
	ctl.value = func() -> float: return get_v.call()
	ctl.range_ = range_
	var set_v := func(v: float) -> void:
		v = clampf(v, range_.x, range_.y)
		if key == "language":
			_put(key, GameSettings.LANGUAGES[int(v) % GameSettings.LANGUAGES.size()])
		else:
			_put(key, v)
		ctl.queue_redraw()
	var b := _row(text, icon, ctl)
	b.gui_input.connect(func(e: InputEvent) -> void:
		if e.is_action_pressed("ui_left") or e.is_action_pressed("ui_right"):
			var dir := 1.0 if e.is_action_pressed("ui_right") else -1.0
			if key == "language":
				set_v.call(posmod(int(get_v.call()) + 1, GameSettings.LANGUAGES.size()))
			else:
				set_v.call(get_v.call() + dir * step)
			Mixer.play(&"tick")
			b.accept_event()
		elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and key != "language":
			var local: float = (e.position.x - (b.size.x - CTL_W - 20)) / (CTL_W - 90.0)  # the track, then the number
			set_v.call(range_.x + clampf(local, 0.0, 1.0) * (range_.y - range_.x)))
	if key == "language":
		b.pressed.connect(func() -> void: set_v.call(posmod(int(get_v.call()) + 1, GameSettings.LANGUAGES.size())))


func _toggle(text: String, icon: String, key: String) -> void:
	var ctl := SettingCtl.new()
	ctl.options = [tr("ui.off"), tr("ui.on")]
	ctl.value = func() -> float: return 1.0 if _values[key] else 0.0
	var flip := func(on: bool) -> void:
		_put(key, on)
		ctl.queue_redraw()
	var b := _row(text, icon, ctl)
	b.pressed.connect(func() -> void: flip.call(not _values[key]))
	b.gui_input.connect(func(e: InputEvent) -> void:
		if e.is_action_pressed("ui_left") or e.is_action_pressed("ui_right"):
			flip.call(e.is_action_pressed("ui_right"))
			Mixer.play(&"tick")
			b.accept_event())


## The value drawn at a row's right edge: a track and a number (a slider) or pills (a toggle, language).
## The active pill is dark text on the light fill; ink flips while its row is selected.
class SettingCtl extends Control:
	var row: Button
	var value := func() -> float: return 0.0
	var range_ := Vector2(0, 1)
	var options: Array = []

	func _draw() -> void:
		var on: bool = row != null and row.has_focus()
		var ink: Color = HudPalette.DARK_INK if on else HudPalette.LIGHT
		var v: float = value.call()
		if options.is_empty():
			var track := Rect2(0, size.y / 2 - 4, CTL_W - 90.0, 8)
			draw_rect(track, Color(ink, 0.25))
			draw_rect(Rect2(track.position, Vector2(track.size.x * inverse_lerp(range_.x, range_.y, v), track.size.y)), ink)
			var pct := str(roundi(inverse_lerp(range_.x, range_.y, v) * 100.0))
			var f := HudPalette.tracked(HudPalette.DISPLAY, 30, 0.04)
			draw_string(f, Vector2(size.x - 70, size.y / 2 + 11), pct, HORIZONTAL_ALIGNMENT_RIGHT, 70, 30, ink)
			return
		var f := HudPalette.tracked(HudPalette.DISPLAY, 26, 0.12)
		var x := size.x
		for i in range(options.size() - 1, -1, -1):
			var w := f.get_string_size(options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 36
			x -= w
			var active := i == int(v)
			var cell := Rect2(x, size.y / 2 - 20, w, 40)
			if active:
				draw_rect(cell, ink)
			draw_string(f, Vector2(x + 18, size.y / 2 + 9), options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, (HudPalette.LIGHT if on else HudPalette.DARK_INK) if active else Color(ink, 0.55))
			x -= 6


func _process(_delta: float) -> void:
	for b in _list.find_children("*", "Button", true, false):  # the value ink follows the selection
		for c in b.get_children():
			if c is SettingCtl:
				c.queue_redraw()
