## Free mode (minimal): pick a Preset and a Mission, then play it. Nothing is written anywhere: the
## Preset's record lives only in that Mission's MissionRun, and committing comes back here.
## Custom: a slider per Habit (0-3) and for the ratio, starting from Clean slate (ratio undefined
## until its slider moves). The cap and budget still apply by Mission index. Group "mission_plan": F3 previews the plan.
extends Control

const BRIEFING := "res://ui/briefing/briefing.tscn"
var _mission_names: Array = Campaign.MISSIONS.map(func(m: Dictionary) -> String: return m.title.get_slice(":", 0))

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
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	theme = Theme.new()
	theme.default_font = load("res://assets/fonts/press_start_2p_regular.ttf")
	theme.default_font_size = 8
	var box := VBoxContainer.new()
	box.position = Vector2(24, 24)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_label(box, "FREE MODE", 12)
	var presets: Array = Aigis.PRESETS.keys() + ["custom"]
	var custom := VBoxContainer.new()
	_choices(box, "PRESET", presets.map(func(p: String) -> String: return p.capitalize().to_upper()),
		func(i: int) -> void:
			preset = presets[i]
			custom.visible = preset == "custom")
	custom.visible = false
	custom.position = Vector2(396, 96)  # a column right of the Mission row, so PLAY stays on screen
	add_child(custom)
	for h: String in Aigis.HABITS:
		_slider(custom, h.to_upper(), 3, 1, "0", func(v: float) -> String:
			custom_levels[h] = int(v)
			return str(int(v)))
	_slider(custom, "RATIO", 1, 0.05, "UNDEFINED", func(v: float) -> String:
		custom_ratio = v
		return "%.2f" % v)
	_choices(box, "MISSION", _mission_names, func(i: int) -> void: mission = i)
	box.add_child(_summary)
	var play := Button.new()
	play.text = "PLAY"
	play.pressed.connect(_play)
	box.add_child(play)
	var campaign := Button.new()  # ponytail: the main menu takes this over
	campaign.text = "NEW CAMPAIGN"
	campaign.pressed.connect(func() -> void:
		Campaign.start()
		get_tree().change_scene_to_file(BRIEFING))
	box.add_child(campaign)
	_label(box, "EVERY MISSION PLAYS IN THE HARBOUR FOR NOW.\nF3: DEBUG OVERLAY", 8).modulate.a = 0.5
	_refresh()
	play.grab_focus()


func _label(parent: Node, text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


## A labelled slider from 0 to max showing start; moving it calls set_value(value), which returns the text to show.
func _slider(parent: Node, title: String, max_value: float, step: float, start: String, set_value: Callable) -> void:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = title
	name_label.custom_minimum_size.x = 72
	var s := HSlider.new()
	s.max_value = max_value
	s.step = step
	s.custom_minimum_size.x = 80
	var shown := Label.new()
	shown.text = start
	s.value_changed.connect(func(v: float) -> void:
		shown.text = set_value.call(v)
		_refresh())
	row.add_child(name_label)
	row.add_child(s)
	row.add_child(shown)
	parent.add_child(row)


## A row of toggle buttons; picking one calls pick(index) and refreshes the plan.
func _choices(parent: Node, title: String, names: Array, pick: Callable) -> void:
	_label(parent, title, 8).modulate.a = 0.6
	var row := HBoxContainer.new()
	var group := ButtonGroup.new()
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
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
		return Aigis.LADDERS[p.habit][p.level - 1][1]))
	_summary.text = "%s ON %s: AIGIS DEPLOYS (BUDGET %d)\n%s" % [preset.capitalize().to_upper(),
		_mission_names[mission], plan.budget, "\n".join(steps).to_upper() if steps else "NOTHING"]


func _play() -> void:
	Campaign.play(get_tree(), record, scene_file_path)
