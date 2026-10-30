## The Requisition screen over the briefing, on paper grey: RECRUITS (the points), the four upgrades as rank
## grids (owned black, next white with its price, far dashed), the S-rank items, Metis's line on the Mission just
## cleared, and a drawing panel on the right for the picked upgrade (a flat icon, wiped in over 7 steps, swaying
## 4 px; the isometric Blender sprites are not rendered). Up/down picks a row, accept buys it (each buy autosaves
## the slot) or continues; cancel continues. Skipping forfeits nothing. Reads and writes Campaign.gear.
## Swallows every press so the briefing behind it waits. Drawn in design px (1080 tall).
extends Control

signal closed

const PAPER := Color("c5c6bf")
const SHEET := Color("f4f4f1")
const DARK := Color("14181a")
const MUTED := Color("555a5b")
const RED := Color("c4202f")
const ROW_H := 112.0
const BOARD := Vector2(80, 230)
const CELL := Vector2(122, 92)
const WIPE_SECS := 0.3

var row := 0  # 0-3 the upgrades in Requisition.UPGRADES order, 4 CONTINUE
var _age := 0.0  # since the picked row changed (real time)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiScan.make())
	HudPalette.fade(self)


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if not (e.is_pressed() and not e.is_echo() and (e is InputEventKey or e is InputEventMouseButton)):
		return
	get_viewport().set_input_as_handled()
	if e.is_action_pressed("ui_up") or e.is_action_pressed("ui_down"):
		_pick(posmod(row + (1 if e.is_action_pressed("ui_down") else -1), Requisition.UPGRADES.size() + 1))
	elif e.is_action_pressed("ui_accept"):
		press()
	elif e.is_action_pressed("ui_cancel"):
		close()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var hit := _row_at(e.position)
		if hit >= 0:
			_pick(hit)
			press()


func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var hit := _row_at(e.position)
		if hit >= 0 and hit != row:
			_pick(hit)


func _pick(i: int) -> void:
	if i == row:
		return
	row = i
	_age = 0.0
	Mixer.play(&"tick")


## The design-px row under a screen point, -1 for none.
func _row_at(p: Vector2) -> int:
	var q := p / (size.y / HudPalette.DESIGN_H)
	for i in Requisition.UPGRADES.size():
		if Rect2(BOARD.x - 20, BOARD.y + i * ROW_H, 1060, ROW_H).has_point(q):
			return i
	if Rect2(BOARD.x, _continue_y(), 400, 56).has_point(q):
		return Requisition.UPGRADES.size()
	return -1


func _continue_y() -> float:
	return BOARD.y + Requisition.UPGRADES.size() * ROW_H + 36.0 + 36.0 + Requisition.ITEMS.size() * 36.0 + 12.0


## Buy the selected upgrade, or continue.
func press() -> void:
	if row >= Requisition.UPGRADES.size():
		close()
	elif Campaign.gear.buy(Requisition.UPGRADES.keys()[row]):
		Mixer.click()
		Campaign.save()
		queue_redraw()


## Closes at once (the briefing resumes) and fades out over HudPalette.FADE.
func close() -> void:
	set_process_unhandled_input(false)
	closed.emit()
	if is_inside_tree():
		HudPalette.fade(self, false).finished.connect(queue_free)
	else:
		queue_free()


## The rows as text, in order; ">" marks the picked one. The screen draws from the same data.
func lines() -> Array:
	var g := Campaign.gear
	var out := [tr("requisition.signed").format({n = g.signed}), tr("ui.req.points").format({n = g.points}), ""]
	var ids: Array = Requisition.UPGRADES.keys()
	for i in ids.size():
		var u: Dictionary = Requisition.UPGRADES[ids[i]]
		var left: int = u.buys - g.bought.get(ids[i], 0)
		var what := "%s %d" % [tr("ui.upgrade.%s.effect" % ids[i]), g.value(ids[i])] + (" -> %d" % (g.value(ids[i]) + u.step) if left > 0 else "")
		var price := tr("ui.req.price").format({n = u.price}) if left > 0 else tr("ui.req.max")
		out.append("%s %s %s  %s" % [">" if row == i else " ", _pad(tr("ui.upgrade.%s" % ids[i]), 18), _pad(price, 6), what])
	out.append_array(["", tr("ui.req.items")])
	for k in Requisition.ITEMS.size():
		var it: Dictionary = Requisition.ITEMS[k]
		var state := tr("ui.req.unlocked") if g.unlocked(it.id) else tr("ui.req.s_on").format({n = k + 1})
		out.append("  %s %s  %s" % [_pad(tr("ui.item.%s" % it.id), 18), _pad(tr("ui.item.%s.effect" % it.id), 24), state])
	out.append_array(["", "%s %s" % [">" if row == ids.size() else " ", tr("ui.menu.continue")]])
	return out


