## Game Over: a dark red glow with a red dial turning slowly behind, animated grain, the title in Michroma, one
## Metis line picked at random, then CONTINUE (the last Checkpoint) or QUIT TO MENU and "CONTINUES n".
## MissionRun opens it on death. This is the one screen that keeps grain and eased slide-ins (no UiMotion wipes).
extends Control

signal continued
signal quit

const LINES := ["gameover.01", "gameover.02", "gameover.03", "gameover.04", "gameover.05", "gameover.06"]
const MICHROMA: FontFile = preload("res://assets/fonts/michroma_regular.ttf")
const INK := Color("f1dcd4")
const RED := Color("e0423a")
const BAR := Color("cbb3a8")
const GRAIN := preload("res://ui/game_over/grain.gdshader")

var continues := 0
var line: String = LINES.pick_random()
var _stage := Control.new()
var _dial: UiDial


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg := ColorRect.new()
	bg.color = Color("0a0506")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_stage.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_stage)
	_glow()
	_dial = UiDial.new(1100)
	_dial.color = Color("a03c32", 0.22)
	_dial.secs_outer = 140.0
	_dial.secs_inner = 90.0
	_dial.position = Vector2(300, -10)
	_stage.add_child(_dial)
	var title := _text(tr("ui.gameover.title").to_upper(), 40, 0.1, INK, MICHROMA)
	title.position = Vector2(250, 504)
	_stage.add_child(title)
	var said := VBoxContainer.new()
	said.position = Vector2(250, 584)
	said.add_theme_constant_override("separation", 8)
	said.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(said)
	said.add_child(_text(tr("ui.who.metis").to_upper(), 17, 0.3, RED, HudPalette.tracked(HudPalette.LABEL, 17, 0.3)))
	var body := _text(tr(line), 22, 0.0, Color(INK, 0.72), HudPalette.FIGURE_MED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.custom_minimum_size.x = 560
	said.add_child(body)
	var opts := VBoxContainer.new()
	opts.position = Vector2(950, 496)
	opts.add_theme_constant_override("separation", 0)
	_stage.add_child(opts)
	var go := _option(opts, "ui.menu.continue", continued.emit)
	_option(opts, "ui.pause.quit", quit.emit)
	var cont := _text(tr("ui.gameover.continues").format({n = continues}).to_upper(), 20, 0.4, Color(INK, 0.6), HudPalette.LABEL)
	cont.position = Vector2(250, 880)
	_stage.add_child(cont)
	var grain := ColorRect.new()
	var m := ShaderMaterial.new()
	m.shader = GRAIN
	grain.material = m
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(grain)
	add_child(UiScan.make())
	var fade := ColorRect.new()  # a fade from black at the start
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var ft := create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ft.tween_property(fade, "color:a", 0.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.tween_callback(fade.queue_free)
	_slide(title, -70.0, 0.5)
	_slide(said, -70.0, 0.7)
	_slide(opts, 70.0, 0.8)
	_slide(cont, 0.0, 1.4)
	resized.connect(_layout)
	_layout()
	go.grab_focus.call_deferred()


func _layout() -> void:
	var k := size.y / HudPalette.DESIGN_H
	_stage.scale = Vector2(k, k)
	_stage.size = size / k


func _glow() -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.56, 0.2, 0.16, 0.55), Color(0.35, 0.12, 0.11, 0.3), Color(0.35, 0.12, 0.11, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	var blob := TextureRect.new()
	blob.texture = t
	blob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blob.position = Vector2(380, 60)
	blob.size = Vector2(1000, 960)
	blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(blob)


func _text(s: String, fs: int, em: float, col: Color, font: Font = HudPalette.DISPLAY) -> Label:
	var l := Label.new()
	l.text = s
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_override("font", HudPalette.tracked(font, fs, em) if em > 0.0 else font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Eased slide-in (70 px, 0.7 s) and fade after `delay`; ignores time scale.
func _slide(n: Control, dx: float, delay: float) -> void:
	var to := n.position
	n.position = to + Vector2(dx, 0.0)
	n.modulate.a = 0.0
	var t := create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	t.tween_property(n, "position", to, 0.7).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(n, "modulate:a", 1.0, 0.7).set_delay(delay)


## A Michroma option: dim until selected, then bright with a pale bar growing in at its left.
func _option(box: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(720, 62)
	b.add_theme_font_override("font", HudPalette.tracked(MICHROMA, 32, 0.06))
	b.add_theme_font_size_override("font_size", 32)
	b.add_theme_color_override("font_color", Color(INK, 0.55))
	b.add_theme_color_override("font_focus_color", Color("f6e6df"))
	b.add_theme_color_override("font_hover_color", Color("f6e6df"))
	var bare := StyleBoxEmpty.new()
	bare.content_margin_left = 150
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, bare)
	var bar := ColorRect.new()
	bar.color = BAR
	bar.position = Vector2(0, 14)
	bar.size = Vector2(116, 34)
	bar.pivot_offset = Vector2.ZERO
	bar.scale = Vector2(0, 1)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bar)
	b.focus_entered.connect(func() -> void:
		Mixer.play(&"tick")
		create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(bar, "scale:x", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	b.focus_exited.connect(func() -> void: bar.scale.x = 0.0)
	b.mouse_entered.connect(b.grab_focus)
	b.pressed.connect(Mixer.click)
	b.pressed.connect(on_press)
	box.add_child(b)
	return b
