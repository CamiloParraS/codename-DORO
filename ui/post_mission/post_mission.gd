## Post-Mission screen, two pages; any key/click advances, the last one commits. Page 1, the Rank: the
## grade large, the stats landing one by one, then the bonuses. Page 2, "AIGIS HAS LEARNED": Aigis's
## Profile as six 0-3 icons with rise/fall arrows, no numbers, no Lethality, in Aigis's cyan on the
## shared HUD chrome. rank_only (replays, Free mode) shows page 1 alone. Laid out on the 640x360 canvas;
## fades in from black (the Game Over screen shares FADE and the font).
extends Control

signal committed

const FIRST := 0.3  # s before the first column
const STEP := 0.14  # s between columns
const FADE := 0.4   # s from clear to the dimmed screen
const FONT := "res://assets/fonts/press_start_2p_regular.ttf"
const STAT_STEP := 0.3  # s between Rank stats

var strip: Array = []   # MissionTally.strip()
var voice_key := ""     # VoiceLines.post_key: the Dominant Voice's line, "" for none
var rank := Rank.new()  # the attempt's counters
var par := 0.0          # Rank.par for the Mission
var rank_only := false
var page := 0           # 0 Rank, 1 Aigis
var _font: FontFile
var _age := 0.0         # since the page opened
var _total := 0.0       # since the screen opened: the fade


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = load(FONT)


func _process(delta: float) -> void:
	_age += delta
	_total += delta
	modulate.a = minf(_total / FADE, 1.0)
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_pressed() and not e.is_echo() and (e is InputEventKey or e is InputEventMouseButton):
		get_viewport().set_input_as_handled()  # first: committing may change the scene
		advance()


## The next page, or commit after the last.
func advance() -> void:
	if page == 0 and not rank_only:
		page = 1
		_age = 0.0
		return
	committed.emit()
	queue_free()


## Page 1's stat lines, in landing order.
func stats() -> Array:
	return [
		["CLEAR TIME", "%d:%02d" % [int(rank.seconds) / 60, int(rank.seconds) % 60]],
		["KILLS", str(rank.kills)],
		["ALERTS", str(rank.alerts)],
		["DOWN GUARDS FOUND", str(rank.found)],
		["CONTINUES", str(rank.continues)],
	]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.88))
	if page == 0:
		_draw_rank()
	else:
		_draw_aigis()


func _draw_rank() -> void:
	_centered(size.x / 2, 56, "RANK", HudPalette.WHITE, 12)
	draw_rect(Rect2(size.x / 2 - 60, 66, 120, 1), HudPalette.CHROME_DIM)
	if _age > FIRST:
		_centered(size.x / 2, 130, rank.grade(par), HudPalette.WHITE, 48)
	var lines := stats()
	for i in lines.size():
		if _age < FIRST + (i + 1) * STAT_STEP:
			break
		var y := 168 + i * 16
		draw_string(_font, Vector2(size.x / 2 - 150, y), lines[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, HudPalette.CHROME_DIM)
		draw_string(_font, Vector2(size.x / 2 + 70, y), lines[i][1], HORIZONTAL_ALIGNMENT_RIGHT, 80, 8, HudPalette.WHITE)
	var done := FIRST + (lines.size() + 1) * STAT_STEP
	if _age > done:
		_centered(size.x / 2, 264, "   ".join(rank.bonuses()), HudPalette.AIGIS, 8)
	if _age > done + 0.4:
		_centered(size.x / 2, size.y - 44, "PRESS ANY KEY", HudPalette.CHROME_DIM, 8)


func _draw_aigis() -> void:
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
	if _age > FIRST + strip.size() * STEP:
		_centered(size.x / 2, 90, "TIME %d:%02d" % [int(rank.seconds) / 60, int(rank.seconds) % 60], HudPalette.CHROME_DIM, 8)
	if voice_key != "" and _age > FIRST + strip.size() * STEP:
		_centered(size.x / 2, 248, tr(voice_key), HudPalette.WHITE, 8)
	if _age > FIRST + strip.size() * STEP + 0.4:
		_centered(size.x / 2, size.y - 44, "PRESS ANY KEY", HudPalette.CHROME_DIM, 8)


func _centered(x: float, y: float, s: String, col: Color, fs: int) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	for o in [Vector2(1, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]:
		draw_string(_font, Vector2(x - w / 2, y) + o, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, col.a))
	draw_string(_font, Vector2(x - w / 2, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
