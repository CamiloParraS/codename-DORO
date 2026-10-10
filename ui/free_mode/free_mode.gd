## Free mode (minimal): pick a Preset and a Mission, then play it. Nothing is written anywhere: the
## Preset's record lives only in that Mission's MissionRun, and committing comes back here.
## The cap and budget still apply by Mission index. Group "mission_plan": F3 previews the plan.
extends Control

const HARBOUR := "res://areas/harbour/harbour.tscn"
## [name, Area scene], by Mission index. ponytail: the Relay station and Research annex aren't
## built yet, so their Mission indices play in the Harbour until their tickets land.
const MISSIONS := [
	["MISSION 1", HARBOUR],
	["MISSION 2", HARBOUR],
	["MISSION 3", HARBOUR],
	["CORE", HARBOUR],
]

var preset: String = Aigis.PRESETS.keys()[0]
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
	_choices(box, "PRESET", Aigis.PRESETS.keys().map(func(p: String) -> String: return p.capitalize().to_upper()),
		func(i: int) -> void: preset = Aigis.PRESETS.keys()[i])
	_choices(box, "MISSION", MISSIONS.map(func(m: Array) -> String: return m[0]), func(i: int) -> void: mission = i)
	box.add_child(_summary)
	var play := Button.new()
	play.text = "PLAY"
	play.pressed.connect(_play)
	box.add_child(play)
	_label(box, "EVERY MISSION PLAYS IN THE HARBOUR FOR NOW.  F3: DEBUG OVERLAY", 8).modulate.a = 0.5
	_refresh()
	play.grab_focus()


func _label(parent: Node, text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


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
	record = Aigis.preset_record(preset, mission)
	plan = Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), mission)
	var steps := PackedStringArray(plan.picks.map(func(p: Dictionary) -> String:
		return Aigis.LADDERS[p.habit][p.level - 1][1]))
	_summary.text = "%s ON %s: AIGIS DEPLOYS (BUDGET %d)\n%s" % [preset.capitalize().to_upper(),
		MISSIONS[mission][0], plan.budget, "\n".join(steps).to_upper() if steps else "NOTHING"]


func _play() -> void:
	var area: Node = load(MISSIONS[mission][1]).instantiate()
	var run: MissionRun = area.get_node("MissionRun")
	run.record = record
	run.return_to = scene_file_path
	get_tree().change_scene_to_node(area)
