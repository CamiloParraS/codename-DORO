## The HUD's state and its corner pieces, drawn on `_canvas` in design px (hud.gd extends it and draws the middle):
## the alert flash, life, the Radar and Voiceprints, the phase plate, the Aigis cue, the gear cards and the selector.
extends Control

const FLASH_TIME := 1.0
const TICK_TIME := 6.0  # s a Habit Aigis just logged stays lit on the strip
const TIP_TIME := Tutorial.WAIT_MAX  # s a tip stays up waiting to be done (tip_done fades it sooner)
const TIP_OUT := 0.3  # s a done tip takes to fade
const TIP_PAD := Vector2(26, 8)  # the tip's plate round its rows, design px
const TIP_PLATE := 0.92  # the steps' glass at its edge (the Aigis cue's), so the tip reads over the lit deck and the fog
const TIP_SPACE := 10.0  # between a tip's words and keys
const TIP_GAP := 34.0  # between a tip's steps (a double space in its text)
const TIP_W := 560.0  # the widest row of a tip's steps in the top-left corner
const VP_SHOWN := 3  # Voiceprint names listed before "+n"
const SELECT_TIME := 1.4  # s the selector stays open after the last change
const SELECT_WIPE := 0.2  # s the strip takes to open, in 6 hard steps
const SLOT_STAGGER := 0.035
const SWEEP_SECS := 5.0  # s per turn of the Radar's sweep
const MINT := HudPalette.MINT  # the live call card's tint
const WEAPON_FADE := 18  # dither pixels in the weapon card's fade, longer than the other plates'
const WEAPON_INSET := 76.0  # px the weapon card's content starts in from its edge
const LIFE_CUT := 10  # pixels the life gauge's top-right and bottom-left corners are cut by
const LOST_HOLD := 0.4  # s the red lost segment waits after a hit
const LOST_DRAIN := 0.6  # life per second
const CALL := Vector2(64, 410)  # the live call card's corner
const CALL_W := 700.0
const CALL_GAP := 28.0  # px of air between the Voiceprints plate and the live call card
const FACE := 88.0
const HABIT_W := 56.0  # px per Habit column on the Aigis cue
const SUB_W := 1000.0  # subtitles and tips: centred, lower middle
const SUB_BOTTOM := 1010.0  # near the bottom edge; the action prompt sits above it
const PORTRAIT := "res://ui/codec/portraits/%s_%d.png"

var vp_bottom := 0.0  # where the Voiceprints plate ends (0 with none): the live call card keeps CALL_GAP below it
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
var _tip_title := ""   # the tip's verb, on its sand slab
var _tip_left := 0.0
var _live: CodecCall  # the live Codec call in progress, if any
var _call_age := 0.0  # s the live call card has been up, for its slide-in
var _call_out := -1.0  # s since the last line finished (the card slides out); -1 while the call runs
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


