## HUD E (Peace Walker side strips) on a 640x360 logical canvas, drawn by hand: detection arcs around
## the screen centre, red edge flash on alert, ALERT/EVASION strip with stance and empty item/weapon
## cards on the right, life bar on the left, compass top-right. Lifted from the PSX look prototype.
## Lives on CanvasLayer 1 so the banding pass on layer 0 does not touch it.
extends Control

const RED := Color(1, 0.22, 0.2)
const ORANGE := Color(1, 0.6, 0.15)
const RING := 96.0
const FLASH_TIME := 1.0

var life := 1.0  # ponytail: no damage model yet; the bar stays full until one exists
var _flash := 0.0
var _was_alert := {}  # guard -> was in ALERT last frame
var _font: FontFile
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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("radio_log")


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
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
		var c := Color(RED, _flash * 0.8)
		var w := 8.0
		draw_rect(Rect2(0, 0, size.x, w), c)
		draw_rect(Rect2(0, size.y - w, size.x, w), c)
		draw_rect(Rect2(0, 0, w, size.y), c)
		draw_rect(Rect2(size.x - w, 0, w, size.y), c)
	if not _operative:
		return
	var cam: Camera3D = _operative.camera
	var fwd := Vector3(-cam.global_basis.z.x, 0, -cam.global_basis.z.z).normalized()
	var right := Vector3(cam.global_basis.x.x, 0, cam.global_basis.x.z).normalized()
	_arcs(fwd, right)
	if _operative.aiming:  # shots leave from the screen centre
		var tex := _crosshair(_operative.gun().crosshair)
		draw_texture(tex, (size / 2 - tex.get_size() / 2).round())
	_left()
	_right()
	_compass(fwd, right)
	_voiceprints()
	_subtitles()
	if _operative.prompt != "":
		_t(Vector2(size.x / 2 - _operative.prompt.length() * 4, size.y - 60), _operative.prompt, Color.WHITE)


## Radio line from a guard (call_group "radio_log").
func say(who: String, text: String) -> void:
	_subs.add(who, text)


func _subtitles() -> void:
	var y := size.y - 28.0
	for l in _subs.lines:
		var a := Subtitles.alpha(l["age"])
		var s: String = "%s: %s" % [l["who"], l["text"]]
		_t(Vector2(size.x / 2 - s.length() * 4, y), s, Color(1, 1, 1, a))
		y += 12.0


func _voiceprints() -> void:
	var p := Vector2(size.x - 112, 78)
	_t(p, "VP", Color(1, 1, 1, 0.85))
	for i in _operative.voiceprints.held.size():
		_t(p + Vector2(0, 10 * (i + 1)), _operative.voiceprints.held[i], Color.WHITE)


func _arcs(fwd: Vector3, right: Vector3) -> void:
	for g in get_tree().get_nodes_in_group("guards"):
		var fill := HudModel.arc_fill(g.alert, g.seen_rate > 0.0)
		if fill < 0.0:
			continue
		var ang := HudModel.screen_angle(g.global_position - _operative.global_position, fwd, right)
		var span := 0.15 + 0.3 * fill
		var col := HudModel.arc_color(fill, g.alert.state == GuardAlert.State.ALERT)
		draw_arc(size / 2, RING, ang - span, ang + span, 16, col, 2.0 + 5.0 * fill, false)


func _left() -> void:
	var lb := Rect2(10, size.y - 104, 7, 86)
	draw_rect(lb, Color(0.3, 0.3, 0.3, 0.6))
	var lh := lb.size.y * life
	draw_rect(Rect2(lb.position.x, lb.end.y - lh, lb.size.x, lh), Color.WHITE if life > 0.4 else RED)
	_vt(Vector2(30, lb.end.y), "OPERATIVE", Color(1, 1, 1, 0.85))


func _right() -> void:
	var sx := size.x - 42
	var ph := HudModel.phase(get_tree().get_nodes_in_group("guards").map(func(g): return g.alert))
	if ph[0] != "":
		_vt(Vector2(sx + 22, 98), "%s %05.2f" % ph, RED if ph[0] == "ALERT" else ORANGE)
	draw_rect(Rect2(sx, 104, 34, 24), Color(0, 0, 0, 0.4))
	_stance(Rect2(sx + 9, 105, 16, 22))
	draw_rect(Rect2(sx, 132, 34, 74), Color(0, 0, 0, 0.55))            # item card, empty
	var wc := Rect2(sx, 210, 34, size.y - 220)
	draw_rect(wc, Color(0, 0, 0, 0.55))  # weapon card
	var gun: Tranq = _operative.gun()
	_t(wc.position + Vector2(3, 12), gun.label, Color.WHITE)
	var lit := HudModel.pips_lit(gun.loaded, gun.load_size, gun.pip_count)
	var pip_h := 48.0 / gun.pip_count  # the column is 48 px tall, 4 or 6 pips
	for i in gun.pip_count:  # pip column, top pip is the next round
		var full: bool = i >= gun.pip_count - lit
		draw_rect(Rect2(wc.position.x + 11, wc.position.y + 20 + i * pip_h, 12, pip_h - 4), Color.WHITE if full else Color(1, 1, 1, 0.2))
	if gun is Rifle:  # shots left on the suppressor
		_t(wc.position + Vector2(3, 80), "S%02d" % gun.suppressor, Color.WHITE if gun.suppressed() else RED)
	_t(wc.position + Vector2(9, 92), "%02d" % gun.reserve, ORANGE if gun.reloading() else Color.WHITE)


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


func _compass(fwd: Vector3, right: Vector3) -> void:
	var cc := Vector2(size.x - 84, 40)
	draw_circle(cc, 28, Color(0, 0, 0, 0.45))
	draw_arc(cc, 28, 0, TAU, 32, Color(1, 1, 1, 0.8), 1.0)
	draw_arc(cc, 8, 0, TAU, 16, Color(1, 1, 1, 0.6), 1.0)
	_t(cc + Vector2(-4, 3), "^", Color.WHITE)
	var north := HudModel.screen_angle(Vector3.FORWARD, fwd, right)
	_t(cc + Vector2.from_angle(north) * 21 + Vector2(-4, 4), "N", RED)


func _t(pos: Vector2, s: String, col: Color) -> void:
	draw_string(_font, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0, 0, 0, col.a))
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)


## Text rotated to read bottom-to-top, starting at pos.
func _vt(pos: Vector2, s: String, col: Color) -> void:
	draw_set_transform(pos, -PI / 2)
	_t(Vector2.ZERO, s, col)
	draw_set_transform(Vector2.ZERO, 0.0)
