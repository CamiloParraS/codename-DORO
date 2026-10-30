## Post-Mission screen, two pages; any key/click advances, the last one commits. Page 1, the Rank: the header
## slab, the stats table (clear time highlighted white) counting up in steps with a tick each, a gold clear-rank
## bar, then the grade stamped in with a thump, a short shake and a two-frame white flash, the codename under it,
## the bonus chips and the Metis ticker. Page 2, "AIGIS HAS LEARNED": a card per Habit the Profile moved on
## (glyph, level pips, rise/fall arrow). A first press while the tally runs skips it to its final values.
## rank_only (replays, Free mode) shows page 1 alone. Drawn in design px (1080 tall); fades in from black.
extends Control

signal committed

const FIRST := 0.3  # s before the first row
const ROW_GAP := 0.14  # s between rows starting
const COUNT_STEP := 0.028  # s per count-up step (at most COUNT_STEPS of them)
const COUNT_STEPS := 14
const STAMP_AT := 1.4  # s in: the rank letter stamps
const STAMP_SECS := 0.5
const DONE_AT := 2.4  # s in: the tally and stamp are over; a press now advances
const CARD := 0.14  # s between learned cards landing
const GRADE_EDGE := Color("14130d")  # the clear-rank bar fades from these into sand
const GRADE_MID := Color("34301b")
const FADE := HudPalette.FADE  # s from clear to the dimmed screen

var strip: Array = []   # MissionTally.strip()
var voice_key := ""     # VoiceLines.post_key: the Dominant Voice's line, "" for none
var rank := Rank.new()  # the attempt's counters
var par := 0.0          # Rank.par for the Mission
var mission_name := ""  # shown under the header, "" for none
var rank_only := false
var page := 0           # 0 Rank, 1 Aigis
var _age := 0.0         # since the page opened (real time)
var _total := 0.0       # since the screen opened: the fade
var _ticked := {}       # row -> last count step ticked
var _stamped := false
var _was_skipped := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _process(delta: float) -> void:
	_age += delta
	_total += delta
	modulate.a = minf(_total / FADE, 1.0)
	if page == 0:
		_sounds()
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_pressed() and not e.is_echo() and (e is InputEventKey or e is InputEventMouseButton):
		get_viewport().set_input_as_handled()  # first: committing may change the scene
		if page == 0 and _age < DONE_AT:  # skip the tally to its final values, quietly
			_skip()
			return
		advance()


## Jump to the finished tally: no extra ticks, no thump.
func _skip() -> void:
	_age = DONE_AT
	_stamped = true
	_was_skipped = true
	for i in stats().size():
		_ticked[i] = COUNT_STEPS


## The next page, or commit after the last.
func advance() -> void:
	if page == 0 and not rank_only:
		page = 1
		_age = 0.0
		return
	committed.emit()
	queue_free()


## Page 1's stat lines in landing order: [label, final value, formatted-for(n)].
func stats() -> Array:
	return [
		[tr("ui.post.time"), int(rank.seconds), true],
		[tr("ui.post.kills"), rank.kills, false],
		[tr("ui.post.alerts"), rank.alerts, false],
		[tr("ui.post.found"), rank.found, false],
		[tr("ui.post.continues"), rank.continues, false],
	]


## How many count-up steps row `i` has taken at `age` (0 before it starts, up to its step total).
static func steps_at(i: int, end: int, age: float) -> int:
	var total := mini(end, COUNT_STEPS)
	return clampi(int((age - FIRST - i * ROW_GAP) / COUNT_STEP), 0, maxi(total, 0))


## The value row `i` shows at `age`: counts up in at most COUNT_STEPS steps, ending exactly on `end`.
static func shown_at(i: int, end: int, age: float) -> int:
	var total := mini(end, COUNT_STEPS)
	if total <= 0:
		return end if age >= FIRST + i * ROW_GAP else 0
	var s := steps_at(i, end, age)
	return end if s >= total else roundi(float(end) * s / total)


## A tick per count-up step, the thump (and a short hit-stop) as the rank stamps in.
func _sounds() -> void:
	var rows := stats()
	for i in rows.size():
		var s := steps_at(i, rows[i][1], _age)
		if s > _ticked.get(i, 0):
			_ticked[i] = s
			Mixer.play(&"tick")
	if not _stamped and _age >= STAMP_AT:
		_stamped = true
		Mixer.play(&"thump")
		Mixer.hit_stop(0.08)


func _k() -> float:
	return size.y / HudPalette.DESIGN_H


