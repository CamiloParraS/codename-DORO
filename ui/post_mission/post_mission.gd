## Post-Mission screen: Aigis's Profile as six 0-3 icons with rise/fall arrows. No numbers, no
## Lethality. E's white/grey palette on the 640x360 logical canvas. Any key/click commits.
extends Control

signal committed

var strip: Array = []   # MissionTally.strip()
var _font: FontFile


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = load("res://assets/fonts/press_start_2p_regular.ttf")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_pressed() and not e.is_echo() and (e is InputEventKey or e is InputEventMouseButton):
		get_viewport().set_input_as_handled()  # first: committing may change the scene
		committed.emit()
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.85))
	_t(Vector2(size.x / 2 - 102, 60), "AIGIS HAS LEARNED", Color.WHITE, 12)
	var w := size.x / strip.size()
	for i in strip.size():
		var e: Dictionary = strip[i]
		var c := Vector2(w * (i + 0.5), 160)
		draw_arc(c, 22, 0, TAU, 24, Color(1, 1, 1, 0.8), 1.0)
		for k in 3:  # pips, filled up to the level
			draw_rect(Rect2(c.x - 14 + k * 10, c.y - 4, 8, 8), Color.WHITE if k < e.level else Color(1, 1, 1, 0.2))
		var arrow: int = e.arrow
		if arrow != 0:  # up = rose (white), down = fell (grey)
			var y := c.y + 38
			var d := -6.0 * arrow
			var col := Color.WHITE if arrow > 0 else Color(0.6, 0.6, 0.6)
			draw_colored_polygon(PackedVector2Array([Vector2(c.x, y + d), Vector2(c.x - 6, y - d), Vector2(c.x + 6, y - d)]), col)
		var label: String = String(e.habit).to_upper()
		_t(Vector2(c.x - label.length() * 3, c.y + 62), label, Color(1, 1, 1, 0.85), 6)
	_t(Vector2(size.x / 2 - 52, size.y - 50), "PRESS ANY KEY", Color(1, 1, 1, 0.5), 8)


func _t(pos: Vector2, s: String, col: Color, fs: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
