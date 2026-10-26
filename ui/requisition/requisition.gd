## The Requisition screen over the briefing: RECRUITS SIGNED, the points, the four upgrades (price, effect,
## buys left), the S-rank items and Metis's line on the Mission just cleared, then CONTINUE. Up/down picks a
## row, accept buys it (each buy autosaves the slot) or continues; cancel continues. Skipping forfeits
## nothing. Reads and writes Campaign.gear. Swallows every press so the briefing behind it waits.
extends Control

signal closed

var row := 0  # 0-3 the upgrades in Requisition.UPGRADES order, 4 CONTINUE
var _font := HudPalette.HEADING


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	HudPalette.fade(self)


func _unhandled_input(e: InputEvent) -> void:
	if not (e.is_pressed() and not e.is_echo() and (e is InputEventKey or e is InputEventMouseButton)):
		return
	get_viewport().set_input_as_handled()
	if e.is_action_pressed("ui_up") or e.is_action_pressed("ui_down"):
		row = posmod(row + (1 if e.is_action_pressed("ui_down") else -1), Requisition.UPGRADES.size() + 1)
		queue_redraw()
	elif e.is_action_pressed("ui_accept"):
		press()
	elif e.is_action_pressed("ui_cancel"):
		close()


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


## The rows under the title, in order; ">" marks the picked one.
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), HudPalette.INK)
	draw_string(_font, Vector2(24, 40), tr("ui.req.title"), HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.TITLE_SIZE, HudPalette.WHITE)
	var l := lines()
	var y := 64.0
	for i in l.size():
		var picked: bool = l[i].begins_with(">")
		var col := HudPalette.WHITE if picked else HudPalette.CHROME
		draw_string(_font, Vector2(24, y), l[i], HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.HEADING_SIZE, col)
		y += 13
	var said := HudPalette.wrap("%s: %s" % [tr("ui.who.metis"), metis()], size.x - 48) if metis() != "" else PackedStringArray()
	for i in said.size():
		draw_string(HudPalette.BODY, Vector2(24, y + 6 + i * 14), said[i], HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.BODY_SIZE, HudPalette.WHITE)
	draw_string(_font, Vector2(24, size.y - 16), tr("ui.req.footer"), HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.HEADING_SIZE, HudPalette.HINT)
