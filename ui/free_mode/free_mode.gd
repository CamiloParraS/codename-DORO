## Free mode (minimal): pick a Preset and a Mission, then play it. Nothing is written anywhere: the
## Preset's record lives only in that Mission's MissionRun, and committing comes back here.
## Custom: a slider per Habit (0-3) and for the ratio, starting from Clean slate (ratio undefined
## until its slider moves). The cap and budget still apply by Mission index. Group "mission_plan": F3 previews the plan.
## Drawn in design px under a scaled stage: a UiMenu of Presets on the left, Mission cells and the plan summary
## on the right, Back / Finale / Play bottom right, a drifting backdrop under one UiScan.
extends Control

const MENU := "res://ui/main_menu/main_menu.tscn"

var preset: String = Aigis.PRESETS.keys()[0]   # or "custom"
var custom_levels := {}
var custom_ratio := NAN
var mission := 0
var record: Dictionary
var plan: Dictionary
var _stage := Control.new()
var _summary := Label.new()  # what Aigis deploys: the Preset, the Mission and the budget
var _steps := VBoxContainer.new()  # then each pick, one per line
var _presets := UiMenu.new(560)
var _preset_rows: Array[Button] = []
var _mission_cells: Array[Button] = []
var _outline: StyleBox  # the idle look of a cell, shared
var _plain: StyleBox  # the Mission cells' untinted idle look
var _custom := VBoxContainer.new()


func _exit_tree() -> void:
	Mixer.screen_off(&"menu")


func _ready() -> void:
	Mixer.screen(&"menu")
	add_to_group("mission_plan")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = HudPalette.INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	add_child(UiScan.make(HudPalette.BACKDROP, false, true, HudPalette.BACKDROP_DIM))
	_stage.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_stage)
	theme = HudPalette.theme()  # the 1 px slider with a square grabber
	var title := _text(tr("ui.menu.free_mode").to_upper(), 64, 0.14, HudPalette.LIGHT)
	title.position = Vector2(80, 50)
	_stage.add_child(title)
	var rule := ColorRect.new()
	rule.color = HudPalette.LIGHT
	rule.position = Vector2(80, 140)
	rule.size = Vector2(1760, 3)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(rule)
	UiMotion.grow_x(rule)  # the rule draws on from the left as the page opens
	_presets.position = Vector2(80, 200)
	_stage.add_child(_presets)
	var presets: Array = Aigis.PRESETS.keys() + ["custom"]
	_presets.clear()
	for i in presets.size():
		var b := _presets.add_row("ui.preset." + presets[i], func() -> void: _pick_preset(presets[i]))
		b.pressed.connect(Mixer.click)
		_preset_rows.append(b)
	var mid := VBoxContainer.new()
	mid.position = Vector2(700, 200)
	mid.custom_minimum_size.x = 1140
	mid.add_theme_constant_override("separation", 20)
	_stage.add_child(mid)
	mid.add_child(_heading("ui.free.mission"))
	var cells := HBoxContainer.new()
	cells.add_theme_constant_override("separation", 8)
	mid.add_child(cells)
	for k in Campaign.MISSIONS.size():
		var c := _cell("ui.mission_short.%d" % k, func() -> void: _pick_mission(k))
		cells.add_child(c)
		_mission_cells.append(c)
	_custom.visible = false
	_custom.add_theme_constant_override("separation", 6)
	mid.add_child(_custom)
	for h: String in Aigis.HABITS:
		_slider(_custom, "ui.habit." + h, 3, 1, "0", func(v: float) -> String:
			custom_levels[h] = int(v)
			return str(int(v)))
	_slider(_custom, "ui.free.ratio", 1, 0.05, tr("ui.free.undefined"), func(v: float) -> String:
		custom_ratio = v
		return "%.2f" % v)
	var sum := PanelContainer.new()
	var sbox := PixelKit.Box.new(Color(HudPalette.GLASS, 0.74), Color(0, 0, 0, 0), 3, HudPalette.CYAN)
	sbox.content_margin_left = 30
	sbox.content_margin_right = 30
	sbox.content_margin_top = 24
	sbox.content_margin_bottom = 26
	sum.add_theme_stylebox_override("panel", sbox)
	var sum_col := VBoxContainer.new()
	sum_col.add_theme_constant_override("separation", 18)
	sum_col.custom_minimum_size.x = 1080
	_summary = _text("", 22, 0.24, HudPalette.CYAN)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD
	sum_col.add_child(_summary)
	_steps.add_theme_constant_override("separation", 10)
	sum_col.add_child(_steps)
	sum.add_child(sum_col)
	mid.add_child(sum)
	var act := HBoxContainer.new()
	act.add_theme_constant_override("separation", 14)
	act.position = Vector2(1840 - 560, 940)
	_stage.add_child(act)
	act.add_child(_cell("ui.back", func() -> void: UiTransition.go(get_tree(), MENU)))
	act.add_child(_cell("ui.free.finale", _finale))
	var play := _cell("ui.free.play", _play)
	play.add_theme_stylebox_override("normal", _fill(Color(HudPalette.SAND, 0.82)))
	play.add_theme_color_override("font_color", HudPalette.DARK_INK)
	act.add_child(play)
	var foot := _text(tr("ui.free.footer").format({debug = Prompts.key("debug_overlay")}), 20, 0.2, HudPalette.LIGHT_3)
	foot.position = Vector2(80, 920)
	_stage.add_child(foot)
	resized.connect(_layout)
	_layout()
	_refresh()
	_pick_preset(preset)
	_pick_mission(0)
	_presets.focus_first()
	_presets.open()
	UiMotion.rise(_mission_cells, 0.06)  # the Mission cells come up one after another
	HudPalette.fade(self)


