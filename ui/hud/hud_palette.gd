## The UI kit every screen pulls from: one colour per meaning, the two faces, the outlined text, word wrap,
## the panel fade and the menu Theme.
## Colour: chrome is the Operative's own information; cyan is only ever Aigis; red is danger or empty;
## amber marks EVASION and nothing else. Type: Press Start 2P (HEADING) for labels and headings at 8 or 16 px,
## VT323 (BODY) for running text at 16 px; both are integer sizes of their pixel grids.
class_name HudPalette
extends RefCounted

const WHITE := Color.WHITE  # a live or highlighted value
const CHROME := Color(0.86, 0.88, 0.86)  # Operative info: life, ammo, stance, labels
const CHROME_DIM := Color(0.86, 0.88, 0.86, 0.8)  # reserve counts, speaker names, secondary labels
const HINT := Color(0.86, 0.88, 0.86, 0.55)  # key prompts in footers, an idle portrait
const EMPTY := Color(0.86, 0.88, 0.86, 0.2)  # empty pips, the life bar's track
const AIGIS := Color("2bd4f5")  # detection arcs, Voice tags, habit ticks
const AIGIS_DIM := Color(0.17, 0.83, 0.96, 0.35)  # a barely-there arc
const DANGER := Color(1, 0.22, 0.2)  # ALERT, low life, empty magazine, edge flash
const EVASION := Color(1, 0.69, 0.1)  # EVASION chip and bar
const SHADE := Color(0, 0, 0, 0.55)  # card backing
const SCRIM := Color(0, 0, 0, 0.9)  # a full-screen panel over play
const INK := Color.BLACK  # outlines and full-screen backgrounds
const STILL := Color(0.55, 0.55, 0.6)  # a finale still dimmed under running text

const HEADING: FontFile = preload("res://assets/fonts/press_start_2p_regular.ttf")
const BODY: FontFile = preload("res://assets/fonts/vt323_regular.ttf")
const HEADING_SIZE := 8
const TITLE_SIZE := 16
const BODY_SIZE := 16
const COLUMN := 400.0  # px, the width running text wraps to (live call, subtitles, briefing)
const FADE := 0.4  # s, every full-screen panel in and out (the post-Mission screen's)
const MARKER := 12  # px left of a menu button's text, where ">" marks focus


## Greedy word wrap of `text` to `width` px in `font` at `fs`; "\n" starts a new line. A word wider
## than the width gets a line of its own.
static func wrap(text: String, width: float, font: Font = BODY, fs := BODY_SIZE) -> PackedStringArray:
	var out := PackedStringArray()
	for para in text.split("\n"):
		var line := ""
		for w in para.split(" ", false):
			var t := w if line == "" else line + " " + w
			if line != "" and font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
				out.append(line)
				line = w
			else:
				line = t
		if line != "":
			out.append(line)
	return out


## Text with the HUD's 4-way black outline (it replaces card backings), from inside `ci`'s _draw().
static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color, font: Font = HEADING, fs := HEADING_SIZE) -> void:
	for o in [Vector2(1, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]:
		ci.draw_string(font, pos + o, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK, col.a))
	ci.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## Outlined text centred on x.
static func centered(ci: CanvasItem, x: float, y: float, s: String, col: Color, font: Font = HEADING, fs := HEADING_SIZE) -> void:
	text(ci, Vector2(roundf(x - font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x / 2), y), s, col, font, fs)


## Fades `c` in from clear (on) or out to clear, over FADE, through pauses and slowed time. A new fade
## replaces one still running, so a quick close-and-reopen never ends hidden.
static func fade(c: CanvasItem, on := true) -> Tween:
	if c.has_meta(&"fade"):
		(c.get_meta(&"fade") as Tween).kill()
	if on:
		c.modulate.a = 0.0
	var t := c.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale()
	c.set_meta(&"fade", t)
	t.tween_property(c, "modulate:a", 1.0 if on else 0.0, FADE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return t


## The menu Theme: bare chrome text, white with a ">" when focused or hovered, a 1 px slider with a square grabber.
static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = HEADING
	t.default_font_size = HEADING_SIZE
	var bare := StyleBoxEmpty.new()
	bare.content_margin_left = MARKER
	bare.content_margin_top = 3
	bare.content_margin_bottom = 3
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		t.set_stylebox(s, "Button", bare)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", CHROME)
	for c in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", WHITE)
	t.set_color("font_disabled_color", "Button", EMPTY)
	t.set_color("font_color", "Label", CHROME)
	var track := StyleBoxLine.new()
	track.color = CHROME_DIM
	track.thickness = 1
	var lit := StyleBoxLine.new()
	lit.color = WHITE
	lit.thickness = 1
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", lit)
	t.set_stylebox("grabber_area_highlight", "HSlider", lit)
	t.set_icon("grabber", "HSlider", _square(CHROME))
	t.set_icon("grabber_highlight", "HSlider", _square(WHITE))
	t.set_icon("grabber_disabled", "HSlider", _square(EMPTY))
	t.set_stylebox("focus", "HSlider", lit)  # a focused slider lights its whole track
	return t


## A menu row: the Theme's button that takes focus on hover and draws ">" while focused, so mouse and
## keyboard share one highlight. `caption` may be a text key (it translates itself).
static func menu_button(caption: String, on_press := Callable()) -> Button:
	var b := Button.new()
	b.text = caption
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	b.focus_entered.connect(b.queue_redraw)
	b.focus_exited.connect(b.queue_redraw)
	b.draw.connect(func() -> void:
		if b.has_focus():
			var y := (b.size.y + HEADING.get_ascent(HEADING_SIZE) - HEADING.get_descent(HEADING_SIZE)) / 2
			b.draw_string(HEADING, Vector2(0, roundf(y)), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, HEADING_SIZE, WHITE))
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


## A label in the Theme: `fs` 8 for rows, 16 for a screen's title.
static func label(s: String, fs := HEADING_SIZE, col := CHROME) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l


static func _square(c: Color) -> ImageTexture:
	var img := Image.create(6, 8, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)
