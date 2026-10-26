## A Mission's intro or outro card: black screen, centred text lines, StoryMotion's timing (2.3 s). The intro opens
## black and clears to the Area; the outro fades the Area to black and stays black until the post-Mission screen
## covers it. The key that advances text skips to the fade. `done` once; MissionRun owns the pause around it.
class_name MissionCard
extends Control

signal done

var intro := true
var lines: Array[String] = []   # translated; the first is the big one
var _t := 0.0
var _box := VBoxContainer.new()
var _bg := ColorRect.new()
var _over := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = HudPalette.theme()
	_bg.color = HudPalette.INK
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 10)
	add_child(_box)
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size.x = HudPalette.COLUMN
		l.add_theme_font_size_override("font_size", HudPalette.TITLE_SIZE if i == 0 else HudPalette.HEADING_SIZE)
		l.add_theme_color_override("font_color", HudPalette.WHITE if i == 0 else HudPalette.CHROME_DIM)
		if i == lines.size() - 1 and i > 0 and not intro:
			l.add_theme_font_override("font", HudPalette.BODY)
		_box.add_child(l)
	_apply()


func _process(delta: float) -> void:
	if _over:
		return
	_t += delta
	_apply()
	if StoryMotion.card_over(_t):
		_over = true
		done.emit()
		if intro:
			queue_free()
		else:  # stays black under the post-Mission screen's own fade-in
			get_tree().create_timer(HudPalette.FADE, true, false, true).timeout.connect(queue_free)


func _apply() -> void:
	_box.modulate.a = StoryMotion.card(_t)
	var total := StoryMotion.CARD_FADE * 2.0 + StoryMotion.CARD_HOLD
	_bg.modulate.a = clampf((total - _t) / StoryMotion.CARD_FADE, 0.0, 1.0) if intro else clampf(_t / StoryMotion.CARD_FADE, 0.0, 1.0)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_t = maxf(_t, StoryMotion.CARD_FADE + StoryMotion.CARD_HOLD)  # straight to the fade-out
