## The Briefing: the next campaign Mission's title, Aigis's Voices on what it noticed and what it deployed
## (a transcript: the Voice's glyph and name in Aigis's cyan, then its line in Barlow, typed out with its
## beeps), then the objectives; any key opens the Mission's Codec call, which starts it. Past the Core it
## shows the ending's band, and any key goes back to the main scene. Group "mission_plan": F3 shows the
## plan table. After a first clear with something to buy the Requisition screen opens over it first;
## R reopens it. The first Mission has no Briefing (Aigis has seen nothing yet): the page stays black and its
## Codec call opens at once.
extends Control

const REQUISITION := preload("res://ui/requisition/requisition.gd")
const GLYPHS: Dictionary = preload("res://ui/finale/finale.gd").GLYPHS
const TAG := 112  # px from the margin to a Voice line's text: room for "() GLAUKOPIS"
const MARGIN := 24
const RIGHT_COL := 560.0  # px from the margin to a Habit row text column
const OBJ_INDENT := 56.0  # px from the margin to an objective's text, past its number

var record: Dictionary
var plan: Dictionary
var _lines: Array = []               # [kind, key or text]: "title", "head", "voice", "band", "objective", "gap"
var _blips: Array[VoiceBlip] = []   # one per line, typed out in turn
var _typing_i := -1                 # the line being typed and how long ago it began: its Voice's glyph pulse
var _line_t := 0.0
var _skip := false                  # the first Mission: straight to its Codec call
var _fit := 1.0                     # < 1 when the lines run past the "any key" row: the page draws smaller to fit
var _prefix := RegEx.create_from_string("^(\\[[a-z]+\\]|[A-Za-zÁÉÍÓÚáéíóú]+:)\\s*")  # "[pallas] " or "Palas: "


func _ready() -> void:
	add_to_group("mission_plan")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	record = Campaign.record
	if record.mission == 0:
		_skip = true
		HudPalette.fade(self)
		_open_codec.call_deferred()
		return
	plan = Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), record.mission)
	_lines = _build_lines().map(func(l: Array) -> Array: return l if l.size() > 2 else l + [tr(l[1])])  # [kind, key, text]
	for l: Array in _lines:
		# objectives and headings have no Voice: shown at once
		var voice := VoiceBlip.voice_of(l[1]) if l[0] in ["voice", "habit", "hint"] else ""
		_blips.append(VoiceBlip.new(_prefix.sub(l[2], "") if l[0] != "band" else "", voice))
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
	if _skip:
		return
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
			UiTransition.go(get_tree(), ProjectSettings.get_setting("application/run/main_scene"))
		else:
			_open_codec()


## The Mission's title card if it has one (black, so the Codec call follows without a flash of this page),
## then its full-screen Codec call, then the Mission itself. A Mission whose intro is a take has no card here:
## the take plays once the Area has loaded, after the call.
func _open_codec() -> void:
	set_process_unhandled_input(false)
	var intro: Dictionary = Campaign.MISSIONS[record.mission].get("intro", {})
	if intro.is_empty() or Campaign.cine_of(record.mission).has("intro"):
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
	lines.append(["gap", ""])
	var keys: Array = plan.briefing_keys.duplicate()
	var shift: String = record.get("last", {}).get("shifted", "")
	if shift != "":  # Aigis saw the Operative drop a Habit: said after the rows, before the close
		keys.insert(keys.size() - 1, "brief.pallas.shift." + shift)
	if plan.get("dissent", "") != "":  # a close call: the outvoted sponsor objects last
		keys.insert(keys.size() - 1, plan.dissent)
	var named := _callsign_line()
	if not named.is_empty():
		keys.push_front(named)
	for extra: Array in _file_lines():  # where, what it bet and how that went, the next bet: before the close
		keys.insert(keys.size() - 1, extra)
	for key: Variant in keys:  # a Habit's row is Pallas naming it ("habit"), then its sponsor's line ("hint")
		lines.append(_line(key))
	lines.append_array([["gap", ""], ["head", "ui.brief.objectives"]])
	lines.append_array(m.steps.map(func(s: Dictionary) -> Array: return ["objective", s.objective]))
	lines.append(["objective", Campaign.objective(record.mission, m.steps.size())])
	return lines