func _layout() -> void:
	var k := size.y / HudPalette.DESIGN_H
	_stage.scale = Vector2(k, k)
	_stage.size = size / k

func _text(s: String, fs: int, em: float, col: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, fs, em))
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _heading(key: String) -> Label:
	var l := _text(tr(key).to_upper(), 24, 0.26, HudPalette.LIGHT_2)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	return l


func _fill(c: Color) -> StyleBox:
	var s := PixelKit.Box.new(c, Color(0, 0, 0, 0), 2)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s


## A bordered cell button; `selected` fills it white with dark text.
func _cell(key: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = key
	b.custom_minimum_size = Vector2(160, 70)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not _outline:
		_outline = PixelKit.Box.new(Color(HudPalette.SAND, 0.1), Color(HudPalette.SAND, 0.55), 2)  # tinted sand, like the chosen Preset
		_outline.content_margin_left = 24
		_outline.content_margin_right = 24
	var line := _outline
	b.add_theme_stylebox_override("normal", line)
	b.add_theme_stylebox_override("hover", line)
	b.add_theme_stylebox_override("pressed", PixelKit.Box.new(Color(HudPalette.SAND, 0.95), Color(0, 0, 0, 0), 2))  # the press flashes sand
	b.add_theme_color_override("font_pressed_color", HudPalette.DARK_INK)
	b.button_down.connect(Mixer.press_thunk)
	b.focus_entered.connect(Mixer.hover_tick)
	b.add_theme_stylebox_override("focus", _fill(HudPalette.SAND.lightened(0.12)))  # hovered or focused: filled sand
	for c: String in ["font_focus_color", "font_hover_color", "font_hover_pressed_color"]:  # the hover colour wins over focus, so the label needs all three
		b.add_theme_color_override(c, HudPalette.DARK_INK)
	b.add_theme_color_override("font_color", HudPalette.SAND)
	b.add_theme_font_size_override("font_size", 26)
	b.mouse_entered.connect(b.grab_focus)
	b.pressed.connect(Mixer.click)
	b.pressed.connect(on_press)
	return b


func _pick_preset(p: String) -> void:
	preset = p
	_custom.visible = p == "custom"
	var presets: Array = Aigis.PRESETS.keys() + ["custom"]
	for i in _preset_rows.size():  # the chosen Preset reads gold
		_preset_rows[i].add_theme_color_override("font_color", HudPalette.SAND if presets[i] == p else HudPalette.LIGHT)
	_refresh()


## The Mission cells' idle look: the original grey-white outline, without the sand tint.
func _plain_outline() -> StyleBox:
	if not _plain:
		_plain = PixelKit.Box.new(Color(0, 0, 0, 0.25), Color(HudPalette.LIGHT, 0.4), 2)
		_plain.content_margin_left = 24
		_plain.content_margin_right = 24
	return _plain


func _pick_mission(k: int) -> void:
	mission = k
	for i in _mission_cells.size():
		var on := i == k
		var look: StyleBox = _fill(HudPalette.LIGHT) if on else _plain_outline()  # hover and pressed too, or the chosen Mission loses its fill under the mouse
		for state: String in ["normal", "hover"]:
			_mission_cells[i].add_theme_stylebox_override(state, look)
		_mission_cells[i].add_theme_stylebox_override("focus", _fill(HudPalette.LIGHT))  # the Mission cells stay white, untinted
		_mission_cells[i].add_theme_color_override("font_color", HudPalette.DARK_INK if on else HudPalette.LIGHT)
	_refresh()


## A labelled slider from 0 to max showing start; moving it calls set_value(value), which returns the text to show.
func _slider(parent: Node, title: String, max_value: float, step: float, start: String, set_value: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var name_label := _heading(title)
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
	name_label.text = title
	name_label.custom_minimum_size.x = 220
	var s := HSlider.new()
	s.max_value = max_value
	s.step = step
	s.custom_minimum_size = Vector2(500, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.mouse_entered.connect(s.grab_focus)
	var shown := _text(start, 30, 0.06, HudPalette.LIGHT)
	s.value_changed.connect(func(v: float) -> void:
		shown.text = set_value.call(v)
		_refresh())
	row.add_child(name_label)
	row.add_child(s)
	row.add_child(shown)
	parent.add_child(row)


func _refresh() -> void:
	if preset == "custom":
		record = Aigis.custom_record(custom_levels, custom_ratio, mission)
	else:
		record = Aigis.preset_record(preset, mission)
	plan = Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), mission)
	var steps := PackedStringArray(plan.picks.map(func(p: Dictionary) -> String:
		return tr("ui.step.%s.%d" % [p.habit, p.level])))
	_summary.text = tr("ui.free.summary").format({preset = tr("ui.preset." + preset), mission = tr("ui.mission_short.%d" % mission),
		budget = plan.budget}).to_upper()
	for c in _steps.get_children():
		c.queue_free()
	if steps.is_empty():
		_steps.add_child(_text(tr("ui.free.nothing").to_upper(), 30, 0.08, HudPalette.LIGHT_3))
	for i in steps.size():  # a numbered pick per line
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		row.add_child(_text("%02d" % (i + 1), 30, 0.06, HudPalette.LIGHT_3))
		row.add_child(_text(steps[i].to_upper(), 30, 0.08, HudPalette.LIGHT))
		_steps.add_child(row)


## The finale for the picked Preset's record, then back here.
func _finale() -> void:
	var f := Control.new()
	f.set_script(load("res://ui/finale/finale.gd"))
	add_child(f)
	f.start(record, scene_file_path)


func _play() -> void:
	Campaign.play(get_tree(), record, scene_file_path)
