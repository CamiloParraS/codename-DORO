## The in-game HUD (DESIGN.md), drawn by hand on `_canvas` in design px: 1080 tall, as wide as the window's
## aspect, scaled to the window and smoothly filtered. Corners: Aigis top-left, the phase plate top-centre, the
## Radar top-right, life bottom-left, item and weapon cards bottom-right (the selector opens beside them when
## either changes), the live call and radio lines middle-left, and the text-free action prompt lower-middle.
## Only the crosshair stays on the 640x360 logical canvas, so its
## pixel art keeps its grid. Lives on CanvasLayer 1 so the banding pass on layer 0 does not touch it.
extends Control

const FLASH_TIME := 1.0
const TICK_TIME := 6.0  # s a Habit Aigis just logged stays lit on the strip
const TIP_TIME := 6.0
const VP_SHOWN := 3  # Voiceprint names listed before "+n"
const SELECT_TIME := 1.4  # s the selector stays open after the last change
const SELECT_WIPE := 0.2  # s the strip takes to open, in 6 hard steps
const SLOT_STAGGER := 0.035
const SWEEP_SECS := 5.0  # s per turn of the Radar's sweep
const MINT := Color("8fd9c0")  # the live call card's tint
const LOST_HOLD := 0.4  # s the red lost segment waits after a hit
const LOST_DRAIN := 0.6  # life per second
const CALL := Vector2(64, 410)  # the live call card's corner
const CALL_W := 430.0
const FACE := 76.0
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


# --- the design-px layer ------------------------------------------------------------------------------

func _k() -> float:
	return size.y / HudPalette.DESIGN_H


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
	_subtitles(_live_call(dim), dim)
	_tutorial_tip(d)
	_prompt(d)


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


## Bottom-left: the stance figure over a 12x300 well with a continuous sand fill and the red lost segment.
func _life(d: Vector2) -> void:
	var c := _canvas
	var well := Rect2(64, d.y - 64 - 300, 12, 300)
	c.draw_rect(well, HudPalette.WELL)
	c.draw_rect(well, HudPalette.HAIRLINE, false, 1.0)
	var inner := well.grow(-2)
	c.draw_rect(Rect2(inner.position.x, inner.end.y - inner.size.y * _lost, inner.size.x, inner.size.y * _lost), HudPalette.DMG)
	c.draw_rect(Rect2(inner.position.x, inner.end.y - inner.size.y * life, inner.size.x, inner.size.y * life), HudPalette.SAND)
	_stance(Vector2(well.position.x + 6, well.position.y - 14))


## Standing or crouched, feet at `foot`.
func _stance(foot: Vector2) -> void:
	var h := 26.0 if _operative.crouching else 40.0
	var col := Color(HudPalette.LIGHT, 0.85)
	_canvas.draw_circle(foot + Vector2(0, -h + 4), 4.5, col)
	_canvas.draw_rect(Rect2(foot.x - 4, foot.y - h + 10, 8, h - 10), col)


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
	c.draw_circle(o, rad, HudPalette.SMOKE)
	c.draw_arc(o, rad, 0, TAU, 96, HudPalette.HAIRLINE, 1.5, true)
	for ring in [rad * 0.32, rad * 0.64]:
		c.draw_arc(o, ring, 0, TAU, 72, Color(HudPalette.SAND, 0.28), 1.0, true)
	for dir: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		c.draw_line(o + dir * (rad - 6), o + dir * (rad - 20), Color(HudPalette.SAND, 0.7), 2.0)
	HudPalette.hud_label(c, o + Vector2(8, -rad + 30), "N", 16, Color(HudPalette.SAND, 0.8), 0.06, HudPalette.LABEL, 0, false)
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
	var f := RadarModel.facing(_operative.global_basis)
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


