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
const MARGIN_X := 96.0    # px: the page's side margin (design px, 1080 tall)
const TAG := 200          # px from a Voice line's head to its text: room for "() GLAUKOPIS"
const LEFT_W := 600.0     # px: the objectives column
const GUTTER := 70.0      # px between the columns
const CARD_GAP := 36.0    # px between the Habit cards
const FS := 40            # px: the page's reading size (Aigis's comment)
const ROW := 54           # px between its rows
const OBJ_FS := 38        # px: an objective, and the lines that close the page
const OBJ_ROW := 48
const CARD_FS := 34       # px: a Habit card's hint; its evidence is EVID_FS
const CARD_ROW := 46
const EVID_FS := 30
const EVID_ROW := 40

var record: Dictionary
var plan: Dictionary
var _lines: Array = []               # [kind, key or text]: "title", "head", "voice", "band", "objective", "gap"
var _blips: Array[VoiceBlip] = []   # one per line, typed out in turn
var _typing_i := -1                 # the line being typed and how long ago it began: its Voice's glyph pulse
var _line_t := 0.0
var _skip := false                  # the first Mission: straight to its Codec call
var _fit := 1.0                     # < 1 when the lines run past the "any key" row: the page draws smaller to fit
var _prefix := RegEx.create_from_string("^(\\[[a-z]+\\]|[A-Za-zÁÉÍÓÚáéíóú]+:)\\s*")  # "[pallas] " or "Palas: "


func _exit_tree() -> void:
	Mixer.screen_off(&"interlude")


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
	Mixer.screen(&"interlude")
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
	if e.is_pressed() and not e.is_echo() and e is InputEventKey:
		get_viewport().set_input_as_handled()
		_press(e)


## A click arrives here, not in _unhandled_input: a full-rect Control takes the mouse in the GUI step first.
func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		accept_event()
		_press(e)


func _press(e: InputEvent) -> void:
	if _skip or not is_processing_unhandled_input():  # the first Mission has no page; once the call is open the page is done
		return
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
	var said_by := ""  # Aigis Voice opens with its comment on the last Mission: its lines run together as one paragraph
	var said_text := PackedStringArray()
	for said: Array in AigisVoice.briefing_lines(record, TranslationServer.get_locale().left(2)):
		said_by = said[0]
		said_text.append(said[1])
	if not said_text.is_empty():
		lines.append(["voice", "brief.%s.said" % said_by, " ".join(said_text)])  # not a text key: the key only names the Voice (VoiceBlip.voice_of)
	var keys: Array = plan.briefing_keys.filter(func(k: String) -> bool: return ".habit." in k or ".hint." in k)  # the Habit cards and their answers: the asides, the close, the shift and the callsign are cut
	for extra: Array in _file_lines():  # then the one line on what to do next: the forecast
		keys.append(extra)
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


## The Dossier's one line on the page, as [key, args]: the Dominant Voice's forecast for this Mission. Where the
## Operative did most and how the last forecast went are on the post-Mission screens; the page holds what to do next.
func _file_lines() -> Array:
	var next := Dossier.bet(record)
	return [] if next.is_empty() else [["brief.%s.bet" % plan.dominant, {bet = Dossier.bet_text(next)}]]


## A plan key (or [key, format args]) as a line. A Habit row cites what Aigis counted (Dossier.evidence) when
## the record says enough.
func _line(entry: Variant) -> Array:
	if entry is Array:
		return ["voice", entry[0], tr(entry[0]).format(entry[1])]
	var key: String = entry
	if not key.begins_with("brief.pallas.habit."):
		return ["hint" if ".hint." in key else "voice", key]
	return ["habit", key, tr("ui.habit." + key.get_slice(".", 3))]  # a card: the Habit's name and levels, then (the "hint" line) the sponsor's answer


