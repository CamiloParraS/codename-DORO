## The paused full-screen Codec call, drawn in design px (1080 tall): two portraits, the frequency and a waveform
## between them, the speaker tag as a slanted slab, and the line centred on a black bar with a thin green rule.
## An incoming call (`ring`) first shows only the handler's frame and rings until it is answered.
## LMB / Space / Enter answers, skips the typing, then moves on; `finished` after the last line.
## Add it over whatever is showing (Briefing) or to a paused tree (it keeps running).
## Portraits are ui/codec/portraits/<id>_<frame>.png, rendered once by tools/render_portraits.gd (frame 1 is
## the talk flap and blink).
## Motion (ui/codec/story_motion.gd, ui/ui_motion.gd): a tune-in on opening, a static burst and tear when the
## speaker changes, a cut on closing; a press skips the tune-in.
class_name CodecScreen
extends Control

signal finished

const FREQUENCY := "140.85"
const PORTRAITS := "res://ui/codec/portraits/%s_0.png"
const FRAME := "res://ui/codec/portraits/%s_%d.png"
const GREEN := HudPalette.MINT
const CRT_GROUND := Color("040b0b")
const CRT_DARK := Color("02100d")  # dark legends on the green fills
const GREEN_DIM := Color(GREEN, 0.45)
const BAR := 120.0         # the black bars top and bottom
const PORTRAIT := Vector2(370, 340)
const PORTRAIT_Y := 200.0
const SIDE := 340.0        # portrait distance from its screen edge
const RING_EVERY := 0.9    # s between the incoming call's beeps
const BURST := 0.16        # s of static and tear on a speaker change
const WAVE_BARS := 34

var talk: CodecCall
var _ringing := false
var _ring_t := 0.0
var _t := 0.0       # since the call opened (the tune-in)
var _line_t := 0.0  # since the current line began
var _line := 0
var _cut := -1.0    # seconds left of the closing cut; -1 while the call is on
var _burst := 0.0   # seconds left of the speaker-change static
var _last_speaker := ""
var _ticked := 0    # text ticks given so far on this line (one per three characters)
var _faces := {}  # portrait path -> texture
var _left := TextureRect.new()
var _right := TextureRect.new()


func _init(lines := [], ring := false) -> void:
	talk = CodecCall.new(lines)
	_ringing = ring


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for f in ResourceLoader.list_directory(PORTRAITS.get_base_dir()):  # not in _draw: a texture first loaded there draws white (Godot 4.7)
		if f.ends_with(".png"):
			_faces[PORTRAITS.get_base_dir().path_join(f)] = load(PORTRAITS.get_base_dir().path_join(f))
	for face: TextureRect in [_left, _right]:
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = preload("res://ui/hud/portrait.gdshader")
		face.material = m
		add_child(face)
	add_child(UiScan.make(null, true))
	Mixer.codec_call(true)
	HudPalette.fade(self)
	if talk.done():
		_finish()


func _exit_tree() -> void:
	Mixer.codec_call(false)
	Mixer.stop_blips()


func _process(delta: float) -> void:
	if _cut >= 0.0:
		_cut -= delta
		if _cut < 0.0:
			set_process(false)
			finished.emit()
		return
	if _ringing:
		var before := _ring_t
		_ring_t += delta
		if before == 0.0 or int(before / RING_EVERY) != int(_ring_t / RING_EVERY):
			Mixer.play(&"beep")
		queue_redraw()
		return
	if not StoryMotion.still(self):
		_t += delta
		_line_t += delta
	_burst = maxf(_burst - delta, 0.0)
	if not talk.done() and talk.speaker() != _last_speaker:
		if _last_speaker != "":
			_burst = BURST
		_last_speaker = talk.speaker()
		_ticked = 0
	var p := talk.advance(delta)
	if not p.is_empty():
		@warning_ignore("integer_division")
		var due := talk.shown().length() / 3
		if due > _ticked:  # a tick every third character
			_ticked = due
			Mixer.blip(p.back())
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		if _ringing:  # answering: the operative's frame wipes in
			_ringing = false
			_t = 0.0
			_line_t = 0.0
			UiMotion.wipe(_left, true, 6, 0.24)
			return
		if StoryMotion.tuning(_t):  # the same key skips the tune-in
			_t = StoryMotion.TUNE
			return
		talk.press()
		if talk.index != _line:
			_line = talk.index
			_line_t = 0.0
		if talk.done():
			_finish()


