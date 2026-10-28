## The Briefing: the next campaign Mission's title, Aigis's Voices on what it noticed and what it deployed
## (a transcript: the Voice's glyph and name in Aigis's cyan, then its line in VT323, typed out with its
## beeps), then the objectives; any key opens the Mission's Codec call, which starts it. Past the Core it
## shows the ending's band, and any key goes back to the main scene. Group "mission_plan": F3 shows the
## plan table. After a first clear with something to buy the Requisition screen opens over it first;
## R reopens it.
extends Control

const REQUISITION := preload("res://ui/requisition/requisition.gd")
const GLYPHS: Dictionary = preload("res://ui/finale/finale.gd").GLYPHS
const TAG := 112  # px from the margin to a Voice line's text: room for "() GLAUKOPIS"
const MARGIN := 24

var record: Dictionary
var plan: Dictionary
var _lines: Array = []               # [kind, key or text]: "title", "head", "voice", "band", "objective", "gap"
var _blips: Array[VoiceBlip] = []   # one per line, typed out in turn
var _typing_i := -1                 # the line being typed and how long ago it began: its Voice's glyph pulse
var _line_t := 0.0
var _prefix := RegEx.create_from_string("^(\\[[a-z]+\\]|[A-Za-zÁÉÍÓÚáéíóú]+:)\\s*")  # "[pallas] " or "Palas: "


func _ready() -> void:
	add_to_group("mission_plan")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	record = Campaign.record
	plan = Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), record.mission)
	_lines = _build_lines()
	for l: Array in _lines:
		# objectives and headings have no Voice: shown at once
		var voice := VoiceBlip.voice_of(l[1]) if l[0] == "voice" else ""
		_blips.append(VoiceBlip.new(_prefix.sub(tr(l[1]), "") if l[0] != "band" else "", voice))
	HudPalette.backdrop(self, Color(0.4, 0.4, 0.45), true)
	HudPalette.fade(self)
	if Campaign.gear.due:
		Campaign.gear.due = false
		if Campaign.gear.worth_opening() and not Campaign.done():
			open_requisition()


func open_requisition() -> void:
	var r := REQUISITION.new()
	r.name = "Requisition"
	add_child(r)


func _process(delta: float) -> void:
	if has_node("Requisition"):
		return  # the briefing types out once Requisition closes
	for i in _blips.size():
		var b := _blips[i]
		if not b.done():
			if i != _typing_i:
				_typing_i = i
				_line_t = 0.0
			elif not StoryMotion.still(self):
				_line_t += delta
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
		elif e is InputEventKey and e.keycode == KEY_R and not Campaign.done():
			open_requisition()
		elif Campaign.done():
			Campaign.start()
			get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
		else:
			_open_codec()


## The Mission's title card if it has one (black, so the Codec call follows without a flash of this page),
## then its full-screen Codec call, then the Mission itself.
func _open_codec() -> void:
	set_process_unhandled_input(false)
	var intro: Dictionary = Campaign.MISSIONS[record.mission].get("intro", {})
	if intro.is_empty():
		_call()
		return
	var card := MissionCard.build([intro.name, intro.area, intro.stamp], true, false)
	card.done.connect(_call)
	add_child(card)


func _call() -> void:
	var codec := CodecScreen.new(Campaign.MISSIONS[record.mission].codec)
	codec.finished.connect(func() -> void: Campaign.play(get_tree(), record, scene_file_path, true))
	add_child(codec)


func _build_lines() -> Array:
	if Campaign.done():
		var band := Aigis.resolve_ending(Aigis.lethality_ratio(record))
		return [["title", "ui.brief.complete"], ["gap", ""], ["head", "ui.brief.ending"], ["band", band]]
	var m: Dictionary = Campaign.MISSIONS[record.mission]
	var lines: Array = [["title", "ui.mission.%d" % record.mission], ["gap", ""], ["head", "ui.brief.title"]]
	lines.append_array(plan.briefing_keys.map(func(k: String) -> Array: return ["voice", k]))
	lines.append_array([["gap", ""], ["head", "ui.brief.objectives"]])
	lines.append_array(m.steps.map(func(s: Dictionary) -> Array: return ["objective", s.objective]))
	lines.append(["objective", Campaign.objective(record.mission, m.steps.size())])
	return lines


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(HudPalette.INK, 0.55))  # over the backdrop
	var y := 40.0
	var body_w := size.x - MARGIN * 2 - TAG
	for i in _lines.size():
		var kind: String = _lines[i][0]
		var s := _blips[i].shown()
		match kind:
			"title":
				draw_string(HudPalette.HEADING, Vector2(MARGIN, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.TITLE_SIZE, HudPalette.WHITE)
				y += 12
			"gap":
				y += 10
			"head":
				draw_string(HudPalette.HEADING, Vector2(MARGIN, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.HEADING_SIZE, HudPalette.CHROME_DIM)
				y += 16
			"band":  # the ending: its Voice, large
				draw_string(HudPalette.HEADING, Vector2(MARGIN, y + 8), "%s %s" % [GLYPHS[_lines[i][1]], tr("ui.voice." + _lines[i][1])],
					HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.TITLE_SIZE, HudPalette.AIGIS)
				y += 24
			"voice":
				var who := VoiceBlip.voice_of(_lines[i][1])
				var w := StoryMotion.draw_glyph(self, HudPalette.HEADING, Vector2(MARGIN, y - 2), GLYPHS[who], _line_t if i == _typing_i and not _blips[i].done() else 99.0, HudPalette.AIGIS, HudPalette.HEADING_SIZE)
				draw_string(HudPalette.HEADING, Vector2(MARGIN + w + 8, y - 2), tr("ui.voice." + who), HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.HEADING_SIZE, HudPalette.AIGIS)
				var full := HudPalette.wrap(_prefix.sub(tr(_lines[i][1]), ""), body_w)
				var left := s.length()
				for l in full:
					draw_string(HudPalette.BODY, Vector2(MARGIN + TAG, y), l.left(maxi(left, 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.BODY_SIZE, HudPalette.WHITE)
					left -= l.length() + 1
					y += 14
			"objective":
				for l in HudPalette.wrap("- " + s, size.x - MARGIN * 2, HudPalette.HEADING, HudPalette.HEADING_SIZE):
					draw_string(HudPalette.HEADING, Vector2(MARGIN, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.HEADING_SIZE, HudPalette.CHROME)
					y += 12
	var foot := tr("ui.brief.any_key") if Campaign.done() else "%s   [R] %s" % [tr("ui.brief.any_key"), tr("ui.brief.requisition")]  # R is the briefing's own key
	draw_string(HudPalette.HEADING, Vector2(MARGIN, size.y - 24), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.HEADING_SIZE, HudPalette.HINT)