func _draw() -> void:
	var k := size.y / HudPalette.DESIGN_H * _fit
	var d := size / k
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	if _skip:
		draw_rect(Rect2(Vector2.ZERO, d), HudPalette.INK)
		return
	draw_rect(Rect2(Vector2.ZERO, d), Color(HudPalette.INK, 0.55))  # over the backdrop
	var y := 110.0
	var x := MARGIN_X
	var disp := HudPalette.DISPLAY
	var col_r := x + LEFT_W + GUTTER  # two columns under the title: the Mission's own facts and objectives stay put on the left,
	var rw := d.x - col_r - x           # and Aigis, across the wide right one, types out what it noticed
	var card_w := (rw - CARD_GAP) / 2.0
	var card_h := _card_h(card_w)
	var head_y := 0.0
	var yl := 0.0           # the left column's cursor
	var card := -1          # the Habit card being drawn, and where the row of cards starts
	var cards_y := 0.0
	var obj_n := 0
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
				y += 34
			"head":
				var on_left: bool = _lines[i][1] == "ui.brief.objectives"
				var hx := x if on_left else col_r
				if on_left:
					yl = head_y + 84
				else:
					head_y = y
					y += 84
				var hs: String = _lines[i][2] if on_left else s
				HudPalette.hud_text(self, Vector2(hx, head_y), hs.to_upper(), 30, HudPalette.LIGHT_2, HudPalette.tracked(disp, 30, 0.26), 0, false)
				draw_rect(Rect2(hx, head_y + 18, LEFT_W if on_left else rw, 2), Color(HudPalette.LIGHT, 0.5))
			"band":  # the ending: its Voice, large
				HudPalette.hud_text(self, Vector2(x, y + 20), "%s %s" % [GLYPHS[_lines[i][1]], tr("ui.voice." + _lines[i][1]).to_upper()], 64, HudPalette.CYAN, HudPalette.tracked(disp, 64, 0.1), 0, false)
				y += 80
			"habit":  # a card: glyph, name and levels, then what Aigis counted
				card += 1
				if card == 0:
					cards_y = y
				if s != "":
					_card(Vector2(col_r + card * (card_w + CARD_GAP), cards_y), card_w, card_h, i)
				if card == 1:
					y = cards_y + card_h + 56
			"hint":  # the sponsoring Voice's answer, closing its card
				var hx := col_r + maxi(card, 0) * (card_w + CARD_GAP)
				var rows := HudPalette.wrap(_prefix.sub(_lines[i][2], ""), card_w - 56, HudPalette.FIGURE_MED, CARD_FS)
				if s != "":
					var base := cards_y + 100.0 + _ev_rows(i - 1, card_w) * EVID_ROW + 62.0
					_voice_head(Vector2(hx + 28, base), VoiceBlip.voice_of(_lines[i][1]), i, k, 28)
					var left := s.length()
					for j in rows.size():
						HudPalette.hud_text(self, Vector2(hx + 28, base + 50 + j * CARD_ROW), rows[j].left(maxi(left, 0)), CARD_FS, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
						left -= rows[j].length() + 1
				if card == 0 and not _lines.slice(i + 1).any(func(l: Array) -> bool: return l[0] == "habit"):
					y = cards_y + card_h + 56  # a lone card: the row is done
			"voice":
				var big := card < 0  # Aigis's comment above the cards reads large; the lines that close the page a step down
				var vfs := FS if big else OBJ_FS
				var vrow := ROW if big else OBJ_ROW - 4
				var full := HudPalette.wrap(_prefix.sub(_lines[i][2], ""), rw - TAG, HudPalette.FIGURE_MED, vfs)
				_voice_head(Vector2(col_r, y), VoiceBlip.voice_of(_lines[i][1]), i, k, 32 if big else 28)
				var left := s.length()
				for l in full:
					HudPalette.hud_text(self, Vector2(col_r + TAG, y), l.left(maxi(left, 0)), vfs, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
					left -= l.length() + 1
					y += vrow
				y += 28 if big else 14
			"objective":  # a sand step number, then the objective in Barlow
				obj_n += 1
				HudPalette.hud_text(self, Vector2(x, yl), "%02d" % obj_n, 36, HudPalette.SAND, HudPalette.tracked(disp, 36, 0.08), 0, false)
				for l in HudPalette.wrap(_lines[i][2], LEFT_W - 72.0, HudPalette.FIGURE_MED, OBJ_FS):  # the Mission's asks are on the page at once: only Aigis types
					HudPalette.hud_text(self, Vector2(x + 72, yl), l, OBJ_FS, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
					yl += OBJ_ROW
				yl += 16
	if yl > 0.0 and not Campaign.done():
		yl = _mission_facts(Vector2(x, yl + 12))
	y = maxf(y, yl)  # the page is as tall as its taller column
	var over := (y + 30.0) / (d.y - 110.0)  # the layout never changes while lines type: this settles in a frame or two
	if over > 1.001 or (over < 0.92 and _fit < 1.0):  # too tall: draw smaller; room to spare after an early frame shrank it: grow back
		_fit = minf(_fit / over, 1.0)
		queue_redraw()
	var af := HudPalette.tracked(disp, 26, 0.24)
	var ak := tr("ui.brief.any_key").to_upper()
	HudPalette.hud_text(self, Vector2(x, d.y - 60), ak, 26, HudPalette.LIGHT_2, af, 0, false)
	if not Campaign.done():  # R is the briefing's own key
		var rx := x + af.get_string_size(ak, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 56
		var kw := HudPalette.keycap(self, Vector2(rx, d.y - 86), "R", true)
		HudPalette.hud_text(self, Vector2(rx + kw + 14, d.y - 60), tr("ui.brief.requisition").to_upper(), 26, HudPalette.LIGHT_2, af, 0, false)


## How many rows a Habit card's evidence takes (the "habit" line at `i`, 0 when it has none).
func _ev_rows(i: int, card_w: float) -> int:
	var ev: String = _lines[i][3] if i >= 0 and _lines[i].size() > 3 else ""
	return 0 if ev == "" else HudPalette.wrap(ev, card_w - 56, HudPalette.FIGURE_MED, EVID_FS).size()


## The Habit cards' common height: the name block, the longest evidence, then the answer's head and its longest text.
func _card_h(card_w: float) -> float:
	var ev := 0
	var ans := 1
	for i in _lines.size():
		if _lines[i][0] == "habit":
			ev = maxi(ev, _ev_rows(i, card_w))
		elif _lines[i][0] == "hint":
			ans = maxi(ans, HudPalette.wrap(_prefix.sub(_lines[i][2], ""), card_w - 56, HudPalette.FIGURE_MED, CARD_FS).size())
	return 100.0 + ev * EVID_ROW + 62.0 + 50.0 + (ans - 1) * CARD_ROW + 36.0


## A Habit's card at `at`: a glass plate, its glyph, name and levels deployed, then what Aigis counted.
func _card(at: Vector2, w: float, h: float, i: int) -> void:
	var hab: String = String(_lines[i][1]).get_slice(".", 3)
	PixelKit.cut_fill(self, Rect2(at, Vector2(w, h)), Color(HudPalette.GLASS, 0.85), 5)
	PixelKit.frame(self, Rect2(at, Vector2(w, h)), Color(HudPalette.CYAN, 0.35), 5)
	PixelKit.cut_fill(self, Rect2(at, Vector2(w, 6)), HudPalette.CYAN, 0)
	HabitGlyphs.draw(self, hab, at + Vector2(28, 14), HudPalette.CYAN, 5.0)
	HudPalette.hud_text(self, at + Vector2(100, 60), _lines[i][2].to_upper(), 50, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 50, 0.06), 0, false)
	var lvl := int(plan.deployed.get(hab, 0))
	for p in 3:
		draw_rect(Rect2(at.x + 100 + p * 36, at.y + 76, 30, 10), HudPalette.SAND if p < lvl else Color(HudPalette.LIGHT, 0.2))
	HudPalette.hud_text(self, at + Vector2(100 + 3 * 36 + 18, 88), tr("ui.brief.level").format({n = lvl}).to_upper(), 24, HudPalette.LIGHT_2, HudPalette.tracked(HudPalette.LABEL, 24, 0.2), 0, false)
	var rows := HudPalette.wrap(_lines[i][3] if _lines[i].size() > 3 else "", w - 56, HudPalette.FIGURE_MED, EVID_FS)
	for j in rows.size():
		HudPalette.hud_text(self, at + Vector2(28, 138 + j * EVID_ROW), rows[j], EVID_FS, HudPalette.LIGHT_2, HudPalette.FIGURE_MED, 0, false)


## The Mission's own facts under its objectives (Area, Target, Encounters, par); returns where they end.
func _mission_facts(at: Vector2) -> float:
	var m: Dictionary = Campaign.MISSIONS[record.mission]
	var rows: Array = []
	if not m.targets.is_empty():
		rows.append(["ui.brief.target", ", ".join(m.targets)])
	var par := int(Rank.par(record.mission))
	@warning_ignore("integer_division")
	rows.append(["ui.brief.par", "%d:%02d" % [par / 60, par % 60]])
	var f := HudPalette.tracked(HudPalette.LABEL, 26, 0.22)
	HudPalette.hud_text(self, at, tr("ui.brief.mission").to_upper(), 30, HudPalette.LIGHT_2, HudPalette.tracked(HudPalette.DISPLAY, 30, 0.26), 0, false)
	draw_rect(Rect2(at.x, at.y + 18, LEFT_W, 2), Color(HudPalette.LIGHT, 0.5))
	var y := at.y + 64
	for row: Array in rows:
		HudPalette.hud_text(self, Vector2(at.x, y), tr(row[0]).to_upper(), 26, HudPalette.LIGHT_3, f, 0, false)
		HudPalette.hud_text(self, Vector2(at.x + 200, y), row[1], 30, HudPalette.LIGHT, HudPalette.FIGURE, 0, false)
		y += 46
	return y


## A Voice's mark, then its name, both in Aigis cyan; the mark pulses while its line types. No frame: a box round
## "[]" or "()" reads as a missing glyph.
func _voice_head(at: Vector2, who: String, i: int, k: float, fs := 30) -> void:
	var disp := HudPalette.DISPLAY
	var glyph: String = GLYPHS[who]
	var gf := HudPalette.tracked(disp, fs, 0.0)
	var w := gf.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pk := StoryMotion.pulse(_line_t if i == _typing_i and not _blips[i].done() else 99.0)
	draw_set_transform((Vector2(at.x, at.y - 2) + Vector2(w / 2, -fs * 0.43)) * k, 0.0, Vector2(k, k) * pk)
	var gp := Vector2(-w / 2, fs * 0.43)
	draw_string_outline(gf, gp, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, HudPalette.CYAN)  # a stroke round it: the glyph reads bold
	draw_string(gf, gp, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, HudPalette.CYAN)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	HudPalette.hud_text(self, Vector2(at.x + w + 16, at.y - 2), tr("ui.voice." + who).to_upper(), fs, HudPalette.CYAN, HudPalette.tracked(disp, fs, 0.2), 0, false)
