## HUD E (Peace Walker side strips) on a 640x360 logical canvas, drawn by hand: detection arcs around
## the screen centre, red edge flash on alert, ALERT/EVASION strip with stance and empty item/weapon
## cards on the right, life bar on the left, voiceprints top-right. Lifted from the PSX look prototype.
## Lives on CanvasLayer 1 so the banding pass on layer 0 does not touch it.
extends Control

const PIP_COLUMN := 48.0  # px tall, weapon card
const SUPPRESSOR_Y := 80  # px down the weapon card
const RESERVE_Y := 92
const RING := 96.0
const FLASH_TIME := 1.0

var life := 1.0  # the Operative's Health.life(), refreshed each frame
var _flash := 0.0
var _phase_name := ""  # last phase drawn, to time the chip's entrance
var _phase_age := 0.0
var _aigis := 0.0  # HudModel.aigis_weight: how awake Aigis is, 0 in Mission 1
var _voice := ""  # the Dominant Voice, shown once _aigis > 0
var _tick := ""  # habit just flagged to Aigis's profile
var _tick_age := 99.0
var _prev_counts := {}
var _run_seen := false  # the first read only takes a baseline, so old events never tick
const TICK_TIME := 2.0
const LINE := 14.0  # px between lines of running text (VT323 16)
const VP_SHOWN := 3  # Voiceprint names listed before "+n"
const TIP_TIME := 6.0
const ICON := int(HabitGlyphs.SIZE)  # px
const ICON_STEP := 14
var _was_alert := {}  # guard -> was in ALERT last frame
var _font := HudPalette.HEADING
var _digits := HudPalette.BODY  # VT323, the big numbers and running text
var _crosshairs := {}  # file name -> texture
var _operative: Node3D
var _subs := Subtitles.new()
var _tip := ""         # Mission 1's tutorial prompt (call_group "tutorial_tip"), TIP_TIME seconds
var _tip_left := 0.0
var _live: CodecCall  # the live Codec call in progress, if any


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("radio_log")
	add_to_group("codec_live")
	add_to_group("tutorial_tip")


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	_phase_age += delta
	_tick_age += delta
	_read_run()
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
	queue_redraw()


func _draw() -> void:
	if _flash > 0.0:
		var c := Color(HudPalette.DANGER, _flash * _flash * 0.8)  # squared: hits hard, then eases out
		var w := 8.0
		draw_rect(Rect2(0, 0, size.x, w), c)
		draw_rect(Rect2(0, size.y - w, size.x, w), c)
		draw_rect(Rect2(0, 0, w, size.y), c)
		draw_rect(Rect2(size.x - w, 0, w, size.y), c)
	if not _operative:
		return
	life = _operative.health.life()
	var cam: Camera3D = _operative.camera
	var fwd := Vector3(-cam.global_basis.z.x, 0, -cam.global_basis.z.z).normalized()
	var right := Vector3(cam.global_basis.x.x, 0, cam.global_basis.x.z).normalized()
	_arcs(fwd, right)
	if _operative.aiming:  # shots leave from the screen centre
		var tex := _crosshair(_operative.gun().crosshair)
		draw_texture(tex, (size / 2 - tex.get_size() / 2).round())
	_left()
	_radar()
	_right()
	_phase()
	_aigis_layer()
	_voiceprints()
	var radio := get_tree().get_first_node_in_group("radio")
	var dim := 0.3 if radio and radio.menu else 1.0  # the radial owns the screen while it is open
	var top := _live_call(_subtitles(size.y - 10.0, dim), dim)
	if _tip_left > 0.0:
		var tip := HudPalette.wrap(_tip, HudPalette.COLUMN, _font, 8)
		for i in tip.size():
			HudPalette.centered(self, size.x / 2, 60 + i * 12, tip[i], Color(HudPalette.WHITE, clampf(_tip_left, 0.0, 1.0)))
	if _operative.prompt != "":
		HudPalette.centered(self, size.x / 2, minf(top - 10.0, size.y - 60), _operative.prompt, HudPalette.WHITE)


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


## Peace Walker style: the CALL bar, then the line wrapped to the column, stacked above the radio lines
## whose top is `bottom`. Returns the block's top. The whole line is wrapped, so the typed text never
## reflows as it types on.
func _live_call(bottom: float, dim: float) -> float:
	if not _live:
		return bottom
	var x := size.x / 2 - HudPalette.COLUMN / 2
	var full := HudPalette.wrap(_live.text(), HudPalette.COLUMN)
	var left := _live.shown().length()
	var y := bottom - LINE * full.size()
	var top := y - 3
	_t(Vector2(x, top), tr("ui.hud.call") + " " + _live.speaker_name(), Color(HudPalette.CHROME, dim))
	for l in full:
		y += LINE
		_body(Vector2(x, y - 4), l.left(maxi(left, 0)), Color(HudPalette.WHITE, dim))
		left -= l.length() + 1
	return top - 14


