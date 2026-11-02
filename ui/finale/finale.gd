## The finale, full screen: the radial's single order "Transmit memories" in slowed time, the Final debate,
## the Dominant Voice's ending over slowly panning stills, then the Epilogue as subtitles over the Ascent (the Core's
## lift rising out of the shaft, the Dominant Voice's set; a paused Codec call when the Area has no such take).
## Group "finale": the Core terminal calls begin(). Free mode calls start(record, leave_to) for any Preset.
## The data lives in ai/finale.gd; stills go through the PSX banding pass like the rest of layer 0.
extends Control

const MENU := "res://ui/main_menu/main_menu.tscn"
const CREDITS := "res://ui/credits/credits.tscn"
const SLOW := 0.3        # time scale while the order is on screen
const STILL_SECONDS := 20.0
const BED_FADE := 2.5    # seconds for an ending's bed to fade in, and out into the Epilogue
const GLITCH_DB := -3.0  # the glitch under each new debate line
const GLYPHS := {promachos = "/\\", nike = ">>", pallas = "[]", gorgo = "XX", glaukopis = "()"}

var model: Finale
var leave_to := MENU
var _lines: Array = []
var _i := 0
var _blip: VoiceBlip
var _t := 0.0
var _line_t := 0.0  # since the current line began: its glyph's pulse
var _still_tex: Texture2D
var _bed: AudioStreamPlayer  # the ending's sound bed (Finale.BEDS)
var _ascending := false  # the Epilogue runs over the live Area: this control draws nothing under it


func _ready() -> void:
	add_to_group("finale")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = model != null


## From the Core terminal: the record the Mission just committed. The campaign rolls the credits on the way to
## `leave_to`; Free mode goes straight there.
func begin() -> void:
	var run := get_tree().get_first_node_in_group("mission_plan")
	if run == null or run.campaign:
		Credits.then = leave_to
		start(run.record if run else Campaign.record, CREDITS)
	else:
		start(run.record, leave_to)


func start(record: Dictionary, then: String) -> void:
	model = Finale.from_record(record)
	_still_tex = load(Finale.stills(model.band)[0].path)  # not in _draw: a texture first loaded there draws white (Godot 4.7)
	leave_to = then
	visible = true
	var hud := get_parent().get_node_or_null("HudLayer") as CanvasLayer  # the HUD's layer sits above this one
	if hud:
		hud.visible = false  # for good: the Ascent's take restores what it found, so it stays down
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
			Mixer.play(&"finale_transmit")
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
		_bed_in()
		_play(Finale.ending(model.band))
	elif model.stage == "epilogue":
		_bed_out(BED_FADE)
		_blip = null
		var codec := CodecScreen.new(Finale.epilogue(model.band))
		var take := _ascend()
		codec.over_picture = take != null
		codec.finished.connect(func() -> void:
			codec.queue_free()
			if take:
				take.release()  # to black, then _leave
			else:
				_leave())
		add_child(codec)
	else:
		_leave()


## The Ascent behind the Epilogue: the world runs at normal speed under a take that holds its last frame until the
## Epilogue is read (the lines are the player's pace; the take is short). A held skip leaves at once. Null when the
## Area has no such take (the Epilogue stays a paused call).
func _ascend() -> Cine:
	var area := get_parent()
	var set := area.get_node_or_null(AscentLogic.SET)
	if set == null or Cine.take_of(area, AscentLogic.KEY) == null:
		return null
	get_tree().paused = false
	Engine.time_scale = 1.0
	set.show_variant(model.band)
	var take := Cine.new()
	take.name = "CineRunner"
	take.hold = true
	take.held.connect(func(skipped: bool) -> void:
		if skipped:
			_leave())
	if not take.play(area, AscentLogic.KEY, _leave):
		return null
	_ascending = true
	return take


func _leave() -> void:
	model.stage = "over"
	get_tree().paused = false
	Engine.time_scale = 1.0
	Mixer.stop_blips()
	_bed_out(0.3)
	UiTransition.go(get_tree(), leave_to)


func _play(lines: Array) -> void:
	_lines = lines
	_show(0)


func _show(i: int) -> void:
	_i = i
	_line_t = 0.0
	_blip = VoiceBlip.new(tr(_lines[i][1]), _lines[i][0])
	if model.stage == "debate":
		Mixer.play(&"finale_glitch", Mixer.UI, 1.0, GLITCH_DB)  # a Voice cutting in


