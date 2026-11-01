## The UI kit every screen pulls from: one colour per meaning, the faces, the outlined HUD text, word wrap,
## the panel fade and the slider Theme (docs/DESIGN.md).
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
const FULL_GREEN := Color("6fe08a")  # the faintest hue life takes at full health
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


const KEY_LIFT := 0.65  # the HUD keycap lift's black (docs/DESIGN.md Shadow Vocabulary): dense enough to read over a dark scene
const DROP := Vector2(0, 2)  # a hold outline's slight drop
const CORNER_STEPS := 5  # segments per rounded corner


## A key drawn as a key (docs/DESIGN.md Keycap), top-left at `p`, `legend` being the bound input's name. Returns its width.
static func keycap(ci: CanvasItem, p: Vector2, legend: String, small := false, a := 1.0) -> float:
	var side := 33.0 if small else 42.0  # whole chrome pixels
	var fs := legible(ci, 14 if small else 20)
	var w := ceilf(maxf(side, FIGURE.get_string_size(legend, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16) / PixelKit.PX) * PixelKit.PX
	var cap := Rect2(p, Vector2(w, side))
	PixelKit.cut_fill(ci, Rect2(p + Vector2(0, PixelKit.PX), cap.size), Color(0, 0, 0, KEY_LIFT * a), 1)  # the key's lift: one pixel row of black
	PixelKit.cut_fill(ci, cap, Color(LIGHT, a), 1)
	hud_text(ci, Vector2(p.x + w / 2, p.y + side / 2 + fs * 0.36), legend, fs, Color(DARK_INK, a), FIGURE, 1, false)
	return w


## The outline of `r`, corners rounded to `radius`, as a track in `track` filled clockwise from the top-left to
## `t` (0..1) in `fill`, lifted off the scene by a slight drop shadow (alpha `shadow`, 0 for none).
static func rect_fill(ci: CanvasItem, r: Rect2, t: float, fill: Color, track: Color, width := 2.0, radius := 0.0, shadow := 0.0) -> void:
	var path := _round_rect(r, radius)
	if shadow > 0.0:
		var drop := PackedVector2Array()
		for p in path:
			drop.append(p + DROP)
		ci.draw_polyline(drop, Color(0, 0, 0, shadow), width + 1.5, true)
	ci.draw_polyline(path, track, width, true)
	t = clampf(t, 0.0, 1.0)
	if t <= 0.0:
		return
	var total := 0.0
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
	var left := t * total
	var pts := PackedVector2Array([path[0]])
	for i in path.size() - 1:
		var seg := path[i].distance_to(path[i + 1])
		if left <= seg:
			pts.append(path[i].lerp(path[i + 1], left / seg if seg > 0.0 else 1.0))
			break
		pts.append(path[i + 1])
		left -= seg
	ci.draw_polyline(pts, fill, width, true)


## The closed outline of `r` with its corners rounded to `radius`, clockwise from the end of the top-left corner.
static func _round_rect(r: Rect2, radius: float) -> PackedVector2Array:
	radius = minf(radius, minf(r.size.x, r.size.y) / 2.0)
	var centres := [Vector2(r.end.x - radius, r.position.y + radius), r.end - Vector2(radius, radius),
			Vector2(r.position.x + radius, r.end.y - radius), r.position + Vector2(radius, radius)]
	var pts := PackedVector2Array([Vector2(r.position.x + radius, r.position.y)])
	for c in 4:  # top-right, bottom-right, bottom-left, top-left: each arc after the straight edge before it
		var from := -PI / 2 + c * PI / 2
		for s in CORNER_STEPS + 1:
			pts.append(centres[c] + Vector2.from_angle(from + PI / 2 * s / CORNER_STEPS) * radius)
	return pts


const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]  # 4x4 ordered-dither thresholds
const DITHER_PX := 6.0  # one dither pixel, in design px
const DITHER_BAND := 13  # dither pixels wide
const FADE_W := DITHER_BAND * DITHER_PX  # a plate's dithered edge, which content keeps clear of