## Metis's line on the Mission just cleared, "" past the last one with an item.
func metis() -> String:
	var cleared: int = Campaign.record.mission - 1
	return tr("requisition.metis.m%d" % (cleared + 1)) if cleared in range(Requisition.ITEMS.size()) else ""


static func _pad(s: String, n: int) -> String:
	return s + " ".repeat(maxi(n - s.length(), 0))


func _f(fs: int, em := 0.1) -> Font:
	return HudPalette.tracked(HudPalette.DISPLAY, fs, em)


func _draw() -> void:
	var k := size.y / HudPalette.DESIGN_H
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var d := size / k
	draw_rect(Rect2(Vector2.ZERO, d), PAPER)
	var g := Campaign.gear
	_title()
	_points(d, g.points)
	var ids: Array = Requisition.UPGRADES.keys()
	for i in ids.size():
		_upgrade_row(i, ids[i], g)
	var y := BOARD.y + ids.size() * ROW_H + 36.0
	HudPalette.hud_text(self, Vector2(BOARD.x, y), tr("ui.req.items").to_upper(), 26, DARK, _f(26, 0.2), 0, false)
	draw_rect(Rect2(BOARD.x, y + 10, 1000, 3), DARK)
	for i in Requisition.ITEMS.size():
		var it: Dictionary = Requisition.ITEMS[i]
		var iy := y + 36.0 + i * 36.0
		var have: bool = g.unlocked(it.id)
		var ink := DARK if have else MUTED
		HudPalette.hud_text(self, Vector2(BOARD.x, iy + 20), tr("ui.item.%s" % it.id).to_upper(), 22, ink, _f(22, 0.12), 0, false)
		HudPalette.hud_text(self, Vector2(BOARD.x + 300, iy + 20), tr("ui.item.%s.effect" % it.id).to_upper(), 18, ink, _f(18, 0.12), 0, false)
		var state := tr("ui.req.unlocked") if have else tr("ui.req.s_on").format({n = i + 1})
		HudPalette.hud_text(self, Vector2(BOARD.x + 1000, iy + 20), state.to_upper(), 18, RED if have else MUTED, _f(18, 0.14), 2, false)
	var cr := Rect2(BOARD.x, _continue_y(), 400, 56)
	var cont := row == ids.size()
	draw_rect(cr, RED if cont else DARK)
	HudPalette.hud_text(self, cr.position + Vector2(24, 39), tr("ui.menu.continue").to_upper(), 30, HudPalette.LIGHT, _f(30, 0.14), 0, false)
	_panel(d, ids, g)
	var line := metis()
	draw_rect(Rect2(0, d.y - 120, d.x, 56), DARK)
	draw_rect(Rect2(0, d.y - 120, 110, 56), RED)
	HudPalette.hud_text(self, Vector2(55, d.y - 84), "METIS", 18, HudPalette.LIGHT, _f(18, 0.3), 1, false)
	if line != "":
		HudPalette.hud_text(self, Vector2(136, d.y - 83), line, 21, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
	draw_rect(Rect2(0, d.y - 64, d.x, 64), Color("0a0d0f"))
	HudPalette.hud_text(self, Vector2(80, d.y - 24), tr("ui.req.footer"), 20, HudPalette.LIGHT_2, _f(20, 0.16), 0, false)


func _title() -> void:
	var t := tr("ui.req.title").to_upper()
	var w := _f(52, 0.1).get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x + 150
	draw_colored_polygon(PackedVector2Array([Vector2(0, 52), Vector2(w, 52), Vector2(w - 24, 132), Vector2(0, 132)]), DARK)
	HudPalette.hud_text(self, Vector2(80, 112), t, 52, HudPalette.LIGHT, _f(52, 0.1), 0, false)


func _points(d: Vector2, n: int) -> void:
	var label := tr("ui.req.recruits").to_upper()
	var lw := _f(20, 0.26).get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 44
	var x := d.x - 80 - 200 - lw
	draw_rect(Rect2(x, 56, lw, 74), DARK)
	HudPalette.hud_text(self, Vector2(x + 22, 103), label, 20, HudPalette.LIGHT, _f(20, 0.26), 0, false)
	draw_rect(Rect2(x + lw, 56, 200, 74), SHEET)
	draw_rect(Rect2(x + lw, 56, 200, 74), DARK, false, 3.0)
	HudPalette.hud_text(self, Vector2(x + lw + 176, 114), str(n), 56, DARK, _f(56, 0.02), 2, false)


## One upgrade: its name and effect at the left, then a cell per buy.
func _upgrade_row(i: int, id: String, g: Requisition) -> void:
	var u: Dictionary = Requisition.UPGRADES[id]
	var y := BOARD.y + i * ROW_H
	var on := row == i
	var bought: int = g.bought.get(id, 0)
	HudPalette.hud_text(self, Vector2(BOARD.x, y + 52), tr("ui.upgrade.%s" % id).to_upper(), 26, RED if on else DARK, _f(26, 0.1), 0, false)
	HudPalette.hud_text(self, Vector2(BOARD.x, y + 80), tr("ui.upgrade.%s.effect" % id).to_upper(), 16, MUTED, _f(16, 0.2), 0, false)
	if on:
		draw_colored_polygon(PackedVector2Array([Vector2(BOARD.x - 26, y + 40), Vector2(BOARD.x - 8, y + 52), Vector2(BOARD.x - 26, y + 64)]), RED)
	draw_rect(Rect2(BOARD.x + 250, y + 40, 600, 3), Color(DARK, 0.35))
	for c in u.buys:
		var cell := Rect2(BOARD.x + 250 + c * 150, y + 4, CELL.x, CELL.y)
		var value: int = Requisition.BASE[u.stat] + u.step * (c + 1)
		if c < bought:  # owned
			draw_rect(cell, DARK)
			HudPalette.hud_text(self, cell.get_center() + Vector2(0, 10), str(value), 40, HudPalette.LIGHT, _f(40, 0.02), 1, false)
		elif c == bought:  # next: white with its cost under it, dashed when out of reach
			var poor: bool = g.points < u.price
			draw_rect(cell, SHEET)
			if poor:
				_dashed(cell, MUTED)
			else:
				draw_rect(cell, DARK, false, 3.0)
			if on and not poor:
				draw_rect(cell.grow(7), RED, false, 4.0)
			HudPalette.hud_text(self, cell.get_center() + Vector2(0, 4), str(value), 40, MUTED if poor else DARK, _f(40, 0.02), 1, false)
			HudPalette.hud_text(self, Vector2(cell.position.x + 10, cell.end.y - 8), tr("ui.req.price").format({n = u.price}).to_upper(), 16, RED, _f(18, 0.1), 0, false)
		else:  # far
			_dashed(cell, Color(DARK, 0.3))
			HudPalette.hud_text(self, cell.get_center() + Vector2(0, 10), str(value), 40, Color(DARK, 0.3), _f(40, 0.02), 1, false)


func _dashed(r: Rect2, col: Color) -> void:
	for e: Array in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), r.end], [r.position, Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), r.end]]:
		var n := int(e[0].distance_to(e[1]) / 10.0)
		for j in n:
			if j % 2 == 0:
				draw_line(e[0].lerp(e[1], float(j) / n), e[0].lerp(e[1], float(j + 1) / n), col, 3.0)