## The ending's bed fading in under its still, and its one-shot. Runs while the tree is paused (this control always processes).
func _bed_in() -> void:
	var b: Dictionary = Finale.BEDS[model.band]
	var s: AudioStream = load(b.path)
	if s is AudioStreamOggVorbis:
		s.loop = b.loop
	_bed = AudioStreamPlayer.new()
	_bed.stream = s
	_bed.bus = Mixer.AMBIENCE
	_bed.volume_db = Mixer.SILENT
	add_child(_bed)
	_bed.play()
	create_tween().tween_property(_bed, "volume_db", b.db, BED_FADE)
	if b.has("hit"):
		Mixer.play(b.hit, Mixer.AMBIENCE)


func _bed_out(secs: float) -> void:
	if _bed == null:
		return
	var b := _bed
	_bed = null
	var t := b.create_tween()
	t.tween_property(b, "volume_db", Mixer.SILENT, secs)
	t.tween_callback(b.queue_free)


func _draw() -> void:
	if model == null or _ascending:
		return
	var k := size.y / HudPalette.DESIGN_H
	var d := size / k
	draw_rect(Rect2(Vector2.ZERO, size), HudPalette.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var c := d / 2
	match model.stage:
		"order":
			draw_arc(c, 150.0, 0, TAU, 64, Color(HudPalette.LIGHT, 0.8), 70.0)
			HudPalette.hud_text(self, c + Vector2(0, 14), tr("ui.finale.order").to_upper(), 40, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 40, 0.2), 1, false)
			HudPalette.hud_text(self, Vector2(c.x, d.y - 80), Prompts.verb("fire", "ui.finale.send").to_upper(), 26, HudPalette.LIGHT_3, HudPalette.tracked(HudPalette.DISPLAY, 26, 0.24), 1, false)
		"debate":
			_voice_line(d, Vector2(110, 160))
		"ending":
			_still(d)
			_voice_line(d, Vector2(110, d.y - 240))


## The Voice's glyph pulsing, its name in cyan, then the line typed out (wrapped whole, so it never reflows).
func _voice_line(d: Vector2, at: Vector2) -> void:
	var k := size.y / HudPalette.DESIGN_H
	var who: String = _lines[_i][0]
	var gf := HudPalette.tracked(HudPalette.DISPLAY, 34, 0.0)
	var glyph: String = GLYPHS[who]
	var w := gf.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	draw_set_transform((at + Vector2(w / 2, -17)) * k, 0.0, Vector2(k, k) * StoryMotion.pulse(_line_t))
	draw_string(gf, Vector2(-w / 2, 17), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, HudPalette.CYAN)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	HudPalette.hud_text(self, at + Vector2(w + 16, 0), tr("ui.voice." + who).to_upper(), 34, HudPalette.CYAN, HudPalette.tracked(HudPalette.DISPLAY, 34, 0.24), 0, false)
	var full := HudPalette.wrap(tr(_lines[_i][1]), minf(d.x - 220, 1500.0), HudPalette.FIGURE_MED, 36)
	var left := _blip.shown().length()
	for i in full.size():
		HudPalette.hud_text(self, at + Vector2(0, 56 + i * 50), full[i].left(maxi(left, 0)), 36, HudPalette.LIGHT, HudPalette.FIGURE_MED)
		left -= full[i].length() + 1
	var next := tr("ui.codec.next").format({key = Prompts.key("codec_advance")})
	HudPalette.hud_text(self, Vector2(d.x - 100, d.y - 70), next.to_upper(), 22, HudPalette.LIGHT_3, HudPalette.tracked(HudPalette.DISPLAY, 22, 0.2), 2, false)


## The band's still, slowly zooming from 1.0x to 1.15x and drifting while the ending plays.
func _still(d: Vector2) -> void:
	var s: Dictionary = Finale.stills(model.band)[0]
	var tex: Texture2D = _still_tex
	var k := clampf(_t / STILL_SECONDS, 0.0, 1.0)
	var r := Rect2(Vector2(-40.0, -20.0) * k, d * (1.0 + 0.15 * k))
	draw_texture_rect(tex, r, false, HudPalette.STILL)
	HudPalette.hud_text(self, Vector2(16, d.y - 16), s.credit, 16, HudPalette.LIGHT_3, HudPalette.FIGURE_MED, 0, false)
