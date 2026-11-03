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
var _note := Label.new()  # the key row's note, where the icon sits
var _key_btn: Button      # the key row, and its value pill
var _key_ctl: SettingCtl
var _key_veil: ColorRect  # the open key editor, null when closed


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
	_fps_row()
	_key_row()
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
	_note.position = _icon.position - Vector2(120, 0)


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


## The max-FPS row: AUTO / 60 / 120 / 144 pills; left/right step, press cycles.
func _fps_row() -> void:
	var ctl := SettingCtl.new()
	ctl.options = GameSettings.FPS_CAPS.map(func(f: int) -> String: return tr("ui.settings.fps_auto") if f == 0 else str(f))
	ctl.value = func() -> float: return GameSettings.FPS_CAPS.find(_values.max_fps)
	var step := func(dir: int) -> void:
		var i: int = clampi(GameSettings.FPS_CAPS.find(_values.max_fps) + dir, 0, GameSettings.FPS_CAPS.size() - 1) if dir != 0 \
				else posmod(GameSettings.FPS_CAPS.find(_values.max_fps) + 1, GameSettings.FPS_CAPS.size())
		_put("max_fps", GameSettings.FPS_CAPS[i])
		ctl.queue_redraw()
	var b := _row("ui.settings.max_fps", "fs", ctl)
	b.pressed.connect(func() -> void: step.call(0))
	b.gui_input.connect(func(e: InputEvent) -> void:
		if e.is_action_pressed("ui_left") or e.is_action_pressed("ui_right"):
			step.call(1 if e.is_action_pressed("ui_right") else -1)
			Mixer.play(&"tick")
			b.accept_event())


## Aigis Voice's Gemini key (LlmClient): the row shows NONE, FROM SYSTEM (GEMINI_API_KEY) or the key's last four;
## press opens the key editor (_open_key). While the row is selected the note on where the key lives replaces the icon.
func _key_row() -> void:
	var ctl := SettingCtl.new()
	_key_ctl = ctl
	ctl.options = [_key_label()]
	var b := _list.add_row("ui.settings.aigis_key")
	_key_btn = b
	ctl.row = b
	ctl.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	ctl.offset_left = -CTL_W - 20
	ctl.offset_right = -20
	ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ctl)
	_note.text = "ui.settings.aigis_key.note"
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.add_theme_font_override("font", HudPalette.FIGURE_MED)
	_note.add_theme_font_size_override("font_size", 28)
	_note.modulate = HudPalette.LIGHT_2
	_note.visible = false
	_note.size = Vector2(ICON_SIZE + 120, ICON_SIZE)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_note)
	b.focus_entered.connect(func() -> void:
		_icon.visible = false
		_note.visible = true)
	b.focus_exited.connect(func() -> void: _note.visible = false)
	b.pressed.connect(_open_key)


func _key_label() -> String:
	var k: String = _values.get("llm_key", "")
	if k != "":
		return "****" + k.right(4)
	return tr("ui.settings.aigis_key.env") if OS.get_environment(LlmClient.KEY_ENV) != "" else tr("ui.settings.aigis_key.none")


