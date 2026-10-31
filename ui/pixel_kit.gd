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
		var end := r.end.x - snappedf(slant * (i + 0.5) / maxf(rows, 1), px)
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
		var end := r.end.x - snappedf(slant * (i + 0.5) / maxf(rows, 1), px)
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
