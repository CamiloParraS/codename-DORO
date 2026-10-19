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
const TICK_TIME := 2.0
const ICON := int(HabitGlyphs.SIZE)  # px
const ICON_STEP := 14
var _was_alert := {}  # guard -> was in ALERT last frame
var _font: FontFile
var _digits: FontFile  # VT323, the big numbers
var _crosshairs := {}  # file name -> texture
var _operative: Node3D
var _subs := Subtitles.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load("res://assets/fonts/press_start_2p_regular.ttf")
	_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_font.hinting = TextServer.HINTING_NONE
	_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	_digits = load("res://assets/fonts/vt323_regular.ttf")
	_digits.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_digits.hinting = TextServer.HINTING_NONE
	_digits.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("radio_log")


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	_phase_age += delta
	_tick_age += delta
	_read_run()
	_subs.tick(delta)
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
	_right()
	_phase()
	_aigis_layer()
	_voiceprints()
	_subtitles()
	if _operative.prompt != "":
		_t(Vector2(size.x / 2 - _operative.prompt.length() * 4, size.y - 60), _operative.prompt, HudPalette.WHITE)


## Radio line from a guard (call_group "radio_log").
func say(who: String, text: String) -> void:
	_subs.add(who, text)


func _subtitles() -> void:
	var y := size.y - 28.0
	for l in _subs.lines:
		var a := Subtitles.alpha(l["age"])
		var s: String = "%s: %s" % [l["who"], l["text"]]
		_t(Vector2(size.x / 2 - s.length() * 4, y), s, Color(HudPalette.CHROME, a))
		y += 12.0


func _read_run() -> void:
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	if not run:
		_aigis = 0.0
		return
	_aigis = HudModel.aigis_weight(run.record.mission, Aigis.lethality_ratio(run.record))
	_voice = str(run.plan.get("dominant", "")).to_upper()
	var risen := HudModel.habits_risen(_prev_counts, run.tally.counts)
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
	var a := lerpf(0.5, 1.0, _aigis)
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
		HabitGlyphs.draw(self, h, Vector2(x0 + i * ICON_STEP, 32), col)
	var s := "+" + _tick
	_t(Vector2(size.x - 8 - s.length() * 8.0, 56), s, Color(HudPalette.AIGIS, fade))


func _voiceprints() -> void:
	if _operative.voiceprints.held.is_empty():  # a bare "VP" with nothing under it is noise
		return
	var p := Vector2(size.x - 42, 72)  # under Aigis's corner
	_t(p, "VP", HudPalette.CHROME_DIM)
	for i in _operative.voiceprints.held.size():
		_t(p + Vector2(0, 10 * (i + 1)), _operative.voiceprints.held[i], HudPalette.CHROME)


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
	draw_rect(lb, Color(0.3, 0.3, 0.3, 0.6))
	var lh := lb.size.y * life
	draw_rect(Rect2(lb.position.x, lb.end.y - lh, lb.size.x, lh), HudPalette.CHROME if life > 0.4 else HudPalette.DANGER)
	_vt(Vector2(30, lb.end.y), "OPERATIVE", HudPalette.CHROME)