## The key editor: a box over the dimmed settings (the veil takes every click, so hovering the rows can't pull
## focus out of the field) with a masked field. ENTER saves (empty clears), ESC or a click on the veil cancels;
## either way focus goes back to the row.
func _open_key() -> void:
	if is_instance_valid(_key_veil):
		return
	_key_veil = ColorRect.new()
	_key_veil.color = Color(0, 0, 0, 0.7)
	_key_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.add_child(_key_veil)
	_key_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # follows _stage through a resize
	var box := PanelContainer.new()
	var frame := StyleBoxFlat.new()
	frame.bg_color = HudPalette.GROUND
	frame.border_color = HudPalette.CYAN
	frame.set_border_width_all(3)
	frame.set_content_margin_all(40)
	box.add_theme_stylebox_override("panel", frame)
	box.custom_minimum_size.x = 900
	_key_veil.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)  # centred, growing both ways as it fills
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	box.add_child(col)
	var title := Label.new()
	title.text = "ui.settings.aigis_key"
	title.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, 40, 0.14))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", HudPalette.CYAN)
	col.add_child(title)
	var edit := LineEdit.new()
	edit.secret = true
	edit.placeholder_text = tr("ui.settings.aigis_key.paste")
	edit.text = _values.get("llm_key", "")
	edit.custom_minimum_size.y = 64
	edit.add_theme_font_override("font", HudPalette.FIGURE_MED)
	edit.add_theme_font_size_override("font_size", 30)
	edit.add_theme_color_override("font_color", HudPalette.LIGHT)
	edit.add_theme_color_override("font_placeholder_color", HudPalette.LIGHT_3)
	edit.add_theme_color_override("caret_color", HudPalette.CYAN)
	var field := StyleBoxFlat.new()
	field.bg_color = Color(0, 0, 0, 0.5)
	field.border_color = Color(HudPalette.LIGHT, 0.5)
	field.set_border_width_all(2)
	field.set_content_margin_all(14)
	for s in ["normal", "focus", "read_only"]:
		edit.add_theme_stylebox_override(s, field)
	col.add_child(edit)
	var hint := Label.new()
	hint.text = "ui.settings.aigis_key.keys"
	hint.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, 22, 0.2))
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", HudPalette.LIGHT_3)
	col.add_child(hint)
	var close := func(save: bool) -> void:
		if not is_instance_valid(_key_veil) or _key_veil.is_queued_for_deletion():
			return
		if save:
			_put("llm_key", edit.text.strip_edges())
			_key_ctl.options = [_key_label()]
			Mixer.click()
		_key_veil.queue_free()
		_key_btn.grab_focus()
	edit.text_submitted.connect(func(_t: String) -> void: close.call(true))
	edit.gui_input.connect(func(e: InputEvent) -> void:
		if e.is_action_pressed("ui_cancel"):
			edit.accept_event()
			close.call(false))
	_key_veil.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and not box.get_global_rect().has_point(e.global_position):
			close.call(false))
	for side in ["focus_neighbor_top", "focus_neighbor_bottom", "focus_neighbor_left", "focus_neighbor_right", "focus_next", "focus_previous"]:
		edit.set(side, NodePath("."))  # up/down/tab stay in the field: the rows behind the veil never take focus
	edit.focus_exited.connect(func() -> void:
		if is_instance_valid(_key_veil) and not _key_veil.is_queued_for_deletion():
			edit.grab_focus.call_deferred())
	edit.grab_focus.call_deferred()
	edit.caret_column = edit.text.length()


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
			var track := Rect2(0, size.y / 2 - 6, CTL_W - 90.0, 12)
			var lit := PixelKit.PX * 2.0 * roundf(track.size.x * inverse_lerp(range_.x, range_.y, v) / (PixelKit.PX * 2.0))  # fills in 6 px cells
			PixelKit.tone(self, Rect2(track.position + Vector2(lit, 0), Vector2(track.size.x - lit, track.size.y)), Color(ink, 0.5), 0.5)
			PixelKit.cut_fill(self, Rect2(track.position, Vector2(lit, track.size.y)), ink, 0)
			var pct := str(roundi(inverse_lerp(range_.x, range_.y, v) * 100.0))
			var pf := HudPalette.tracked(HudPalette.DISPLAY, 30, 0.04)
			draw_string(pf, Vector2(size.x - 70, size.y / 2 + 11), pct, HORIZONTAL_ALIGNMENT_RIGHT, 70, 30, ink)
			return
		var f := HudPalette.tracked(HudPalette.DISPLAY, 26, 0.12)
		var x := size.x
		for i in range(options.size() - 1, -1, -1):
			var w := f.get_string_size(options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 36
			x -= w
			var active := i == int(v)
			var cell := Rect2(x, size.y / 2 - 20, w, 40)
			if active:
				PixelKit.cut_fill(self, PixelKit.snap(cell), ink, 2)
			draw_string(f, Vector2(x + 18, size.y / 2 + 9), options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, (HudPalette.LIGHT if on else HudPalette.DARK_INK) if active else Color(ink, 0.55))
			x -= 6


func _process(_delta: float) -> void:
	for b in _list.find_children("*", "Button", true, false):  # the value ink follows the selection
		for c in b.get_children():
			if c is SettingCtl:
				c.queue_redraw()
