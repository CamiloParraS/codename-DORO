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
	s.draw_rect(area, Color(HudPalette.GLASS, 0.6))
	s.draw_rect(Rect2(area.position, Vector2(area.size.x, 3)), HudPalette.CYAN)
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
	if line.size() >= 2:
		s.draw_polyline(line, Color(HudPalette.CYAN, 0.7), 3.0, true)
	if not pts.is_empty():  # where the Operative came in
		s.draw_rect(Rect2(_to(pts[0], fit) - Vector2(7, 7), Vector2(14, 14)), HudPalette.LIGHT, false, 2.0)
	for m: Array in marks:
		if m[1] <= t:
			var born: float = FIRST + m[1] / total_t(dossier) * SAW_SECS
			_mark(s, m[0], _to(Vector2(m[2], m[3]), fit), 1.6 if s._age - born < POP else 1.0)
	if not line.is_empty():
		s.draw_circle(line[line.size() - 1], 7.0, HudPalette.LIGHT)
	@warning_ignore("integer_division")
	var clock := "T+ %d:%02d" % [int(t) / 60, int(t) % 60]
	HudPalette.hud_text(s, area.position + Vector2(area.size.x - 24, 44), clock, 26, HudPalette.LIGHT_2, HudPalette.tracked(HudPalette.DISPLAY, 26, 0.2), 2, false)
	_legend(s, Vector2(area.end.x + 60, area.position.y + 30), marks, t)
	if s._age >= done_at(s):
		var ak := s.tr("ui.brief.any_key").to_upper()
		HudPalette.hud_text(s, Vector2(d.x - 80, d.y - 110), ak, 26, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 26, 0.3), 2, false)


## What each mark means and how many the route has reached, then Aigis's note under them.
static func _legend(s: Control, at: Vector2, marks: Array, t: float) -> void:
	var f := HudPalette.tracked(HudPalette.DISPLAY, 26, 0.2)
	var y := at.y
	for kind: String in LEGEND:
		var n := marks.filter(func(m: Array) -> bool: return m[0] == kind and m[1] <= t).size()
		_mark(s, kind, Vector2(at.x + 14, y - 9), 1.0)
		HudPalette.hud_text(s, Vector2(at.x + 50, y), s.tr("ui.post.saw." + kind).to_upper(), 26, HudPalette.LIGHT_2, f, 0, false)
		HudPalette.hud_text(s, Vector2(at.x + 500, y), "%02d" % n, 30, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 30, 0.08), 2, false)
		y += 62
	y += 30
	for l in HudPalette.wrap(s.tr("ui.post.saw.note"), 500, HudPalette.FIGURE_MED, 28):
		HudPalette.hud_text(s, Vector2(at.x, y), l, 28, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
		y += 38


## A mark's shape: Down a sand dot, kill a red cross, spotted a light ring, Alert a red triangle.
static func _mark(s: Control, kind: String, p: Vector2, k: float) -> void:
	match kind:
		"down":
			s.draw_circle(p, 8.0 * k, HudPalette.SAND)
		"kill":
			var r := 9.0 * k
			s.draw_line(p - Vector2(r, r), p + Vector2(r, r), HudPalette.DMG, 4.0)
			s.draw_line(p + Vector2(-r, r), p + Vector2(r, -r), HudPalette.DMG, 4.0)
		"spotted":
			s.draw_arc(p, 13.0 * k, 0.0, TAU, 24, HudPalette.LIGHT, 2.5)
		"alert":
			var r := 13.0 * k
			s.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, r * 0.8), p + Vector2(-r, r * 0.8)]), HudPalette.DMG)


static func _grid(s: Control, area: Rect2, fit: Array) -> void:
	var lo: Vector2 = fit[0]
	var span: Vector2 = (area.size / fit[1]) as Vector2
	var gx := ceilf(lo.x / GRID) * GRID
	while gx < lo.x + span.x:
		var x: float = _to(Vector2(gx, 0), fit).x
		s.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), Color(HudPalette.LIGHT, 0.06), 1.0)
		gx += GRID
	var gy := ceilf(lo.y / GRID) * GRID
	while gy < lo.y + span.y:
		var y: float = _to(Vector2(0, gy), fit).y
		s.draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(HudPalette.LIGHT, 0.06), 1.0)
		gy += GRID


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