## The drawing panel: the picked upgrade's name, a flat icon, effect and the buy bar.
func _panel(d: Vector2, ids: Array, g: Requisition) -> void:
	var r := Rect2(d.x - 80 - 700, 150, 700, 790)
	draw_rect(r, Color(SHEET, 0.93))
	draw_rect(r, DARK, false, 3.0)
	if row >= ids.size():
		return
	var id: String = ids[row]
	var u: Dictionary = Requisition.UPGRADES[id]
	HudPalette.hud_text(self, r.position + Vector2(30, 80), tr("ui.upgrade.%s" % id).to_upper(), 54, DARK, _f(54, 0.04), 0, false)
	var art := Rect2(r.position + Vector2(30, 130), Vector2(r.size.x - 60, 330))
	draw_rect(Rect2(art.position, Vector2(art.size.x, 2)), DARK)
	draw_rect(Rect2(art.position + Vector2(0, art.size.y), Vector2(art.size.x, 2)), DARK)
	var wipe := floorf(clampf(_age / WIPE_SECS, 0.0, 1.0) * 7.0) / 7.0  # the icon wipes in over 7 steps
	var sway := Vector2(floorf(sin(Time.get_ticks_msec() / 1500.0) * 4.0), 0.0)  # a very slow 4 px sway
	_icon(id, art.get_center() + sway, 1.0, DARK, art.position.x + art.size.x * wipe + 10.0)
	var left: int = u.buys - g.bought.get(id, 0)
	var eff := tr("ui.upgrade.%s.effect" % id).to_upper()
	HudPalette.hud_text(self, r.position + Vector2(30, 520), eff, 24, DARK, _f(24, 0.16), 0, false)
	var v := str(g.value(id)) + ("  >  %d" % (g.value(id) + u.step) if left > 0 else "")
	HudPalette.hud_text(self, r.position + Vector2(r.size.x - 30, 530), v, 56, DARK, _f(56, 0.02), 2, false)
	var can: bool = g.can_buy(id)
	var bar := Rect2(r.position + Vector2(30, r.size.y - 94), Vector2(r.size.x - 60, 68))
	draw_rect(bar, DARK if can else Color("8a8e8d"))
	var label := tr("ui.req.max") if left <= 0 else tr("ui.req.price").format({n = u.price})
	HudPalette.hud_text(self, bar.get_center() + Vector2(0, 10), label.to_upper(), 28, HudPalette.LIGHT if can else Color("d5d6d0"), _f(28, 0.2), 1, false)


