## The revamp's menu list: a smoke panel with a white top rule, rows 62 px tall in Antonio, and the selected row
## as a white bar with a red 8 px tab. Focus drives selection (the mouse takes focus on hover); each change snaps
## the bar in with a 0.16 s stepped wipe and plays `tick`. Rows wipe in with a stagger when the page opens.
## Used by the main menu and the pause menu; design px, so put it under a scaled stage.
class_name UiMenu
extends PanelContainer

const ROW_H := 62.0
const WIDTH := 640.0
const FONT_SIZE := 32
const SELECT_STEPS := 5
const SELECT_SECS := 0.16
const OPEN_STEPS := 10
const OPEN_SECS := 0.5

var _rows := VBoxContainer.new()
var _rule := ColorRect.new()
var _width := WIDTH


func _init(width := WIDTH) -> void:
	_width = width
	custom_minimum_size.x = width
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.03, 0.04, 0.8)
	box.content_margin_bottom = 6
	box.content_margin_top = 0
	add_theme_stylebox_override("panel", box)
	_rows.add_theme_constant_override("separation", 0)
	add_child(_rows)
	_rule.color = HudPalette.LIGHT
	_rule.custom_minimum_size.y = 3
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_child(_rule)  # the first child; clear() leaves it


## Empties the list, then adds `heading` (dim, spaced; nothing when empty) as its first line.
func clear(heading := "") -> void:
	for c in _rows.get_children():
		if c == _rule:
			continue
		_rows.remove_child(c)
		c.queue_free()
	if heading != "":
		var l := Label.new()
		l.text = heading
		l.custom_minimum_size.y = 52
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, 20, 0.2))
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color", HudPalette.LIGHT_3)
		l.add_theme_constant_override("line_spacing", 0)
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_left", 28)
		pad.add_child(l)
		_rows.add_child(pad)


## One row; the right-hand `small` caption is optional. Pressing plays no sound of its own (the click is `tick`'s
## sibling, left to the caller's action).
func add_row(text: String, on_press := Callable(), danger := false) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(_width, ROW_H)
	b.focus_mode = Control.FOCUS_ALL
	b.clip_text = true
	var bare := StyleBoxEmpty.new()
	bare.content_margin_left = 28
	bare.content_margin_right = 20
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, bare)
	var font := HudPalette.tracked(HudPalette.DISPLAY, FONT_SIZE, 0.04)
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.add_theme_color_override("font_color", HudPalette.LIGHT)
	b.add_theme_color_override("font_hover_color", HudPalette.DARK_INK)
	b.add_theme_color_override("font_focus_color", HudPalette.DARK_INK)
	b.add_theme_color_override("font_pressed_color", HudPalette.DARK_INK)
	b.add_theme_color_override("font_hover_pressed_color", HudPalette.DARK_INK)
	b.add_theme_color_override("font_disabled_color", Color(HudPalette.LIGHT, 0.3))
	var bar := ColorRect.new()  # the selection: white, with the red tab, drawn under the text
	bar.color = HudPalette.DMG if danger else HudPalette.LIGHT  # a danger row (quit) selects in red
	bar.show_behind_parent = true
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.visible = false
	var tab := ColorRect.new()
	tab.color = HudPalette.LIGHT if danger else HudPalette.DMG
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	tab.offset_right = 8
	bar.add_child(tab)
	b.add_child(bar)
	b.focus_entered.connect(func() -> void:
		bar.visible = true
		Mixer.play(&"tick")
		UiMotion.wipe(bar, true, SELECT_STEPS, SELECT_SECS))
	b.focus_exited.connect(func() -> void: bar.visible = false)
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	if on_press.is_valid():
		b.pressed.connect(on_press)
	_rows.add_child(b)
	return b


## Focus the first enabled row; `last` focuses the last one instead (NO, on a confirm).
func focus_first(last := false) -> void:
	await get_tree().process_frame  # the old rows are still children until freed
	var rows := _rows.get_children().filter(func(c: Node) -> bool: return c is Button and not c.disabled and not c.is_queued_for_deletion())
	if not rows.is_empty():
		(rows.back() if last else rows[0]).grab_focus()


## The page opening: the top rule draws on and the rows cut in one after another.
func open() -> void:
	await get_tree().process_frame
	UiMotion.wipe(_rule, true, OPEN_STEPS, OPEN_SECS)
	UiMotion.stagger(_rows.get_children().filter(func(c: Node) -> bool: return c != _rule))
