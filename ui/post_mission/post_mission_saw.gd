## The post-Mission "WHAT AIGIS SAW" page, drawn on the screen (static: the screen owns the age and the Dossier).
## The Operative's route seen from above (diagram x right, y down: north up) plays back over SAW_SECS, each mark
## popping in when the route reaches it with a tick; beside it what Aigis counted. Design px, like the screen.
extends RefCounted

const SAW_SECS := 3.2  # the whole route, however long the Mission was
const FIRST := 0.3     # s before the route starts drawing
const PAD := 6.0       # metres of margin round the route
const GRID := 10.0     # metres between grid lines
const POP := 0.18      # s a fresh mark stays enlarged
const LEGEND := ["down", "kill", "spotted", "alert"]


static func done_at(_s: Control) -> float:
	return FIRST + SAW_SECS + 0.3


## The route's playback clock: the Mission second the drawing has reached.
static func shown_t(s: Control) -> float:
	return clampf((s._age - FIRST) / SAW_SECS, 0.0, 1.0) * total_t(s.dossier)


static func total_t(dossier: Dictionary) -> float:
	var n := floori(dossier.get("path", []).size() / 2.0)
	return maxf((n - 1) * float(dossier.get("every", SessionLog.PATH_EVERY)), 0.001)


## A tick per mark as the route reaches it.
static func sounds(s: Control) -> void:
	var t := shown_t(s)
	var due: int = s.dossier.get("marks", []).filter(func(m: Array) -> bool: return m[1] <= t).size()
	if due > int(s.get_meta("saw_ticked", 0)):
		s.set_meta("saw_ticked", due)
		Mixer.play(&"tick")


static func draw_page(s: Control, d: Vector2) -> void:
	var dossier: Dictionary = s.dossier
	var flat: Array = dossier.get("path", [])
	var pts := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		pts.append(Vector2(flat[i], flat[i + 1]))
	var marks: Array = dossier.get("marks", [])
	var area := Rect2(80, 200, d.x - 80 - 640, d.y - 200 - 64 - 50)
	var plan: Dictionary = s.floor_plan
	var fit := _fit(pts, marks, area, plan)
	area = PixelKit.snap(area)
	PixelKit.cut_fill(s, area, Color(HudPalette.GLASS, 0.6), 5)
	PixelKit.frame(s, area, Color(HudPalette.CYAN, 0.45), 5)
	PixelKit.cut_fill(s, Rect2(area.position + Vector2(15, 0), Vector2(180, 6)), HudPalette.CYAN, 0)  # the cyan tab on the plan's top edge
	_grid(s, area, fit)
	_floor(s, plan, fit)
	var every: float = dossier.get("every", SessionLog.PATH_EVERY)
	var t := shown_t(s)
	var line := PackedVector2Array()
	for i in pts.size():
		if i * every > t:
			if i > 0:  # part way to the next point
				line.append(_to(pts[i - 1].lerp(pts[i], (t - (i - 1) * every) / every), fit))
			break
		line.append(_to(pts[i], fit))
	var fresh := maxi(0, line.size() - 14)  # the last stretch is bright, what it walked earlier settles dim
	for i in range(1, line.size()):
		PixelKit.line(s, line[i - 1], line[i], Color(HudPalette.CYAN, 0.95 if i >= fresh else 0.5), 1)
	if not pts.is_empty():  # where the Operative came in
		PixelKit.frame(s, Rect2(PixelKit.snap(Rect2(_to(pts[0], fit) - Vector2(9, 9), Vector2.ZERO)).position, Vector2(18, 18)), HudPalette.LIGHT, 0)
	for m: Array in marks:
		if m[1] <= t:
			var born: float = FIRST + m[1] / total_t(dossier) * SAW_SECS
			_mark(s, m[0], _to(Vector2(m[2], m[3]), fit), 1.6 if s._age - born < POP else 1.0)
	if not line.is_empty():
		var head: Vector2 = line[line.size() - 1]
		HudPalette.px_ring(s, head, 7.0, 0.0, HudPalette.LIGHT)
		if int(Time.get_ticks_msec() / 400.0) % 2 == 0:  # the head blinks a ring
			HudPalette.px_ring(s, head, 15.0, 3.0, Color(HudPalette.LIGHT, 0.6))
	@warning_ignore("integer_division")
	var clock := "T+ %d:%02d" % [int(t) / 60, int(t) % 60]
	_legend(s, Vector2(area.end.x + 60, area.position.y), marks, t, clock)
	if s._age >= done_at(s):
		var ak := s.tr("ui.brief.any_key").to_upper()
		HudPalette.hud_text(s, Vector2(d.x - 80, d.y - 110), ak, 26, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 26, 0.3), 2, false)


