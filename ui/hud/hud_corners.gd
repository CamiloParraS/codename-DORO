## The HUD's state and its corner pieces, drawn on `_canvas` in design px (hud.gd extends it and draws the middle):
## the alert flash, life, the Radar and Voiceprints, the phase plate, the Aigis cue, the gear cards and the selector.
extends Control

const FLASH_TIME := 1.0
const TICK_TIME := 6.0  # s a Habit Aigis just logged stays lit on the strip
const TIP_TIME := 6.0
const VP_SHOWN := 3  # Voiceprint names listed before "+n"
const SELECT_TIME := 1.4  # s the selector stays open after the last change
const SELECT_WIPE := 0.2  # s the strip takes to open, in 6 hard steps
const SLOT_STAGGER := 0.035
const SWEEP_SECS := 5.0  # s per turn of the Radar's sweep
const MINT := HudPalette.MINT  # the live call card's tint
const LOST_HOLD := 0.4  # s the red lost segment waits after a hit
const LOST_DRAIN := 0.6  # life per second
const CALL := Vector2(64, 410)  # the live call card's corner
const CALL_W := 430.0
const FACE := 76.0
const HABIT_W := 56.0  # px per Habit column on the Aigis cue
const SUB_W := 1000.0  # subtitles and tips: centred, lower middle
const SUB_BOTTOM := 1010.0  # near the bottom edge; the action prompt sits above it
const PORTRAIT := "res://ui/codec/portraits/%s_%d.png"

var life := 1.0  # the Operative's Health.life(), refreshed each frame
var _lost := 1.0  # where the red lost segment ends
var _lost_hold := 0.0
var _flash := 0.0
var _phase_name := ""  # last phase drawn, to time the plate's entrance
var _phase_age := 0.0
var _aigis := 0.0  # HudModel.aigis_weight: how awake Aigis is, 0 in Mission 1
var _voice := ""  # the Dominant Voice, shown once _aigis > 0
var _levels := {}  # habit -> 0..3, as this Mission sees the Profile
var _tick := ""  # habit just logged to Aigis's profile
var _tick_age := 99.0
var _prev_counts := {}
var _run_seen := false  # the first read only takes a baseline, so old events never tick
var _was_alert := {}  # guard -> was in ALERT last frame
var _crosshairs := {}  # file name -> texture
var _operative: Node3D
var _subs := Subtitles.new()
var _tip := ""         # Mission 1's tutorial prompt (call_group "tutorial_tip"), TIP_TIME seconds
var _tip_left := 0.0
var _live: CodecCall  # the live Codec call in progress, if any
var _select := ""  # "weapon" or "item" while the selector is open
var _select_left := 0.0
var _select_age := 0.0  # s since the selector opened (unscaled), for its wipe
var _last_gun: Gun
var _last_item := -1
var _canvas := Control.new()  # the design-px layer
var _face := TextureRect.new()  # the live call's portrait, under the halftone shader
var _faces := {}  # path -> texture
var _prompt_age := 0.0  # s the current action prompt has been up, for its fade-in
var _cue_age := 0.0  # s the Aigis cue has been up
var _rounds := 1.0  # the rounds bar's displayed fill, easing toward the real one


## Exponential ease-out of `t` seconds into a `secs` entrance: 0 → 1.
func _enter(t: float, secs: float) -> float:
	return 1.0 - pow(2.0, -10.0 * clampf(t / secs, 0.0, 1.0)) if t < secs else 1.0


func _k() -> float:
	return size.y / HudPalette.DESIGN_H


## A hard red frame when a guard goes ALERT, easing out.
func _edge_flash(d: Vector2) -> void:
	if _flash <= 0.0:
		return
	var c := Color(HudPalette.DMG, _flash * _flash * 0.7)  # squared: hits hard, then eases out
	var w := 14.0
	_canvas.draw_rect(Rect2(0, 0, d.x, w), c)
	_canvas.draw_rect(Rect2(0, d.y - w, d.x, w), c)
	_canvas.draw_rect(Rect2(0, 0, w, d.y), c)
	_canvas.draw_rect(Rect2(d.x - w, 0, w, d.y), c)


