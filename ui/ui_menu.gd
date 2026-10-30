## The revamp's menu list: a stack of slanted plates, each with a line icon and its name in Antonio. The selected
## plate slides out toward the screen's middle, turns light with dark text and takes a red tab; its one-line
## description shows under the list and the key hints under that. Focus drives selection (the mouse takes focus on
## hover) and plays `tick`. Plates fade up in a stagger when the page opens, and the selection eases in over 0.16 s.
## Used by the main menu and the pause menu; design px, so put it under a scaled stage.
class_name UiMenu
extends PanelContainer

const ROW_H := 58.0
const GAP := 8.0
const WIDTH := 560.0
const FONT_SIZE := 30
const SLANT := 20.0       # px the plate's right edge leans in
const REACH := 26.0       # px the selected plate slides left
const SELECT_SECS := 0.16
const OPEN_SECS := 0.45
const ROW_STAGGER := 0.045
const REST := Color(0.95, 0.96, 0.95, 0.8)  # an unselected row's name
const PLATE := Color(HudPalette.GLASS, 0.66)
const ICONS := "res://assets/ui/icons/%s.svg"

var _rows := VBoxContainer.new()
var _rule := ColorRect.new()
var _desc := Label.new()
var _hints := Control.new()
var _width := WIDTH
var _show_hints := false


func _init(width := WIDTH, hints := false) -> void:
	_width = width
	_show_hints = hints
	custom_minimum_size.x = width
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	add_theme_stylebox_override("panel", box)
	_rows.add_theme_constant_override("separation", int(GAP))
	add_child(_rows)
	_rule.color = Color(HudPalette.LIGHT, 0.45)
	_rule.custom_minimum_size.y = 1
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_child(_rule)  # the first child; clear() leaves it
	_desc.add_theme_font_override("font", HudPalette.tracked(HudPalette.LABEL, 22, 0.14))
	_desc.add_theme_font_size_override("font_size", 22)
	_desc.add_theme_color_override("font_color", HudPalette.LIGHT_2)
	_desc.custom_minimum_size = Vector2(0, 30)
	_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hints.custom_minimum_size = Vector2(0, 44)
	_hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hints.draw.connect(_draw_hints)


## Empties the list, then adds `heading` (dim, spaced; nothing when empty) as its first line.
func clear(heading := "") -> void:
	for c in _rows.get_children():
		if c == _rule or c == _desc or c == _hints:
			continue
		_rows.remove_child(c)
		c.queue_free()
	_desc.text = ""
	if heading != "":
		var l := Label.new()
		l.text = heading
		l.custom_minimum_size.y = 44
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, 22, 0.2))
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", HudPalette.LIGHT_2)
		l.add_theme_constant_override("line_spacing", 0)
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_left", 8)
		pad.add_child(l)
		_rows.add_child(pad)


## One plate. `icon` names an SVG in assets/ui/icons (none: the name starts further left); `desc` is the line
## shown under the list while the row is selected. Pressing plays no sound of its own.
func add_row(text: String, on_press := Callable(), danger := false, icon := "", desc := "") -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(_width, ROW_H)
	b.focus_mode = Control.FOCUS_ALL
	b.clip_text = true
	var bare := StyleBoxEmpty.new()
	bare.content_margin_left = 86 if icon != "" else 36
	bare.content_margin_right = 30
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, bare)
	b.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, FONT_SIZE, 0.06))
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.add_theme_color_override("font_color", REST)
	for c in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, HudPalette.DARK_INK)
	b.add_theme_color_override("font_disabled_color", Color(HudPalette.LIGHT, 0.3))
	var plate := _Plate.new()
	plate.danger = danger
	plate.show_behind_parent = true
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(plate)
	var glyph: TextureRect
	if icon != "":
		glyph = TextureRect.new()
		glyph.texture = load(ICONS % icon)
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glyph.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.position = Vector2(30, 11)
		glyph.size = Vector2(36, 36)
		glyph.modulate = REST
		b.add_child(glyph)
	b.focus_entered.connect(func() -> void:
		Mixer.play(&"tick")
		_desc.text = desc
		plate.select(true, SELECT_SECS)
		if glyph:
			glyph.modulate = HudPalette.DARK_INK)
	b.focus_exited.connect(func() -> void:
		plate.select(false, SELECT_SECS)
		if glyph:
			glyph.modulate = REST if not b.disabled else Color(HudPalette.LIGHT, 0.3))
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


## The page opening: the top rule draws on and the plates fade up one after another. The description and key
## hints go in last, under the list.
func open() -> void:
	await get_tree().process_frame
	var extras: Array[Control] = [_desc]
	if _show_hints:
		extras.append(_hints)
	for extra in extras:
		if extra.get_parent() == null:
			_rows.add_child(extra)
		else:
			_rows.move_child(extra, -1)
	UiMotion.grow_x(_rule, OPEN_SECS)
	var plates := _rows.get_children().filter(func(c: Node) -> bool: return c != _rule and c != _desc and c != _hints)
	UiMotion.rise(plates, ROW_STAGGER)


func _draw_hints() -> void:
	var x := 6.0
	for pair in [["ENTER", "ui.hint.select"], ["ESC", "ui.hint.back"]]:
		var w := HudPalette.keycap(_hints, Vector2(x, 6), pair[0], true, 0.9)
		var label := tr(pair[1]).to_upper()
		HudPalette.hud_text(_hints, Vector2(x + w + 10, 28), label, 20, HudPalette.LIGHT_2, HudPalette.tracked(HudPalette.LABEL, 20, 0.16), 0, false)
		x += w + 10 + HudPalette.LABEL.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 40


## One row's slanted plate: dark at rest, and when selected it slides left, turns light and shows the red tab.
class _Plate extends Control:
	var danger := false
	var t := 0.0  # 0 at rest .. 1 selected
	var _tw: Tween

	func select(on: bool, secs: float) -> void:
		if _tw:
			_tw.kill()
		if UiMotion.reduced():
			t = 1.0 if on else 0.0
			queue_redraw()
			return
		_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
		UiMotion.ease_out(_tw)
		_tw.tween_method(func(v: float) -> void:
			t = v
			queue_redraw(), t, 1.0 if on else 0.0, secs)

	func _draw() -> void:
		var x := -UiMenu.REACH * t
		var w := size.x + UiMenu.REACH * t
		var h := size.y
		var pts := PackedVector2Array([Vector2(x, 0), Vector2(x + w, 0), Vector2(x + w - UiMenu.SLANT, h), Vector2(x, h)])
		var lit := HudPalette.DMG if danger else HudPalette.LIGHT
		draw_colored_polygon(pts, UiMenu.PLATE.lerp(lit, t * 0.95))
		if t < 1.0:  # the resting plate's hairline along its slanted edge
			draw_polyline(PackedVector2Array([Vector2(x + w, 0), Vector2(x + w - UiMenu.SLANT, h)]), Color(HudPalette.LIGHT, 0.25 * (1.0 - t)), 1.0)
		draw_rect(Rect2(x, 0, 6, h), Color(HudPalette.MARK_RED if danger else HudPalette.DMG, 0.35 + 0.65 * t))
