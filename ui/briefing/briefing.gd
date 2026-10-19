## Placeholder Briefing: the next campaign Mission, its objectives and the Voices' briefing keys as
## plain text; any key opens the Mission's Codec call, which starts it. Past the Core it shows the ending's band, and any key goes back to
## the main scene. Group "mission_plan": F3 shows the plan table.
## ponytail: the Codec player and the written Briefings replace the text, the finale the ending.
extends Control

var record: Dictionary
var plan: Dictionary
var _lines: Array = []
var _blips: Array[VoiceBlip] = []   # one per line, typed out in turn
var _font: Font = load("res://assets/fonts/press_start_2p_regular.ttf")


func _ready() -> void:
	add_to_group("mission_plan")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	record = Campaign.record
	plan = Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), record.mission)
	_lines = _build_lines()
	for l: String in _lines:
		# objectives and headings have no Voice: shown at once
		_blips.append(VoiceBlip.new(tr(l), VoiceBlip.voice_of(l)))


func _process(delta: float) -> void:
	for b in _blips:
		if not b.done():
			var p := b.advance(delta)
			if not p.is_empty():
				Mixer.blip(p.back())  # one blip per frame: they never stack
			queue_redraw()
			return  # lines type out in order


func _typing() -> bool:
	return not _blips.all(func(b: VoiceBlip) -> bool: return b.done())


func _unhandled_input(e: InputEvent) -> void:
	if e.is_pressed() and not e.is_echo() and (e is InputEventKey or e is InputEventMouseButton):
		get_viewport().set_input_as_handled()
		if _typing():  # first press skips the typing and stops the blips
			_blips.map(func(b: VoiceBlip) -> void: b.skip())
			Mixer.stop_blips()
			queue_redraw()
		elif Campaign.done():
			Campaign.start()
			get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
		else:
			_open_codec()


## The Mission's full-screen Codec call, then the Mission itself.
func _open_codec() -> void:
	set_process_unhandled_input(false)
	var codec := CodecScreen.new(Campaign.MISSIONS[record.mission].codec)
	codec.finished.connect(func() -> void: Campaign.play(get_tree(), record, scene_file_path, true))
	add_child(codec)


func _build_lines() -> Array:
	var lines: Array = []
	if Campaign.done():
		return ["CAMPAIGN COMPLETE", "", "ENDING: %s" % Aigis.resolve_ending(Aigis.lethality_ratio(record)).to_upper()]
	var m: Dictionary = Campaign.MISSIONS[record.mission]
	lines = [m.title, "", "BRIEFING"]
	lines.append_array(plan.briefing_keys)
	lines.append_array(["", "OBJECTIVES"])
	lines.append_array(m.steps.map(func(s: Dictionary) -> String: return "- " + s.objective))
	lines.append("- " + Campaign.objective(record.mission, m.steps.size()))
	return lines


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	for i in _lines.size():
		draw_string(_font, Vector2(24, 40 + i * 14), _blips[i].shown(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	draw_string(_font, Vector2(24, size.y - 24), "PRESS ANY KEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.5))
