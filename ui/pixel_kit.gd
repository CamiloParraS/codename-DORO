## The pixel-and-dither chrome shared by every screen (the HUD's language, docs/DESIGN.md Pixel Chrome): shapes snap to
## a 3 px grid, slants are stairs, and a fill arrives or dies in an ordered-dither band, never a smooth ramp.
## Type stays clean; only the chrome is pixels. Draw with these from a CanvasItem's `_draw`.
class_name PixelKit
extends RefCounted

const PX := 3.0  # one chrome pixel, in design px
const BAND := 5  # cells wide of a wipe's dithered leading edge
const STEPS := 6  # frames a tween's progress is quantised to, so a fade reads as hard steps


## `t` (0..1) held to STEPS hard steps.
static func stepped(t: float) -> float:
	return floorf(clampf(t, 0.0, 1.0) * STEPS) / STEPS


## Row `i` of `rows`'s right edge for a slab leaning in `slant` px: whole cells, one step every `run` rows, so the
## stair is even (a 3 px step per fixed number of rows) and its corners sit on the chrome grid.
static func stair_end(right: float, slant: float, i: int, rows: int, px := PX) -> float:
	var cells := roundi(slant / px)
	if cells <= 0:
		return snappedf(right, px)
	var run := maxi(1, roundi(float(rows) / cells))
	return snappedf(right, px) - px * mini(cells, floori(float(i) / run))


## `r` as stacked rows of `px` height, its right edge leaning in `slant` px toward the bottom, on a stair.
## `col` fills it up to `t` (0..1) from the left, the leading edge crumbling in an ordered-dither band that
## crawls with `shift`; at t = 1 it is solid. Rows are snapped to the grid.
static func stair_fill(ci: CanvasItem, r: Rect2, col: Color, slant := 0.0, t := 1.0, shift := 0, px := PX) -> void:
	if t <= 0.0 or col.a <= 0.0:
		return
	var rows := ceili(r.size.y / px)
	var band := BAND * px
	for i in rows:
		var y := r.position.y + i * px
		var end := stair_end(r.end.x, slant, i, rows, px)
		var h := minf(px, r.end.y - y)
		var reach := r.position.x + t * (end - r.position.x + band)  # the wipe's far edge, band included
		var solid := minf(end, reach - band)
		if solid > r.position.x:
			ci.draw_rect(Rect2(r.position.x, y, solid - r.position.x, h), col)
		if t >= 1.0:
			continue
		var x := maxf(solid, r.position.x)
		var cell := floori((x - r.position.x) / px)
		while r.position.x + cell * px < minf(reach, end):
			var dens := 1.0 - clampf((r.position.x + cell * px - (reach - band)) / band, 0.0, 1.0)
			if (HudPalette.BAYER[((i + shift) & 3) * 4 + ((cell + shift * 3) & 3)] + 0.5) / 16.0 < dens:
				ci.draw_rect(Rect2(r.position.x + cell * px, y, px, h), col)
			cell += 1


## The stair along `r`'s slanted right edge: one pixel per row, for a hairline that stays on the grid.
static func stair_edge(ci: CanvasItem, r: Rect2, col: Color, slant: float, px := PX) -> void:
	var rows := ceili(r.size.y / px)
	for i in rows:
		var end := stair_end(r.end.x, slant, i, rows, px)
		ci.draw_rect(Rect2(end - px, r.position.y + i * px, px, minf(px, r.end.y - r.position.y - i * px)), col)


## A pixel frame: `width` cells thick, the top-right and bottom-left corners cut `cut` cells on a stair.
static func frame(ci: CanvasItem, r: Rect2, col: Color, cut := 0, width := 1, px := PX) -> void:
	var cols := roundi(r.size.x / px)
	var rows := roundi(r.size.y / px)
	for i in rows:
		var x0 := maxi(0, cut - (rows - 1 - i))
		var x1 := cols - maxi(0, cut - i)
		var y := r.position.y + i * px
		if i < width or i >= rows - width:
			ci.draw_rect(Rect2(r.position.x + x0 * px, y, (x1 - x0) * px, px), col)
		else:
			ci.draw_rect(Rect2(r.position.x + x0 * px, y, width * px, px), col)
			ci.draw_rect(Rect2(r.position.x + (x1 - width) * px, y, width * px, px), col)


## A dashed rule from `a` along x for `len` px, `on` cells drawn then `off` cells skipped.
static func dashes(ci: CanvasItem, a: Vector2, len: float, col: Color, on := 2, off := 2, px := PX) -> void:
	var n := floori(len / px)
	var i := 0
	while i < n:
		var run := mini(on, n - i)
		ci.draw_rect(Rect2(a.x + i * px, a.y, run * px, px), col)
		i += on + off


