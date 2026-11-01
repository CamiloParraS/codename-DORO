## The revamp's menu list: a stack of slanted plates, each with a line icon and its name in Antonio. The selected
## plate slides out toward the screen's middle, turns light with dark text and takes a red tab; its one-line
## description shows under the list and the key hints under that. Focus drives selection (the mouse takes focus on
## hover) and plays `tick`. Plates fade up in a stagger when the page opens, and the selection wipes in over 0.11 s.
## Used by the main menu and the pause menu; design px, so put it under a scaled stage.
class_name UiMenu
extends PanelContainer

const ROW_H := 58.0
const GAP := 8.0
const WIDTH := 560.0
const FONT_SIZE := 30
const SLANT := 20.0       # px the plate's right edge leans in
const REACH := 26.0       # px the selected plate slides left
const SELECT_SECS := 0.11
const OPEN_SECS := 0.45
const ROW_STAGGER := 0.045
const REST := Color(0.95, 0.96, 0.95, 0.8)  # an unselected row's name
const PLATE := Color(HudPalette.GLASS, 0.66)
const ICONS := "res://assets/ui/icons/%s.svg"
const COLS: Array[float] = [52.0, 96.0, 60.0, 68.0]  # widths of the right-aligned stat columns a row may carry, rightmost last

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
	_desc.custom_minimum_size = Vector2(0, 52)  # its text sits at the bottom: a clear gap from the last plate
	_desc.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
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
func add_row(text: String, on_press := Callable(), danger := false, icon := "", desc := "", cols: Array = []) -> Button:
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
		glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # pixel art: keep its edges hard
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.position = Vector2(30, 11)
		glyph.size = Vector2(36, 36)
		glyph.modulate = REST
		b.add_child(glyph)
	var cells: Array[Label] = []
	for i in cols.size():
		var cell := _cell(String(cols[i]), i, 26, REST)
		b.add_child(cell)
		cells.append(cell)
	b.focus_entered.connect(func() -> void:
		Mixer.hover_tick()
		_desc.text = desc
		plate.select(true, SELECT_SECS)
		if glyph:
			glyph.modulate = HudPalette.DARK_INK
		for cell in cells:
			cell.add_theme_color_override("font_color", HudPalette.DARK_INK))
	b.focus_exited.connect(func() -> void:
		plate.select(false, SELECT_SECS)
		if glyph:
			glyph.modulate = REST if not b.disabled else Color(HudPalette.LIGHT, 0.3)
		for cell in cells:
			cell.add_theme_color_override("font_color", REST))
	b.button_down.connect(func() -> void:
		Mixer.press_thunk()
		plate.kick())
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	if on_press.is_valid():
		b.pressed.connect(on_press)
	_rows.add_child(b)
	return b


## A small dim line naming the stat columns of the rows below it, aligned with them.
func add_columns_header(labels: Array) -> void:
	var row := Control.new()
	row.custom_minimum_size.y = 30
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in labels.size():
		row.add_child(_cell(String(labels[i]).to_upper(), i, 16, HudPalette.LIGHT_3))
	_rows.add_child(row)


## Column `i` of a row: right-aligned in its slot, which counts back from the plate's right margin.
func _cell(text: String, i: int, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, fs, 0.06))
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	var behind := 0.0
	for j in range(i + 1, COLS.size()):
		behind += COLS[j]
	l.size = Vector2(COLS[i], ROW_H if fs > 20 else 30.0)
	l.position = Vector2(_width - 30.0 - behind - COLS[i], 0)
	return l


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
	var kick_t := 0.0  # 1 as a press lands, falling to 0
	var _tw: Tween
	var _kt: Tween

	## The press: the plate flashes white and jolts 6 px right, then settles, in 0.16 s.
	func kick() -> void:
		if UiMotion.reduced():
			return
		if _kt:
			_kt.kill()
		kick_t = 1.0
		queue_redraw()
		_kt = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
		_kt.tween_method(func(v: float) -> void:
			kick_t = v
			queue_redraw(), 1.0, 0.0, 0.16)

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
		var q := t  # the wipe moves a grid cell at a time on its own; quantising t as well made it stutter
		var x := -snappedf(UiMenu.REACH * q, PixelKit.PX) + snappedf(6.0 * kick_t, PixelKit.PX)
		var r := Rect2(x, 0, size.x - x, size.y)
		var lit := HudPalette.DMG if danger else HudPalette.LIGHT
		PixelKit.ramp(self, Rect2(r.position.x, 0, 30, size.y), UiMenu.PLATE, 5)  # the resting plate crumbles away on its left, as the HUD's do
		PixelKit.stair_fill(self, Rect2(r.position.x + 30, 0, r.size.x - 30, size.y), UiMenu.PLATE, UiMenu.SLANT)
		PixelKit.stair_fill(self, r, Color(lit, 0.95), UiMenu.SLANT, q)  # the light plate wipes in, its edge dithered
		if kick_t > 0.5:  # the press's flash
			PixelKit.stair_fill(self, r, Color.WHITE, UiMenu.SLANT)
		if q < 1.0:  # the resting plate's stair along its slanted edge
			PixelKit.stair_edge(self, r, Color(HudPalette.LIGHT, 0.25 * (1.0 - q)), UiMenu.SLANT)
		draw_rect(Rect2(x, 0, 6, size.y), Color(HudPalette.MARK_RED if danger else HudPalette.DMG, 0.35 + 0.65 * q))
		if q > 0.0:  # the pick's chevron, in pixels
			var m := size.y / 2.0
			HudPalette.px_poly(self, PackedVector2Array([Vector2(x + 12, m - 9), Vector2(x + 24, m), Vector2(x + 12, m + 9)]), Color(HudPalette.DARK_INK, q))