## Pallas names the file: the callsign Aigis has for the Operative ([key, args]), saying so when it changed
## since the last Briefing. [] while nothing stands out.
func _callsign_line() -> Array:
	var now := Dossier.callsign(record)
	if now == "callsign.none":
		return []
	var was: String = record.get("last", {}).get("called", "")
	if was != "" and was != now and was != "callsign.none":
		return ["brief.pallas.callsign.renamed", {was = tr(was), name = tr(now)}]
	return ["brief.pallas.callsign", {name = tr(now)}]


## The Dossier's other lines, as [key, args]: where the Operative did most last time (Pallas), the Dominant
## Voice on its last forecast (won or lost), then its forecast for this Mission.
func _file_lines() -> Array:
	var out := []
	var last: Dictionary = record.get("last", {})
	var hot: Dictionary = last.get("hot", {})
	if not hot.is_empty():
		var place := tr("place.%d.%d" % [last.mission, hot.enc])
		var mins := roundi(hot.secs / 60.0)
		out.append(["brief.pallas.hot.m", {place = place, n = hot.n, m = mins}] if hot.secs >= 120 else ["brief.pallas.hot.s", {place = place, n = hot.n, s = maxi(hot.secs, 1)}])
	var bet: Dictionary = last.get("bet", {})
	if not bet.is_empty():
		out.append(["brief.%s.bet.%s" % [plan.dominant, "won" if bet.won else "lost"], {bet = Dossier.bet_text(bet), got = bet.got}])
	var next := Dossier.bet(record)
	if not next.is_empty():
		out.append(["brief.%s.bet" % plan.dominant, {bet = Dossier.bet_text(next)}])
	return out


## A plan key (or [key, format args]) as a line. A Habit row cites what Aigis counted (Dossier.evidence) when
## the record says enough.
func _line(entry: Variant) -> Array:
	if entry is Array:
		return ["voice", entry[0], tr(entry[0]).format(entry[1])]
	var key: String = entry
	if not key.begins_with("brief.pallas.habit."):
		return ["hint" if ".hint." in key else "voice", key]
	var ev := Dossier.evidence(record, key.get_slice(".", 3))
	return ["habit", key, tr(ev[0]).format(ev[1]) if not ev.is_empty() else tr(key)]


