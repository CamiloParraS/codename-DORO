## PROTOTYPE, throwaway (branch prototype/hud-redesign): three Control-node HUD layouts on a fake
## 640x360 scene. Question: what should the HUD look like, PSX pixels + modern tactical styling?
## Left/Right = variant. 1-4 = phase (none/suspicion/alert/evasion). F = fire, V = reload,
## L = hurt, H = crouch, P = pick up (card pulse). Nothing here reads the real game.
extends Control

const PS: FontFile = preload("res://assets/fonts/press_start_2p_regular.ttf")
const VT: FontFile = preload("res://assets/fonts/vt323_regular.ttf")
const AMBER := Color("ffb000")
const AMBER_DIM := Color(1, 0.69, 0, 0.4)
const RED := Color("ff3b30")
const INK := Color(0.03, 0.04, 0.03, 0.72)
const NAMES := ["A SIDE STRIPS", "B BOTTOM BAR", "C MINIMAL"]

var variant := 0
var phase := 0  # 0 none, 1 suspicion, 2 alert, 3 evasion
var life := 0.72
var ammo := 5
var reserve := 12
var crouch := false
var pulse := 0.0  # item card pickup pulse, 1 → 0
var _hud: Control
var _bar: Label


func _ready() -> void:
	for f in [PS, VT]:
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar = Label.new()
	_bar.add_theme_font_override("font", PS)
	_bar.add_theme_font_size_override("font_size", 8)
	_bar.add_theme_color_override("font_color", Color.BLACK)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ff4fd8")
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	_bar.add_theme_stylebox_override("normal", sb)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	layer.add_child(_bar)
	_rebuild()


func _process(delta: float) -> void:
	if pulse > 0.0:
		pulse = maxf(pulse - delta * 4.0, 0.0)
		_rebuild()


func _unhandled_key_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():
		return
	match (e as InputEventKey).keycode:
		KEY_LEFT: variant = posmod(variant - 1, NAMES.size())
		KEY_RIGHT: variant = posmod(variant + 1, NAMES.size())
		KEY_1: phase = 0
		KEY_2: phase = 1
		KEY_3: phase = 2
		KEY_4: phase = 3
		KEY_F: ammo = maxi(ammo - 1, 0)
		KEY_V: ammo = 6
		KEY_L: life = fposmod(life - 0.15, 1.0)
		KEY_H: crouch = not crouch
		KEY_P: pulse = 1.0
	_rebuild()


func _rebuild() -> void:
	if _hud:
		_hud.queue_free()
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_hud)
	call(["_variant_a", "_variant_b", "_variant_c"][variant])
	_bar.text = "< %s >" % NAMES[variant]
	_bar.position = Vector2(8, 6)
	queue_redraw()


# ---- fake game ----------------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 180), Color("5d7f95"))  # sky
	draw_rect(Rect2(0, 180, 640, 180), Color("3b4a3f"))  # ground
	draw_rect(Rect2(380, 120, 150, 90), Color("cfd6d4"))  # bright wall: worst case for white text
	draw_rect(Rect2(40, 150, 110, 60), Color("2a2f33"))  # dark container
	draw_rect(Rect2(318, 178, 4, 4), Color.WHITE)  # crosshair stand-in


func _guards() -> Array:
	match phase:
		1: return [{ang = -1.2, fill = 0.45, alert = false}, {ang = 0.4, fill = 0.2, alert = false}]
		2: return [{ang = -1.9, fill = 1.0, alert = true}]
		3: return []
	return []


func _phase_text() -> Array:  # [label, seconds, color]
	match phase:
		1: return ["CAUTION", 0.0, AMBER]
		2: return ["ALERT", 12.4, RED]
		3: return ["EVASION", 31.2, AMBER]
	return ["", 0.0, AMBER]


# ---- helpers ------------------------------------------------------------------------------------

func _lbl(parent: Node, s: String, col := Color.WHITE, font: Font = VT, fs := 16) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(l)
	return l


func _panel(parent: Node, border := AMBER_DIM, bw := 1, fill := INK) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p


func _box(parent: Node, vertical := true, sep := 2) -> BoxContainer:
	var b: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	parent.add_child(b)
	return b