func _draw() -> void:
	var k := _k()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var d := size / k
	draw_rect(Rect2(Vector2.ZERO, d), HudPalette.GROUND)
	draw_rect(Rect2(Vector2.ZERO, d), Color(0, 0, 0, 0.25))
	_header(Vector2(80, 56), tr("ui.post.learned" if page == 1 else "ui.post.title").to_upper(), mission_name.to_upper(), HudPalette.CYAN if page == 1 else HudPalette.LIGHT)
	if page == 0:
		_draw_rank(d)
	else:
		_draw_aigis(d)
	if voice_key != "":  # the Metis ticker
		draw_rect(Rect2(0, d.y - 64, d.x, 64), Color.BLACK)
		draw_rect(Rect2(0, d.y - 64, 130, 64), HudPalette.DMG)
		HudPalette.hud_text(self, Vector2(65, d.y - 24), "METIS", 18, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 18, 0.3), 1, false)
		HudPalette.hud_text(self, Vector2(160, d.y - 22), tr(voice_key), 22, HudPalette.LIGHT_2, HudPalette.FIGURE_MED, 0, false)


## The header slab: dark text on a light plate cut at its right foot, the Mission under it.
func _header(at: Vector2, title: String, sub: String, col: Color) -> void:
	var f := HudPalette.tracked(HudPalette.DISPLAY, 54, 0.08)
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 54).x + 56
	draw_colored_polygon(PackedVector2Array([at, at + Vector2(w, 0), at + Vector2(w - 22, 76), at + Vector2(0, 76)]), col)
	HudPalette.hud_text(self, at + Vector2(22, 60), title, 54, HudPalette.DARK_INK, f, 0, false)
	if sub != "":
		HudPalette.hud_text(self, at + Vector2(w + 26, 58), sub, 26, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 26, 0.24), 0, false)


func _draw_rank(d: Vector2) -> void:
	var rows := stats()
	var tf := HudPalette.tracked(HudPalette.DISPLAY, 28, 0.14)
	var vf := HudPalette.tracked(HudPalette.DISPLAY, 34, 0.08)
	var y := 200.0
	for i in rows.size():
		var row_born := FIRST + i * ROW_GAP
		if _age < row_born:
			break
		var hl := i == 0
		var r := Rect2(80, y, 1180, 64)
		var a := clampf((_age - row_born) / 0.1, 0.0, 1.0)
		if hl:
			draw_rect(r, Color(HudPalette.LIGHT, a))
		draw_line(r.position + Vector2(0, 64), r.end, Color(HudPalette.LIGHT, 0.14 * a), 1.0)
		var ink := HudPalette.DARK_INK if hl else HudPalette.LIGHT_2
		HudPalette.hud_text(self, r.position + Vector2(26, 43), String(rows[i][0]).to_upper(), 28, Color(ink, a), tf, 0, false)
		var n := shown_at(i, rows[i][1], _age)
		@warning_ignore("integer_division")
		var text := "%d:%02d" % [n / 60, n % 60] if rows[i][2] else "%03d" % n
		var bad: bool = not hl and i in [2, 3] and rows[i][1] > 0
		HudPalette.hud_text(self, r.position + Vector2(r.size.x - 26, 44), text, 34, Color(HudPalette.DMG if bad else (HudPalette.DARK_INK if hl else HudPalette.LIGHT), a), vf, 2, false)
		if hl and par > 0.0:
			@warning_ignore("integer_division")
			var ps := "PAR %d:%02d" % [int(par) / 60, int(par) % 60]
			HudPalette.hud_text(self, r.position + Vector2(r.size.x - 210, 41), ps, 18, Color(HudPalette.DARK_INK, 0.55 * a), HudPalette.tracked(HudPalette.DISPLAY, 18, 0.2), 2, false)
		y += 64.0
	var born := FIRST + rows.size() * ROW_GAP + 0.1
	var grade := rank.grade(par)
	if _age >= born:  # the gold clear-rank bar
		var bar := Rect2(80, y + 22, 1180, 92)
		var pts := PackedVector2Array([bar.position, Vector2(bar.position.x + bar.size.x * 0.45, bar.position.y), Vector2(bar.end.x, bar.position.y), bar.end, Vector2(bar.position.x + bar.size.x * 0.45, bar.end.y), Vector2(bar.position.x, bar.end.y)])
		draw_polygon(pts, PackedColorArray([GRADE_EDGE, GRADE_MID, HudPalette.SAND, HudPalette.SAND, GRADE_MID, GRADE_EDGE]))
		HudPalette.hud_text(self, bar.position + Vector2(30, 59), tr("ui.post.rank").to_upper(), 38, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 38, 0.2), 0, false)
		if _age >= STAMP_AT:
			HudPalette.hud_text(self, bar.position + Vector2(bar.size.x - 40, 78), grade, 96, HudPalette.DARK_INK, HudPalette.DISPLAY, 2, false)
		y = bar.end.y
	_chips(Vector2(80, 840))
	if _age >= STAMP_AT:
		_stamp(d, grade)
	if _age >= DONE_AT:
		var ak := tr("ui.brief.any_key").to_upper()
		HudPalette.hud_text(self, Vector2(d.x - 80, d.y - 110), ak, 26, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 26, 0.3), 2, false)


