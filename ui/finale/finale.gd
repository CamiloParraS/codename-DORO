## The finale, full screen: the radial's single order "Transmit memories" in slowed time, the Final debate,
## the Dominant Voice's ending over slowly panning stills, then the Epilogue as a paused Codec call.
## Group "finale": the Core terminal calls begin(). Free mode calls start(record, leave_to) for any Preset.
## The data lives in ai/finale.gd; stills go through the PSX banding pass like the rest of layer 0.
extends Control

const MENU := "res://ui/main_menu/main_menu.tscn"
const SLOW := 0.3        # time scale while the order is on screen
const STILL_SECONDS := 20.0
const GLYPHS := {promachos = "/\\", nike = ">>", pallas = "[]", gorgo = "XX", glaukopis = "()"}

var model: Finale
var leave_to := MENU
var _lines: Array = []
var _i := 0
var _blip: VoiceBlip
var _t := 0.0
var _line_t := 0.0  # since the current line began: its glyph's pulse
var _font := HudPalette.HEADING


func _ready() -> void:
	add_to_group("finale")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = model != null


## From the Core terminal: the record the Mission just committed.
func begin() -> void:
	var run := get_tree().get_first_node_in_group("mission_plan")
	start(run.record if run else Campaign.record, leave_to)


func start(record: Dictionary, then: String) -> void:
	model = Finale.from_record(record)
	leave_to = then
	visible = true
	HudPalette.fade(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	Engine.time_scale = SLOW
	queue_redraw()


func _process(delta: float) -> void:
	if model == null:
		return
	_t += delta / maxf(Engine.time_scale, 0.01)  # stills pan in real time, not slowed time
	if not StoryMotion.still(self):
		_line_t += delta / maxf(Engine.time_scale, 0.01)
	if _blip:
		var p := _blip.advance(delta / maxf(Engine.time_scale, 0.01))
		if not p.is_empty():
			Mixer.blip(p.back())
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if model == null or not (e.is_action_pressed("ui_accept") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT)):
		return
	get_viewport().set_input_as_handled()
	match model.stage:
		"order":
			Engine.time_scale = 1.0
			model.transmit()
			_play(Finale.debate(model.band, model.spoofing))
		"debate", "ending":
			if not _blip.done():
				_blip.skip()
				_line_t = StoryMotion.PULSE
				Mixer.stop_blips()
			elif _i + 1 < _lines.size():
				_show(_i + 1)
			else:
				_advance()


func _advance() -> void:
	model.next()
	_t = 0.0
	if model.stage == "ending":
		_play(Finale.ending(model.band))
	elif model.stage == "epilogue":
		_blip = null
		var codec := CodecScreen.new(Finale.epilogue(model.band))
		codec.finished.connect(func() -> void:
			codec.queue_free()
			_leave())
		add_child(codec)
	else:
		_leave()


func _leave() -> void:
	model.stage = "over"
	get_tree().paused = false
	Engine.time_scale = 1.0
	Mixer.stop_blips()
	get_tree().change_scene_to_file(leave_to)


func _play(lines: Array) -> void:
	_lines = lines
	_show(0)


func _show(i: int) -> void:
	_i = i
	_line_t = 0.0
	_blip = VoiceBlip.new(tr(_lines[i][1]), _lines[i][0])


func _draw() -> void:
	if model == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), HudPalette.INK)
	var c := size / 2
	match model.stage:
		"order":
			draw_arc(c, 60.0, 0, TAU, 48, Color(HudPalette.CHROME, 0.8), 28.0)
			HudPalette.centered(self, c.x, c.y + 4, tr("ui.finale.order").to_upper(), HudPalette.WHITE)
			HudPalette.centered(self, c.x, size.y - 24, Prompts.verb("fire", "ui.finale.send"), HudPalette.HINT)
		"debate":
			_voice_line(Vector2(40, 60))
		"ending":
			_still()
			_voice_line(Vector2(40, size.y - 90))


func _voice_line(at: Vector2) -> void:
	var who: String = _lines[_i][0]
	var w := StoryMotion.draw_glyph(self, _font, at, GLYPHS[who], _line_t, HudPalette.AIGIS)
	_text(at + Vector2(w + 16, 0), tr("ui.voice." + who), HudPalette.AIGIS)
	var full := HudPalette.wrap(tr(_lines[_i][1]), size.x - 80)
	var left := _blip.shown().length()
	for i in full.size():
		HudPalette.text(self, at + Vector2(0, 24 + i * 16), full[i].left(maxi(left, 0)), HudPalette.WHITE, HudPalette.BODY, HudPalette.BODY_SIZE)
		left -= full[i].length() + 1
	var next := tr("ui.codec.next").format({key = Prompts.key("codec_advance")})
	_text(Vector2(size.x - 40 - _font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, size.y - 24), next, HudPalette.HINT)


## The band's still, slowly zooming from 1.0x to 1.15x and drifting while the ending plays.
func _still() -> void:
	var s: Dictionary = Finale.stills(model.band)[0]
	var tex: Texture2D = load(s.path)
	var k := clampf(_t / STILL_SECONDS, 0.0, 1.0)
	var r := Rect2(Vector2(-20.0, -10.0) * k, size * (1.0 + 0.15 * k))
	draw_texture_rect(tex, r, true, HudPalette.STILL)
	_text(Vector2(8, size.y - 8), s.credit, HudPalette.EMPTY)


func _text(pos: Vector2, s: String, col: Color) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
