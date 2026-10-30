## A Mission's intro or outro card: black screen, centred text lines, StoryMotion's timing (2.3 s). The intro opens
## black and clears to the Area; the outro fades the Area to black and stays black until the post-Mission screen
## covers it. The key that advances text skips to the fade. `done` once; MissionRun owns the pause around it.
class_name MissionCard
extends Control

signal done

var intro := true
var clears := true              # an intro clears to the Area; before the Codec call it stays black
var lines: Array[String] = []   # translated; the first is the big one
var _t := 0.0
var _box := VBoxContainer.new()
var _bg := ColorRect.new()
var _over := false


## A card with its lines translated.
static func build(keys: Array, is_intro: bool, clears_to_area := true) -> MissionCard:
	var card := MissionCard.new()
	card.intro = is_intro
	card.clears = clears_to_area
	for k: String in keys:
		card.lines.append(TranslationServer.translate(k))
	return card


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
	var k := get_viewport_rect().size.y / HudPalette.DESIGN_H  # sized from the 1080 design
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size.x = 1300.0 * k
		var fs := roundi((96 if i == 0 else 28) * k)
		var last_line := i == lines.size() - 1 and i > 0 and not intro
		var font: Font = HudPalette.FIGURE_MED if last_line else HudPalette.tracked(HudPalette.DISPLAY, fs, 0.2 if i == 0 else 0.3)
		l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", roundi(32 * k) if last_line else fs)
		l.add_theme_color_override("font_color", HudPalette.LIGHT if i == 0 else HudPalette.LIGHT_2)
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
	_bg.modulate.a = backdrop(_t)


## The black's opacity at time t.
func backdrop(t: float) -> float:
	if intro and not clears:
		return 1.0
	var total := StoryMotion.CARD_FADE * 2.0 + StoryMotion.CARD_HOLD
	return clampf((total - t) / StoryMotion.CARD_FADE, 0.0, 1.0) if intro else clampf(t / StoryMotion.CARD_FADE, 0.0, 1.0)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_t = maxf(_t, StoryMotion.CARD_FADE + StoryMotion.CARD_HOLD)  # straight to the fade-out