func _draw() -> void:
	var k := size.y / HudPalette.DESIGN_H * _fit
	var d := size / k
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	if _skip:
		draw_rect(Rect2(Vector2.ZERO, d), HudPalette.INK)
		return
	draw_rect(Rect2(Vector2.ZERO, d), Color(HudPalette.INK, 0.55))  # over the backdrop
	var y := 110.0
	var x := 110.0
	var body_w := minf(d.x - x * 2 - TAG, 1300.0)
	var disp := HudPalette.DISPLAY
	var obj_n := 0  # objectives are numbered, in the order the Mission asks for them
	for i in _lines.size():
		var kind: String = _lines[i][0]
		var s := _blips[i].shown()
		match kind:
			"title":
				var f := HudPalette.tracked(disp, 64, 0.12)
				var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x + 56
				PixelKit.stair_fill(self, Rect2(0, y - 70, x - 40 + w, 90), HudPalette.LIGHT, 22.0)
				HudPalette.hud_text(self, Vector2(x - 40, y), s, 64, HudPalette.DARK_INK, f, 0, false)  # the title sits left of the body column
				y += 84
			"gap":
				y += 40
			"head":
				HudPalette.hud_text(self, Vector2(x, y), s.to_upper(), 24, HudPalette.LIGHT_2, HudPalette.tracked(disp, 24, 0.26), 0, false)
				draw_rect(Rect2(x, y + 16, 400, 2), Color(HudPalette.LIGHT, 0.5))
				y += 76
			"band":  # the ending: its Voice, large
				HudPalette.hud_text(self, Vector2(x, y + 20), "%s %s" % [GLYPHS[_lines[i][1]], tr("ui.voice." + _lines[i][1]).to_upper()], 64, HudPalette.CYAN, HudPalette.tracked(disp, 64, 0.1), 0, false)
				y += 80
			"habit":  # the Habit Aigis noticed: glyph, name and levels deployed on the left, Pallas's line beside them
				if s != "":
					var h: String = String(_lines[i][1]).get_slice(".", 3)
					HabitGlyphs.draw(self, h, Vector2(x, y - 22), HudPalette.CYAN, 4.0)
					HudPalette.hud_text(self, Vector2(x + 62, y + 10), tr("ui.habit." + h).to_upper(), 40, HudPalette.LIGHT, HudPalette.tracked(disp, 40, 0.06), 0, false)
					for p in 3:
						draw_rect(Rect2(x + 62 + p * 30, y + 22, 25, 8), HudPalette.SAND if p < int(plan.deployed.get(h, 0)) else Color(HudPalette.LIGHT, 0.2))
					HudPalette.hud_text(self, Vector2(x + RIGHT_COL, y), s, 24, HudPalette.LIGHT_2, HudPalette.FIGURE_MED, 0, false)
			"hint":  # what that Habit now meets: the sponsoring Voice and its line, closing the row
				var who := VoiceBlip.voice_of(_lines[i][1])
				var rows := HudPalette.wrap(_prefix.sub(_lines[i][2], ""), d.x - x * 2 - RIGHT_COL, HudPalette.FIGURE_MED, 34)
				if s != "":
					_voice_head(Vector2(x + RIGHT_COL, y + 50), who, i, k)
					var left := s.length()
					for j in rows.size():
						HudPalette.hud_text(self, Vector2(x + RIGHT_COL, y + 100 + j * 46), rows[j].left(maxi(left, 0)), 34, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
						left -= rows[j].length() + 1
				y += 100 + rows.size() * 46 - 12
				draw_rect(Rect2(x, y + 8, d.x - x * 2, 1), Color(HudPalette.LIGHT, 0.14))
				y += 52
			"voice":
				var who := VoiceBlip.voice_of(_lines[i][1])
				_voice_head(Vector2(x, y), who, i, k)
				var full := HudPalette.wrap(_prefix.sub(_lines[i][2], ""), body_w, HudPalette.FIGURE_MED, 28)
				var left := s.length()
				for l in full:
					HudPalette.hud_text(self, Vector2(x + TAG + 90, y), l.left(maxi(left, 0)), 28, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
					left -= l.length() + 1
					y += 42
				y += 38
			"objective":  # a sand step number, then the objective in Barlow
				obj_n += 1
				HudPalette.hud_text(self, Vector2(x, y), "%02d" % obj_n, 24, HudPalette.SAND, HudPalette.tracked(disp, 24, 0.08), 0, false)
				for l in HudPalette.wrap(s, d.x - x * 2 - OBJ_INDENT, HudPalette.FIGURE_MED, 28):
					HudPalette.hud_text(self, Vector2(x + OBJ_INDENT, y), l, 28, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
					y += 42
				y += 20
	var over := (y + 30.0) / (d.y - 110.0)  # the layout never changes while lines type: this settles in a frame or two
	if over > 1.001:
		_fit /= over
		queue_redraw()
	var af := HudPalette.tracked(disp, 22, 0.24)
	var ak := tr("ui.brief.any_key").to_upper()
	HudPalette.hud_text(self, Vector2(x, d.y - 60), ak, 22, HudPalette.LIGHT_2, af, 0, false)
	if not Campaign.done():  # R is the briefing's own key
		var rx := x + af.get_string_size(ak, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 56
		var kw := HudPalette.keycap(self, Vector2(rx, d.y - 86), "R", true)
		HudPalette.hud_text(self, Vector2(rx + kw + 14, d.y - 60), tr("ui.brief.requisition").to_upper(), 22, HudPalette.LIGHT_2, af, 0, false)


## A Voice's mark, then its name, both in Aigis cyan; the mark pulses while its line types. No frame: a box round
## "[]" or "()" reads as a missing glyph.
func _voice_head(at: Vector2, who: String, i: int, k: float) -> void:
	var disp := HudPalette.DISPLAY
	var glyph: String = GLYPHS[who]
	var gf := HudPalette.tracked(disp, 26, 0.0)
	var w := gf.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	var pk := StoryMotion.pulse(_line_t if i == _typing_i and not _blips[i].done() else 99.0)
	draw_set_transform((Vector2(at.x, at.y - 2) + Vector2(w / 2, -13)) * k, 0.0, Vector2(k, k) * pk)
	draw_string(gf, Vector2(-w / 2, 13), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, HudPalette.CYAN)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	HudPalette.hud_text(self, Vector2(at.x + w + 14, at.y - 2), tr("ui.voice." + who).to_upper(), 26, HudPalette.CYAN, HudPalette.tracked(disp, 26, 0.2), 0, false)