## The last radio lines, each wrapped to the column and centred, the newest at the bottom; the speaker
## as a dim prefix. Returns the stack's top.
func _subtitles(bottom: float, dim: float) -> float:
	var y := bottom
	for k in range(_subs.lines.size() - 1, -1, -1):
		var l: Dictionary = _subs.lines[k]
		var a := Subtitles.alpha(l["age"]) * dim
		var who := _who(l["who"]) + ": "
		var rows := HudPalette.wrap(who + l["text"], HudPalette.COLUMN)
		y -= LINE * rows.size()
		for i in rows.size():
			var w := _digits.get_string_size(rows[i], HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.BODY_SIZE).x
			var p := Vector2(roundf(size.x / 2 - w / 2), y + LINE * (i + 1) - 4)
			if i == 0 and rows[0].begins_with(who):
				_body(p, who, Color(HudPalette.CHROME_DIM, a * HudPalette.CHROME_DIM.a))
				p.x += _digits.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.BODY_SIZE).x
				_body(p, rows[0].substr(who.length()), Color(HudPalette.CHROME, a))
			else:
				_body(p, rows[i], Color(HudPalette.CHROME, a))
		y -= 4
	return y


## A speaker's subtitle name: guards by name, the radio voices (HQ, METIS, INTEL) translated.
func _who(who: String) -> String:
	var k := "ui.who." + who.to_lower()
	var n := tr(k)
	return who.to_upper() if n == k else n


func _read_run() -> void:
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	if not run:
		_aigis = 0.0
		return
	_aigis = HudModel.aigis_weight(run.record.mission, Aigis.lethality_ratio(run.record))
	_voice = str(run.plan.get("dominant", "")).to_upper()
	var risen := HudModel.habits_risen(_prev_counts, run.tally.counts) if _run_seen else []
	_run_seen = true
	_prev_counts = run.tally.counts.duplicate()
	if _aigis > 0.0 and not risen.is_empty():
		_tick = str(risen[0]).to_upper()
		_tick_age = 0.0


