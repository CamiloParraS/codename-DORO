## The in-game HUD (docs/DESIGN.md), drawn by hand on `_canvas` in design px: 1080 tall, as wide as the window's
## aspect, scaled to the window and smoothly filtered. Corners: Aigis top-left, the phase plate top-centre, the
## Radar top-right, life bottom-left, item and weapon cards bottom-right (the selector opens beside them when
## either changes), the live call and radio lines middle-left, and the text-free action prompt lower-middle.
## Only the crosshair stays on the 640x360 logical canvas, so its
## pixel art keeps its grid. Lives on CanvasLayer 1 so the banding pass on layer 0 does not touch it.
extends "res://ui/hud/hud_corners.gd"


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
	if _operative and _operative.aiming:
		_crosshair(_operative.gun().crosshair)  # loaded here: a texture first loaded inside _draw draws white (Godot 4.7)
	_subs.tick(delta)
	_tip_left = maxf(_tip_left - delta, 0.0)
	if _live:
		var p := _live.advance(delta, true)
		if not p.is_empty():
			Mixer.blip(p.back())
		if _live.done():
			_live = null
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


## The crosshair only: pixel art on the logical canvas. Shots leave from it, and it wanders a little with the sway.
func _draw() -> void:
	if _operative and _operative.aiming:
		var tex := _crosshair(_operative.gun().crosshair)
		var wander := Locomotion.drift_px(_operative.aim_drift(), _operative.camera.fov, size.y)
		draw_texture(tex, (size / 2 + wander - tex.get_size() / 2).round())


## Radio line from a guard (call_group "radio_log").
func say(who: String, text: String) -> void:
	_subs.add(who, text)


## Mission 1's tutorial prompt (call_group "tutorial_tip").
func tip(text: String) -> void:
	_tip = text
	_tip_left = TIP_TIME


## A live Codec call (call_group "codec_live"): play goes on while it runs.
func live_call(lines: Array) -> void:
	_live = CodecCall.new(lines)


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
	_voiceprints(d)
	_phase(d)
	if not radio_open:
		_aigis_cue()
		_gear(d)
		_selector(d)
	var dim := 0.3 if radio_open else 1.0
	_live_call(dim)
	_tutorial_tip(d, _subtitles(d, dim))
	_prompt(d)


## Lower-middle, no text: per choice, the key (a held key gets a sand outline), then a round disc holding the
## action's pictogram. A move under way spins a sand arc round its disc; a barred one is struck through in red.
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
			w += HudPalette.FIGURE.get_string_size(Prompts.key(p.action), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 16 + 14
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
			if p.hold:
				_canvas.draw_rect(Rect2(cx - 4, top + 13, kw + 8, 50), Color(HudPalette.SAND_DIM, HudPalette.SAND_DIM.a * e), false, 2.0)
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
	var who := "handler" if _live.speaker() == "operative" else _live.portrait()
	var frame := 1 if _live.typing() and int(Time.get_ticks_msec() / 160.0) % 2 == 0 else 0
	var tex := _portrait(who, frame)
	var tx := CALL.x + 12 + FACE + 16
	var full := HudPalette.wrap(_live.text(), CALL_W - (tx - CALL.x) - 18, HudPalette.FIGURE_MED, 24)
	var rows := mini(full.size(), 4)
	var box := Rect2(CALL, Vector2(CALL_W, maxf(FACE + 26, 62 + rows * 32)))
	c.draw_rect(box, Color(HudPalette.GLASS, 0.74 * dim))
	c.draw_rect(Rect2(box.position, Vector2(box.size.x, 2)), Color(MINT, dim))
	if tex:
		_face.texture = tex
		_face.position = (CALL + Vector2(12, 14)) * k
		_face.size = Vector2.ONE * FACE * k
		_face.modulate = Color(MINT, dim)
		_face.visible = true
		c.draw_rect(Rect2(CALL + Vector2(12, 14), Vector2.ONE * FACE), Color(MINT, 0.6 * dim), false, 1.0)
	var name_f := HudPalette.tracked(HudPalette.LABEL_BOLD, 18, 0.3)
	var nm := _live.speaker_name().to_upper()
	HudPalette.hud_text(c, Vector2(tx, CALL.y + 34), nm, 18, Color(MINT, dim), name_f, 0, false)
	var bx := tx + name_f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 14
	for i in 3:  # three bars that step only while text is typing
		var hgt := 4.0 + 10.0 * float(int((absf(sin(Time.get_ticks_msec() / 130.0 + i * 1.7))) * 3.0) + 1) / 3.0 if _live.typing() else 4.0
		c.draw_rect(Rect2(bx + i * 5, CALL.y + 27 - hgt / 2, 3, hgt), Color(MINT, dim))
	var left := _live.shown().length()
	var y := CALL.y + 66
	for i in rows:
		var l: String = full[i]
		HudPalette.hud_text(c, Vector2(tx, y), l.left(maxi(left, 0)), 24, Color(HudPalette.LIGHT, dim), HudPalette.FIGURE_MED)
		left -= l.length() + 1
		y += 32
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
	for l: Dictionary in _subs.lines:
		var rows := HudPalette.wrap(l["text"], SUB_W, HudPalette.FIGURE_MED, 26)
		blocks.append([_who(l["who"]), rows, minf(Subtitles.alpha(l["age"]), clampf(l["age"] / 0.2, 0.0, 1.0)) * dim])
		total += 28 + rows.size() * 34 + 10
	var y := SUB_BOTTOM - total
	var top := y
	for b: Array in blocks:
		HudPalette.hud_label(_canvas, Vector2(d.x / 2, y + 18), b[0], 17, Color(HudPalette.LIGHT_3, b[2]), 0.16, HudPalette.LABEL, 1)
		y += 28
		for row: String in b[1]:
			HudPalette.hud_text(_canvas, Vector2(d.x / 2, y + 22), row, 26, Color(HudPalette.LIGHT, b[2]), HudPalette.FIGURE_MED, 1)
			y += 34
		y += 10
	return top


## Mission 1's tutorial line, centred in the lower middle, just above the subtitles (or where they would be).
func _tutorial_tip(d: Vector2, above: float) -> void:
	if _tip_left <= 0.0:
		return
	var a := minf(clampf(_tip_left, 0.0, 1.0), clampf((TIP_TIME - _tip_left) / 0.25, 0.0, 1.0))
	var rows := HudPalette.wrap(_tip, SUB_W, HudPalette.FIGURE_MED, 26)
	var y := above - 16 - rows.size() * 34
	for i in rows.size():
		HudPalette.hud_text(_canvas, Vector2(d.x / 2, y + 26 + i * 34), rows[i], 26, Color(HudPalette.LIGHT, a), HudPalette.FIGURE_MED, 1)
