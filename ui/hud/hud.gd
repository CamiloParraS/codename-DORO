## The in-game HUD (docs/DESIGN.md), drawn by hand on `_canvas` in design px: 1080 tall, as wide as the window's
## aspect, scaled to the window and smoothly filtered. Corners: Aigis top-left, the phase plate top-centre, the
## Radar top-right with the objective under it, Voiceprints under the Aigis cue, life bottom-left, item and weapon cards bottom-right (the selector opens beside them when
## either changes), the live call and radio lines middle-left, and the text-free action prompt lower-middle.
## Only the crosshair stays on the 640x360 logical canvas, so its
## pixel art keeps its grid. Lives on CanvasLayer 1, above the banding pass (layer -1).
extends "res://ui/hud/hud_corners.gd"

const CALL_IN_SECS := 0.28   # the live call card slides in from the left and fades up
const CALL_OUT_SECS := 0.2   # and slides back out, faster, when the call ends
const CALL_SLIDE := 48.0     # design px of travel
const CROSSHAIR_PX := 30.0  # logical px a side; the textures are 48, so this shrinks them to 5/8

var _objective := HudObjective.new()  # the objective line and the CHECKPOINT card, top-centre


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("radio_log")
	add_to_group("codec_live")
	add_to_group("tutorial_tip")
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_canvas.draw.connect(_draw_design)
	add_child(_canvas)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://ui/hud/portrait.gdshader")
	_face.material = m
	_face.visible = false
	_canvas.add_child(_face)


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	_phase_age += delta
	_cue_age = _cue_age + delta if _aigis > 0.0 else 0.0
	_prompt_age = _prompt_age + delta if _operative and not _operative.prompt_parts.is_empty() else 0.0
	_tick_age += delta
	_select_left = maxf(_select_left - delta, 0.0)
	_select_age += delta / maxf(Engine.time_scale, 0.05)
	_read_run()
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	if _objective.update(delta, run, run.lesson if run else ""):
		Mixer.play(&"checkpoint")
	if _operative and _operative.aiming:
		_crosshair(_operative.gun().crosshair)  # loaded here: a texture first loaded inside _draw draws white (Godot 4.7)
	_subs.tick(delta)
	_tip_left = maxf(_tip_left - delta, 0.0)
	if _live and _call_out < 0.0:
		_call_age += delta
		var p := _live.advance(delta, true)
		if not p.is_empty():
			Mixer.blip(p.back())
		if _live.done():
			_live.index = _live.lines.size() - 1  # the last line stays drawn while the card slides out
			_call_out = 0.0
	elif _live:
		_call_out += delta
		if _call_out >= CALL_OUT_SECS:
			_live = null
			_call_out = -1.0
	for g in get_tree().get_nodes_in_group("guards"):
		var now: bool = g.alert.state == GuardAlert.State.ALERT
		if now and not _was_alert.get(g, false):
			_flash = 1.0
		_was_alert[g] = now
	if not _operative:
		_operative = get_tree().get_first_node_in_group("operative")
	else:
		_track_lost(_operative.health.life(), delta)
		_track_selection()
	queue_redraw()
	_canvas.queue_redraw()


## The crosshair only, CROSSHAIR_PX square (the art is 48): pixel art on the logical canvas. Shots leave from it, and it wanders a little with the sway.
func _draw() -> void:
	if _operative and _operative.aiming:
		var tex := _crosshair(_operative.gun().crosshair)
		var wander := Locomotion.drift_px(_operative.aim_drift(), _operative.camera.fov, size.y)
		var side := CROSSHAIR_PX
		draw_texture_rect(tex, Rect2((size / 2 + wander - Vector2(side, side) / 2).round(), Vector2(side, side)), false)


## Radio line from a guard (call_group "radio_log").
func say(who: String, text: String) -> void:
	_subs.add(who, text)


## Mission 1's tutorial prompt (call_group "tutorial_tip"): `text` its steps, `title` the verb on its sand slab.
func tip(text: String, title := "") -> void:
	_tip = text
	_tip_title = title
	_tip_left = TIP_TIME


## The tip on screen was done (call_group "tutorial_tip"): it fades out over TIP_OUT.
func tip_done() -> void:
	_tip_left = minf(_tip_left, TIP_OUT)