func _rect(parent: Node, size: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.custom_minimum_size = size
	r.color = col
	parent.add_child(r)
	return r


func _pips(parent: Node, vertical: bool, n: int, lit: int, size: Vector2) -> void:
	var b := _box(parent, vertical, 2)
	for i in n:  # first pip = next round
		var on: bool = i >= n - lit if vertical else i < lit
		_rect(b, size, Color.WHITE if on else Color(1, 1, 1, 0.18))


func _life_segments(parent: Node, vertical: bool, n: int, size: Vector2) -> void:
	var b := _box(parent, vertical, 1)
	var lit := ceili(life * n)
	for i in n:
		var on: bool = i >= n - lit if vertical else i < lit
		var col := Color.WHITE if life > 0.4 else RED
		_rect(b, size, col if on else Color(1, 1, 1, 0.15))


func _stance_icon(parent: Node) -> Control:
	var s := Ring.new()
	s.mode = "stance"
	s.crouch = crouch
	s.custom_minimum_size = Vector2(16, 20)
	parent.add_child(s)
	return s


func _ring(extra := "") -> Ring:
	var r := Ring.new()
	r.mode = extra
	r.guards = _guards()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(r)
	return r


func _item_card(parent: Node) -> void:
	var p := _panel(parent, Color.WHITE.lerp(AMBER, 1.0 - pulse) if pulse > 0.0 else AMBER_DIM, 2 if pulse > 0.0 else 1)
	var b := _box(p, true, 0)
	_lbl(b, "SCANNER", AMBER, PS, 8)
	_lbl(b, "x02", Color.WHITE, VT, 32)


# ---- A: side strips, framed. Same layout as today, now in panels with a real type hierarchy -----

func _variant_a() -> void:
	_ring("compass")
	var left := MarginContainer.new()
	left.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 10)
	_hud.add_child(left)
	var lp := _panel(left)
	var lb := _box(lp, true, 3)
	_lbl(lb, "LIFE", AMBER, PS, 8)
	_life_segments(lb, true, 10, Vector2(10, 6))

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
	_hud.add_child(right)
	var ph := _phase_text()
	if ph[0] != "":
		var pp := _panel(right, ph[2], 2, Color(ph[2], 0.18))
		var pb := _box(pp, false, 6)
		_lbl(pb, ph[0], ph[2], PS, 8)
		if ph[1] > 0.0:
			_lbl(pb, "%05.2f" % ph[1], Color.WHITE, VT, 16)
	var sp := _panel(right)
	var sb := _box(sp, false, 6)
	_stance_icon(sb)
	_lbl(sb, "CROUCH" if crouch else "STAND", Color.WHITE, VT, 16)
	_item_card(right)
	var wp := _panel(right)
	var wb := _box(wp, true, 2)
	_lbl(wb, "TRANQ", AMBER, PS, 8)
	var row := _box(wb, false, 6)
	_pips(row, true, 6, ammo, Vector2(8, 5))
	var nums := _box(row, true, 0)
	_lbl(nums, "%02d" % ammo, RED if ammo == 0 else Color.WHITE, VT, 32)
	_lbl(nums, "/%02d" % reserve, Color(1, 1, 1, 0.6), VT, 16)


# ---- B: bottom bar + heading tape. Everything on the screen edge, centre stays clear ------------

func _variant_b() -> void:
	_ring()
	var tape := _panel(_hud, AMBER_DIM, 1, INK)
	tape.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 8)
	var tb := _box(tape, false, 14)
	for c in ["W", "NW", "N", "NE", "E"]:
		_lbl(tb, c, RED if c == "N" else Color(1, 1, 1, 0.7), VT, 16)
	var ph := _phase_text()
	if ph[0] != "":
		var chip := _panel(_hud, ph[2], 2, Color(ph[2], 0.25))
		chip.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 36)
		var cb := _box(chip, false, 8)
		_lbl(cb, ph[0], ph[2], PS, 8)
		if ph[1] > 0.0:
			_lbl(cb, "%05.2f" % ph[1], Color.WHITE, VT, 16)

	var bar := _panel(_hud, AMBER_DIM, 1, Color(0.02, 0.03, 0.02, 0.8))
	bar.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 22)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	_stance_icon(row)
	var lc := _box(row, true, 1)
	_lbl(lc, "OPERATIVE", AMBER, PS, 8)
	_life_segments(lc, false, 20, Vector2(5, 6))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	var ic := _box(row, true, 0)
	_lbl(ic, "SCANNER", AMBER, PS, 8)
	_lbl(ic, "x02", Color.WHITE, VT, 16)
	_rect(row, Vector2(1, 28), AMBER_DIM)
	var wc := _box(row, true, 1)
	_lbl(wc, "TRANQ", AMBER, PS, 8)
	var wr := _box(wc, false, 3)
	_pips(wr, false, 6, ammo, Vector2(5, 8))
	_lbl(wr, "%02d/%02d" % [ammo, reserve], RED if ammo == 0 else Color.WHITE, VT, 16)


