## The post-Mission "WHAT AIGIS SAW" page, drawn on the screen (static: the screen owns the age and the Dossier).
## The Operative's route seen from above (diagram x right, y down: north up) plays back over SAW_SECS, each mark
## popping in when the route reaches it with a tick; beside it what Aigis counted, and under that Aigis Voice's
## comment on the run (the Dossier's analysis: ANALYSING while the request is out, then typed with its Voice's
## blips once the route has drawn). Design px, like the screen.
extends RefCounted

const SAW_SECS := 3.2  # the whole route, however long the Mission was
const FIRST := 0.3     # s before the route starts drawing
const PAD := 6.0       # metres of margin round the route
const GRID := 10.0     # metres between grid lines
const POP := 0.18      # s a fresh mark stays enlarged
const LEGEND := ["down", "kill", "spotted", "alert"]
const SAID_W := 540.0    # Aigis Voice's panel: the legend column's width
const SAID_FS := 24      # its lines (raised on small windows, see HudPalette.legible)
const SAID_BOTTOM := 940.0  # its last row ends with the route's plan, above the "any key" prompt
const SAID_HEAD := 64.0     # the header plate and its rule, above the rows
const CLOCK_FS := 64        # the Mission clock under the legend
const CLOCK_DROP := 76.0    # from the legend's rule to the clock's baseline


static func done_at(_s: Control) -> float:
	return FIRST + SAW_SECS + 0.3


## The route's playback clock: the Mission second the drawing has reached.
static func shown_t(s: Control) -> float:
	return clampf((s._age - FIRST) / SAW_SECS, 0.0, 1.0) * total_t(s.dossier)


static func total_t(dossier: Dictionary) -> float:
	var n := floori(dossier.get("path", []).size() / 2.0)
	return maxf((n - 1) * float(dossier.get("every", SessionLog.PATH_EVERY)), 0.001)


## A tick per mark as the route reaches it; then Aigis Voice's comment types out with its Voice's blips.
static func sounds(s: Control, delta: float) -> void:
	var t := shown_t(s)
	var due: int = s.dossier.get("marks", []).filter(func(m: Array) -> bool: return m[1] <= t).size()
	if due > int(s.get_meta("saw_ticked", 0)):
		s.set_meta("saw_ticked", due)
		Mixer.play(&"tick")
	var typer := _typer(s)
	if typer and not typer.done():
		var p := typer.advance(delta)
		if not p.is_empty():
			Mixer.blip(p.back())  # one blip per frame: they never stack


## A press on this page: finishes the route, then the typing. False when nothing is left to finish.
static func skip(s: Control) -> bool:
	if s._age < done_at(s):
		s._age = done_at(s)
		return true
	var typer := _typer(s)
	if typer and not typer.done():
		typer.skip()
		Mixer.stop_blips()
		return true
	return false


## The comment's typewriter, made once the route has drawn and the request is settled (so the text never changes
## under it); null before that, or with no comment. Reduced motion shows it at once.
static func _typer(s: Control) -> VoiceBlip:
	var said: Dictionary = s.dossier.get("analysis", {})
	if said.is_empty() or said.get("pending", false) or s._age < done_at(s):
		return null
	if not s.has_meta("saw_typer"):  # every line, joined as the rows join them: a resize rewraps, the count still lines up
		var typer := VoiceBlip.new(" ".join(said.lines), said.voice)
		if UiMotion.reduced():
			typer.skip()
		s.set_meta("saw_typer", typer)
	return s.get_meta("saw_typer")


## The comment's rows at the size it draws at in this window.
static func _rows(s: Control) -> Array:
	return said_rows(s.dossier.analysis.lines, SAID_W - 24.0, HudPalette.legible(s, SAID_FS), SAID_BOTTOM - _said_top() - SAID_HEAD)


## The comment's lines wrapped to `width` at `fs` as [text, line index] rows, whole lines only while they fit in
## `height` (the first line always shows, cut to what fits).
static func said_rows(lines: Array, width: float, fs: int, height: float) -> Array:
	var most := maxi(1, floori(height / row_h(fs)))
	var out := []
	for i in lines.size():
		var wrapped := HudPalette.wrap(lines[i], width, HudPalette.FIGURE_MED, fs)
		if not out.is_empty() and out.size() + wrapped.size() > most:
			break
		for r in wrapped:
			out.append([r, i])
	return out.slice(0, most)


static func row_h(fs: int) -> float:
	return roundf(fs * 1.3)


## Where the comment's header sits: under the legend's plates and the Mission clock (see _legend).
static func _said_top() -> float:
	return 200.0 + LEGEND.size() * 72 + 22 + CLOCK_DROP + 36


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
	_said(s, Vector2(area.end.x + 60, _said_top()))
	var typer := _typer(s)
	if s._age >= done_at(s) and not (typer and not typer.done()):
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
	HudPalette.hud_text(s, Vector2(at.x, y + CLOCK_DROP), clock, CLOCK_FS, HudPalette.CYAN, HudPalette.FIGURE, 0, false)


## Aigis Voice's comment (the Dossier's analysis) under the clock: a cyan tab and "AIGIS · <VOICE>", then
## "ANALYSING" with cycling dots while the request is out, then the lines typing in, a cyan pip at each line's start.
static func _said(s: Control, at: Vector2) -> void:
	var said: Dictionary = s.dossier.get("analysis", {})
	if said.is_empty():
		return
	var pending: bool = said.get("pending", false)
	var hf := HudPalette.tracked(HudPalette.DISPLAY, 26, 0.3)
	PixelKit.cut_fill(s, Rect2(at, Vector2(6, 34)), HudPalette.CYAN, 0)
	var head := "AIGIS" if pending else "AIGIS  ·  " + s.tr("ui.voice." + said.voice)
	HudPalette.hud_text(s, at + Vector2(20, 28), head.to_upper(), 26, HudPalette.CYAN, hf, 0, false)
	PixelKit.dashes(s, at + Vector2(0, 48), SAID_W, Color(HudPalette.CYAN, 0.3), 2, 2)
	var top := at.y + SAID_HEAD
	if pending:
		var dots := ".".repeat(int(Time.get_ticks_msec() / 350.0) % 4)
		HudPalette.hud_text(s, Vector2(at.x + 24, top + 30), s.tr("ui.post.saw.analysing").to_upper() + dots, 26, HudPalette.LIGHT_3, hf, 0, false)
		return
	var typer := _typer(s)
	if typer == null:
		return
	var fs := HudPalette.legible(s, SAID_FS)
	var rows := _rows(s)
	var left := typer.shown().length()
	var y := top + fs
	for j in rows.size():
		if left <= 0:
			break
		if j == 0 or rows[j][1] != rows[j - 1][1]:
			s.draw_rect(Rect2(at.x + 2, y - fs * 0.45, 8, 8), HudPalette.CYAN)
		HudPalette.hud_text(s, Vector2(at.x + 24, y), String(rows[j][0]).left(left), SAID_FS, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
		left -= String(rows[j][0]).length() + 1
		y += row_h(fs)


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