## `r` filled with ordered-dither pixels of `col` at `density` (0..1): a flat tone with no gradient.
static func tone(ci: CanvasItem, r: Rect2, col: Color, density: float, shift := 0, px := PX) -> void:
	for gy in ceili(r.size.y / px):
		for gx in ceili(r.size.x / px):
			if (HudPalette.BAYER[((gy + shift) & 3) * 4 + ((gx + shift * 3) & 3)] + 0.5) / 16.0 < density:
				ci.draw_rect(Rect2(r.position.x + gx * px, r.position.y + gy * px, px, px), col)


## `r` filled with `col` that dies out toward its left edge (`to_left`) or right edge in an ordered-dither band
## `cells` wide of `px` cells, solid beyond it: the pixel version of a gradient bar.
static func ramp(ci: CanvasItem, r: Rect2, col: Color, cells: int, to_left := true, px := HudPalette.DITHER_PX) -> void:
	var band := cells * px
	var solid := Rect2(r.position.x + band, r.position.y, r.size.x - band, r.size.y) if to_left else Rect2(r.position, Vector2(r.size.x - band, r.size.y))
	ci.draw_rect(solid, col)
	var rows := ceili(r.size.y / px)
	for cx in cells:
		var dens := (cx + 0.5) / cells if to_left else 1.0 - (cx + 0.5) / cells
		var x := r.position.x + cx * px if to_left else r.end.x - band + cx * px
		for ry in rows:
			if (HudPalette.BAYER[(ry & 3) * 4 + (cx & 3)] + 0.5) / 16.0 < dens:
				ci.draw_rect(Rect2(x, r.position.y + ry * px, px, minf(px, r.end.y - r.position.y - ry * px)), col)


## `r` snapped to whole chrome pixels, so a frame and its fill agree.
static func snap(r: Rect2, px := PX) -> Rect2:
	return Rect2(r.position, Vector2(snappedf(r.size.x, px), snappedf(r.size.y, px)))


## `r` filled with its top-right and bottom-left corners cut `cut` cells on a stair: the fill that `frame` outlines.
static func cut_fill(ci: CanvasItem, r: Rect2, col: Color, cut := 3, px := PX) -> void:
	var cols := roundi(r.size.x / px)
	var rows := roundi(r.size.y / px)
	for i in rows:
		var x0 := maxi(0, cut - (rows - 1 - i))
		var x1 := cols - maxi(0, cut - i)
		ci.draw_rect(Rect2(r.position.x + x0 * px, r.position.y + i * px, (x1 - x0) * px, px), col)


## A wheel of `n` sectors between radii `r_in` and `r_out` about `c`, drawn as `px` cells in one pass: sector `hover`
## in `on`, the rest in `off`. `gap` (radians) is left between sectors; the first one is centred straight up.
static func wheel(ci: CanvasItem, c: Vector2, r_in: float, r_out: float, n: int, hover: int, on: Color, off: Color, gap := 0.04, px := 6.0) -> void:
	var step := TAU / n
	for gy in range(floori((c.y - r_out) / px), ceili((c.y + r_out) / px)):
		for gx in range(floori((c.x - r_out) / px), ceili((c.x + r_out) / px)):
			var cell := Vector2((gx + 0.5) * px, (gy + 0.5) * px)
			var d := cell.distance_to(c)
			if d < r_in or d > r_out:
				continue
			var a := fposmod(cell.angle_to_point(c) + PI - (-PI / 2) + step / 2, TAU)  # from the first sector's start, clockwise
			var i := int(a / step) % n
			if n > 1 and fposmod(a, step) < gap * 1.5 or n > 1 and step - fposmod(a, step) < gap * 1.5:
				continue
			ci.draw_rect(Rect2(gx * px, gy * px, px, px), on if i == hover else off)


## A panel container that paints a stair-slanted slab behind its child (slanting its right edge `slant` px).
class Slab extends PanelContainer:
	var color := Color.WHITE
	var slant := 36.0

	func _init(col := Color.WHITE, lean := 36.0) -> void:
		color = col
		slant = lean
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	func _draw() -> void:
		PixelKit.stair_fill(self, Rect2(Vector2.ZERO, size), color, slant)


## `r` washed with ordered-dither `col` whose density runs from `d0` at its top to `d1` at its bottom (or, `across`, its
## left to right): a flat dithered shade in place of a gradient.
static func wash(ci: CanvasItem, r: Rect2, col: Color, d0: float, d1: float, across := false, px := HudPalette.DITHER_PX) -> void:
	var cols := ceili(r.size.x / px)
	var rows := ceili(r.size.y / px)
	for gy in rows:
		for gx in cols:
			var dens := lerpf(d0, d1, float(gx) / maxf(cols - 1, 1) if across else float(gy) / maxf(rows - 1, 1))
			if (HudPalette.BAYER[(gy & 3) * 4 + (gx & 3)] + 0.5) / 16.0 < dens:
				ci.draw_rect(Rect2(r.position.x + gx * px, r.position.y + gy * px, px, px), col)