## Bottom-left: a labelled 18x340 gauge, 70 px from the edges: ink fill, the red lost segment behind it, a 1 px
## frame, quarter ticks and the percentage underneath. Under a quarter of life the fill and the number go red and blink.
func _life(d: Vector2) -> void:
	var c := _canvas
	var well := Rect2(70, d.y - 70 - 340, 18, 340)
	var low := life < 0.25
	var warn := low and int(Time.get_ticks_msec() / 300.0) % 2 == 0
	c.draw_rect(well.grow(4), Color(HudPalette.GLASS, 0.62))
	c.draw_rect(well, Color(0.0, 0.0, 0.0, 0.35))
	c.draw_rect(well, Color(HudPalette.LIGHT, 0.5), false, 1.0)
	var inner := well.grow(-2)
	c.draw_rect(Rect2(inner.position.x, inner.end.y - inner.size.y * _lost, inner.size.x, inner.size.y * _lost), HudPalette.DMG)
	c.draw_rect(Rect2(inner.position.x, inner.end.y - inner.size.y * life, inner.size.x, inner.size.y * life), HudPalette.DMG if warn else HudPalette.LIGHT)
	for q in [0.25, 0.5, 0.75]:
		var ty: float = well.end.y - well.size.y * q
		c.draw_line(Vector2(well.end.x + 4, ty), Vector2(well.end.x + 12, ty), Color(HudPalette.LIGHT, 0.55), 1.0)
	HudPalette.hud_label(c, Vector2(well.position.x - 2, well.position.y - 14), tr("ui.hud.life"), 16, HudPalette.LIGHT_2, 0.2, HudPalette.LABEL, 0)
	HudPalette.hud_text(c, Vector2(well.position.x - 2, well.end.y + 28), "%d" % roundi(life * 100.0), 24, HudPalette.DMG if low else HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 24, 0.04), 0, true)


## Top-right disc, north-up: range rings and compass ticks in sand, guards as triangles on their facing
## (only while they make noise, or under the Scanner; a calling guard always, flashing red), the objective
## (white diamond) or Target (white ring), the Operative's sand arrow. No vision cones: the Scanner owns those.
## ALERT/EVASION jam it outright (MGS1): dark red static, rolling bands, JAMMED, nothing shows through.
func _radar(d: Vector2) -> void:
	var c := _canvas
	var o := RadarModel.rect(d).get_center()
	var rad := RadarModel.HALF
	if RadarModel.jammed(_phase_name):
		_jammed(o, rad)
		return
	c.draw_circle(o, rad, Color(HudPalette.GLASS, 0.8))
	c.draw_arc(o, rad - 1, 0, TAU, 96, Color(HudPalette.LIGHT, 0.85), 2.0, true)
	for ring in [rad * 0.32, rad * 0.645]:  # range rings at 50 and 100 of 155
		c.draw_arc(o, ring, 0, TAU, 72, Color(HudPalette.LIGHT, 0.25), 1.0, true)
	for dir: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:  # dashed cross and edge ticks
		for n in 25:
			c.draw_line(o + dir * (n * 6.0 + 4.0), o + dir * (n * 6.0 + 7.0), Color(HudPalette.LIGHT, 0.25), 1.0)
		c.draw_line(o + dir * rad, o + dir * (rad - 12), Color(HudPalette.LIGHT, 0.9), 2.0)
	HudPalette.hud_text(c, o + Vector2(0, -rad + 29), "N", 17, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 17, 0.12), 1, false)
	var origin := RadarModel.flat(_operative.global_position)
	var sweep := fmod(Time.get_ticks_msec() / 1000.0, SWEEP_SECS) / SWEEP_SECS * TAU - PI / 2
	for w in 8:  # a faint wedge trailing the line
		c.draw_arc(o, rad * 0.5, sweep - 0.5 + w * 0.0625, sweep - 0.5 + (w + 1) * 0.0625, 4, Color(HudPalette.LIGHT, 0.02 * (w + 1)), rad, true)
	c.draw_line(o, o + Vector2.from_angle(sweep) * (rad - 2), Color(HudPalette.LIGHT, 0.5), 1.5, true)
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		if g.is_down():
			continue
		var off := RadarModel.flat(g.global_position) - origin
		var scanned: bool = _operative.items.scanning() and off.length() <= Items.SCANNER_RANGE
		var calling := AlertChain.area.calling(g)  # a calling guard is always on: it is the one to stop
		var a := 1.0 if calling else RadarModel.guard_alpha(g.ping_age, scanned)
		if a <= 0.0:
			continue
		if off.length() > RadarModel.RANGE:
			a *= 0.55  # pinned to the rim
		var col := HudPalette.DMG if RadarModel.call_flash(calling, Time.get_ticks_msec()) else HudPalette.LIGHT
		_triangle(o + RadarModel.blip(off, 10), RadarModel.facing(g.global_basis), 9.0, Color(col, a))
	var ring := RadarModel.ping_radius(_operative.ping_range, _operative.ping_age)
	if ring > 0.0:
		c.draw_arc(o, ring, 0, TAU, 72, Color(HudPalette.LIGHT, 1.0 - _operative.ping_age / RadarModel.PING_TIME), 2.0, true)
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	for b: Dictionary in (run.radar_blips() if run else []):
		var p := o + RadarModel.blip(RadarModel.flat(b.pos) - origin, 12)
		if b.target:
			c.draw_arc(p, 11, 0, TAU, 32, HudPalette.LIGHT, 2.5, true)
			c.draw_circle(p, 4, HudPalette.LIGHT)
		else:
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -12), p + Vector2(12, 0), p + Vector2(0, 12), p + Vector2(-12, 0)]), HudPalette.LIGHT)
	var f := RadarModel.facing(_operative.look_basis)
	var arrow := PackedVector2Array([o + f * 17, o + f.rotated(2.55) * 14, o - f * 5, o + f.rotated(-2.55) * 14])
	c.draw_colored_polygon(arrow, HudPalette.SAND)
	arrow.append(arrow[0])
	c.draw_polyline(arrow, HudPalette.DARK_INK, 1.5, true)