## Bottom-left: a labelled gauge as wide as its label, 70 px from the edges: ink fill, the red lost segment behind it,
## a pixel frame, cut corners, quarter ticks and the percentage underneath. Under a quarter of life the fill and the number go red and blink.
func _life(d: Vector2) -> void:
	var c := _canvas
	var label_w := HudPalette.tracked(HudPalette.LABEL, 16, 0.2).get_string_size(tr("ui.hud.life").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.legible(c, 16)).x
	var px := 3.0  # the gauge is a grid of 3 px pixels
	var cols := roundi(label_w / px)  # as wide as the label above it
	var rows := 113
	var well := Rect2(70, d.y - 70 - rows * px, cols * px, rows * px)
	var low := life < 0.25
	var warn := low and int(Time.get_ticks_msec() / 300.0) % 2 == 0
	HudPalette.plate(c, well.grow_individual(8, 8, HudPalette.FADE_W + 24, 8), HudPalette.GLASS, 0.35, 0.92, false, LIFE_CUT * px + 14.0, HudPalette.DITHER_BAND, HudPalette.FADE_W)  # the top-right slant runs the whole dithered band: ~30 degrees
	var full := smoothstep(0.96, 1.0, life)  # at full life the fill takes a faint green hue
	var ink := HudPalette.LIGHT.lerp(HudPalette.FULL_GREEN, 0.16 * full)
	var edge := Color(HudPalette.LIGHT, 0.7)
	# One pixel row at a time, but rows that repeat the one above (same columns, same colour) merge into one
	# taller rect: the same pixels in a fraction of the draws. Rows never overlap, so each layer can go in turn.
	var ground: Array = []  # each a run: [first row, row count, x0, width, colour] in gauge pixels
	var lefts: Array = []
	var rights: Array = []
	var fills: Array = []
	for i in rows:  # top-right and bottom-left corners are cut on a stair, like the menu plates' slant
		var x0 := maxi(0, LIFE_CUT - (rows - 1 - i))
		var x1 := cols - maxi(0, LIFE_CUT - i)
		_row_run(ground, i, x0, x1 - x0, Color(0.0, 0.0, 0.0, 0.4))
		if i == 0 or i == rows - 1:
			_row_run(fills, i, x0, x1 - x0, edge)  # the top and bottom frame rows
			continue
		_row_run(lefts, i, x0, 1, edge)
		_row_run(rights, i, x1 - 1, 1, edge)
		if i < 2 or i > rows - 3:
			continue
		var frac := (rows - 2.5 - i) / (rows - 4)  # how far up the gauge this row is
		var col := HudPalette.DMG if frac <= _lost and frac > life else (HudPalette.DMG if warn else ink) if frac <= life else Color(0, 0, 0, 0)
		if col.a > 0.0:
			_row_run(fills, i, x0 + 2, x1 - x0 - 4, col)
	for runs: Array in [ground, lefts, rights, fills]:
		for r: Array in runs:
			c.draw_rect(Rect2(well.position.x + r[2] * px, well.position.y + r[0] * px, r[3] * px, r[1] * px), r[4])
	for q in [0.25, 0.5, 0.75]:
		var ty: float = well.end.y - well.size.y * q
		c.draw_line(Vector2(well.end.x + 4, ty), Vector2(well.end.x + 12, ty), Color(HudPalette.LIGHT, 0.55), 1.0)
	HudPalette.hud_label(c, Vector2(well.position.x, well.position.y - 14), tr("ui.hud.life"), 16, HudPalette.LIGHT_2, 0.2, HudPalette.LABEL, 0)
	HudPalette.hud_text(c, Vector2(well.position.x - 2, well.end.y + 28), "%d" % roundi(life * 100.0), 24, HudPalette.DMG if low else ink, HudPalette.tracked(HudPalette.DISPLAY, 24, 0.04), 0, true)


