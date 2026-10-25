## The paused full-screen Codec call: two portraits, the frequency, the speaker and typewriter text with
## PSone-style beeps. LMB / Space / Enter skips the typing, then moves on; `finished` after the last line.
## Add it over whatever is showing (Briefing) or to a paused tree (it keeps running).
## Portraits are ui/codec/portraits/<id>_<frame>.png, rendered once by tools/render_portraits.gd (frame 1 is
## for 13b's talk flap).
class_name CodecScreen
extends Control

signal finished

const FREQUENCY := "140.85"
const COLS := 52  # text columns at 8 px
const PORTRAITS := "res://ui/codec/portraits/%s_0.png"

var talk: CodecCall
var _font: Font = load("res://assets/fonts/press_start_2p_regular.ttf")


func _init(lines := []) -> void:
	talk = CodecCall.new(lines)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Mixer.codec_call(true)
	if talk.done():
		_finish()


func _exit_tree() -> void:
	Mixer.codec_call(false)
	Mixer.stop_blips()


func _process(delta: float) -> void:
	var p := talk.advance(delta)
	if not p.is_empty():
		Mixer.blip(p.back())  # one beep per frame: they never stack
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		talk.press()
		if talk.done():
			_finish()


func _finish() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	finished.emit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	if talk.done():
		return
	var who := talk.speaker()
	_portrait(Rect2(40, 40, 120, 120), "operative", who == "operative")
	_portrait(Rect2(size.x - 160, 40, 120, 120), "handler" if who == "operative" else talk.portrait(), who != "operative")
	_text(Vector2(size.x / 2 - FREQUENCY.length() * 4, 100), FREQUENCY, Color.WHITE)
	_text(Vector2(40, 190), talk.speaker_name(), Color(1, 1, 1, 0.6))
	draw_multiline_string(_font, Vector2(40, 210), talk.shown(), HORIZONTAL_ALIGNMENT_LEFT, COLS * 8, 8, -1, Color.WHITE)
	_text(Vector2(size.x - 40 - 14 * 8, size.y - 24), "LMB / SPACE >>", Color(1, 1, 1, 0.5))


func _portrait(r: Rect2, id: String, speaking: bool) -> void:
	var col := Color(1, 1, 1, 1.0 if speaking else 0.35)
	draw_texture_rect(load(PORTRAITS % id), r, false, col)
	draw_rect(r, col, false, 2.0)


func _text(pos: Vector2, s: String, col: Color) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