func _finish() -> void:  # closes on a cut: a short dark beat, then `finished`
	set_process_unhandled_input(false)
	_cut = StoryMotion.CUT
	queue_redraw()


func _k() -> float:
	return size.y / HudPalette.DESIGN_H


func _draw() -> void:
	var k := _k()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var d := size / k
	draw_rect(Rect2(Vector2.ZERO, d), CRT_GROUND)
	_grid(d)
	_left.visible = false
	_right.visible = false
	if talk.done():
		return
	var who := talk.speaker()
	var still := StoryMotion.still(self)
	draw_rect(Rect2(0, 0, d.x, BAR), Color.BLACK)
	draw_rect(Rect2(0, d.y - BAR, d.x, BAR), Color.BLACK)
	var tag := tr("ui.codec.incoming" if _ringing else "ui.codec.in_progress").to_upper()
	if not _ringing or int(_ring_t / 0.4) % 2 == 0:
		HudPalette.hud_text(self, Vector2(80, 70), tag, 20, GREEN, HudPalette.tracked(HudPalette.DISPLAY, 20, 0.4), 0, false)
	var near := who == "operative"  # the Operative speaks from the left frame, everyone else from the right
	var far_id := "handler" if _ringing else ("handler" if near else talk.portrait())
	var far_name := tr("codec.speaker.handler") if (_ringing or near) else talk.speaker_name()
	var typing := talk.typing() and not _ringing
	var tear := Vector2(14.0 if _burst > BURST / 2 else -8.0, 0.0) if _burst > 0.0 else Vector2.ZERO
	var rx := d.x - SIDE - PORTRAIT.x
	if not _ringing:
		_portrait(_left, Vector2(SIDE, PORTRAIT_Y) + (tear if near else Vector2.ZERO), "operative", near, typing, k)
		_slab(Vector2(SIDE, PORTRAIT_Y + PORTRAIT.y + 10), tr("codec.speaker.operative").to_upper(), false, near)
	_portrait(_right, Vector2(rx, PORTRAIT_Y) + (tear if not near else Vector2.ZERO), far_id, _ringing or not near, typing, k)
	_slab(Vector2(rx, PORTRAIT_Y + PORTRAIT.y + 10), far_name.to_upper(), true, _ringing or not near)
	var freq := FREQUENCY if still else StoryMotion.frequency(_t, FREQUENCY)
	HudPalette.hud_text(self, Vector2(d.x / 2, PORTRAIT_Y + 130), freq, 136, GREEN, HudPalette.tracked(HudPalette.DISPLAY, 136, 0.04), 1, false)
	_wave(Vector2(d.x / 2, PORTRAIT_Y + 280), typing)
	if _ringing:
		var prompt := tr("ui.codec.answer").format({key = Prompts.key("codec_advance")}).to_upper()
		HudPalette.hud_text(self, Vector2(d.x / 2, d.y - BAR - 70), prompt, 30, GREEN, HudPalette.tracked(HudPalette.DISPLAY, 30, 0.3), 1, false)
		return
	if StoryMotion.tuning(_t) and not still:
		_static(d)
		return
	if _burst > 0.0:
		_static(d)
	_subtitle(d)


## The grid scrolls slowly (one cell in 16 s).
func _grid(d: Vector2) -> void:
	var off := fmod(Time.get_ticks_msec() / 1000.0 * 4.0, 64.0)
	var line := Color(GREEN, 0.05)
	var x := -off
	while x < d.x:
		draw_line(Vector2(x, 0), Vector2(x, d.y), line, 1.0)
		x += 64.0
	var y := -off
	while y < d.y:
		draw_line(Vector2(0, y), Vector2(d.x, y), line, 1.0)
		y += 64.0