## A live Codec call (call_group "codec_live"): play goes on while it runs.
func live_call(lines: Array) -> void:
	_live = CodecCall.new(lines)
	_call_age = 0.0
	_call_out = -1.0


func _read_run() -> void:
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	if not run:
		_aigis = 0.0
		return
	_aigis = HudModel.aigis_weight(run.record.mission, Aigis.lethality_ratio(run.record))
	_voice = str(run.plan.get("dominant", "")).to_upper()
	for h: String in Aigis.HABITS:
		_levels[h] = Aigis.level(int(run.record.points.get(h, 0)), run.record.mission)
	var risen := HudModel.habits_risen(_prev_counts, run.tally.counts) if _run_seen else []
	_run_seen = true
	_prev_counts = run.tally.counts.duplicate()
	if _aigis > 0.0 and not risen.is_empty():
		_tick = str(risen[0])
		_tick_age = 0.0


## The red lost segment follows life down after a short hold, and snaps up on a heal.
func _track_lost(now: float, delta: float) -> void:
	if now >= _lost:
		_lost = now
		_lost_hold = LOST_HOLD
	elif _lost_hold > 0.0:
		_lost_hold -= delta
	else:
		_lost = move_toward(_lost, now, LOST_DRAIN * delta)


## Opens the selector when the weapon in hand or the selected item changes (not on the first read).
func _track_selection() -> void:
	var g: Gun = _operative.gun()
	var it: int = _operative.items.selected
	var changed := ""
	if _last_gun and g != _last_gun:
		changed = "weapon"
	elif _last_item >= 0 and it != _last_item:
		changed = "item"
	if changed != "":
		if _select_left <= 0.0 or _select != changed:
			_select_age = 0.0  # a fresh opening wipes in; a change while open just moves the highlight
		_select = changed
		_select_left = SELECT_TIME
		Mixer.play(&"tick")
	_last_gun = g
	_last_item = it


func _crosshair(file: String) -> Texture2D:
	if not _crosshairs.has(file):
		_crosshairs[file] = load("res://assets/textures/%s.png" % file)
	return _crosshairs[file]


## A speaker's subtitle name: guards by name, the radio voices (HQ, METIS, INTEL) translated.
func _who(who: String) -> String:
	var k := "ui.who." + who.to_lower()
	var n := tr(k)
	return who.to_upper() if n == k else n


func _draw_design() -> void:
	_face.visible = false
	if not _operative:
		return
	var k := _k()
	_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var d := size / k
	var radio := get_tree().get_first_node_in_group("radio")
	var radio_open: bool = radio != null and radio.menu != null  # the radial owns the screen while it is open
	life = _operative.health.life()
	_edge_flash(d)
	_life(d)
	_radar(d)
	_phase(d)
	_objective.draw(_canvas, d, 0.0 if _operative.cine else 0.3 if radio_open else 1.0)
	var cue_shown := not radio_open and _tip_left <= 0.0 and _aigis > 0.0 and _voice != ""
	if not radio_open:
		if _tip_left <= 0.0:  # a tip takes the top-left corner (Mission 1 has no cue anyway)
			_aigis_cue()
		_gear(d)
		_selector(d)
	_voiceprints(d, cue_shown)
	var dim := 0.3 if radio_open else 1.0
	_live_call(dim)
	_subtitles(d, dim)
	_tutorial_tip()
	_prompt(d)