## Row `i` of a pixel gauge (columns x0 to x0 + w, colour col) onto `runs`: it extends the last run when it
## carries straight on from it, else starts a new one.
func _row_run(runs: Array, i: int, x0: int, w: int, col: Color) -> void:
	if not runs.is_empty():
		var last: Array = runs.back()
		if last[0] + last[1] == i and last[2] == x0 and last[3] == w and last[4] == col:
			last[1] += 1
			return
	runs.append([i, 1, x0, w, col])


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
	var dashes := PackedVector2Array()  # the dashed cross, as one draw; the arms only meet in the middle, where no dash falls
	for dir: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		for n in 25:
			dashes.append_array([o + dir * (n * 6.0 + 4.0), o + dir * (n * 6.0 + 7.0)])
	c.draw_multiline(dashes, Color(HudPalette.LIGHT, 0.25), 1.0)
	for dir: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:  # edge ticks, over the dashes they cross
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
		var lv := RadarModel.level(g.global_position.y - _operative.global_position.y)
		var at := o + RadarModel.blip(off, 10)
		if lv == 0:
			_triangle(at, RadarModel.facing(g.global_basis), 9.0, Color(col, a))
		else:  # another floor: hollow, fainter, with a caret for up or down (playtest 1: "a guard right here" wasn't)
			_triangle(at, RadarModel.facing(g.global_basis), 9.0, Color(col, a * 0.6), true)
			_floor_caret(at, lv, Color(col, a * 0.8))
	var ring := RadarModel.ping_radius(_operative.ping_range, _operative.ping_age)
	if ring > 0.0:
		c.draw_arc(o, ring, 0, TAU, 72, Color(HudPalette.LIGHT, 1.0 - _operative.ping_age / RadarModel.PING_TIME), 2.0, true)
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	for b: Dictionary in (run.radar_blips() if run else []):
		var boff := RadarModel.flat(b.pos) - origin
		var p := o + RadarModel.blip(boff, 12)
		if boff.length() > RadarModel.RANGE:  # off the disc: an arrow on the rim pointing at it (a pinned diamond slid round the rim as he moved)
			var out := boff.normalized()
			var tip := o + out * (rad - 4.0)
			HudPalette.px_poly(c, PackedVector2Array([tip, tip - out * 16.0 + out.orthogonal() * 9.0, tip - out * 11.0, tip - out * 16.0 - out.orthogonal() * 9.0]), HudPalette.LIGHT if b.target else HudPalette.LIGHT.lerp(HudPalette.GOLD, 0.3))
		elif b.target:
			HudPalette.px_ring(c, p, 12, 3, HudPalette.LIGHT)
			HudPalette.px_ring(c, p, 4, 0, HudPalette.LIGHT)
		else:
			var diamond := PackedVector2Array([p + Vector2(0, -12), p + Vector2(12, 0), p + Vector2(0, 12), p + Vector2(-12, 0)])
			var gold := HudPalette.LIGHT.lerp(HudPalette.GOLD, 0.3)  # white with a slight gold hue
			var lv := RadarModel.level(b.pos.y - _operative.global_position.y)
			if lv == 0:
				HudPalette.px_poly(c, diamond, gold)
			else:
				c.draw_polyline(diamond + PackedVector2Array([diamond[0]]), gold, 2.5)
				_floor_caret(p, lv, gold, 16.0)
	var f := RadarModel.facing(_operative.look_basis)
	var arrow := PackedVector2Array([o + f * 17, o + f.rotated(2.55) * 14, o - f * 5, o + f.rotated(-2.55) * 14])
	var rim := Geometry2D.offset_polygon(arrow, 2.5, Geometry2D.JOIN_MITER)  # a dark pixel rim round the sand arrow
	if not rim.is_empty():
		HudPalette.px_poly(c, rim[0], HudPalette.DARK_INK)
	HudPalette.px_poly(c, arrow, HudPalette.SAND)


## A guard on the Radar: a triangle pointing along `face`; `hollow` for one on another floor.
func _triangle(p: Vector2, face: Vector2, s: float, col: Color, hollow := false) -> void:
	var tri := PackedVector2Array([p + face * s * 1.2, p + face.rotated(2.4) * s, p + face.rotated(-2.4) * s])
	if hollow:
		_canvas.draw_polyline(tri + PackedVector2Array([tri[0]]), col, 2.0)
	else:
		HudPalette.px_poly(_canvas, tri, col)


## A caret beside a blip on another floor: above it pointing up for a floor above (`level` 1), below pointing down.
func _floor_caret(p: Vector2, level: int, col: Color, gap := 13.0) -> void:
	var tip := p + Vector2(0, -gap - 5.0) * level
	var back := Vector2(0, 5.0) * level
	_canvas.draw_polyline(PackedVector2Array([tip + back + Vector2(-5, 0), tip, tip + back + Vector2(5, 0)]), col, 2.0)


## The jammed Radar: dark red ground, red ordered-dither static that swells and crumbles toward the rim, 2 px dark bands every 6 px rolling down, a red rim, JAMMED.
func _jammed(o: Vector2, rad: float) -> void:
	var c := _canvas
	c.draw_circle(o, rad, HudPalette.JAM)
	var px := HudPalette.DITHER_PX
	var beat := Time.get_ticks_msec()
	var shift := int(beat / 110.0)  # the pattern shuffles fast: dead air
	var dens := 0.36 + 0.2 * sin(beat / 520.0)  # the static swells and thins
	var edge := rad - 3.0
	for gy in range(floori((o.y - edge) / px), ceili((o.y + edge) / px)):
		for gx in range(floori((o.x - edge) / px), ceili((o.x + edge) / px)):
			var cell := Vector2((gx + 0.5) * px, (gy + 0.5) * px)
			var dist := cell.distance_to(o)
			if dist > edge:
				continue
			var rim := clampf((edge - dist) / (px * 4.0), 0.0, 1.0)  # thins out toward the rim: crumbling away
			if (HudPalette.BAYER[((gy + shift) & 3) * 4 + ((gx + shift * 3) & 3)] + 0.5) / 16.0 < dens * rim:
				c.draw_rect(Rect2(gx * px, gy * px, px, px), Color(HudPalette.DMG, 0.55))
	var y := -rad + fmod(Time.get_ticks_msec() / 50.0, 6.0)
	while y < rad:
		var half := sqrt(maxf(rad * rad - y * y, 0.0))
		c.draw_line(o + Vector2(-half, y), o + Vector2(half, y), Color(0, 0, 0, 0.35), 2.0)
		y += 6.0
	c.draw_arc(o, rad, 0, TAU, 96, Color(HudPalette.DMG, 0.7), 1.5, true)
	HudPalette.hud_label(c, o + Vector2(0, 7), tr("ui.hud.jammed"), 20, HudPalette.LIGHT, 0.32, HudPalette.LABEL_BOLD, 1)