## Top-centre: ALERT is a solid red plate with the timer behind a divider; EVASION a smoke plate edged in
## sand; CAUTION a quiet smoke plate. The word and the plate's shape carry the phase, not hue alone.
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
	var wf := HudPalette.tracked(HudPalette.LABEL_BOLD, 26, 0.4)
	var ww := wf.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	var tw := HudPalette.FIGURE.get_string_size(secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	var r := Rect2(0, 52, 24 + ww + 8 + 18 + tw + 22, 46)
	r.position.x = roundf((d.x - r.size.x) / 2)
	var alert: bool = ph[0] == "ALERT"
	var evasion: bool = ph[0] == "EVASION"
	for i in 3:  # the plate's lift
		c.draw_rect(Rect2(r.position + Vector2(0, 4), r.size).grow(2 + i * 4), Color(0, 0, 0, 0.1))
	if alert:  # two hard flickers on arrival, in step with the edge flash
		var lit: bool = _phase_age > 0.32 or int(_phase_age * 12.5) % 2 == 0
		c.draw_rect(r, HudPalette.DMG if lit else HudPalette.DMG.darkened(0.6))
	else:
		c.draw_rect(r, HudPalette.SMOKE_HI)
		c.draw_rect(r, HudPalette.SAND if evasion else HudPalette.HAIRLINE, false, 1.5 if evasion else 1.0)
	var ink := HudPalette.LIGHT if alert else (HudPalette.SAND if evasion else HudPalette.LIGHT_2)
	var x := r.position.x + 24
	HudPalette.hud_text(c, Vector2(x, r.position.y + 33), word, 26, ink, wf, 0, false)
	x += ww + 8
	c.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(ink, 0.45), 1.0)
	HudPalette.hud_text(c, Vector2(x + 18, r.position.y + 33), secs, 26, ink, HudPalette.FIGURE, 0, false)


## Top-left, from Mission 2 on: the Dominant Voice, then the six Habits with their 0-3 levels as pips. The one
## Aigis just logged against you is lit, with a cyan rise mark, for TICK_TIME.
func _aigis_cue() -> void:
	if _aigis <= 0.0 or _voice == "":
		return
	var c := _canvas
	var at := Vector2(64, 52)
	var eye := at + Vector2(13, 13)
	c.draw_arc(eye, 12, 0, TAU, 32, HudPalette.CYAN, 2.0, true)
	c.draw_arc(eye + Vector2(-4, -1), 3.2, 0, TAU, 16, HudPalette.CYAN, 2.0, true)
	c.draw_arc(eye + Vector2(4, -1), 3.2, 0, TAU, 16, HudPalette.CYAN, 2.0, true)
	HudPalette.hud_label(c, at + Vector2(36, 21), _voice, 22, Color(HudPalette.CYAN, 0.92), 0.26)
	var lit := _tick if _tick_age < TICK_TIME else ""
	for i in Aigis.HABITS.size():
		var h: String = Aigis.HABITS[i]
		var p := at + Vector2(i * 52, 40)
		var on := h == lit
		var col := Color(HudPalette.LIGHT, 1.0 if on else 0.62)
		HabitGlyphs.draw(c, h, p + Vector2(1, 1), Color(0, 0, 0, 0.5), 3.0)
		HabitGlyphs.draw(c, h, p, col, 3.0)
		if on:
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(36, -6), p + Vector2(41, 3), p + Vector2(31, 3)]), HudPalette.CYAN)
		for j in 3:
			var pip := Rect2(p + Vector2(3 + j * 10, 38), Vector2(8, 3))
			c.draw_rect(pip, HudPalette.SAND if j < int(_levels.get(h, 0)) else Color(HudPalette.LIGHT, 0.25))