## A flat pictogram of the upgrade about 350 px wide, drawn only left of `clip_x` (the wipe).
func _icon(id: String, c: Vector2, s: float, col: Color, clip_x: float) -> void:
	var rects: Array[Rect2] = []
	var circles: Array = []  # [center, radius]
	var lines: Array = []    # [from, to, width]
	match id:
		"scanner":
			rects = [Rect2(-120, -60, 150, 120), Rect2(40, -30, 30, 60), Rect2(90, -50, 14, 100), Rect2(120, -70, 14, 140)]
		"magazines":
			rects = [Rect2(-110, -70, 70, 140), Rect2(-30, -70, 70, 140), Rect2(50, -70, 70, 140)]
			lines = [[Vector2(-110, -30), Vector2(-40, -30), 4.0], [Vector2(-30, -30), Vector2(40, -30), 4.0], [Vector2(50, -30), Vector2(120, -30), 4.0]]
		"fultons":
			circles = [[Vector2(0, -60), 80.0]]
			lines = [[Vector2(0, 20), Vector2(0, 80), 5.0]]
			rects = [Rect2(-30, 80, 60, 50)]
		"darts":
			for i in 3:
				lines.append([Vector2(-130 + i * 10, -70 + i * 70), Vector2(100 + i * 10, -70 + i * 70), 10.0])
				circles.append([Vector2(120 + i * 10, -70 + i * 70), 14.0])
	for r in rects:
		var x0 := c.x + r.position.x * s
		var w := minf(r.size.x * s, clip_x - x0)
		if w > 0.0:
			draw_rect(Rect2(Vector2(x0, c.y + r.position.y * s), Vector2(w, r.size.y * s)), col)
	for ci: Array in circles:
		if c.x + ci[0].x * s < clip_x:
			draw_circle(c + ci[0] * s, ci[1] * s, col)
	for l: Array in lines:
		if c.x + l[0].x * s < clip_x:
			draw_line(c + l[0] * s, c + l[1] * s, col, l[2])