## A guard on the Radar: a triangle pointing along `face`.
func _triangle(p: Vector2, face: Vector2, s: float, col: Color) -> void:
	_canvas.draw_colored_polygon(PackedVector2Array([p + face * s * 1.2, p + face.rotated(2.4) * s, p + face.rotated(-2.4) * s]), col)


## The jammed Radar: dark red ground, red static, 2 px dark bands every 6 px rolling down, a red rim, JAMMED.
func _jammed(o: Vector2, rad: float) -> void:
	var c := _canvas
	c.draw_circle(o, rad, HudPalette.JAM)
	for i in 220:  # static, kept inside the disc
		var p := Vector2.from_angle(randf() * TAU) * sqrt(randf()) * (rad - 3)
		c.draw_rect(Rect2(o + p, Vector2(randf_range(2, 8), 2)), Color(HudPalette.DMG, randf_range(0.25, 0.8)))
	var y := -rad + fmod(Time.get_ticks_msec() / 50.0, 6.0)
	while y < rad:
		var half := sqrt(maxf(rad * rad - y * y, 0.0))
		c.draw_line(o + Vector2(-half, y), o + Vector2(half, y), Color(0, 0, 0, 0.35), 2.0)
		y += 6.0
	c.draw_arc(o, rad, 0, TAU, 96, Color(HudPalette.DMG, 0.7), 1.5, true)
	HudPalette.hud_label(c, o + Vector2(0, 7), tr("ui.hud.jammed"), 20, HudPalette.LIGHT, 0.32, HudPalette.LABEL_BOLD, 1)


## Held Voiceprints under the Radar, right-aligned; past VP_SHOWN, a "+n".
func _voiceprints(d: Vector2) -> void:
	var held: Array = _operative.voiceprints.held
	if held.is_empty():  # a bare "VP" with nothing under it is noise
		return
	var x := d.x - 64
	var y := RadarModel.TOP + RadarModel.HALF * 2 + 32
	HudPalette.hud_label(_canvas, Vector2(x, y), tr("ui.hud.vp"), 15, HudPalette.LIGHT_3, 0.16, HudPalette.LABEL, 2)
	var rows: Array = held.slice(0, VP_SHOWN).map(func(n: String) -> String: return n)
	if held.size() > VP_SHOWN:
		rows.append("+%d" % (held.size() - VP_SHOWN))
	for i in rows.size():
		HudPalette.hud_label(_canvas, Vector2(x, y + 24 + 22 * i), rows[i], 17, HudPalette.LIGHT_2, 0.12, HudPalette.LABEL, 2)