## A borderless plate: `tint` rising from alpha `a0` at the dithered edge to `a1` at the far one, the dithered edge
## (`fade_left`: the left one) crumbling away in an ordered-dither band whose pixels crawl slowly, as if fading out.
## `cells` widens the dithered edge. `cut` slants two opposite corners (the dithered edge's top and the far edge's bottom) by that many px, on a 45 degree line.
static func plate(ci: CanvasItem, r: Rect2, tint: Color, a0: float, a1: float, fade_left := true, cut := 0.0, cells := DITHER_BAND) -> void:
	var band := cells * DITHER_PX
	var body := Rect2(r.position.x + band, r.position.y, r.size.x - band, r.size.y) if fade_left else Rect2(r.position, Vector2(r.size.x - band, r.size.y))
	var lo := Color(tint, a0)  # the body starts here and the dither pixels are this strong
	var hi := Color(tint, a1)
	var shape := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	if cut > 0.0:  # clockwise from the top-left; the cuts sit top-right and bottom-left (mirrored for fade_left)
		if fade_left:
			shape = PackedVector2Array([r.position + Vector2(cut, 0), Vector2(r.end.x, r.position.y), r.end - Vector2(cut, 0), Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.position.y + cut)])
		else:
			shape = PackedVector2Array([r.position, Vector2(r.end.x - cut, r.position.y), Vector2(r.end.x, r.position.y + cut), r.end, Vector2(r.position.x + cut, r.end.y), Vector2(r.position.x, r.end.y - cut)])
	var body_shape := PackedVector2Array([body.position, Vector2(body.end.x, body.position.y), body.end, Vector2(body.position.x, body.end.y)])
	for poly in Geometry2D.intersect_polygons(shape, body_shape):
		var cols := PackedColorArray()
		for v in poly:
			var u := clampf((v.x - body.position.x) / body.size.x, 0.0, 1.0)
			cols.append(hi.lerp(lo, u) if not fade_left else lo.lerp(hi, u))
		ci.draw_polygon(poly, cols)
	var t := int(Time.get_ticks_msec() / 700.0)  # the pattern crawls a cell every 700 ms
	var w := cells * DITHER_PX
	var mask := _dither_mask(r.size, cells, fade_left, cut, t & 3)
	ci.draw_texture_rect_region(mask, Rect2(r.end.x - w if not fade_left else r.position.x, r.position.y, w, r.size.y),
			Rect2(0, 0, cells, r.size.y / DITHER_PX), lo, false, false)  # no clip_uv: it would pull a part-row back onto the row above


static var _masks := {}  # [size, cells, fade_left, cut, phase] -> CanvasTexture


## A plate's dithered band as a texture, one texel per dither pixel (white where it is lit), drawn nearest-filtered
## over the band and tinted: the same squares a draw_rect per lit cell gave, in one draw. The crawl repeats every
## 4 steps, so each plate shape needs at most 4.
static func _dither_mask(size: Vector2, cells: int, fade_left: bool, cut: float, phase: int) -> CanvasTexture:
	var key := [size if cut > 0.0 else Vector2(0, ceilf(size.y / DITHER_PX)), cells, fade_left, cut, phase]
	if _masks.has(key):
		return _masks[key]
	if _masks.size() > 256:  # a plate whose size animates would otherwise grow this without end
		_masks.clear()
	var r := Rect2(Vector2.ZERO, size)
	var shape := PackedVector2Array()
	if cut > 0.0:  # as plate's, at the origin
		if fade_left:
			shape = PackedVector2Array([Vector2(cut, 0), Vector2(r.end.x, 0), r.end - Vector2(cut, 0), Vector2(0, r.end.y), Vector2(0, cut)])
		else:
			shape = PackedVector2Array([Vector2.ZERO, Vector2(r.end.x - cut, 0), Vector2(r.end.x, cut), r.end, Vector2(cut, r.end.y), Vector2(0, r.end.y - cut)])
	var rows := ceili(size.y / DITHER_PX)
	var img := Image.create_empty(cells, rows, false, Image.FORMAT_RGBA8)
	for cx in cells:
		var dens := (cx + 0.5) / cells  # 0 at the dying edge, 1 where it meets the body
		var tx := cx if fade_left else cells - 1 - cx
		var x := cx * DITHER_PX if fade_left else r.end.x - (cx + 1) * DITHER_PX
		for ry in rows:
			if (BAYER[((ry + phase) & 3) * 4 + ((cx + phase * 3) & 3)] + 0.5) / 16.0 < dens:
				if cut > 0.0 and not Geometry2D.is_point_in_polygon(Vector2(x, ry * DITHER_PX) + Vector2(DITHER_PX, DITHER_PX) / 2.0, shape):
					continue
				img.set_pixel(tx, ry, Color.WHITE)
	var tex := CanvasTexture.new()
	tex.diffuse_texture = ImageTexture.create_from_image(img)
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_masks[key] = tex
	return tex


## `pts` filled as chunky pixels: every `px`-sized cell of the canvas grid whose centre falls inside the polygon.
static func px_poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, px := 3.0) -> void:
	var lo := pts[0]
	var hi := pts[0]
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	for gy in range(floori(lo.y / px), ceili(hi.y / px)):
		for gx in range(floori(lo.x / px), ceili(hi.x / px)):
			if Geometry2D.is_point_in_polygon(Vector2((gx + 0.5) * px, (gy + 0.5) * px), pts):
				ci.draw_rect(Rect2(gx * px, gy * px, px, px), col)


## A ring (or, with `width` 0, a disc) of radius `r` at `c`, drawn as chunky pixels.
static func px_ring(ci: CanvasItem, c: Vector2, r: float, width: float, col: Color, px := 3.0) -> void:
	for gy in range(floori((c.y - r) / px) - 1, ceili((c.y + r) / px) + 1):
		for gx in range(floori((c.x - r) / px) - 1, ceili((c.x + r) / px) + 1):
			var d := Vector2((gx + 0.5) * px, (gy + 0.5) * px).distance_to(c)
			if d <= r and (width <= 0.0 or d >= r - width):
				ci.draw_rect(Rect2(gx * px, gy * px, px, px), col)


## A smoke panel with its hairline and the two sand corner brackets (docs/DESIGN.md Panel).
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