## Lower-middle, no text: per choice, the key (a held key gets a sand outline), then a round disc holding the
## action's pictogram. A held key's outline fills as the hold progresses; a move with no key (the kill) spins a
## sand arc round its pictogram; a barred one is struck through in red.
func _prompt(d: Vector2) -> void:
	var parts: Array = _operative.prompt_parts
	if parts.is_empty():
		return
	var e := _enter(_prompt_age, 0.22)  # fades up from 10 px low
	var widths: Array = []
	var total := 0.0
	for p: Dictionary in parts:
		var w := 76.0
		if p.action != "":
			w += HudPalette.keycap_width(_canvas, Prompts.key(p.action)) + 14
		widths.append(maxf(w, 76.0))
		total += widths.back()
	total += 28.0 * (parts.size() - 1)
	var x := d.x / 2 - total / 2
	var top := 730.0 + 10.0 * (1.0 - e)
	for i in parts.size():
		var p: Dictionary = parts[i]
		var cx := x
		if p.action != "":
			var kw := _keycap(Vector2(cx, top + 17), Prompts.key(p.action), false, e)
			if p.hold:  # the outline is the hold's gauge: it fills clockwise as the key stays down
				var prog: float = p.get("progress", 0.0)
				HudPalette.rect_fill(_canvas, Rect2(cx - 4, top + 13, kw + 8, 50), prog,
						Color(HudPalette.SAND, e), Color(HudPalette.SAND_DIM, HudPalette.SAND_DIM.a * e * (0.6 if prog > 0.0 else 1.0)),
						3.0 if prog > 0.0 else 2.0, 10.0, 0.45 * e)  # the keycap's 6 px corner, 4 px out
			cx += kw + 14
		var o := Vector2(cx + 38, top + 38)  # no disc: the pictogram stands alone on a soft dark drop
		var col := Color(HudPalette.LIGHT_3 if p.state == "warn" else HudPalette.LIGHT, e)
		for off: Vector2 in [Vector2(0, 3), Vector2(2, 2), Vector2(-2, 2)]:
			_pictogram(p.icon, o + off, Color(0, 0, 0, 0.32 * e))
		_pictogram(p.icon, o, col)
		if p.state == "busy":
			var spin := Time.get_ticks_msec() / 300.0
			_canvas.draw_arc(o, 42, spin, spin + 2.0, 24, Color(HudPalette.SAND, e), 3.0, true)
		elif p.state == "warn":
			_canvas.draw_line(o + Vector2(-26, 26), o + Vector2(26, -26), Color(HudPalette.DMG, e), 5.0, true)
		x += widths[i] + 28.0


## The action pictograms, ~50 px, centred on `o`.
func _pictogram(icon: String, o: Vector2, col: Color) -> void:
	var c := _canvas
	var at := func(x: float, y: float) -> Vector2: return o + Vector2(x - 20, y - 20) * 1.25
	var poly := func(pts: Array) -> void:
		var out := PackedVector2Array()
		for i in range(0, pts.size(), 2):
			out.append(at.call(pts[i], pts[i + 1]))
		c.draw_colored_polygon(out, col)
	var line := func(x1: float, y1: float, x2: float, y2: float, w: float) -> void:
		c.draw_line(at.call(x1, y1), at.call(x2, y2), col, w, true)
	match icon:
		"hold_up":
			c.draw_circle(at.call(20, 8), 5 * 1.25, col)
			poly.call([9, 38, 9, 22, 4, 11, 7, 9, 14, 18, 26, 18, 33, 9, 36, 11, 31, 22, 31, 38, 26, 38, 26, 28, 14, 28, 14, 38])
		"choke", "kill":
			c.draw_circle(at.call(26, 9), 4.5 * 1.25, col)
			poly.call([21, 15, 31, 15, 33, 38, 27, 38, 26, 27, 24, 38, 18, 38])
			c.draw_circle(at.call(12, 13), 4.5 * 1.25, Color(col, 0.75))
			line.call(14, 20, 27, 17, 4.0)
			if icon == "kill":
				poly.call([2, 30, 14, 22, 16, 25, 5, 33])
		"carry":
			c.draw_circle(at.call(20, 8), 4.5 * 1.25, col)
			poly.call([15, 14, 25, 14, 27, 38, 22, 38, 20, 28, 18, 38, 13, 38])
			poly.call([4, 12, 36, 12, 36, 18, 4, 18])
		"drop":
			poly.call([6, 32, 34, 32, 34, 37, 6, 37])
			line.call(20, 4, 20, 24, 3.5)
			poly.call([13, 20, 27, 20, 20, 28])
		"question":
			poly.call([5, 6, 35, 6, 35, 26, 18, 26, 10, 33, 11, 26, 5, 26])
			c.draw_circle(at.call(13, 16), 2.5, Color(HudPalette.DARK_INK, col.a))
			c.draw_circle(at.call(20, 16), 2.5, Color(HudPalette.DARK_INK, col.a))
			c.draw_circle(at.call(27, 16), 2.5, Color(HudPalette.DARK_INK, col.a))
		"resupply":
			c.draw_rect(Rect2(at.call(6, 12), Vector2(28, 22) * 1.25), col)
			line.call(20, 16, 20, 30, 4.0)
			c.draw_line(at.call(13, 23), at.call(27, 23), Color(HudPalette.DARK_INK, col.a), 4.0)
			c.draw_line(at.call(20, 16), at.call(20, 30), Color(HudPalette.DARK_INK, col.a), 4.0)
		"climb", "drop_off":
			line.call(11, 3, 11, 37, 3.5)
			line.call(29, 3, 29, 37, 3.5)
			for y in [9, 17, 25, 33]:
				line.call(11, y, 29, y, 3.0)
			if icon == "drop_off":
				poly.call([33, 22, 40, 22, 36.5, 30])
		"fulton":
			c.draw_circle(at.call(20, 12), 10 * 1.25, col)
			line.call(20, 22, 20, 31, 2.5)
			c.draw_rect(Rect2(at.call(15, 31), Vector2(10, 7) * 1.25), col)
		"console":
			c.draw_rect(Rect2(at.call(5, 6), Vector2(30, 20) * 1.25), col)
			c.draw_rect(Rect2(at.call(8, 9), Vector2(24, 14) * 1.25), Color(HudPalette.DARK_INK, col.a))
			poly.call([14, 29, 26, 29, 29, 36, 11, 36])