## Top-centre, 56 px down: ALERT is a red slab with a slanted foot and the timer on a dark slab beside it;
## EVASION the same with a dark word slab over a red underline; CAUTION a quiet dark plate. The word and the
## plate's shape carry the phase, not hue alone.
func _phase(d: Vector2) -> void:
	var ph := HudModel.phase(AlertChain.area)
	if ph[0] != _phase_name:
		_phase_name = ph[0]
		_phase_age = 0.0
	if ph[0] == "":
		return
	var c := _canvas
	var word: String = tr("ui.phase." + String(ph[0]).to_lower()).to_upper()
	var whole := ceili(ph[1])
	var secs := "%d:%02d" % [floori(whole / 60.0), whole % 60]
	var wf := HudPalette.tracked(HudPalette.DISPLAY, 28, 0.5)
	var tf := HudPalette.tracked(HudPalette.DISPLAY, 28, 0.1)
	var ww := wf.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	var tw := tf.get_string_size(secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	var h := 50.0
	var wslab := 36.0 + ww + 26.0
	var tslab := 22.0 + tw + 30.0
	var x0 := roundf((d.x - (wslab + tslab - 14.0)) / 2.0)
	var alert: bool = ph[0] == "ALERT"
	var evasion: bool = ph[0] == "EVASION"
	var dark := Color(HudPalette.GLASS, 0.86)
	var red := HudPalette.DMG
	if alert and _phase_age <= 0.32 and int(_phase_age * 12.5) % 2 != 0:  # two hard flickers on arrival
		red = red.darkened(0.6)
	var y := 56.0 - 36.0 * (1.0 - _enter(_phase_age, 0.35))  # the plate drops in from above the edge
	var word_col := red if alert else dark
	c.draw_colored_polygon(PackedVector2Array([Vector2(x0, y), Vector2(x0 + wslab, y), Vector2(x0 + wslab - 18, y + h), Vector2(x0, y + h)]), word_col)
	if evasion:
		c.draw_rect(Rect2(x0, y + h - 3, wslab - 18, 3), HudPalette.DMG)
	var tx := x0 + wslab - 14.0
	c.draw_colored_polygon(PackedVector2Array([Vector2(tx + 14, y), Vector2(tx + tslab, y), Vector2(tx + tslab, y + h), Vector2(tx, y + h)]), dark)
	c.draw_rect(Rect2(tx, y + h - 3, tslab, 3), HudPalette.DMG if (alert or evasion) else Color(HudPalette.LIGHT, 0.3))
	var word_ink := HudPalette.LIGHT if alert else HudPalette.MARK_RED if evasion else HudPalette.LIGHT_2
	HudPalette.hud_text(c, Vector2(x0 + 36, y + 36), word, 28, word_ink, wf, 0, false)
	HudPalette.hud_text(c, Vector2(tx + 22, y + 36), secs, 28, HudPalette.LIGHT, tf, 0, false)


## Top-left, from Mission 2 on: the Dominant Voice, then the six Habits with their 0-3 levels as pips. The one
## Aigis just logged against you is lit, with a cyan rise mark, for TICK_TIME.
func _aigis_cue() -> void:
	if _aigis <= 0.0 or _voice == "":
		return
	var c := _canvas
	var e := _enter(_cue_age, 0.6)
	var at := Vector2(70 - 28 * (1.0 - e), 56)
	var plate := Rect2(at + Vector2(-16, -14), Vector2(6 * HABIT_W + 20, 100))  # a smoke plate: the cue reads on a white wall too
	c.draw_rect(plate, Color(HudPalette.GLASS, 0.78 * e))
	c.draw_rect(plate, Color(HudPalette.CYAN, 0.35 * e), false, 1.0)
	c.draw_rect(Rect2(plate.position, Vector2(3, plate.size.y)), Color(HudPalette.CYAN, e))
	var eye := at + Vector2(13, 13)
	c.draw_arc(eye, 12, 0, TAU, 32, HudPalette.CYAN, 2.0, true)
	c.draw_arc(eye + Vector2(-4, -1), 3.2, 0, TAU, 16, HudPalette.CYAN, 2.0, true)
	c.draw_arc(eye + Vector2(4, -1), 3.2, 0, TAU, 16, HudPalette.CYAN, 2.0, true)
	HudPalette.hud_text(c, at + Vector2(38, 22), _voice, 24, HudPalette.CYAN, HudPalette.tracked(HudPalette.DISPLAY, 22, 0.34), 0)
	var lit := _tick if _tick_age < TICK_TIME else ""
	if lit != "":  # the glyphs are too tight for six names: name the one Aigis just logged
		HudPalette.hud_label(c, Vector2(plate.end.x - 14, at.y + 22), tr("ui.habit." + lit), 16, HudPalette.LIGHT, 0.14, HudPalette.LABEL, 2)
	for i in Aigis.HABITS.size():
		var h: String = Aigis.HABITS[i]
		var p := at + Vector2(i * HABIT_W, 40)
		var on := h == lit
		var col := Color(HudPalette.LIGHT, 1.0 if on else 0.62)
		HabitGlyphs.draw(c, h, p + Vector2(1, 1), Color(0, 0, 0, 0.5), 3.0)
		HabitGlyphs.draw(c, h, p, col, 3.0)
		if on:
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(36, -6), p + Vector2(41, 3), p + Vector2(31, 3)]), HudPalette.CYAN)
		for j in 3:
			var pip := Rect2(p + Vector2(3 + j * 10, 38), Vector2(8, 3))
			c.draw_rect(pip, HudPalette.SAND if j < int(_levels.get(h, 0)) else Color(HudPalette.LIGHT, 0.3))


