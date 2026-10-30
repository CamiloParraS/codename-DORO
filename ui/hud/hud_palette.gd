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
const BACKDROP: Texture2D = preload("res://ui/main_menu/backdrop.png")

const HEADING: FontFile = preload("res://assets/fonts/press_start_2p_regular.ttf")
const BODY: FontFile = preload("res://assets/fonts/vt323_regular.ttf")
const HEADING_SIZE := 8
const TITLE_SIZE := 16
const BODY_SIZE := 16
const COLUMN := 400.0  # px, the width running text wraps to (live call, subtitles, briefing)

# The revamp's HUD kit (DESIGN.md), drawn on a design canvas 1080 px tall and as wide as the window's
# aspect. Ported screens use these; the ones still on the 640x360 look keep the constants above.
const DESIGN_H := 1080.0
const LIGHT := Color("f2f4f3")  # ink on the HUD: values, pictograms, marks
const LIGHT_2 := Color("f2f4f3bd")
const LIGHT_3 := Color("f2f4f38f")  # reserve counts, secondary labels
const SMOKE := Color("16191b8c")  # panel fill over the scene
const SMOKE_HI := Color("16191bb8")  # the prompt's action disc
const HAIRLINE := Color("f2f4f342")
const SAND := Color("d4bc8a")  # the Operative's own readouts: brackets, gear names, life, the Radar's arrow
const SAND_DIM := Color("d4bc8a80")
const CYAN := Color("a9d6dc")  # Aigis, and nothing else
const DMG := Color("c9302a")  # ALERT, a calling guard, life lost
const MARK_RED := Color("e0423a")  # the ! over a guard
const SLP := Color("2c6aa3")
const DARK_INK := Color("0c0e0f")  # legends on keycaps, keylines
const WELL := Color("0c0e0f8c")  # the life bar's track
const JAM := Color("150a0b")  # the jammed Radar's ground
const FIGURE: FontFile = preload("res://assets/fonts/barlow_semibold.ttf")  # numbers
const FIGURE_MED: FontFile = preload("res://assets/fonts/barlow_medium.ttf")  # sentences
const LABEL: FontFile = preload("res://assets/fonts/barlow_condensed_semibold.ttf")  # tracked uppercase labels
const DISPLAY: FontFile = preload("res://assets/fonts/antonio.ttf")  # the revamp headline face
const LABEL_BOLD: FontFile = preload("res://assets/fonts/barlow_condensed_bold.ttf")
const LABEL_MED: FontFile = preload("res://assets/fonts/barlow_condensed_medium.ttf")
const HALO := Color(0, 0, 0, 0.55)  # the dark legibility halo under text on the scene
static var _tracked := {}  # [font, px] -> FontVariation


## `font` with `em` of tracking at `fs` px, cached.
static func tracked(font: Font, fs: int, em: float) -> Font:
	var px := roundi(fs * em)
	if px == 0:
		return font
	var key := [font, px]
	if not _tracked.has(key):
		var v := FontVariation.new()
		v.base_font = font
		v.spacing_glyph = px
		_tracked[key] = v
	return _tracked[key]


## A HUD label: uppercase Barlow Condensed, tracked, over a dark halo; `align` 0 left, 1 centred on x, 2 right-aligned to x.
static func hud_label(ci: CanvasItem, pos: Vector2, s: String, fs: int, col: Color, em := 0.14, font: Font = LABEL, align := 0, halo := true) -> void:
	hud_text(ci, pos, s.to_upper(), fs, col, tracked(font, fs, em), align, halo)


## HUD text in any face over a dark halo (the Dark Halo rule: black, never a glow).
static func hud_text(ci: CanvasItem, pos: Vector2, s: String, fs: int, col: Color, font: Font = FIGURE, align := 0, halo := true) -> void:
	if align != 0:
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		pos.x -= w if align == 2 else w / 2
	if halo:
		ci.draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(4, fs / 4), Color(HALO, HALO.a * col.a))
	ci.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


static var _key_box: StyleBoxFlat


## A key drawn as a key (DESIGN.md Keycap), top-left at `p`, `legend` being the bound input's name. Returns its width.
static func keycap(ci: CanvasItem, p: Vector2, legend: String, small := false, a := 1.0) -> float:
	if not _key_box:
		_key_box = StyleBoxFlat.new()
		_key_box.shadow_size = 8
		_key_box.shadow_offset = Vector2(0, 3)
		_key_box.anti_aliasing = true
	var side := 30.0 if small else 42.0
	var fs := 14 if small else 20
	var w := maxf(side, FIGURE.get_string_size(legend, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16)
	_key_box.set_corner_radius_all(4 if small else 6)
	_key_box.bg_color = Color(LIGHT, a)
	_key_box.shadow_color = Color(0, 0, 0, 0.5 * a)
	ci.draw_style_box(_key_box, Rect2(p, Vector2(w, side)))
	hud_text(ci, Vector2(p.x + w / 2, p.y + side / 2 + fs * 0.36), legend, fs, Color(DARK_INK, a), FIGURE, 1, false)
	return w


## A smoke panel with its hairline and the two sand corner brackets (DESIGN.md Panel).
static func hud_panel(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, SMOKE)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.4)), Color(LIGHT, 0.05))
	ci.draw_rect(r, HAIRLINE, false, 1.0)
	var a := r.position - Vector2(3, 3)
	var b := r.end + Vector2(3, 3)
	ci.draw_polyline(PackedVector2Array([a + Vector2(0, 10), a, a + Vector2(10, 0)]), SAND, 2.0)
	ci.draw_polyline(PackedVector2Array([b - Vector2(0, 10), b, b - Vector2(10, 0)]), SAND, 2.0)
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


## The Harbour at dusk (shot by tools/shots.gd, set "menu") behind a full-screen page, dimmed to `dim`,
## drifting slowly, with a shade down the left so text reads over it. `behind`: drawn under the page's own _draw.
static func backdrop(page: Control, dim := Color(0.6, 0.6, 0.65), behind := false) -> void:
	var art := TextureRect.new()
	art.texture = BACKDROP
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.modulate = dim
	art.pivot_offset = page.get_viewport_rect().size * Vector2(0.7, 0.4)
	var grad := Gradient.new()
	grad.set_color(0, Color(INK, 0.9))
	grad.set_color(1, Color(INK, 0.0))
	var shade_tex := GradientTexture2D.new()
	shade_tex.gradient = grad
	shade_tex.fill_to = Vector2(1, 0)
	var shade := TextureRect.new()
	shade.texture = shade_tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	for r: TextureRect in [art, shade]:
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.show_behind_parent = behind
		page.add_child(r)
	shade.anchor_right = 0.65
	var drift := art.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	drift.tween_property(art, "scale", Vector2.ONE * 1.08, 30.0)
	drift.tween_property(art, "scale", Vector2.ONE, 30.0)


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