## Middle-left, a narrow card: the speaker's green-tinted halftone portrait, the name in spaced capitals with
## three small bars that move only while the line types, and the line below, typed on. The whole line is wrapped
## first, so the text never reflows as it types. Returns where the radio lines start below it.
func _live_call(dim: float) -> float:
	if not _live:
		return CALL.y
	var c := _canvas
	var k := _k()
	var e := _enter(_call_age, CALL_IN_SECS)  # 0 -> 1 in, 1 -> 0 out (ease-in, so it leaves briskly)
	if _call_out >= 0.0:
		e = 1.0 - pow(clampf(_call_out / CALL_OUT_SECS, 0.0, 1.0), 2.0)
	var slide := -(1.0 - e) * CALL_SLIDE
	dim *= e
	c.draw_set_transform(Vector2(slide, 0) * k, 0.0, Vector2(k, k))
	var who := "handler" if _live.speaker() == "operative" else _live.portrait()
	var frame := 1 if _live.typing() and int(Time.get_ticks_msec() / 160.0) % 2 == 0 else 0
	var tex := _portrait(who, frame)
	var origin := Vector2(CALL.x, maxf(CALL.y, vp_bottom + CALL_GAP if vp_bottom > 0.0 else 0.0))  # clear of the Voiceprints
	var tx := origin.x + 16 + FACE + 20
	var call_fs := HudPalette.legible(c, 23)  # wrapped at the size it is drawn at, so a small window loses no words
	var call_row := maxf(35.0, call_fs * 1.35)
	var full := HudPalette.wrap(_live.text(), CALL_W - (tx - origin.x) - 22, HudPalette.FIGURE_MED, call_fs)
	var rows := full.size()
	var box := Rect2(origin, Vector2(CALL_W, maxf(FACE + 28, 58 + rows * call_row)))
	HudPalette.plate(c, Rect2(box.position, box.size + Vector2(HudPalette.FADE_W, 0)), HudPalette.GLASS, 0.4 * dim, 0.92 * dim, false)  # borderless, dithering away on its inner side like the other plates
	if tex:
		_face.texture = tex
		_face.position = (origin + Vector2(16 + slide, 16)) * k
		_face.size = Vector2.ONE * FACE * k
		_face.modulate = Color(MINT, dim)
		_face.visible = true
		PixelKit.frame(c, PixelKit.snap(Rect2(origin + Vector2(16, 16), Vector2.ONE * FACE)), Color(MINT, 0.7 * dim), 1)
	var name_f := HudPalette.tracked(HudPalette.LABEL_BOLD, 20, 0.3)
	var nm := _live.speaker_name().to_upper()
	HudPalette.hud_text(c, Vector2(tx, origin.y + 40), nm, 20, Color(MINT, dim), name_f, 0, false)
	var bx := tx + name_f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 14
	for i in 3:  # three bars that step only while text is typing
		var hgt := 4.0 + 10.0 * float(int((absf(sin(Time.get_ticks_msec() / 130.0 + i * 1.7))) * 3.0) + 1) / 3.0 if _live.typing() else 4.0
		c.draw_rect(Rect2(bx + i * 5, origin.y + 32 - hgt / 2, 3, hgt), Color(MINT, dim))
	var left := _live.shown().length()
	var y := origin.y + 70
	for i in rows:
		var l: String = full[i]
		HudPalette.hud_text(c, Vector2(tx, y), l.left(maxi(left, 0)), 23, Color(HudPalette.LIGHT, dim), HudPalette.FIGURE_MED)
		left -= l.length() + 1
		y += call_row
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	return box.end.y + 24


