## Free mode (minimal): pick a Preset and a Mission, then play it. Nothing is written anywhere: the
## Preset's record lives only in that Mission's MissionRun, and committing comes back here.
## Custom: a slider per Habit (0-3) and for the ratio, starting from Clean slate (ratio undefined
## until its slider moves). The cap and budget still apply by Mission index. Group "mission_plan": F3 previews the plan.
extends Control

const MENU := "res://ui/main_menu/main_menu.tscn"

var preset: String = Aigis.PRESETS.keys()[0]   # or "custom"
var custom_levels := {}
var custom_ratio := NAN
var mission := 0
var record: Dictionary
var plan: Dictionary
var _summary := Label.new()


func _ready() -> void:
	add_to_group("mission_plan")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = HudPalette.INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	theme = HudPalette.theme()
	var box := VBoxContainer.new()
	box.position = Vector2(24, 24)
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	_label(box, "ui.menu.free_mode", HudPalette.TITLE_SIZE, HudPalette.WHITE).custom_minimum_size.y = 24
	var presets: Array = Aigis.PRESETS.keys() + ["custom"]
	var custom := VBoxContainer.new()
	_choices(box, "ui.free.preset", presets.map(func(p: String) -> String: return "ui.preset." + p),
		func(i: int) -> void:
			preset = presets[i]
			custom.visible = preset == "custom")
	custom.visible = false
	custom.position = Vector2(396, 96)  # a column right of the Mission row, so PLAY stays on screen
	add_child(custom)
	for h: String in Aigis.HABITS:
		_slider(custom, "ui.habit." + h, 3, 1, "0", func(v: float) -> String:
			custom_levels[h] = int(v)
			return str(int(v)))
	_slider(custom, "ui.free.ratio", 1, 0.05, tr("ui.free.undefined"), func(v: float) -> String:
		custom_ratio = v
		return "%.2f" % v)
	_choices(box, "ui.free.mission", range(Campaign.MISSIONS.size()).map(func(k: int) -> String: return "ui.mission_short.%d" % k),
		func(i: int) -> void: mission = i)
	_summary.custom_minimum_size = Vector2(360, 60)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD
	_summary.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_summary.add_theme_color_override("font_color", HudPalette.AIGIS)  # the plan is Aigis's
	box.add_child(_summary)
	var play := _button(box, "ui.free.play", _play)
	_button(box, "ui.free.finale", _finale)
	_button(box, "ui.back", func() -> void: get_tree().change_scene_to_file(MENU))
	_label(box, tr("ui.free.footer").format({debug = Prompts.key("debug_overlay")}), HudPalette.HEADING_SIZE, HudPalette.HINT)
	_refresh()
	play.grab_focus()
	HudPalette.fade(self)


func _label(parent: Node, text: String, fs: int, col := HudPalette.CHROME) -> Label:
	var l := HudPalette.label(text, fs, col)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, on_press: Callable) -> Button:
	var b := HudPalette.menu_button(text, on_press)
	b.pressed.connect(Mixer.click)
	parent.add_child(b)
	return b


## A labelled slider from 0 to max showing start; moving it calls set_value(value), which returns the text to show.
func _slider(parent: Node, title: String, max_value: float, step: float, start: String, set_value: Callable) -> void:
	var row := HBoxContainer.new()
	var name_label := HudPalette.label(title)
	name_label.custom_minimum_size.x = 96
	var s := HSlider.new()
	s.max_value = max_value
	s.step = step
	s.custom_minimum_size = Vector2(80, 16)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.mouse_entered.connect(s.grab_focus)
	var shown := HudPalette.label(start, HudPalette.HEADING_SIZE, HudPalette.WHITE)
	shown.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	s.value_changed.connect(func(v: float) -> void:
		shown.text = set_value.call(v)
		_refresh())
	row.add_child(name_label)
	row.add_child(s)
	row.add_child(shown)
	parent.add_child(row)


## A row of toggle buttons (text keys); picking one calls pick(index) and refreshes the plan. The picked
## one stays white in brackets.
func _choices(parent: Node, title: String, names: Array, pick: Callable) -> void:
	_label(parent, title, HudPalette.HEADING_SIZE, HudPalette.CHROME_DIM)
	var row := HBoxContainer.new()
	var group := ButtonGroup.new()
	for i in names.size():
		var b := HudPalette.menu_button(names[i])
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		var shown := func(on: bool) -> void: b.text = ("[%s]" if on else " %s ") % tr(names[i])
		shown.call(i == 0)
		b.toggled.connect(shown)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = i == 0
		b.pressed.connect(func() -> void:
			pick.call(i)
			_refresh())
		row.add_child(b)
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
		budget = plan.budget}) + "\n" + ("\n".join(steps) if steps else tr("ui.free.nothing"))


## The finale for the picked Preset's record, then back here.
func _finale() -> void:
	var f := Control.new()
	f.set_script(load("res://ui/finale/finale.gd"))
	add_child(f)
	f.start(record, scene_file_path)


func _play() -> void:
	Campaign.play(get_tree(), record, scene_file_path)