## No-traces / no-kills chips: lit gold when earned, outlined when not.
func _chips(at: Vector2) -> void:
	if _age < 1.2:
		return
	var got := rank.bonuses()
	var x := at.x
	for b: String in ["NO KILLS", "NO TRACES"]:
		var ok := b in got
		var label := tr("ui.bonus." + b.to_lower().replace(" ", "_")).to_upper()
		var f := HudPalette.tracked(HudPalette.DISPLAY, 20, 0.2)
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 36
		var r := Rect2(x, at.y, w, 46)
		if ok:
			draw_rect(r, HudPalette.SAND)
		else:
			draw_rect(r, Color(HudPalette.LIGHT, 0.3), false, 1.0)
		HudPalette.hud_text(self, r.position + Vector2(18, 31), label, 20, HudPalette.DARK_INK if ok else HudPalette.LIGHT_3, f, 0, false)
		x += w + 10


## The big gold letter: scales from 1.5 to 1 in hard steps, shakes, and flashes white for two frames.
func _stamp(d: Vector2, grade: String) -> void:
	var t := _age - STAMP_AT
	var frame := int(t / (STAMP_SECS / 6.0))
	var pop := 1.5 if frame == 0 else 1.0
	var shake := Vector2.ZERO
	if frame == 1:
		shake = Vector2(-8, 5)
	elif frame == 2:
		shake = Vector2(6, -4)
	var c := Vector2(d.x - 80 - 250, 440) + shake
	var k := _k()
	draw_set_transform(c * k, 0.0, Vector2(k, k) * pop)
	HudPalette.hud_text(self, Vector2(0, 150), grade, 400, HudPalette.SAND, HudPalette.DISPLAY, 1, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	if t < 0.08 and not _was_skipped:  # two frames of white
		draw_rect(Rect2(Vector2.ZERO, d), Color(1, 1, 1, 0.5 if t < 0.04 else 0.25))
	var name_ := String(Rank.TITLES[grade])
	draw_line(Vector2(d.x - 580, 790), Vector2(d.x - 80, 790), HudPalette.LIGHT, 3.0)
	if _age >= 1.9:
		HudPalette.hud_text(self, Vector2(d.x - 330, 842), name_, 40, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 40, 0.7), 1, false)


func _draw_aigis(d: Vector2) -> void:
	var changed := strip.filter(func(e: Dictionary) -> bool: return e.arrow != 0)
	var cols := 3
	var gap := 40.0
	var w := (d.x - 160 - gap * (cols - 1)) / cols
	if changed.is_empty():
		HudPalette.hud_text(self, Vector2(80, 260), tr("ui.post.nothing").to_upper(), 34, HudPalette.LIGHT_3, HudPalette.tracked(HudPalette.DISPLAY, 34, 0.2), 0, false)
	for i in changed.size():
		var born := FIRST + i * CARD
		if _age < born:
			continue
		var e: Dictionary = changed[i]
		var x := 80.0 + (i % cols) * (w + gap) + (1.0 - clampf((_age - born) / 0.1, 0.0, 1.0)) * 36.0
		@warning_ignore("integer_division")
		var y := 230.0 + (i / cols) * 340.0
		draw_rect(Rect2(x, y, w, 300), Color(HudPalette.GLASS, 0.74))
		draw_rect(Rect2(x, y, w, 3), HudPalette.CYAN)
		HabitGlyphs.draw(self, e.habit, Vector2(x + 30, y + 40), HudPalette.CYAN, 4.0)
		var arrow: int = e.arrow
		HudPalette.hud_text(self, Vector2(x + 30, y + 160), tr("ui.habit." + e.habit).to_upper() + (" ▲" if arrow > 0 else " ▼"), 48, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 48, 0.06), 0, false)
		for p in 3:  # level pips, filled up to the level
			draw_rect(Rect2(x + 30 + p * 33, y + 214, 28, 10), HudPalette.SAND if p < int(e.level) else Color(HudPalette.LIGHT, 0.2))
		var pts := PackedVector2Array([Vector2(x + w - 50, y + 230 - 14 * arrow), Vector2(x + w - 70, y + 230 + 14 * arrow), Vector2(x + w - 30, y + 230 + 14 * arrow)])
		if arrow > 0:
			draw_colored_polygon(pts, HudPalette.CYAN)
		else:
			draw_polyline(pts + PackedVector2Array([pts[0]]), HudPalette.LIGHT_3, 2.0)
	if _age >= FIRST + changed.size() * CARD + 0.4:
		var ak := tr("ui.brief.any_key").to_upper()
		HudPalette.hud_text(self, Vector2(d.x - 80, d.y - 110), ak, 26, HudPalette.LIGHT, HudPalette.tracked(HudPalette.DISPLAY, 26, 0.3), 2, false)