func _portrait(who: String, frame: int) -> Texture2D:
	var path := PORTRAIT % [who, frame]
	if not _faces.has(path):
		_faces[path] = load(path) if ResourceLoader.exists(path) else null
	return _faces[path]


## Guards' radio lines under the call: the speaker in a dim caption, the line wrapped to the call column, each
## fading out by Subtitles.LIFE, the newest at the bottom.
func _subtitles(d: Vector2, dim: float) -> float:
	var blocks: Array = []  # [who, rows, alpha], oldest first
	var total := 0.0
	var fs := HudPalette.legible(_canvas, 26)  # wrapped at the size it is drawn at, so a small window keeps SUB_W
	var row_h := maxf(34.0, fs * 1.3)
	for l: Dictionary in _subs.lines:
		var rows := HudPalette.wrap(l["text"], SUB_W, HudPalette.FIGURE_MED, fs)
		blocks.append([_who(l["who"]), rows, minf(Subtitles.alpha(l["age"]), clampf(l["age"] / 0.2, 0.0, 1.0)) * dim])
		total += 28 + rows.size() * row_h + 10
	var y := SUB_BOTTOM - total
	var top := y
	for b: Array in blocks:
		HudPalette.hud_label(_canvas, Vector2(d.x / 2, y + 18), b[0], 17, Color(HudPalette.LIGHT_3, b[2]), 0.16, HudPalette.LABEL, 1)
		y += 28
		for row: String in b[1]:
			HudPalette.hud_text(_canvas, Vector2(d.x / 2, y + 22), row, 26, Color(HudPalette.LIGHT, b[2]), HudPalette.FIGURE_MED, 1)
			y += row_h
		y += 10
	return top


## Mission 1's tutorial tip, top-left where the Aigis cue sits from Mission 2 on, sliding in from the edge as the cue
## does: the verb on a sand slab whose right edge slants in, and under it the steps, one per row, on a glass plate
## that dithers away on its inner side, in tracked condensed caps with each [KEY] drawn as a key. A step wider than
## TIP_W wraps between its words; every width is measured at the size it is drawn at.
func _tutorial_tip() -> void:
	if _tip_left <= 0.0:
		return
	var c := _canvas
	var age := TIP_TIME - _tip_left
	var a := minf(clampf(_tip_left / TIP_OUT, 0.0, 1.0), clampf(age / 0.12, 0.0, 1.0))
	var e := _enter(age, 0.2)
	var at := Vector2(roundf(70 - 28 * (1.0 - e)), 56)
	var fs := HudPalette.legible(c, 24)
	var font := _tip_font()
	var row_h := maxf(HudPalette.keycap_side(true) + 10.0, fs * 1.45)
	var rows: Array = []  # [indent, parts]: a wrapped step's later rows line up under its words, past its key
	var step: Array = []
	for part: Array in _tip_parts(_tip) + [["gap", ""]]:
		if part[0] != "gap":
			step.append(part)
			continue
		if not step.is_empty():
			var hang := HudPalette.keycap_width(c, step[0][1], true) + TIP_SPACE if step[0][0] == "key" else 0.0
			var wrapped := _tip_rows(step, TIP_W)
			for i in wrapped.size():
				rows.append([hang if i > 0 else 0.0, wrapped[i]])
		step = []
	var bw := 0.0
	for r: Array in rows:
		bw = maxf(bw, r[0] + _row_width(r[1]))
	var title := _tip_title.to_upper()
	var y := at.y
	if title != "":  # the verb's slab
		var tfs := HudPalette.legible(c, 23)
		var tfont := HudPalette.tracked(HudPalette.DISPLAY, tfs, 0.3)
		var th := 44.0
		var ws := 22.0 + tfont.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x + 18.0 + 16.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(at.x - 16, y), Vector2(at.x - 16 + ws, y), Vector2(at.x - 16 + ws - 16, y + th), Vector2(at.x - 16, y + th)]), Color(HudPalette.SAND, a))
		HudPalette.hud_text(c, Vector2(at.x + 6, y + th / 2 + tfs * 0.36), title, tfs, Color(HudPalette.DARK_INK, a), tfont, 0, false)
		y += th
	var plate := Rect2(at.x - 16, y, bw + 16 + 30 + HudPalette.FADE_W, rows.size() * row_h + TIP_PAD.y * 2)
	HudPalette.plate(c, plate, HudPalette.GLASS, 0.35 * a, TIP_PLATE * a, false)
	c.draw_rect(Rect2(plate.position, Vector2(3, plate.size.y)), Color(HudPalette.SAND, 0.7 * a))  # the sand edge ties the steps to their verb
	var ry := y + TIP_PAD.y
	for r: Array in rows:
		var x: float = at.x + 6 + r[0]
		for part: Array in r[1]:
			if part[0] == "key":
				x += HudPalette.keycap(c, Vector2(x, ry + (row_h - HudPalette.keycap_side(true)) / 2), part[1], true, a) + TIP_SPACE
			else:
				HudPalette.hud_text(c, Vector2(x, ry + row_h / 2 + fs * 0.36), part[1], fs, Color(HudPalette.LIGHT, a), font, 0, false)
				x += _word_width(part[1]) + TIP_SPACE
		ry += row_h


