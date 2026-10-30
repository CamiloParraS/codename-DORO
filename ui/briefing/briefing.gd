## The Briefing: the next campaign Mission's title, Aigis's Voices on what it noticed and what it deployed
## (a transcript: the Voice's glyph and name in Aigis's cyan, then its line in Barlow, typed out with its
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
	var scan := UiScan.make(HudPalette.BACKDROP, true, true, HudPalette.BACKDROP_DIM)
	scan.show_behind_parent = true  # under the page's own drawing
	add_child(scan)
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
	var codec := CodecScreen.new(Campaign.MISSIONS[record.mission].codec, true)
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
	var k := size.y / HudPalette.DESIGN_H
	var d := size / k
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	draw_rect(Rect2(Vector2.ZERO, d), Color(HudPalette.INK, 0.55))  # over the backdrop
	var y := 110.0
	var x := 110.0
	var body_w := minf(d.x - x * 2 - TAG, 1300.0)
	var disp := HudPalette.DISPLAY
	for i in _lines.size():
		var kind: String = _lines[i][0]
		var s := _blips[i].shown()
		match kind:
			"title":
				var f := HudPalette.tracked(disp, 64, 0.12)
				var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x + 56
				draw_colored_polygon(PackedVector2Array([Vector2(0, y - 70), Vector2(x - 40 + w, y - 70), Vector2(x - 40 + w - 22, y + 20), Vector2(0, y + 20)]), HudPalette.LIGHT)
				HudPalette.hud_text(self, Vector2(x, y), s, 64, HudPalette.DARK_INK, f, 0, false)
				y += 70
			"gap":
				y += 24
			"head":
				HudPalette.hud_text(self, Vector2(x, y), s.to_upper(), 24, HudPalette.LIGHT_2, HudPalette.tracked(disp, 24, 0.26), 0, false)
				draw_rect(Rect2(x, y + 12, 400, 2), Color(HudPalette.LIGHT, 0.5))
				y += 52
			"band":  # the ending: its Voice, large
				HudPalette.hud_text(self, Vector2(x, y + 20), "%s %s" % [GLYPHS[_lines[i][1]], tr("ui.voice." + _lines[i][1]).to_upper()], 64, HudPalette.CYAN, HudPalette.tracked(disp, 64, 0.1), 0, false)
				y += 80
			"voice":
				var who := VoiceBlip.voice_of(_lines[i][1])
				var glyph: String = GLYPHS[who]
				var gf := HudPalette.tracked(disp, 26, 0.0)
				var w := gf.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
				var pk := StoryMotion.pulse(_line_t if i == _typing_i and not _blips[i].done() else 99.0)
				draw_set_transform((Vector2(x, y - 2) + Vector2(w / 2, -13)) * k, 0.0, Vector2(k, k) * pk)  # the glyph's pulse
				draw_string(gf, Vector2(-w / 2, 13), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, HudPalette.CYAN)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
				HudPalette.hud_text(self, Vector2(x + w + 10, y - 2), tr("ui.voice." + who).to_upper(), 26, HudPalette.CYAN, HudPalette.tracked(disp, 26, 0.2), 0, false)
				var full := HudPalette.wrap(_prefix.sub(tr(_lines[i][1]), ""), body_w, HudPalette.FIGURE_MED, 28)
				var left := s.length()
				for l in full:
					HudPalette.hud_text(self, Vector2(x + TAG + 90, y), l.left(maxi(left, 0)), 28, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
					left -= l.length() + 1
					y += 38
				y += 14
			"objective":
				for l in HudPalette.wrap("- " + s, d.x - x * 2, HudPalette.FIGURE_MED, 28):
					HudPalette.hud_text(self, Vector2(x, y), l, 28, HudPalette.LIGHT_2, HudPalette.FIGURE_MED, 0, false)
					y += 38
	var foot := tr("ui.brief.any_key") if Campaign.done() else "%s   [R] %s" % [tr("ui.brief.any_key"), tr("ui.brief.requisition")]  # R is the briefing's own key
	HudPalette.hud_text(self, Vector2(x, d.y - 60), foot.to_upper(), 22, HudPalette.LIGHT_3, HudPalette.tracked(disp, 22, 0.24), 0, false)
