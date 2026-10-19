## The six Habits as drawn glyphs (eye, crossed blades, reticle, drop arrow, Z for asleep, signal wave),
## shared by the in-play strip and the post-Mission screen. Drawn, not imported; 10 px at scale 1.
class_name HabitGlyphs
extends RefCounted

const SIZE := 10.0


## Draws `habit`'s glyph with its top-left at `p`, scaled by `k` (2 = 20 px), onto any CanvasItem
## that is inside its _draw().
static func draw(ci: CanvasItem, habit: String, p: Vector2, col: Color, k := 1.0) -> void:
	var s := SIZE * k
	var m := s / 2.0
	var w := maxf(1.0, k)
	match habit:
		"stealth":
			ci.draw_polyline(PackedVector2Array([p + Vector2(0, m), p + Vector2(m, m - 3 * k), p + Vector2(s, m), p + Vector2(m, m + 3 * k), p + Vector2(0, m)]), col, w)
			ci.draw_rect(Rect2(p + Vector2(m - k, m - k), Vector2(2, 2) * k), col)
		"combat":
			ci.draw_line(p, p + Vector2(s, s), col, w)
			ci.draw_line(p + Vector2(s, 0), p + Vector2(0, s), col, w)
		"headshots":
			ci.draw_arc(p + Vector2(m, m), m - k, 0, TAU, 16, col, w)
			ci.draw_rect(Rect2(p + Vector2(m - k, m - k), Vector2(2, 2) * k), col)
		"takedowns":
			ci.draw_polyline(PackedVector2Array([p + Vector2(k, 2 * k), p + Vector2(m, s - 3 * k), p + Vector2(s - k, 2 * k)]), col, w)
			ci.draw_rect(Rect2(p + Vector2(0, s - k), Vector2(s, k)), col)
		"downs":
			ci.draw_polyline(PackedVector2Array([p + Vector2(k, k), p + Vector2(s - k, k), p + Vector2(k, s - k), p + Vector2(s - k, s - k)]), col, w)
		"spoofing":
			ci.draw_polyline(PackedVector2Array([p + Vector2(0, m), p + Vector2(2 * k, k), p + Vector2(5 * k, s - k), p + Vector2(8 * k, k), p + Vector2(s, m)]), col, w)