## Geometry of the two cards (design px): the mock's 400 px column, 70 px from the right, 66 from the bottom.
func _weapon_rect(d: Vector2) -> Rect2:
	return Rect2(d.x - 70 - 376, d.y - 84 - 150, 376, 150)


func _item_rect(d: Vector2) -> Rect2:
	var wr := _weapon_rect(d)
	return Rect2(wr.position.x, wr.position.y - 8 - 64, wr.size.x, 64)


## A card: smoke fill and a 1 px ink frame at 50%.
func _card(r: Rect2) -> void:
	_canvas.draw_rect(r, Color(HudPalette.GLASS, 0.66))
	_canvas.draw_rect(r, Color(HudPalette.LIGHT, 0.5), false, 1.0)


## Bottom-right: the item card (with the Fulton balloons beside it) over the weapon card and its rounds bar.
func _gear(d: Vector2) -> void:
	var gun: Gun = _operative.gun()
	var wr := _weapon_rect(d)
	_card(wr)
	var name_w := _card_name(wr.position + Vector2(12, 29), tr("ui.gear.rifle" if gun == _operative.rifle else "ui.gear.tranq"))
	var chip := "LTH" if gun.lethal else "SLP"
	_chip(Vector2(wr.position.x + 12 + name_w + 8, wr.position.y + 11), chip, HudPalette.DMG if gun.lethal else HudPalette.SLP)
	_sil(&"rifle" if gun == _operative.rifle else &"tranq", wr.position + Vector2(36, 132), 1.0, HudPalette.LIGHT)
	if gun.suppressor_max >= 0:  # shots left on the suppressor
		var sx := wr.position.x + 12
		for i in gun.suppressor_max:
			var col := HudPalette.LIGHT if i < gun.suppressor else Color(HudPalette.LIGHT, 0.2)
			_canvas.draw_rect(Rect2(sx + i * 12, wr.position.y + 40, 9, 9), HudPalette.DMG if gun.suppressor <= 0 else col)
	var count := str(gun.loaded)
	var res := " / %d" % gun.reserve
	var cf := HudPalette.tracked(HudPalette.DISPLAY, 48, 0.04)
	var rf := HudPalette.DISPLAY
	var rw := rf.get_string_size(res, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	HudPalette.hud_text(_canvas, Vector2(wr.end.x - 14, wr.end.y - 10), res, 24, HudPalette.LIGHT if gun.reloading() else HudPalette.LIGHT_3, rf, 2, false)
	HudPalette.hud_text(_canvas, Vector2(wr.end.x - 14 - rw, wr.end.y - 10), count, 48, HudPalette.DMG if gun.loaded == 0 else HudPalette.LIGHT, cf, 2, false)
	var track := Rect2(wr.position.x, wr.end.y + 12, wr.size.x, 6)  # rounds left, loaded and reserve
	_canvas.draw_rect(track, Color(HudPalette.LIGHT, 0.22))
	var left := float(gun.loaded + gun.reserve) / maxf(gun.total, 1.0)
	_rounds = lerpf(_rounds, left, 1.0 - exp(-get_process_delta_time() * 14.0))
	_canvas.draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(_rounds, 0.0, 1.0), track.size.y)), HudPalette.DMG if gun.loaded == 0 else HudPalette.LIGHT)
	var it: Items = _operative.items
	var ir := _item_rect(d)
	_card(ir)
	var live: bool = it.scanning() or _operative.throwing
	var split := ir.end.x - 104.0  # the item on the left, the Fulton balloons on the right
	var scanner: bool = it.selected == Items.Kind.SCANNER
	_sil(&"scanner" if scanner else &"magazine", Vector2(ir.position.x + 12, ir.end.y - 10), 0.6, HudPalette.LIGHT if live else Color(HudPalette.LIGHT, 0.86))
	_card_name(ir.position + Vector2(66, 38), tr("ui.gear.scanner" if scanner else "ui.gear.magazine"), HudPalette.LIGHT)
	HudPalette.hud_text(_canvas, Vector2(split - 12, ir.end.y - 14), str(it.count()), 32, HudPalette.DMG if it.count() == 0 else HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 32, 0.04), 2, false)
	_canvas.draw_line(Vector2(split, ir.position.y + 10), Vector2(split, ir.end.y - 10), Color(HudPalette.LIGHT, 0.25), 1.0)
	if it.scanning():
		_canvas.draw_rect(Rect2(ir.position.x + 1, ir.end.y - 4, (ir.size.x - 2) * it.scan_left / it.scan_time, 3), HudPalette.LIGHT)
	_balloons(Rect2(split, ir.position.y, ir.end.x - split, ir.size.y))