## Held Voiceprints, top-left: under the Aigis cue's plate while the cue shows, up in the cue's own place while it
## doesn't (Mission 1, or the radio open), and below the tutorial tip's corner while one is up. Left-aligned; past
## VP_SHOWN, a "+n".
func _voiceprints(d: Vector2, cue_shown: bool) -> void:
	var held: Array = _operative.voiceprints.held
	vp_bottom = 0.0
	if held.is_empty():  # a bare "VP" with nothing under it is noise
		return
	var x := 70.0
	var y := 56.0 + 14.0
	if cue_shown:
		y += 100.0 + 22.0  # the cue's plate ends at 142; leave a gap
	elif _tip_left > 0.0:
		y = 330.0
	var rows: Array = held.slice(0, VP_SHOWN).map(func(n: String) -> String: return n)
	if held.size() > VP_SHOWN:
		rows.append("+%d" % (held.size() - VP_SHOWN))
	var plate := Rect2(x - 16, y - 22, 164 + HudPalette.FADE_W, 24 + 22 * rows.size() + 14)  # smoke behind the names: they sit over any sky
	vp_bottom = plate.end.y
	HudPalette.plate(_canvas, plate, HudPalette.GLASS, 0.35, 0.9, false)
	HudPalette.hud_label(_canvas, Vector2(x, y), tr("ui.hud.vp"), 15, HudPalette.LIGHT_2, 0.16, HudPalette.LABEL, 0)
	for i in rows.size():
		HudPalette.hud_label(_canvas, Vector2(x, y + 24 + 22 * i), rows[i], 17, HudPalette.LIGHT_2, 0.12, HudPalette.LABEL, 0)


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
	var plate := Rect2(at + Vector2(-16, -14), Vector2(6 * HABIT_W + 20 + HudPalette.FADE_W, 100))  # a smoke plate: the cue reads on a white wall too
	HudPalette.plate(c, plate, HudPalette.GLASS, 0.35 * e, 0.92 * e, false)  # no frame: the cyan inside says Aigis
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
	return Rect2(d.x - 70 - 450, d.y - 84 - 150, 450, 150)


func _item_rect(d: Vector2) -> Rect2:
	var wr := _weapon_rect(d)
	return Rect2(wr.position.x, wr.position.y - 8 - 80, wr.size.x, 80)


## A card: a borderless smoke plate that rises in opacity toward the screen edge and dithers away on its inner side.
func _card(r: Rect2, cells := HudPalette.DITHER_BAND) -> void:
	HudPalette.plate(_canvas, r, HudPalette.GLASS, 0.35, 0.92, true, 0.0, cells)


