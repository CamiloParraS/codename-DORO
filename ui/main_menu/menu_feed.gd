## The menu backdrop read as Aigis's camera feed: a caption top left (a blinking REC dot, the feed number, the Area
## and a running clock) that types itself in when a picture arrives, and cyan lock brackets that close on the guards
## and the Operative in it once the dissolve has finished. Cyan is Aigis's colour and nothing else's. Drawn in design
## px (1080 tall) by the MenuBackdrop that owns it, which passes the front picture and its pose on every change.
class_name MenuFeed
extends Control

const CAPTION := Vector2(116, 92)  # baseline of the first line, on the logo's left edge
const TYPE_SECS := 0.35   # s for the caption to type in, after the dissolve
const LOCK_AFTER := 0.15  # s after the caption starts before the first bracket closes
const LOCK_STAGGER := 0.12
const LOCK_SECS := 0.3    # s a bracket takes to close, in LOCK_STEPS hard steps
const LOCK_STEPS := 3
const LOCK_FROM := 1.8    # of its size, where a bracket starts closing from
const ARM := 0.28         # of the bracket's shorter side, each corner's arm
const BLINK_SECS := 1.2

var slide := {}           # the front picture's entry in MenuBackdrop.SLIDES
var index := 0            # its place in the run, 0-based
var age := 0.0            # s since it became the front one
var marks: Array[Rect2] = []  # its marks, in this control's px, already through the pose
var clear_from := INF     # px: brackets reaching past this x are left off (the open menu's list)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The share of a caption of `n` characters shown `t` s after its picture arrived (`fade` s of dissolve first).
static func typed(n: int, t: float, fade: float) -> int:
	return ceili(clampf((t - fade) / TYPE_SECS, 0.0, 1.0) * n)


## The scale bracket `k` is drawn at `t` s in (0 while it has not appeared): it steps in from LOCK_FROM to 1.
static func lock(k: int, t: float, fade: float) -> float:
	var u := (t - fade - LOCK_AFTER - k * LOCK_STAGGER) / LOCK_SECS
	if u < 0.0:
		return 0.0
	var step := mini(floori(u * LOCK_STEPS), LOCK_STEPS)
	return lerpf(LOCK_FROM, 1.0, float(step) / LOCK_STEPS)


## The clock for a picture `t` s in: its own time of day (`base`, "hh:mm") running on in seconds.
static func clock(base: String, t: float) -> String:
	var hm := base.split(":")
	var s := int(hm[0]) * 3600 + int(hm[1]) * 60 + int(t)
	@warning_ignore("integer_division")
	return "%02d:%02d:%02d" % [(s / 3600) % 24, (s / 60) % 60, s % 60]


func _draw() -> void:
	if slide.is_empty():
		return
	var k := size.y / HudPalette.DESIGN_H
	var fade := 0.0 if index == 0 else MenuBackdrop.FADE
	var done := UiMotion.reduced()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	_caption(fade, done)
	draw_set_transform(Vector2.ZERO)
	for i in marks.size():
		var s := 1.0 if done else lock(i, age, fade)
		if s > 0.0 and marks[i].end.x < clear_from:
			_bracket(marks[i], s, k)


func _caption(fade: float, done: bool) -> void:
	var top := "%s %02d" % [tr("ui.menu.feed").to_upper(), index % MenuBackdrop.SLIDES.size() + 1]
	var area := tr(slide.area).to_upper()
	var time := clock(slide.time, age)
	var lit := done or fmod(age, BLINK_SECS) < BLINK_SECS * 0.6
	var dot := CAPTION + Vector2(6, -8)
	if lit:
		draw_circle(dot + Vector2(0, 1), 7.0, HudPalette.HALO)
		draw_circle(dot, 5.0, HudPalette.CYAN)
	var n := top.length() + area.length()
	var shown := n if done else typed(n, age, fade)
	HudPalette.hud_label(self, CAPTION + Vector2(22, 0), top.left(shown), 22, HudPalette.LIGHT_3, 0.3)
	if shown > top.length():
		var line := Vector2(CAPTION.x, CAPTION.y + 34)
		var name_ := area.left(shown - top.length())
		HudPalette.hud_label(self, line, name_, 26, HudPalette.LIGHT_2, 0.22, HudPalette.LABEL_BOLD)
		if shown == n:
			var w := HudPalette.tracked(HudPalette.LABEL_BOLD, 26, 0.22).get_string_size(area, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.legible(self, 26)).x
			HudPalette.hud_text(self, line + Vector2(w + 20, 0), time, 22, Color(HudPalette.CYAN, 0.6), HudPalette.tracked(HudPalette.FIGURE, 22, 0.08))


## Four cyan corners around `r`, drawn `s` times its size about its centre, over a dark keyline.
func _bracket(r: Rect2, s: float, k: float) -> void:
	var c := r.get_center()
	var half := r.size * s / 2.0
	var arm := minf(half.x, half.y) * 2.0 * ARM
	var w := maxf(2.0 * k, 1.5)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var p := c + Vector2(sx * half.x, sy * half.y)
			var pts := PackedVector2Array([p - Vector2(sx * arm, 0), p, p - Vector2(0, sy * arm)])
			draw_polyline(pts, HudPalette.HALO, w + 2.0 * k)
			draw_polyline(pts, Color(HudPalette.CYAN, 0.9), w)
