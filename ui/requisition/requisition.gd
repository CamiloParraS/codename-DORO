## The Requisition screen over the briefing: RECRUITS SIGNED, the points, the four upgrades (price, effect,
## buys left), the S-rank items and Metis's line on the Mission just cleared, then CONTINUE. Up/down picks a
## row, accept buys it (each buy autosaves the slot) or continues; cancel continues. Skipping forfeits
## nothing. Reads and writes Campaign.gear. Swallows every press so the briefing behind it waits.
extends Control

signal closed

var row := 0  # 0-3 the upgrades in Requisition.UPGRADES order, 4 CONTINUE
var _font: Font = load("res://assets/fonts/press_start_2p_regular.ttf")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


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


func close() -> void:
	closed.emit()
	queue_free()


func lines() -> Array:
	var g := Campaign.gear
	var out := ["REQUISITION", "", tr("requisition.signed").format({n = g.signed}), "POINTS: %d" % g.points, ""]
	var ids: Array = Requisition.UPGRADES.keys()
	for i in ids.size():
		var u: Dictionary = Requisition.UPGRADES[ids[i]]
		var left: int = u.buys - g.bought.get(ids[i], 0)
		var what := "%s %d" % [u.effect, g.value(ids[i])] + (" -> %d" % (g.value(ids[i]) + u.step) if left > 0 else "")
		out.append("%s %-15s %s  %s" % [">" if row == i else " ", u.name, ("%d PTS" % u.price) if left > 0 else "MAX  ", what])
	out.append_array(["", "S-RANK ITEMS"])
	for k in Requisition.ITEMS.size():
		var it: Dictionary = Requisition.ITEMS[k]
		out.append("  %-17s %s  %s" % [it.name, it.effect, "UNLOCKED" if g.unlocked(it.id) else "S ON MISSION %d" % (k + 1)])
	var cleared: int = Campaign.record.mission - 1
	out.append_array(["", tr("requisition.metis.m%d" % (cleared + 1)) if cleared in range(Requisition.ITEMS.size()) else ""])
	out.append_array(["", "%s CONTINUE" % (">" if row == ids.size() else " ")])
	return out


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	var l := lines()
	for i in l.size():
		draw_string(_font, Vector2(24, 32 + i * 13), l[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	draw_string(_font, Vector2(24, size.y - 16), "UP/DOWN: PICK   ENTER: BUY   ESC: CONTINUE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.5))
