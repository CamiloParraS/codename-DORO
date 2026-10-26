## The paused full-screen Codec call: two portraits, the frequency boxed between them, the speaker and
## typewriter text (VT323, wrapped to the text block) with PSone-style beeps. Fades in over HudPalette.FADE. LMB / Space / Enter skips the typing, then moves on; `finished` after the last line.
## Add it over whatever is showing (Briefing) or to a paused tree (it keeps running).
## Portraits are ui/codec/portraits/<id>_<frame>.png, rendered once by tools/render_portraits.gd (frame 1 is
## the talk flap and blink).
## Motion (ui/codec/story_motion.gd): a tune-in on opening, a cut on closing; a press skips either.
class_name CodecScreen
extends Control

signal finished

const FREQUENCY := "140.85"
const PORTRAITS := "res://ui/codec/portraits/%s_0.png"
const FRAME := "res://ui/codec/portraits/%s_%d.png"
const TEXT_Y := 206.0  # the speaker's line; the text starts under it

var talk: CodecCall
var _t := 0.0       # since the call opened (the tune-in)
var _line_t := 0.0  # since the current line began
var _line := 0
var _cut := -1.0    # seconds left of the closing cut; -1 while the call is on
var _font := HudPalette.HEADING


func _init(lines := []) -> void:
	talk = CodecCall.new(lines)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	if not StoryMotion.still(self):
		_t += delta
		_line_t += delta
	var p := talk.advance(delta)
	if not p.is_empty():
		Mixer.blip(p.back())  # one beep per frame: they never stack
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), HudPalette.INK)
	if talk.done():
		return
	var who := talk.speaker()
	var typing := talk.typing()
	_portrait(Rect2(40, 40, 120, 120), "operative", who == "operative", typing)
	_portrait(Rect2(size.x - 160, 40, 120, 120), "handler" if who == "operative" else talk.portrait(), who != "operative", typing)
	var still := StoryMotion.still(self)
	var freq := FREQUENCY if still else StoryMotion.frequency(_t, FREQUENCY)
	var fw := _font.get_string_size(FREQUENCY, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.TITLE_SIZE).x
	var box := Rect2(roundf(size.x / 2 - fw / 2) - 8, 86, fw + 16, 28)
	draw_rect(box, HudPalette.CHROME_DIM, false, 1.0)
	draw_string(_font, box.position + Vector2(8, 22), freq, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.TITLE_SIZE, HudPalette.WHITE)
	if StoryMotion.tuning(_t) and not still:
		_static()
		return
	_text(Vector2(40, TEXT_Y - 16), talk.speaker_name(), HudPalette.CHROME)
	var full := HudPalette.wrap(talk.text(), size.x - 80)
	var left := talk.shown().length()
	for i in full.size():  # wrapped on the whole line, so typing never reflows
		draw_string(HudPalette.BODY, Vector2(40, TEXT_Y + 6 + i * 16), full[i].left(maxi(left, 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.BODY_SIZE, HudPalette.WHITE)
		left -= full[i].length() + 1
	var next := tr("ui.codec.next").format({key = Prompts.key("codec_advance")})
	_text(Vector2(size.x - 40 - _font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, size.y - 24), next, HudPalette.HINT)


## Static over the call while it tunes in: flicker bars, reseeded at 30 Hz.
func _static() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_t * 30.0)
	for i in 40:
		draw_rect(Rect2(rng.randf() * size.x, rng.randf() * size.y, rng.randf_range(8, 80), 2), Color(HudPalette.WHITE, rng.randf_range(0.1, 0.5)))


func _portrait(r: Rect2, id: String, speaking: bool, typing: bool) -> void:
	var f := 0 if StoryMotion.still(self) else StoryMotion.frame(_line_t, speaking, typing)
	draw_texture_rect(load(FRAME % [id, f]), r, false, HudPalette.WHITE if speaking else HudPalette.HINT)
	draw_rect(r, HudPalette.CHROME if speaking else HudPalette.EMPTY, false, 2.0)


func _text(pos: Vector2, s: String, col: Color) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
