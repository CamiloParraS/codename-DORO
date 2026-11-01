## The rings behind the title logo: one thin set, turning very slowly as a whole (120 s per turn). When the menu
## opens, the dial dims and the side under the list recedes further, so the rows read on a quiet ground. Still under
## reduced motion.
class_name MenuDial
extends Control

const SIZE := 1240.0
const TURN_SECS := 120.0  # s per turn
const STRENGTH := 0.3     # the alpha every ring is a share of
const ARCS := 72          # a full ring is drawn in this many arcs, so each can fade on its own
const OPEN_DIM := 0.6     # of the dial's strength while the menu is open
const OPEN_EDGE := 0.35   # and of that, on the side under the list
const BAND_W := 28.0      # px, the segmented band (it was the heaviest stroke at 44)

var _t := 0.0
var _open := 0.0  # 0 on the title, 1 with the menu open
var _tween: Tween


## How much of the dial shows at screen angle `a` (0 points right, at the list) with the menu `open` (0 to 1).
static func fade(a: float, open: float) -> float:
	var toward_list := smoothstep(0.0, 0.7, cos(a))
	return lerpf(1.0, OPEN_DIM * lerpf(1.0, OPEN_EDGE, toward_list), open)


func _ready() -> void:
	size = Vector2(SIZE, SIZE)
	pivot_offset = size / 2
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(not UiMotion.reduced())


## Eases the dial down behind the menu (`on`) or back up for the title.
func dim(on: bool) -> void:
	if _tween:
		_tween.kill()
	if UiMotion.reduced():
		_set_open(1.0 if on else 0.0)
		return
	_tween = UiMotion.ease_out(create_tween())
	_tween.tween_method(_set_open, _open, 1.0 if on else 0.0, UiMotion.T_MOMENT)


func _set_open(v: float) -> void:
	_open = v
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var turn := TAU * _t / TURN_SECS
	_ring(486, 0.55, 2.0, turn)
	_ring(420, 0.5, 1.5, turn)
	_segments(392, 18, 0.09, 0.42, BAND_W, turn)
	_segments(366, 36, 0.06, 0.6, 6.0, turn)
	_ring(300, 0.7, 3.0, turn)


## A whole ring at radius `r`, drawn as ARCS arcs so the side under the list can recede.
func _ring(r: float, share: float, w: float, turn: float) -> void:
	for i in ARCS:
		var a := turn + TAU * i / ARCS
		_arc(r, a, a + TAU / ARCS + 0.002, share, w)


## `n` segments at radius `r`, each `gap` radians short of the next.
func _segments(r: float, n: int, gap: float, share: float, w: float, turn: float) -> void:
	for i in n:
		var a := turn + TAU * i / n
		_arc(r, a, a + TAU / n - gap, share, w)


func _arc(r: float, a0: float, a1: float, share: float, w: float) -> void:
	var col := Color(HudPalette.SOFT, STRENGTH * share * fade((a0 + a1) / 2.0, _open))
	draw_arc(size / 2, r, a0, a1, 6, col, w, true)