## Bottom-right: the item card (with the Fulton balloons beside it) over the weapon card.
func _gear(d: Vector2) -> void:
	var xr := d.x - 64
	var yb := d.y - 64
	var gun: Gun = _operative.gun()
	var wr := Rect2(xr - 320, yb - 118, 320, 118)
	HudPalette.hud_panel(_canvas, wr)
	var name_w := _card_name(wr.position + Vector2(16, 30), tr("ui.gear.rifle" if gun == _operative.rifle else "ui.gear.tranq"))
	var chip := "LTH" if gun.lethal else "SLP"
	_chip(Vector2(wr.position.x + 16 + name_w + 8, wr.position.y + 14), chip, HudPalette.DMG if gun.lethal else HudPalette.SLP)
	_sil(&"rifle" if gun == _operative.rifle else &"tranq", wr.position + Vector2(16, 112), 0.72 if gun == _operative.rifle else 0.78, HudPalette.LIGHT)
	if gun.suppressor_max >= 0:  # shots left on the suppressor
		var sx := wr.position.x + 16
		HudPalette.hud_label(_canvas, Vector2(sx, wr.position.y + 54), "SUP", 13, HudPalette.LIGHT_3, 0.12, HudPalette.LABEL, 0, false)
		for i in gun.suppressor_max:
			var col := HudPalette.LIGHT if i < gun.suppressor else Color(HudPalette.LIGHT, 0.2)
			_canvas.draw_rect(Rect2(sx + 32 + i * 12, wr.position.y + 44, 9, 9), HudPalette.DMG if gun.suppressor <= 0 else col)
	var count := str(gun.loaded)
	var res := "/ %d" % gun.reserve
	var rw := HudPalette.FIGURE_MED.get_string_size(res, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	HudPalette.hud_text(_canvas, Vector2(wr.end.x - 16, wr.end.y - 14), res, 20, HudPalette.LIGHT if gun.reloading() else HudPalette.LIGHT_3, HudPalette.FIGURE_MED, 2, false)
	HudPalette.hud_text(_canvas, Vector2(wr.end.x - 16 - rw - 6, wr.end.y - 12), count, 46, HudPalette.DMG if gun.loaded == 0 else HudPalette.LIGHT, HudPalette.FIGURE, 2, false)
	var track := Rect2(wr.position.x + 16, wr.end.y + 12, wr.size.x - 32, 6)  # rounds left, loaded and reserve
	_canvas.draw_rect(track, Color(HudPalette.LIGHT, 0.22))
	var left := float(gun.loaded + gun.reserve) / maxf(gun.total, 1.0)
	_canvas.draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(left, 0.0, 1.0), track.size.y)), HudPalette.DMG if gun.loaded == 0 else HudPalette.LIGHT)
	var it: Items = _operative.items
	var ir := Rect2(xr - 220, wr.position.y - 12 - 84, 220, 84)
	HudPalette.hud_panel(_canvas, ir)
	var live: bool = it.scanning() or _operative.throwing
	_card_name(ir.position + Vector2(16, 30), tr("ui.gear.scanner" if it.selected == Items.Kind.SCANNER else "ui.gear.magazine"), HudPalette.LIGHT if live else HudPalette.SAND)
	_sil(&"scanner" if it.selected == Items.Kind.SCANNER else &"magazine", ir.position + Vector2(16, 76), 0.8, HudPalette.LIGHT)
	HudPalette.hud_text(_canvas, Vector2(ir.end.x - 16, ir.end.y - 12), str(it.count()), 34, HudPalette.DMG if it.count() == 0 else HudPalette.LIGHT, HudPalette.FIGURE, 2, false)
	if it.scanning():
		_canvas.draw_rect(Rect2(ir.position.x + 1, ir.end.y - 4, (ir.size.x - 2) * it.scan_left / it.scan_time, 3), HudPalette.SAND)
	if not (_select == "item" and _select_left > 0.0):  # the open strip takes the balloons' place
		_balloons(Rect2(xr - 320, ir.position.y, 88, 84))