## The tip's parts in rows no wider than max_w: whole steps (the parts between gaps) where they fit, and a step
## too wide for a row of its own broken between its words.
func _tip_rows(parts: Array, max_w: float) -> Array:
	var steps: Array = [[]]
	for p: Array in parts:
		if p[0] == "gap":
			steps.append([])
		else:
			steps.back().append(p)
	var rows: Array = [[]]
	for step: Array in steps:
		var joined: Array = rows.back() + ([["gap", ""]] if not rows.back().is_empty() else []) + step
		if rows.back().is_empty() or _row_width(joined) <= max_w:
			rows[-1] = joined
		else:
			rows.append(step)
	var out: Array = []
	for r: Array in rows:
		if _row_width(r) <= max_w:
			out.append(r)
			continue
		var cur: Array = []
		for p: Array in r:
			var pieces: Array = [p] if p[0] != "text" else Array(p[1].split(" ", false)).map(func(word: String) -> Array: return ["text", word])
			for q: Array in pieces:
				if not cur.is_empty() and _row_width(cur + [q]) > max_w:
					out.append(cur)
					cur = []
				if not (cur.is_empty() and q[0] == "gap"):
					cur.append(q)
		out.append(cur)
	return out


func _row_width(row: Array) -> float:
	var w := 0.0
	for part: Array in row:
		match part[0]:
			"key":
				w += HudPalette.keycap_width(_canvas, part[1], true) + TIP_SPACE
			"gap":
				w += TIP_GAP
			_:
				w += _word_width(part[1]) + TIP_SPACE
	return maxf(w - TIP_SPACE, 0.0)


func _word_width(s: String) -> float:
	return _tip_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.legible(_canvas, 24)).x


## The tip's steps: tracked condensed caps, like the HUD's labels.
func _tip_font() -> Font:
	return HudPalette.tracked(HudPalette.LABEL_BOLD, HudPalette.legible(_canvas, 24), 0.08)


## A tip split into ["key", "RMB"], ["text", "AIM FROM BEHIND"] and ["gap", ""] parts: `[KEY]` tokens (an InputMap
## action's name, `[aim]`, shows its binding), the words between them, and the double spaces between steps.
static func _tip_parts(tip: String) -> Array:
	var out: Array = []
	for chunk: String in tip.split("  "):
		if not out.is_empty():
			out.append(["gap", ""])
		var rest := chunk
		while rest != "":
			var open := rest.find("[")
			var close := rest.find("]")
			var piece := rest
			if open == 0 and close > 0:
				piece = rest.left(close + 1)
				var token := piece.trim_prefix("[").trim_suffix("]")
				out.append(["key", Prompts.key(token) if InputMap.has_action(token) else token])  # [interact] shows its binding
			elif open > 0:
				piece = rest.left(open)
			if not piece.begins_with("[") and piece.strip_edges() != "":
				out.append(["text", piece.strip_edges()])
			rest = rest.substr(piece.length())
	return out