## Bottom-right: the item card (with the Fulton balloons beside it) over the weapon card and its rounds bar.
func _gear(d: Vector2) -> void:
	var gun: Gun = _operative.gun()
	var wr := _weapon_rect(d)
	_card(wr, WEAPON_FADE)
	wr = Rect2(wr.position.x + WEAPON_INSET, wr.position.y, wr.size.x - WEAPON_INSET, wr.size.y)  # the content sits clear of the fade
	var name_w := _card_name(wr.position + Vector2(20, 34), tr("ui.gear.rifle" if gun == _operative.rifle else "ui.gear.tranq"))
	var chip := "LTH" if gun.lethal else "SLP"
	_chip(Vector2(wr.position.x + 20 + name_w + 8, wr.position.y + 13), chip, HudPalette.DMG if gun.lethal else HudPalette.SLP)
	_sil(&"rifle" if gun == _operative.rifle else &"tranq", wr.position + Vector2(42, 134), 1.0, HudPalette.LIGHT)
	if gun.suppressor_max >= 0:  # shots left on the suppressor
		var sx := wr.position.x + 20
		for i in gun.suppressor_max:
			var col := HudPalette.LIGHT if i < gun.suppressor else Color(HudPalette.LIGHT, 0.2)
			_canvas.draw_rect(Rect2(sx + i * 12, wr.position.y + 44, 9, 9), HudPalette.DMG if gun.suppressor <= 0 else col)
	var count := str(gun.loaded)
	var res := " / %d" % gun.reserve
	var cf := HudPalette.tracked(HudPalette.DISPLAY, 50, 0.04)
	var rf := HudPalette.DISPLAY
	var rw := rf.get_string_size(res, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	HudPalette.hud_text(_canvas, Vector2(wr.end.x - 16, wr.end.y - 12), res, 24, HudPalette.LIGHT if gun.reloading() else HudPalette.LIGHT_3, rf, 2, false)
	var flash := gun.dry > 0.0 and int(gun.dry / 0.1) % 2 == 0  # a pull on an empty gun blinks the count
	HudPalette.hud_text(_canvas, Vector2(wr.end.x - 16 - rw, wr.end.y - 12), count, 50, HudPalette.LIGHT if flash else HudPalette.DMG if gun.loaded == 0 else HudPalette.LIGHT, cf, 2, false)
	if gun.reloading() or gun.loaded == 0:  # say it in words: RELOADING, or EMPTY with nothing left to load
		var word := tr("ui.hud.reloading" if gun.reloading() else "ui.hud.empty")
		HudPalette.hud_label(_canvas, Vector2(wr.end.x - 16, wr.position.y + 34), word, 16, HudPalette.LIGHT if gun.reloading() else HudPalette.DMG, 0.16, HudPalette.LABEL_BOLD, 2)
	if gun.reloading():
		_canvas.draw_rect(Rect2(wr.position.x, wr.end.y - 4, wr.size.x * (1.0 - gun.reload_left / Gun.RELOAD_TIME), 4), HudPalette.LIGHT)
	var track := Rect2(wr.position.x + 20, wr.end.y + 12, wr.size.x - 20, 6)  # rounds left, loaded and reserve
	_canvas.draw_rect(track, Color(HudPalette.LIGHT, 0.22))
	var left := float(gun.loaded + gun.reserve) / maxf(gun.total, 1.0)
	_rounds = lerpf(_rounds, left, 1.0 - exp(-get_process_delta_time() * 14.0))
	_canvas.draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(_rounds, 0.0, 1.0), track.size.y)), HudPalette.DMG if gun.loaded == 0 else HudPalette.LIGHT)
	var it: Items = _operative.items
	var ir := _item_rect(d)
	_card(ir, WEAPON_FADE)  # the same dithered width as the weapon card
	ir = Rect2(ir.position.x + WEAPON_INSET, ir.position.y, ir.size.x - WEAPON_INSET, ir.size.y)
	var live: bool = it.scanning() or _operative.throwing
	var split := ir.end.x - 108.0  # the item on the left, the Fulton balloons on the right
	var scanner: bool = it.selected == Items.Kind.SCANNER
	_sil(&"scanner" if scanner else &"magazine", Vector2(ir.position.x + 50, ir.end.y - 10), 0.92 if scanner else 0.68, HudPalette.LIGHT if live else Color(HudPalette.LIGHT, 0.86))
	_card_name(ir.position + Vector2(112, 46), tr("ui.gear.scanner" if scanner else "ui.gear.magazine"), HudPalette.LIGHT)
	HudPalette.hud_text(_canvas, Vector2(split - 14, ir.end.y - 18), str(it.count()), 34, HudPalette.DMG if it.count() == 0 else HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 34, 0.04), 2, false)
	_canvas.draw_line(Vector2(split, ir.position.y + 10), Vector2(split, ir.end.y - 10), Color(HudPalette.LIGHT, 0.25), 1.0)
	if it.scanning():
		_canvas.draw_rect(Rect2(ir.position.x, ir.end.y - 4, ir.size.x * it.scan_left / it.scan_time, 4), HudPalette.LIGHT)
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
	_sil(&"balloon", Vector2(r.position.x + 14, r.end.y - 14), 0.6, col)
	HudPalette.hud_text(_canvas, Vector2(r.end.x - 16, r.end.y - 18), str(n), 34, col, HudPalette.tracked(HudPalette.DISPLAY, 34, 0.04), 2, false)


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
	var x := card.position.x - 6 - 24.0  # clear of the card's dithered edge
	var step := floorf(clampf(_select_age / SELECT_WIPE, 0.0, 1.0) * 6.0) / 6.0  # the strip's wipe, outward from the card
	var reach := card.position.x - 6 - 24.0 - (step * slots.size() * 92.0)
	for i in slots.size():
		var s: Array = slots[i]
		var on: bool = s[3]
		var w := 90.0 if on else 76.0
		var h := 116.0 if on else 100.0
		var r := Rect2(x - w, card.end.y - h, w, h)
		x -= w + 6
		if _select_age < i * SLOT_STAGGER or r.position.x < reach - 92.0:
			continue
		var ink := HudPalette.DARK_INK if on else HudPalette.LIGHT
		if on:
			_canvas.draw_rect(r, Color(HudPalette.LIGHT, a))
		else:
			HudPalette.plate(_canvas, r, HudPalette.GLASS, 0.35 * a, 0.92 * a)
		if s[1] in [&"tranq", &"rifle"]:  # guns stand on end, muzzle up
			var gs := 0.4 if on else 0.34
			_sil_up(s[1], r.get_center() + Vector2(0, -8), gs, Color(ink, a))
		else:
			var gs := 0.78 if on else 0.68
			var isz := _sil_size(s[1], gs)
			_sil(s[1], Vector2(r.get_center().x - isz.x / 2, r.position.y + 14 + isz.y), gs, Color(ink, a))
		HudPalette.hud_text(_canvas, Vector2(r.end.x - 8, r.end.y - 8), s[2], 22, Color(ink, a), HudPalette.FIGURE, 2, false)
		if on:
			var f := HudPalette.tracked(HudPalette.LABEL_BOLD, 20, 0.14)
			var label_text := tr(s[0]).to_upper()
			var nw := f.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var tag := Rect2(r.end.x - nw - 24, r.position.y - 34, nw + 24, 28)
			_canvas.draw_rect(tag, Color(HudPalette.LIGHT, a))
			HudPalette.hud_text(_canvas, tag.position + Vector2(12, 21), label_text, 20, Color(HudPalette.DARK_INK, a), f, 0, false)