func _card_name(p: Vector2, s: String, col := HudPalette.SAND) -> float:
	var f := HudPalette.tracked(HudPalette.LABEL, 19, 0.1)
	HudPalette.hud_text(_canvas, p, s.to_upper(), 19, col, f, 0, false)
	return f.get_string_size(s.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x


func _chip(p: Vector2, s: String, bg: Color) -> void:
	var f := HudPalette.tracked(HudPalette.LABEL_BOLD, 13, 0.1)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_canvas.draw_rect(Rect2(p, Vector2(w + 10, 18)), bg)
	HudPalette.hud_text(_canvas, p + Vector2(5, 14), s, 13, HudPalette.LIGHT, f, 0, false)


## Fulton balloons left: a balloon and the count, red at none, blinking light while one could go up now.
func _balloons(r: Rect2) -> void:
	HudPalette.hud_panel(_canvas, r)
	var n: int = _operative.fultons
	var ready: bool = n > 0 and _operative.fulton_ready()
	var blink := ready and int(Time.get_ticks_msec() / 250) % 2 == 0
	var col := HudPalette.DMG if n == 0 else (HudPalette.LIGHT if blink else HudPalette.SAND)
	_sil(&"balloon", r.position + Vector2(12, 70), 0.9, col)
	HudPalette.hud_text(_canvas, Vector2(r.end.x - 12, r.end.y - 14), str(n), 30, col, HudPalette.FIGURE, 2, false)


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
	slots.sort_custom(func(x: Array, y: Array) -> bool: return x[3] and not y[3])  # the selected one first
	var xr := d.x - 64
	var yb := d.y - 64
	var wr := Rect2(xr - 320, yb - 118, 320, 118)
	var card := wr if _select == "weapon" else Rect2(xr - 220, wr.position.y - 96, 220, 84)
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
		var big := 0.46 if on else 0.4
		_sil(s[1], r.get_center() + Vector2(0, 28 if s[1] in [&"tranq", &"rifle"] else 22) * (1.0 if on else 0.9) - Vector2(0, 8), big if s[1] in [&"scanner", &"magazine"] else big * 0.7, Color(ink, a))
		HudPalette.hud_text(_canvas, Vector2(r.end.x - 8, r.end.y - 8), s[2], 20, Color(ink, a), HudPalette.FIGURE, 2, false)
		if on:
			var f := HudPalette.tracked(HudPalette.LABEL_BOLD, 20, 0.14)
			var name := tr(s[0]).to_upper()
			var nw := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var tag := Rect2(r.end.x - nw - 24, r.position.y - 34, nw + 24, 28)
			_canvas.draw_rect(tag, Color(HudPalette.LIGHT, a))
			HudPalette.hud_text(_canvas, tag.position + Vector2(12, 21), name, 20, Color(HudPalette.DARK_INK, a), f, 0, false)


func _dashed(r: Rect2, col: Color) -> void:
	for edge in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), r.end], [r.position, Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), r.end]]:
		var from: Vector2 = edge[0]
		var to: Vector2 = edge[1]
		var n := int(from.distance_to(to) / 8.0)
		for k in n:
			if k % 2 == 0:
				_canvas.draw_line(from.lerp(to, float(k) / n), from.lerp(to, float(k + 1) / n), col, 1.0)


## The gear drawn as solid silhouettes, feet at `foot`, scaled by `s` and turned by `rot`.
func _sil(kind: StringName, foot: Vector2, s: float, col: Color, rot := 0.0) -> void:
	var polys: Array = []
	var cuts: Array = []  # dark detail lines over the silhouette
	match kind:
		&"tranq":  # 200 x 80
			polys = [[8, 18, 116, 18, 120, 14, 126, 14, 126, 18, 196, 18, 196, 30, 126, 30, 126, 34, 8, 34],
				[40, 34, 96, 34, 92, 40, 78, 40, 71, 45, 62, 74, 38, 74, 47, 40, 40, 40]]
			cuts = [[16, 20, 16, 30], [22, 20, 22, 30], [28, 20, 28, 30]]
		&"rifle":  # 240 x 80
			polys = [[4, 22, 40, 17, 60, 17, 60, 14, 150, 14, 150, 20, 186, 20, 186, 16, 236, 16, 236, 30, 186, 30, 186, 26, 150, 26, 150, 34, 112, 34, 118, 60, 100, 60, 94, 34, 76, 34, 70, 50, 56, 50, 60, 34, 40, 34, 4, 40],
				[92, 6, 124, 6, 124, 13, 92, 13]]
			cuts = [[66, 20, 66, 32], [196, 16, 196, 30], [212, 16, 212, 30]]
		&"scanner":  # 80 x 50
			polys = [[4, 14, 44, 14, 44, 40, 4, 40], [14, 40, 26, 40, 24, 48, 16, 48], [44, 18, 60, 8, 60, 46, 44, 36],
				[64, 12, 68, 12, 68, 42, 64, 42], [72, 8, 75, 8, 75, 46, 72, 46]]
			cuts = [[9, 22, 31, 22], [9, 27, 25, 27]]
		&"magazine":  # 60 x 50, lying down
			polys = [[4, 18, 44, 14, 52, 16, 54, 30, 46, 34, 6, 34]]
			cuts = [[14, 20, 14, 31], [24, 19, 24, 31], [34, 18, 34, 31]]
		&"balloon":  # 40 x 70
			var top := foot + Vector2(20, -52) * s
			_canvas.draw_circle(top, 15 * s, col)
			_canvas.draw_line(top + Vector2(0, 15 * s), foot + Vector2(20, -14) * s, col, 2.0)
			_canvas.draw_rect(Rect2(foot + Vector2(13, -14) * s, Vector2(14, 12) * s), col)
			return
	var h := 80.0 if kind in [&"tranq", &"rifle"] else 50.0
	for poly: Array in polys:
		var pts := PackedVector2Array()
		for i in range(0, poly.size(), 2):
			pts.append(foot + (Vector2(poly[i], poly[i + 1] - h) * s).rotated(rot))
		_canvas.draw_colored_polygon(pts, col)
	var cut := Color(HudPalette.DARK_INK, col.a * 0.9)
	for l: Array in cuts:
		_canvas.draw_line(foot + (Vector2(l[0], l[1] - h) * s).rotated(rot), foot + (Vector2(l[2], l[3] - h) * s).rotated(rot), cut, 2.0 * s)