func _card_name(p: Vector2, s: String, col := HudPalette.LIGHT) -> float:
	var f := HudPalette.tracked(HudPalette.DISPLAY, 20, 0.14)
	HudPalette.hud_text(_canvas, p, s.to_upper(), 20, col, f, 0, false)
	return f.get_string_size(s.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.legible(_canvas, 20)).x


func _chip(p: Vector2, s: String, bg: Color) -> void:
	var f := HudPalette.tracked(HudPalette.DISPLAY, 13, 0.1)
	var fs := HudPalette.legible(_canvas, 13)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_canvas.draw_rect(Rect2(p, Vector2(w + 12, fs + 7)), bg)
	HudPalette.hud_text(_canvas, p + Vector2(6, fs + 2), s, 13, HudPalette.LIGHT, f, 0, false)


## Fulton balloons left, inline in the item card: a balloon and the count, red at none, blinking light while one
## could go up now.
func _balloons(r: Rect2) -> void:
	var n: int = _operative.fultons
	var is_ready: bool = n > 0 and _operative.fulton_ready()
	var blink := is_ready and int(Time.get_ticks_msec() / 250.0) % 2 == 0
	var col := HudPalette.DMG if n == 0 else (HudPalette.LIGHT if blink else HudPalette.SAND)
	_sil(&"balloon", Vector2(r.position.x + 14, r.end.y - 10), 0.55, col)
	HudPalette.hud_text(_canvas, Vector2(r.end.x - 14, r.end.y - 14), str(n), 32, col, HudPalette.tracked(HudPalette.DISPLAY, 32, 0.04), 2, false)