## Aigis's corner, top right: the Dominant Voice, and a strip of the six Habit glyphs with the one it just
## logged against you lit.
func _aigis_layer() -> void:
	if _aigis <= 0.0 or _voice == "":
		return
	var x := size.x - 8 - _voice.length() * 8.0
	var a := lerpf(0.75, 1.0, _aigis)  # floored: it must read on the Annex's pale sky
	_t(Vector2(x, 18), _voice, Color(HudPalette.AIGIS, a))
	if _tick_age >= TICK_TIME:
		return
	var fade := 1.0 if _tick_age < 1.5 else (TICK_TIME - _tick_age) / 0.5
	var pulse := _tick_age < 0.12  # hard white pulse on arrival
	var x0 := size.x - 8 - Aigis.HABITS.size() * ICON_STEP + (ICON_STEP - ICON)
	for i in Aigis.HABITS.size():
		var h: String = Aigis.HABITS[i]
		var hit := h == _tick.to_lower()
		var col := HudPalette.WHITE if hit and pulse else (HudPalette.AIGIS if hit else HudPalette.CHROME_DIM)
		col.a *= fade if hit else fade * 0.75
		var at := Vector2(x0 + i * ICON_STEP, 32)
		for o in [Vector2(1, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]:  # the text's outline, on the glyphs
			HabitGlyphs.draw(self, h, at + o, Color(HudPalette.INK, col.a))
		HabitGlyphs.draw(self, h, at, col)
	var s := "+" + _tick
	_t(Vector2(size.x - 8 - s.length() * 8.0, 56), s, Color(HudPalette.AIGIS, fade))


## Held Voiceprints under Aigis's corner, right-aligned to the edge; past VP_SHOWN, a "+n".
func _voiceprints() -> void:
	var held: Array = _operative.voiceprints.held
	if held.is_empty():  # a bare "VP" with nothing under it is noise
		return
	var rows: Array = [tr("ui.hud.vp")]
	rows.append_array(held.slice(0, VP_SHOWN).map(func(n: String) -> String: return n.to_upper()))
	if held.size() > VP_SHOWN:
		rows.append("+%d" % (held.size() - VP_SHOWN))
	for i in rows.size():
		var w := _font.get_string_size(rows[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		_t(Vector2(size.x - 8 - w, 72 + 10 * i), rows[i], HudPalette.CHROME_DIM if i == 0 else HudPalette.CHROME)


func _arcs(fwd: Vector3, right: Vector3) -> void:
	for g in get_tree().get_nodes_in_group("guards"):
		var fill := HudModel.deceive(HudModel.arc_fill(g.alert, g.seen_rate > 0.0), _voice if _aigis > 0.0 else "")
		if fill < 0.0:
			continue
		var ang := HudModel.screen_angle(g.global_position - _operative.global_position, fwd, right)
		var span := 0.15 + 0.3 * fill
		var col := HudModel.arc_color(fill, g.alert.state == GuardAlert.State.ALERT, _aigis)
		draw_arc(size / 2, RING, ang - span, ang + span, 16, col, 2.0 + 5.0 * fill, false)


func _left() -> void:
	var lb := Rect2(10, size.y - 104, 7, 86)
	draw_rect(lb, HudPalette.EMPTY)
	var lh := lb.size.y * life
	draw_rect(Rect2(lb.position.x, lb.end.y - lh, lb.size.x, lh), HudPalette.CHROME if life > 0.4 else HudPalette.DANGER)
	_vt(Vector2(30, lb.end.y), tr("ui.hud.operative"), HudPalette.CHROME)


func _right() -> void:
	var sx := size.x - 42
	_stance(Rect2(sx + 9, 105, 16, 22))
	var it: Items = _operative.items
	var live: bool = it.scanning() or _operative.throwing
	_t(Vector2(sx + 3, 144), it.label(), HudPalette.WHITE if live else HudPalette.CHROME)
	_t(Vector2(sx + 9, 164), "%02d" % it.count(), HudPalette.CHROME if it.count() > 0 else HudPalette.DANGER)
	_balloons(Vector2(sx + 3, 178))
	var wc := Rect2(sx, 210, 34, size.y - 220)  # weapon column, no backing: the text outline carries contrast
	var gun: Gun = _operative.gun()
	_t(wc.position + Vector2(3, 12), gun.label, HudPalette.CHROME)
	var lit := HudModel.pips_lit(gun.loaded, gun.load_size, gun.pip_count)
	var pip_h := PIP_COLUMN / gun.pip_count  # the column is a fixed height, 4 or 6 pips
	for i in gun.pip_count:  # pip column, top pip is the next round
		var full: bool = i >= gun.pip_count - lit
		draw_rect(Rect2(wc.position.x + 11, wc.position.y + 20 + i * pip_h, 12, pip_h - 4), HudPalette.CHROME if full else HudPalette.EMPTY)
	if gun.suppressor_max >= 0:  # shots left on the suppressor
		_t(wc.position + Vector2(3, SUPPRESSOR_Y), "S%02d" % gun.suppressor, HudPalette.CHROME if gun.suppressed() else HudPalette.DANGER)
	_t(wc.position + Vector2(9, RESERVE_Y), "%02d" % gun.reserve, HudPalette.WHITE if gun.reloading() else HudPalette.CHROME_DIM)


## The one container on the HUD, top centre. ALERT is a solid red chip; EVASION (amber) and CAUTION (chrome)
## are outlined chips with a bar draining to the phase's end: shape for ALERT, hue for the other two, and
## the word for all three.
func _phase() -> void:
	var ph := HudModel.phase(AlertChain.area)
	if ph[0] != _phase_name:
		_phase_name = ph[0]
		_phase_age = 0.0
	if ph[0] == "":
		return
	var alert: bool = ph[0] == "ALERT"
	var hue := HudPalette.EVASION if ph[0] == "EVASION" else HudPalette.CHROME
	var secs := str(ceili(ph[1]))  # whole seconds: the hundredths were noise at a glance
	var secs_w := _digits.get_string_size(secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var word := tr("ui.phase." + String(ph[0]).to_lower())
	var r := Rect2(0, 10, word.length() * 8 + secs_w + 22, 22)
	r.position.x = roundf((size.x - r.size.x) / 2)
	var pop := clampf(_phase_age / 0.2, 0.0, 1.0)  # EVASION fades in over 0.2 s
	if alert:  # two hard flickers on arrival, in step with the edge flash
		var lit: bool = _phase_age > 0.32 or int(_phase_age * 12.5) % 2 == 0
		draw_rect(r, HudPalette.DANGER if lit else HudPalette.DANGER.darkened(0.6))
	else:
		draw_rect(r, Color(HudPalette.SHADE, HudPalette.SHADE.a * pop))
		draw_rect(r, Color(hue, pop), false, 1.0)
		var left: float = clampf(ph[2], 0.0, 1.0)
		draw_rect(Rect2(r.position.x, r.end.y + 2, r.size.x * left, 2), hue)
	var col := HudPalette.INK if alert else hue
	draw_string(_font, r.position + Vector2(6, 15), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
	draw_string(_digits, r.position + Vector2(word.length() * 8 + 14, 17), secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)


func _crosshair(file: String) -> Texture2D:
	if not _crosshairs.has(file):
		_crosshairs[file] = load("res://assets/textures/%s.png" % file)
	return _crosshairs[file]


func _stance(r: Rect2) -> void:
	var col := HudPalette.CHROME
	var head := Vector2(r.position.x + r.size.x / 2, r.position.y + r.size.y * (0.45 if _operative.crouching else 0.25))
	draw_circle(head, r.size.x * 0.13, col)
	var top := head.y + r.size.x * 0.15
	draw_rect(Rect2(r.position.x + r.size.x * 0.32, top, r.size.x * 0.36, r.end.y - top - r.size.y * 0.1), col)


func _t(pos: Vector2, s: String, col: Color) -> void:
	HudPalette.text(self, pos, s, col)


## Running text: VT323 at its native 16 px, outlined like the labels.
func _body(pos: Vector2, s: String, col: Color) -> void:
	HudPalette.text(self, pos, s, col, _digits, HudPalette.BODY_SIZE)


## Fulton balloons left, under the item card: a balloon glyph and the count, red at none, blinking
## white while a balloon could go up now.
func _balloons(p: Vector2) -> void:
	var n: int = _operative.fultons
	var ready: bool = n > 0 and _operative.fulton_ready()
	var blink := ready and int(Time.get_ticks_msec() / 250) % 2 == 0
	var col := HudPalette.DANGER if n == 0 else (HudPalette.WHITE if blink else HudPalette.CHROME)
	draw_circle(p + Vector2(4, 4), 4.5, HudPalette.INK)
	draw_circle(p + Vector2(4, 4), 3.5, col)
	draw_line(p + Vector2(4, 8), p + Vector2(4, 13), col, 1.0)
	_t(p + Vector2(12, 12), "%02d" % n, col)


## Text rotated to read bottom-to-top, starting at pos.
func _vt(pos: Vector2, s: String, col: Color) -> void:
	draw_set_transform(pos, -PI / 2)
	_t(Vector2.ZERO, s, col)
	draw_set_transform(Vector2.ZERO, 0.0)


## Bottom-left square, north-up: faint grid, guards in chrome with a facing tick, the objective (white diamond)
## or Target (white ring), the Operative's triangle. Dark with static and a blinking "JAMMED" in ALERT/EVASION.
## No vision cones: the Scanner owns those.
func _radar() -> void:
	var r := RadarModel.rect(size)
	var c := r.get_center()
	var half := RadarModel.HALF
	draw_rect(r, HudPalette.SHADE)
	draw_rect(r, HudPalette.CHROME_DIM, false)
	var origin := RadarModel.flat(_operative.global_position)
	if RadarModel.jammed(_phase_name):
		for i in 60:
			var p := r.position + Vector2(randf_range(0, r.size.x - 8), randf_range(0, r.size.y))
			draw_rect(Rect2(p, Vector2(randi_range(2, 8), 1)), Color(HudPalette.CHROME, randf() * 0.5))
		if int(Time.get_ticks_msec() / 250) % 2 == 0:
			HudPalette.centered(self, c.x, c.y + 4, tr("ui.hud.jammed"), HudPalette.DANGER)
		return
	for i in range(-3, 4):
		var o := i * half / 3.5
		draw_line(c + Vector2(o, -half), c + Vector2(o, half), Color(HudPalette.CHROME, 0.12))
		draw_line(c + Vector2(-half, o), c + Vector2(half, o), Color(HudPalette.CHROME, 0.12))
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		if g.is_down():
			continue
		var p := c + RadarModel.blip(RadarModel.flat(g.global_position) - origin, 2)
		var face := RadarModel.facing(g.global_basis)
		var mid_call := RadarModel.call_flash(AlertChain.area.calling(g), Time.get_ticks_msec())  # flashes red mid-call
		draw_circle(p, 2, HudPalette.DANGER if mid_call else HudPalette.CHROME)
		draw_line(p, p + face * 6, HudPalette.CHROME_DIM, 1.0)
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	for b: Dictionary in (run.radar_blips() if run else []):
		var p := c + RadarModel.blip(RadarModel.flat(b.pos) - origin, 4)
		if b.target:
			draw_arc(p, 4, 0, TAU, 12, HudPalette.WHITE, 1.0)
			draw_circle(p, 1.5, HudPalette.WHITE)
		else:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(4, 0), p + Vector2(0, 4), p + Vector2(-4, 0)]), HudPalette.WHITE)
	var f := RadarModel.facing(_operative.global_basis)
	draw_colored_polygon(PackedVector2Array([c + f * 4, c + f.rotated(2.5) * 3, c + f.rotated(-2.5) * 3]), HudPalette.WHITE)
