## The UI kit every screen pulls from: one colour per meaning, the faces, the outlined HUD text, word wrap,
## the panel fade and the slider Theme (DESIGN.md).
## Colour: sand is the Operative's own information and selection; cyan is only ever Aigis; red is danger.
## Type: Barlow, Barlow Condensed and Antonio, drawn on a 1080 px design canvas as wide as the window's aspect.
class_name HudPalette
extends RefCounted

const INK := Color.BLACK  # outlines and full-screen backgrounds
const SCRIM := Color(0, 0, 0, 0.9)  # a full-screen panel over play
const STILL := Color(0.55, 0.55, 0.6)  # a finale still dimmed under running text
const BACKDROP: Texture2D = preload("res://ui/main_menu/backdrop.png")

const DESIGN_H := 1080.0
const LIGHT := Color("ecebe3")  # ink on the HUD: values, pictograms, marks
const LIGHT_2 := Color("f2f4f3bd")
const LIGHT_3 := Color("f2f4f38f")  # reserve counts, secondary labels
const SMOKE := Color("16191b8c")  # panel fill over the scene
const GLASS := Color(0.035, 0.05, 0.058)  # the dark teal under every translucent plate; set the alpha at the call
const GROUND := Color("0a0d0f")  # the near-black under full-screen menus
const SOFT := Color(0.81, 0.83, 0.82)  # the main menu dial and its rings
const BACKDROP_DIM := Color(0.4, 0.4, 0.45)  # the backdrop under a menu page
const SMOKE_HI := Color("16191bb8")  # the prompt's action disc
const HAIRLINE := Color("f2f4f342")
const SAND := Color("d4bc8a")  # the Operative's own readouts: brackets, gear names, life, the Radar's arrow
const SAND_DIM := Color("d4bc8a80")
const MINT := Color("8fd9c0")  # the live call card and the Codec
const CYAN := Color("a9d6dc")  # Aigis, and nothing else
const DMG := Color("c42032")  # ALERT, a calling guard, life lost
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
const FADE := UiMotion.T_MOMENT  # s, every full-screen panel in and out (the post-Mission screen's)
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


## The smallest a design-px size may be on the real screen, so low-resolution windows stay readable.
const MIN_PX := 15.0  # on the real screen
const MIN_DESIGN := 20  # and never below this on the 1080 canvas, so labels hold up at any window size


## `fs` (1080-tall design px) raised until it is at least MIN_DESIGN, and MIN_PX tall in the actual window.
static func legible(ci: CanvasItem, fs: int) -> int:
	var win := ci.get_window()
	var per_design: float = (float(win.size.y) if win else DESIGN_H) / DESIGN_H
	return maxi(maxi(fs, MIN_DESIGN), ceili(MIN_PX / maxf(per_design, 0.01)))


## HUD text in any face over a dark halo (the Dark Halo rule: black, never a glow).
static func hud_text(ci: CanvasItem, pos: Vector2, s: String, fs: int, col: Color, font: Font = FIGURE, align := 0, halo := true) -> void:
	fs = legible(ci, fs)
	if align != 0:
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		pos.x -= w if align == 2 else w / 2
	if halo:
		var outline := maxi(4, roundi(fs * 0.25))
		ci.draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, Color(HALO, HALO.a * col.a))
	ci.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


static var _key_box: StyleBoxFlat


## A key drawn as a key (DESIGN.md Keycap), top-left at `p`, `legend` being the bound input's name. Returns its width.
static func keycap(ci: CanvasItem, p: Vector2, legend: String, small := false, a := 1.0) -> float:
	if not _key_box:
		_key_box = StyleBoxFlat.new()
		_key_box.shadow_size = 8
		_key_box.shadow_offset = Vector2(0, 3)
		_key_box.anti_aliasing = true
	var side := 34.0 if small else 42.0
	var fs := legible(ci, 14 if small else 20)
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


## Greedy word wrap of `body` to `width` px in `font` at `fs`; "\n" starts a new line. A word wider
## than the width gets a line of its own.
static func wrap(body: String, width: float, font: Font = FIGURE_MED, fs := 24) -> PackedStringArray:
	var out := PackedStringArray()
	for para in body.split("\n"):
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


## Fades `c` in from clear (on) or out to clear, over FADE, through pauses and slowed time. A new fade
## replaces one still running, so a quick close-and-reopen never ends hidden.
static func fade(c: CanvasItem, on := true) -> Tween:
	if c.has_meta(&"fade"):
		(c.get_meta(&"fade") as Tween).kill()
	if on:
		c.modulate.a = 0.0
	var t := c.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale()
	c.set_meta(&"fade", t)
	UiMotion.ease_out(t).tween_property(c, "modulate:a", 1.0 if on else 0.0, FADE)
	return t


## The Theme: bare chrome text, light with a dark face when focused, a 1 px slider with a square grabber.
static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = tracked(DISPLAY, 24, 0.1)
	t.default_font_size = 24
	var bare := StyleBoxEmpty.new()
	bare.content_margin_top = 3
	bare.content_margin_bottom = 3
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		t.set_stylebox(s, "Button", bare)
	t.set_color("font_color", "Button", LIGHT_2)
	for c in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", LIGHT)
	t.set_color("font_disabled_color", "Button", Color(LIGHT, 0.3))
	t.set_color("font_color", "Label", LIGHT_2)
	var track := StyleBoxLine.new()
	track.color = LIGHT_3
	track.thickness = 1
	var lit := StyleBoxLine.new()
	lit.color = LIGHT
	lit.thickness = 1
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", lit)
	t.set_stylebox("grabber_area_highlight", "HSlider", lit)
	t.set_icon("grabber", "HSlider", _square(LIGHT_2))
	t.set_icon("grabber_highlight", "HSlider", _square(LIGHT))
	t.set_icon("grabber_disabled", "HSlider", _square(Color(LIGHT, 0.3)))
	t.set_stylebox("focus", "HSlider", lit)  # a focused slider lights its whole track
	return t


static func _square(c: Color) -> ImageTexture:
	var img := Image.create(6, 8, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)