func _keycap(p: Vector2, legend: String, small := false, a := 1.0) -> float:
	return HudPalette.keycap(_canvas, p, legend, small, a)


## Lower-middle, no text: per choice, the key (a held key gets a sand outline), then a round disc holding the
## action's pictogram. A move under way spins a sand arc round its disc; a barred one is struck through in red.
func _prompt(d: Vector2) -> void:
	var parts: Array = _operative.prompt_parts
	if parts.is_empty():
		return
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
	var top := 850.0
	for i in parts.size():
		var p: Dictionary = parts[i]
		var cx := x
		if p.action != "":
			var kw := _keycap(Vector2(cx, top + 17), Prompts.key(p.action))
			if p.hold:
				_canvas.draw_rect(Rect2(cx - 4, top + 13, kw + 8, 50), HudPalette.SAND_DIM, false, 2.0)
			cx += kw + 14
		var o := Vector2(cx + 38, top + 38)
		_canvas.draw_circle(o, 38, HudPalette.SMOKE_HI)
		_canvas.draw_arc(o, 38, 0, TAU, 64, HudPalette.HAIRLINE, 1.0, true)
		var col := HudPalette.LIGHT_3 if p.state == "warn" else HudPalette.LIGHT
		_pictogram(p.icon, o, col)
		if p.state == "busy":
			var spin := Time.get_ticks_msec() / 300.0
			_canvas.draw_arc(o, 42, spin, spin + 2.0, 24, HudPalette.SAND, 3.0, true)
		elif p.state == "warn":
			_canvas.draw_line(o + Vector2(-26, 26), o + Vector2(26, -26), HudPalette.DMG, 5.0, true)
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
	var frame := 1 if _live.typing() and int(Time.get_ticks_msec() / 160) % 2 == 0 else 0
	var tex := _portrait(who, frame)
	var tx := CALL.x + 12 + FACE + 16
	var full := HudPalette.wrap(_live.text(), CALL_W - (tx - CALL.x) - 18, HudPalette.FIGURE_MED, 24)
	var rows := mini(full.size(), 4)
	var box := Rect2(CALL, Vector2(CALL_W, maxf(FACE + 26, 62 + rows * 32)))
	c.draw_rect(box, Color(0.024, 0.035, 0.043, 0.74 * dim))
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
func _subtitles(top: float, dim: float) -> void:
	var y := top
	for l: Dictionary in _subs.lines:
		var a := Subtitles.alpha(l["age"]) * dim
		HudPalette.hud_label(_canvas, Vector2(CALL.x, y), _who(l["who"]), 15, Color(HudPalette.LIGHT_3, a), 0.16)
		y += 28
		for row in HudPalette.wrap(l["text"], CALL_W, HudPalette.FIGURE_MED, 22):
			HudPalette.hud_text(_canvas, Vector2(CALL.x, y), row, 22, Color(HudPalette.LIGHT_2, a), HudPalette.FIGURE_MED)
			y += 30
		y += 10


## Mission 1's tutorial line, centred under the phase plate.
func _tutorial_tip(d: Vector2) -> void:
	if _tip_left <= 0.0:
		return
	var a := clampf(_tip_left, 0.0, 1.0)
	var rows := HudPalette.wrap(_tip, 900, HudPalette.FIGURE_MED, 24)
	for i in rows.size():
		HudPalette.hud_text(_canvas, Vector2(d.x / 2, 150 + i * 34), rows[i], 24, Color(HudPalette.LIGHT, a), HudPalette.FIGURE_MED, 1)