## What each mark means and how many the route has reached, on a stack of plates, then the Mission clock big under them.
static func _legend(s: Control, at: Vector2, marks: Array, t: float, clock: String) -> void:
	var f := HudPalette.tracked(HudPalette.LABEL_BOLD, 30, 0.16)  # Barlow Condensed: the summary reads as data, Antonio stays on the headline
	var y := at.y
	for kind: String in LEGEND:
		var n := marks.filter(func(m: Array) -> bool: return m[0] == kind and m[1] <= t).size()
		var row := Rect2(at.x, y, 540, 60)
		PixelKit.stair_fill(s, row, Color(HudPalette.GLASS, 0.75), 15.0)
		PixelKit.cut_fill(s, Rect2(row.position, Vector2(6, row.size.y)), HudPalette.DMG if kind == "alert" or kind == "kill" else HudPalette.SAND if kind == "down" else HudPalette.LIGHT, 0)
		_mark(s, kind, Vector2(at.x + 44, y + 30), 1.0)
		HudPalette.hud_text(s, Vector2(at.x + 84, y + 40), s.tr("ui.post.saw." + kind).to_upper(), 28, HudPalette.LIGHT_2 if n > 0 else HudPalette.LIGHT_3, f, 0, false)
		HudPalette.hud_text(s, Vector2(at.x + 500, y + 43), "%02d" % n, 38, HudPalette.LIGHT if n > 0 else HudPalette.LIGHT_3, HudPalette.FIGURE, 2, false)
		y += 72
	y += 22
	PixelKit.dashes(s, Vector2(at.x, y), 540.0, Color(HudPalette.LIGHT, 0.3), 2, 2)
	HudPalette.hud_text(s, Vector2(at.x, y + 110), clock, 88, HudPalette.CYAN, HudPalette.FIGURE, 0, false)


## A mark's shape: Down a sand dot, kill a red cross, spotted a light ring, Alert a red triangle.
static func _mark(s: Control, kind: String, p: Vector2, k: float) -> void:
	match kind:
		"down":
			HudPalette.px_ring(s, p, 9.0 * k, 0.0, HudPalette.SAND)
		"kill":
			var r := 10.0 * k
			PixelKit.line(s, p - Vector2(r, r), p + Vector2(r, r), HudPalette.DMG, 1)
			PixelKit.line(s, p + Vector2(-r, r), p + Vector2(r, -r), HudPalette.DMG, 1)
		"spotted":
			HudPalette.px_ring(s, p, 14.0 * k, 3.0, HudPalette.LIGHT)
		"alert":
			var r := 14.0 * k
			HudPalette.px_poly(s, PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, r * 0.8), p + Vector2(-r, r * 0.8)]), HudPalette.DMG)


static func _grid(s: Control, area: Rect2, fit: Array) -> void:
	var lo: Vector2 = fit[0]
	var span: Vector2 = (area.size / fit[1]) as Vector2
	var gx := ceilf(lo.x / GRID) * GRID
	while gx < lo.x + span.x:  # the grid is a field of pixel dots, one per crossing
		var x: float = _to(Vector2(gx, 0), fit).x
		var gy := ceilf(lo.y / GRID) * GRID
		while gy < lo.y + span.y:
			var y: float = _to(Vector2(0, gy), fit).y
			s.draw_rect(Rect2(floorf(x / 3.0) * 3.0, floorf(y / 3.0) * 3.0, 3, 3), Color(HudPalette.CYAN, 0.22))
			gy += GRID
		gx += GRID


## The Area's floor under the route (FloorPlan): one faint fill, its outline brighter. Screen-space arrays
## are cached on the screen per fit, so a still page doesn't transform the navmesh every frame.
static func _floor(s: Control, plan: Dictionary, fit: Array) -> void:
	if plan.is_empty():
		return
	var cache: Array = s.get_meta("saw_floor", [])
	if cache.is_empty() or cache[0] != fit:
		var tris := PackedVector2Array()
		for p in plan.tris:
			tris.append(_to(p, fit))
		var edges := PackedVector2Array()
		for p in plan.edges:
			edges.append(_to(p, fit))
		var idx := PackedInt32Array(range(tris.size()))
		cache = [fit, tris, edges, idx]
		s.set_meta("saw_floor", cache)
	if not cache[1].is_empty():
		RenderingServer.canvas_item_add_triangle_array(s.get_canvas_item(), cache[3], cache[1], PackedColorArray([Color(HudPalette.LIGHT, 0.07)]))
	if not cache[2].is_empty():
		s.draw_multiline(cache[2], Color(HudPalette.LIGHT, 0.3), 1.5)


## [diagram corner shown at area.position, px per metre, area.position]: the floor (when there is one), the route
## and the marks fit, centred.
static func _fit(pts: PackedVector2Array, marks: Array, area: Rect2, plan := {}) -> Array:
	var all := Array(pts)
	if not plan.is_empty():
		all.append_array([plan.lo, plan.hi])
	for m: Array in marks:
		all.append(Vector2(m[2], m[3]))
	var box := Rect2(all[0] if not all.is_empty() else Vector2.ZERO, Vector2.ZERO)
	for p: Vector2 in all:
		box = box.expand(p)
	box = box.grow(PAD)
	var k := minf(area.size.x / box.size.x, area.size.y / box.size.y)
	var lo := box.get_center() - area.size / k / 2.0
	return [lo, k, area.position]


static func _to(p: Vector2, fit: Array) -> Vector2:
	return fit[2] + (p - fit[0]) * fit[1]