## The gear icons (assets/ui/icons/*.svg, white, designed in docs/ui-mock/icons.html): the SVG's own size, so `s`
## 1.0 is the size the shape was drawn at. The third value evens out the boxes so the weapons read at one scale.
const GEAR := {
	&"rifle": [preload("res://assets/ui/icons/rifle.svg"), Vector2(199.5, 59.5), 1.0],
	&"tranq": [preload("res://assets/ui/icons/tranq.svg"), Vector2(133, 63), 1.0],
	&"scanner": [preload("res://assets/ui/icons/scanner.svg"), Vector2(52.5, 71.75), 1.0],
	&"magazine": [preload("res://assets/ui/icons/magazine.svg"), Vector2(63, 72), 1.0],
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


## The gear icon `kind` turned a quarter-turn so its muzzle points up, centred on `at`.
func _sil_up(kind: StringName, at: Vector2, s: float, col: Color) -> void:
	var sz := _sil_size(kind, s)
	var k := _k()  # the canvas draws in design px under this scale (hud.gd)
	_canvas.draw_set_transform(at * k, -PI / 2.0, Vector2(k, k))
	_canvas.draw_texture_rect(GEAR[kind][0], Rect2(-sz / 2.0, sz), false, col)
	_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))


func _keycap(p: Vector2, legend: String, small := false, a := 1.0) -> float:
	return HudPalette.keycap(_canvas, p, legend, small, a)