# ---- C: minimal. No panels, corner brackets, ammo hugs the aim point, text is the only chrome ---

func _variant_c() -> void:
	_ring("brackets")
	var ph := _phase_text()
	if ph[0] != "":
		var t := _lbl(_hud, "%s  %s" % [ph[0], "%05.2f" % ph[1] if ph[1] > 0.0 else ""], ph[2], PS, 8)
		t.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 22)
	var life_line := Ring.new()
	life_line.mode = "lifeline"
	life_line.life = life
	life_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(life_line)
	var aim := _box(_hud, true, 0)  # ammo: right of the crosshair, inside the detection ring
	aim.position = Vector2(334, 168)
	_lbl(aim, "%02d" % ammo, RED if ammo == 0 else Color.WHITE, VT, 32)
	_pips(aim, false, 6, ammo, Vector2(4, 4))
	var br := _box(_hud, true, 0)
	br.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	var item := _lbl(br, "SCANNER x02", AMBER if pulse > 0.0 else Color(1, 1, 1, 0.8), VT, 16)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var wl := _lbl(br, "TRANQ  %02d" % reserve, Color(1, 1, 1, 0.8), VT, 16)
	wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var st := _lbl(_hud, "CROUCH" if crouch else "", Color(1, 1, 1, 0.8), VT, 16)
	st.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 24)


## One custom-drawn Control for the spatial bits: detection arcs, compass, brackets, life line, stance.
class Ring extends Control:
	var mode := ""
	var guards: Array = []
	var crouch := false
	var life := 1.0

	func _draw() -> void:
		var c := size / 2
		if mode == "stance":
			var head := Vector2(size.x / 2, size.y * (0.45 if crouch else 0.25))
			draw_circle(head, size.x * 0.13, Color.WHITE)
			var top := head.y + size.x * 0.15
			draw_rect(Rect2(size.x * 0.32, top, size.x * 0.36, size.y - top - size.y * 0.1), Color.WHITE)
			return
		if mode == "lifeline":
			var h := 120.0
			draw_rect(Rect2(14, size.y - 24 - h, 2, h), Color(1, 1, 1, 0.2))
			draw_rect(Rect2(14, size.y - 24 - h * life, 2, h * life), Color.WHITE if life > 0.4 else Color("ff3b30"))
			return
		for g in guards:
			var span: float = 0.15 + 0.3 * g.fill
			var col: Color = Color("ff3b30") if g.alert else Color.WHITE.lerp(Color("ffb000"), g.fill)
			col.a = 0.35 + 0.65 * g.fill
			draw_arc(c, 96.0, g.ang - span, g.ang + span, 16, col, 2.0 + 5.0 * g.fill, false)
		if mode == "compass":
			var cc := Vector2(size.x - 70, 38)
			draw_circle(cc, 26, Color(0.03, 0.04, 0.03, 0.72))
			draw_arc(cc, 26, 0, TAU, 32, Color("ffb000", 0.4), 1.0)
			draw_arc(cc, 8, 0, TAU, 16, Color(1, 1, 1, 0.4), 1.0)
			draw_string(ThemeDB.fallback_font, cc + Vector2(-3, -13), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ff3b30"))
		elif mode == "brackets":
			var m := 12.0
			var l := 18.0
			var col := Color(1, 1, 1, 0.55)
			for sx: float in [0.0, 1.0]:
				for sy: float in [0.0, 1.0]:
					var p := Vector2(m + (size.x - 2 * m) * sx, m + (size.y - 2 * m) * sy)
					var dx: float = l * (1.0 - 2.0 * sx)
					var dy: float = l * (1.0 - 2.0 * sy)
					draw_polyline(PackedVector2Array([p + Vector2(dx, 0), p, p + Vector2(0, dy)]), col, 1.0)
