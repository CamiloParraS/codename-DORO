## Placeholder Briefing: the next campaign Mission, its objectives and the Voices' briefing keys as
## plain text; any key plays it. Past the Core it shows the ending's band, and any key goes back to
## the main scene. Group "mission_plan": F3 shows the plan table.
## ponytail: the Codec player and the written Briefings replace the text, the finale the ending.
extends Control

var record: Dictionary
var plan: Dictionary
var _font: Font = load("res://assets/fonts/press_start_2p_regular.ttf")


func _ready() -> void:
	add_to_group("mission_plan")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	record = Campaign.record
	plan = Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), record.mission)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_pressed() and not e.is_echo() and (e is InputEventKey or e is InputEventMouseButton):
		get_viewport().set_input_as_handled()
		if Campaign.done():
			Campaign.start()
			get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
		else:
			Campaign.play(get_tree(), record, scene_file_path, true)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	var lines: Array = []
	if Campaign.done():
		lines = ["CAMPAIGN COMPLETE", "", "ENDING: %s" % Aigis.resolve_ending(Aigis.lethality_ratio(record)).to_upper()]
	else:
		var m: Dictionary = Campaign.MISSIONS[record.mission]
		lines = [m.title, "", "BRIEFING"]
		lines.append_array(plan.briefing_keys)
		lines.append_array(["", "OBJECTIVES"])
		lines.append_array(m.steps.map(func(s: Dictionary) -> String: return "- " + s.objective))
		lines.append("- " + Campaign.objective(record.mission, m.steps.size()))
	for i in lines.size():
		draw_string(_font, Vector2(24, 40 + i * 14), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	draw_string(_font, Vector2(24, size.y - 24), "PRESS ANY KEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.5))