func _portrait(node: TextureRect, at: Vector2, id: String, speaking: bool, typing: bool, k: float) -> void:
	var f := 0 if StoryMotion.still(self) else StoryMotion.frame(_line_t, speaking, typing)
	node.texture = _faces.get(FRAME % [id, f], _faces.get(FRAME % [id, 0]))
	node.position = (at + Vector2(14, 14)) * k
	node.size = (PORTRAIT - Vector2(28, 28)) * k
	node.modulate = Color(GREEN, 1.0 if speaking else 0.42)
	node.visible = true
	draw_rect(Rect2(at, PORTRAIT), CRT_DARK, true)
	draw_rect(Rect2(at, PORTRAIT), GREEN if speaking else GREEN_DIM, false, 2.0)


## The speaker's name as a slanted slab under its portrait: cut on the outer-bottom corner.
func _slab(at: Vector2, label: String, right: bool, on: bool) -> void:
	var f := HudPalette.tracked(HudPalette.DISPLAY, 28, 0.12)
	var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 46
	var x := at.x + PORTRAIT.x - w if right else at.x
	var pts := PackedVector2Array([Vector2(x, at.y), Vector2(x + w, at.y), Vector2(x + w, at.y + 52), Vector2(x, at.y + 52)])
	if right:
		pts[0].x += 20
	else:
		pts[2].x -= 20
	draw_colored_polygon(pts, GREEN if on else GREEN_DIM)
	HudPalette.hud_text(self, Vector2(x + 24, at.y + 37), label, 28, CRT_DARK, f, 0, false)


## Bars that step (never ease) only while someone talks.
func _wave(c: Vector2, talking: bool) -> void:
	@warning_ignore("integer_division")
	var step := int(Time.get_ticks_msec() / 160)
	for i in WAVE_BARS:
		var h := 12.0
		if talking:
			h = 12.0 + 108.0 * float((i * 7 + step * 5 + i * step) % 4) / 3.0
		draw_rect(Rect2(c.x - WAVE_BARS * 6 + i * 12, c.y - h / 2, 7, h), GREEN)


func _subtitle(d: Vector2) -> void:
	var top := d.y - BAR - 190
	draw_rect(Rect2(0, top, d.x, 190), Color.BLACK)
	draw_rect(Rect2(0, top, d.x, 2), GREEN)
	HudPalette.hud_text(self, Vector2(d.x / 2, top + 54), talk.speaker_name().to_upper(), 24, GREEN, HudPalette.tracked(HudPalette.DISPLAY, 24, 0.3), 1, false)
	var font := HudPalette.FIGURE
	var full := HudPalette.wrap(talk.text(), d.x - 840, font, 36)
	var left := talk.shown().length()
	for i in full.size():  # wrapped on the whole line, so typing never reflows
		var row := full[i].left(maxi(left, 0))
		var w := font.get_string_size(full[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
		var p := Vector2(d.x / 2 - w / 2, top + 108 + i * 48)
		draw_string_outline(font, p, row, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, 6, Color.BLACK)
		draw_string(font, p, row, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color.WHITE)
		left -= full[i].length() + 1
	var next := tr("ui.codec.next").format({key = Prompts.key("codec_advance")})
	var count := "%d / %d" % [talk.index + 1, talk.lines.size()]
	HudPalette.hud_text(self, Vector2(d.x - 80, d.y - BAR - 24), next + "   " + count, 18, HudPalette.LIGHT_2, HudPalette.LABEL, 2, false)


## Static over the call: flicker bars, reseeded at 30 Hz.
func _static(d: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Time.get_ticks_msec() / 33.0)
	for i in 70:
		draw_rect(Rect2(rng.randf() * d.x, rng.randf() * d.y, rng.randf_range(20, 240), 3), Color(Color.WHITE, rng.randf_range(0.1, 0.5)))
