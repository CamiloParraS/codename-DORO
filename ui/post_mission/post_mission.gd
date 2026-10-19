## Post-Mission screen: Aigis's Profile as six 0-3 icons with rise/fall arrows. No numbers, no
## Lethality. Aigis is the one acting, so the profile is in its cyan on the shared HUD chrome, laid out
## on the 640x360 logical canvas. The columns land one by one; any key/click commits.
extends Control

signal committed

const FIRST := 0.3  # s before the first column
const STEP := 0.14  # s between columns

var strip: Array = []   # MissionTally.strip()
var _font: FontFile
var _age := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = load("res://assets/fonts/press_start_2p_regular.ttf")


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age > FIRST + strip.size() * STEP + 0.5:
		set_process(false)  # everything has landed: nothing left to animate


func _unhandled_input(e: InputEvent) -> void:
	if e.is_pressed() and not e.is_echo() and (e is InputEventKey or e is InputEventMouseButton):
		get_viewport().set_input_as_handled()  # first: committing may change the scene
		committed.emit()
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.88))
	_centered(size.x / 2, 56, "AIGIS HAS LEARNED", HudPalette.AIGIS, 12)
	draw_rect(Rect2(size.x / 2 - 60, 66, 120, 1), HudPalette.AIGIS_DIM)
	var w := size.x / maxi(strip.size(), 1)
	for i in strip.size():
		if _age < FIRST + i * STEP:
			continue  # not landed yet
		var landed := _age - (FIRST + i * STEP)
		var e: Dictionary = strip[i]
		var on: bool = e.level > 0 or e.arrow != 0
		var col := HudPalette.WHITE if landed < 0.1 else (HudPalette.AIGIS if on else HudPalette.CHROME_DIM)
		var cx := w * (i + 0.5)
		HabitGlyphs.draw(self, e.habit, Vector2(cx - HabitGlyphs.SIZE, 128), col, 2.0)
		for k in 3:  # pips, filled up to the level
			var lit: bool = k < e.level
			draw_rect(Rect2(cx - 16 + k * 12, 160, 8, 8), HudPalette.AIGIS if lit else Color(HudPalette.CHROME, 0.2))
		var arrow: int = e.arrow
		if arrow != 0:  # up = rose (cyan, solid), down = fell (dim, hollow): shape differs as well as tone
			var y := 186.0
			var d := -6.0 * arrow
			var pts := PackedVector2Array([Vector2(cx, y + d), Vector2(cx - 6, y - d), Vector2(cx + 6, y - d)])
			if arrow > 0:
				draw_colored_polygon(pts, HudPalette.AIGIS)
			else:
				draw_polyline(pts + PackedVector2Array([pts[0]]), HudPalette.CHROME_DIM, 1.0)
		_centered(cx, 212, String(e.habit).to_upper(), HudPalette.WHITE if on else HudPalette.CHROME_DIM, 8)
	if _age > FIRST + strip.size() * STEP + 0.4:
		_centered(size.x / 2, size.y - 44, "PRESS ANY KEY", HudPalette.CHROME_DIM, 8)


func _centered(x: float, y: float, s: String, col: Color, fs: int) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	for o in [Vector2(1, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]:
		draw_string(_font, Vector2(x - w / 2, y) + o, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, col.a))
	draw_string(_font, Vector2(x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