## A short strip that grows leftward from the card it changes: icon and count only, the selected slot (white,
## larger) touching the card with its name in a tag above. Empty slots are dashed. Open for SELECT_TIME after the
## weapon or item changes; opens in six hard steps with a stagger per slot, fades out over its last 0.3 s.
func _selector(d: Vector2) -> void:
	if _select_left <= 0.0:
		return
	var a := clampf(_select_left / 0.3, 0.0, 1.0)
	var slots: Array = []  # [name key, silhouette, count, selected]
	if _select == "weapon":
		var g: Gun = _operative.gun()
		for pair in [[_operative.tranq, "ui.gear.tranq", &"tranq"], [_operative.rifle, "ui.gear.rifle", &"rifle"]]:
			var gun: Gun = pair[0]
			slots.append([pair[1], pair[2], "%d" % gun.loaded, gun == g])
	else:
		var it: Items = _operative.items
		slots.append(["ui.gear.scanner", &"scanner", str(it.charges), it.selected == Items.Kind.SCANNER])
		slots.append(["ui.gear.magazine", &"magazine", str(it.magazines), it.selected == Items.Kind.MAGAZINE])
	slots.sort_custom(func(first: Array, second: Array) -> bool: return first[3] and not second[3])  # the selected one first
	var card := _weapon_rect(d) if _select == "weapon" else _item_rect(d)
	var x := card.position.x - 6
	var line := Color(HudPalette.LIGHT, 0.16 * a)
	var step := floorf(clampf(_select_age / SELECT_WIPE, 0.0, 1.0) * 6.0) / 6.0  # the strip's wipe, outward from the card
	var reach := card.position.x - 6 - (step * 5.0 * 84.0)
	for i in 5:
		var s: Array = slots[i] if i < slots.size() else []
		var on: bool = not s.is_empty() and s[3]
		var w := 92.0 if on else 78.0
		var h := 112.0 if on else 98.0
		var r := Rect2(x - w, card.end.y - h, w, h)
		x -= w + 6
		if _select_age < i * SLOT_STAGGER or r.position.x < reach - 84.0:
			continue
		if s.is_empty():
			_dashed(r, Color(HudPalette.LIGHT, 0.14 * a))
			continue
		var ink := HudPalette.DARK_INK if on else HudPalette.LIGHT
		_canvas.draw_rect(r, Color(HudPalette.LIGHT, a) if on else Color(HudPalette.SMOKE, HudPalette.SMOKE.a * a))
		_canvas.draw_rect(r, Color(HudPalette.LIGHT, a) if on else line, false, 1.0)
		var gun_icon: bool = s[1] in [&"tranq", &"rifle"]
		var gs := (0.36 if on else 0.3) if gun_icon else (0.78 if on else 0.68)
		var isz := _sil_size(s[1], gs)
		_sil(s[1], Vector2(r.get_center().x - isz.x / 2, r.position.y + 14 + isz.y), gs, Color(ink, a))
		HudPalette.hud_text(_canvas, Vector2(r.end.x - 8, r.end.y - 8), s[2], 20, Color(ink, a), HudPalette.FIGURE, 2, false)
		if on:
			var f := HudPalette.tracked(HudPalette.LABEL_BOLD, 20, 0.14)
			var label_text := tr(s[0]).to_upper()
			var nw := f.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var tag := Rect2(r.end.x - nw - 24, r.position.y - 34, nw + 24, 28)
			_canvas.draw_rect(tag, Color(HudPalette.LIGHT, a))
			HudPalette.hud_text(_canvas, tag.position + Vector2(12, 21), label_text, 20, Color(HudPalette.DARK_INK, a), f, 0, false)


func _dashed(r: Rect2, col: Color) -> void:
	for edge in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), r.end], [r.position, Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), r.end]]:
		var from: Vector2 = edge[0]
		var to: Vector2 = edge[1]
		var n := int(from.distance_to(to) / 8.0)
		for k in n:
			if k % 2 == 0:
				_canvas.draw_line(from.lerp(to, float(k) / n), from.lerp(to, float(k + 1) / n), col, 1.0)


## The gear icons (assets/ui/icons/*.svg, white, designed in docs/ui-mock/icons.html): the SVG's own size, so `s`
## 1.0 is the size the shape was drawn at. The third value evens out the boxes so the weapons read at one scale.
const GEAR := {
	&"rifle": [preload("res://assets/ui/icons/rifle.svg"), Vector2(199.5, 59.5), 1.0],
	&"tranq": [preload("res://assets/ui/icons/tranq.svg"), Vector2(133, 63), 1.0],
	&"scanner": [preload("res://assets/ui/icons/scanner.svg"), Vector2(80, 72), 1.0],
	&"magazine": [preload("res://assets/ui/icons/magazine.svg"), Vector2(80, 72), 1.0],
	&"balloon": [preload("res://assets/ui/icons/balloon.svg"), Vector2(31.5, 78), 1.0],
}


## Drawn size of a gear icon at scale `s`.
func _sil_size(kind: StringName, s: float) -> Vector2:
	var g: Array = GEAR[kind]
	return g[1] * g[2] * s


## The gear icon `kind` with its bottom-left corner at `foot`.
func _sil(kind: StringName, foot: Vector2, s: float, col: Color) -> void:
	var sz := _sil_size(kind, s)
	_canvas.draw_texture_rect(GEAR[kind][0], Rect2(foot - Vector2(0, sz.y), sz), false, col)


func _keycap(p: Vector2, legend: String, small := false, a := 1.0) -> float:
	return HudPalette.keycap(_canvas, p, legend, small, a)