func _right() -> void:
	var sx := size.x - 42
	_stance(Rect2(sx + 9, 105, 16, 22))
	var it: Items = _operative.items
	var live: bool = it.scanning() or _operative.throwing
	_t(Vector2(sx + 3, 144), it.label(), HudPalette.WHITE if live else HudPalette.CHROME)
	_t(Vector2(sx + 9, 164), "%02d" % it.count(), HudPalette.CHROME if it.count() > 0 else HudPalette.DANGER)
	var wc := Rect2(sx, 210, 34, size.y - 220)  # weapon column, no backing: the text outline carries contrast
	var gun: Gun = _operative.gun()
	_t(wc.position + Vector2(3, 12), gun.label, HudPalette.CHROME)
	var lit := HudModel.pips_lit(gun.loaded, gun.load_size, gun.pip_count)
	var pip_h := PIP_COLUMN / gun.pip_count  # the column is a fixed height, 4 or 6 pips
	for i in gun.pip_count:  # pip column, top pip is the next round
		var full: bool = i >= gun.pip_count - lit
		draw_rect(Rect2(wc.position.x + 11, wc.position.y + 20 + i * pip_h, 12, pip_h - 4), HudPalette.CHROME if full else Color(1, 1, 1, 0.2))
	if gun.suppressor_max >= 0:  # shots left on the suppressor
		_t(wc.position + Vector2(3, SUPPRESSOR_Y), "S%02d" % gun.suppressor, HudPalette.CHROME if gun.suppressed() else HudPalette.DANGER)
	_t(wc.position + Vector2(9, RESERVE_Y), "%02d" % gun.reserve, HudPalette.WHITE if gun.reloading() else HudPalette.CHROME_DIM)


## The one container on the HUD, top centre. ALERT is a solid red chip; EVASION is an outlined chip with a
## bar draining to the end of the search, so the two differ by shape and motion as well as hue.
func _phase() -> void:
	var ph := HudModel.phase(get_tree().get_nodes_in_group("guards").map(func(g): return g.alert))
	if ph[0] != _phase_name:
		_phase_name = ph[0]
		_phase_age = 0.0
	if ph[0] == "":
		return
	var alert: bool = ph[0] == "ALERT"
	var secs := str(ceili(ph[1]))  # whole seconds: the hundredths were noise at a glance
	var secs_w := _digits.get_string_size(secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var r := Rect2(0, 10, ph[0].length() * 8 + secs_w + 22, 22)
	r.position.x = roundf((size.x - r.size.x) / 2)
	var pop := clampf(_phase_age / 0.2, 0.0, 1.0)  # EVASION fades in over 0.2 s
	if alert:  # two hard flickers on arrival, in step with the edge flash
		var lit: bool = _phase_age > 0.32 or int(_phase_age * 12.5) % 2 == 0
		draw_rect(r, HudPalette.DANGER if lit else HudPalette.DANGER.darkened(0.6))
	else:
		draw_rect(r, Color(0, 0, 0, 0.5 * pop))
		draw_rect(r, Color(HudPalette.EVASION, pop), false, 1.0)
		var left: float = clampf(ph[1] / GuardAlert.SEARCH_TIME, 0.0, 1.0)
		draw_rect(Rect2(r.position.x, r.end.y + 2, r.size.x * left, 2), HudPalette.EVASION)
	var col := Color.BLACK if alert else HudPalette.EVASION
	draw_string(_font, r.position + Vector2(6, 15), ph[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
	draw_string(_digits, r.position + Vector2(ph[0].length() * 8 + 14, 17), secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)


func _crosshair(file: String) -> Texture2D:
	if not _crosshairs.has(file):
		_crosshairs[file] = load("res://assets/textures/%s.png" % file)
	return _crosshairs[file]


func _stance(r: Rect2) -> void:
	var col := Color(1, 1, 1, 0.8)
	var head := Vector2(r.position.x + r.size.x / 2, r.position.y + r.size.y * (0.45 if _operative.crouching else 0.25))
	draw_circle(head, r.size.x * 0.13, col)
	var top := head.y + r.size.x * 0.15
	draw_rect(Rect2(r.position.x + r.size.x * 0.32, top, r.size.x * 0.36, r.end.y - top - r.size.y * 0.1), col)


func _t(pos: Vector2, s: String, col: Color) -> void:
	for o in [Vector2(1, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]:  # 4-way outline replaces card backings
		draw_string(_font, pos + o, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0, 0, 0, col.a))
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)


## Text rotated to read bottom-to-top, starting at pos.
func _vt(pos: Vector2, s: String, col: Color) -> void:
	draw_set_transform(pos, -PI / 2)
	_t(Vector2.ZERO, s, col)
	draw_set_transform(Vector2.ZERO, 0.0)
