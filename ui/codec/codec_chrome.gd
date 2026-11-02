## The quiet furniture of a Codec call, drawn from CodecScreen._draw in design px: radio rings behind the
## frequency, a tuning scale under it, TX/RX level meters beside the frames, the screen's
## corner brackets, the line's signal, lock and call clock in the top bar, and a pip per line of the call.
## All of it sits well under the portraits and the line in weight; only the needle and the live pips are full mint.
class_name CodecChrome
extends RefCounted

const GREEN := HudPalette.MINT
const DIM := Color(HudPalette.MINT, 0.45)
const PX := PixelKit.PX
const RING_GAP := 110.0  # px between the rings
const RING_DRIFT := 22.0  # px/s outward while the line is live


## Dotted rings about `c`, drifting outward while `live`; each fades in at the centre and out with distance.
static func rings(ci: CanvasItem, c: Vector2, t: float, live: bool) -> void:
	var drift := fmod(t * RING_DRIFT, RING_GAP) if live else 0.0
	for i in 10:
		var r := 140.0 + i * RING_GAP + drift
		var a := 0.2 * clampf(1.0 - (r - 140.0) / 1150.0, 0.0, 1.0) * clampf((r - 140.0) / RING_GAP + 0.15, 0.0, 1.0)
		if a <= 0.004:
			continue
		var n := int(r * TAU / 18.0)  # a dot every 18 px
		for j in n:
			var p := c + Vector2.from_angle(TAU * j / n) * r
			ci.draw_rect(Rect2(snappedf(p.x, PX), snappedf(p.y, PX), PX, PX), Color(GREEN, a))


## A tuning scale `w` wide centred on `c`: a tick every step, a tall one every fifth, sliding in under a
## fixed needle until `settle` (0..1) reaches 1, and thinning toward its ends.
static func scale(ci: CanvasItem, c: Vector2, w: float, settle: float) -> void:
	var step := 12.0
	var off := snappedf((1.0 - settle) * 300.0, PX)
	var half := w / 2.0
	for k in range(floori((-half + off) / step), ceili((half + off) / step) + 1):
		var x := k * step - off
		if absf(x) > half:
			continue
		var major := k % 5 == 0
		var h := 15.0 if major else 6.0
		var a := (0.42 if major else 0.26) * (1.0 - pow(absf(x) / half, 2.0))
		ci.draw_rect(Rect2(snappedf(c.x + x, PX), c.y - h, PX, h), Color(GREEN, a))
	ci.draw_rect(Rect2(c.x - half, c.y, w, PX), Color(GREEN, 0.12))
	ci.draw_rect(Rect2(c.x - 1.5, c.y - 27, PX, 30), GREEN)  # the needle
	HudPalette.px_poly(ci, PackedVector2Array([c + Vector2(-9, 12), c + Vector2(9, 12), c + Vector2(0, 3)]), GREEN)


## A vertical level meter of `n` cells rising from `base`, lit to `level` (0..1), its label under it.
static func meter(ci: CanvasItem, base: Vector2, n: int, level: float, label: String) -> void:
	var lit := roundi(level * n)
	for i in n:
		var on := i < lit
		ci.draw_rect(Rect2(base.x, base.y - (i + 1) * 18.0, 12, 12), Color(GREEN, 0.75 if on else 0.1))
	HudPalette.hud_text(ci, base + Vector2(6, 36), label, 20, DIM, HudPalette.tracked(HudPalette.DISPLAY, 20, 0.3), 1, false)


## A speaker's level while their line types: a stepped, restless value; resting low otherwise.
static func level(speaking: bool, typing: bool, seed: int) -> float:
	if not (speaking and typing):
		return 0.0
	@warning_ignore("integer_division")
	var step := int(Time.get_ticks_msec() / 110)
	return 0.35 + 0.6 * float((step * 7 + seed * 3 + step * seed) % 5) / 4.0


## L-shaped brackets at the four corners of `r`.
static func corners(ci: CanvasItem, r: Rect2, col: Color, arm := 27.0) -> void:
	for cx in [0.0, 1.0]:
		for cy in [0.0, 1.0]:
			var p := r.position + r.size * Vector2(cx, cy)
			var sx := 1.0 if cx == 0.0 else -1.0
			var sy := 1.0 if cy == 0.0 else -1.0
			ci.draw_rect(Rect2(p.x - (PX if sx < 0 else 0.0), p.y + (0.0 if sy > 0 else -arm), PX, arm), col)
			ci.draw_rect(Rect2(p.x + (0.0 if sx > 0 else -arm), p.y - (PX if sy < 0 else 0.0), arm, PX), col)


## The line's status, right-aligned at `right` (a text baseline): signal bars, a lock, and the call clock
## (`secs`, hidden while `ringing`, when the bars blink instead).
static func status(ci: CanvasItem, right: Vector2, secs: float, ringing: bool, blink: bool) -> void:
	var x := right.x
	if not ringing:
		var clock := "%02d:%02d" % [int(secs) / 60, int(secs) % 60]
		var f := HudPalette.tracked(HudPalette.DISPLAY, 24, 0.2)
		HudPalette.hud_text(ci, right, clock, 24, GREEN, f, 2, false)
		x -= f.get_string_size(clock, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.legible(ci, 24)).x + 30
	# the lock: a shackle over a body
	var lx := snappedf(x - 18, PX)
	var col := DIM
	ci.draw_rect(Rect2(lx, right.y - 15, 18, 15), col)
	ci.draw_rect(Rect2(lx + 3, right.y - 27, PX, 12), col)
	ci.draw_rect(Rect2(lx + 12, right.y - 27, PX, 12), col)
	ci.draw_rect(Rect2(lx + 3, right.y - 27, 12, PX), col)
	ci.draw_rect(Rect2(lx + 7.5, right.y - 10, PX, 6), Color.BLACK)
	# signal: five rising bars
	var bx := lx - 30 - 5 * 9
	for i in 5:
		var h := 6.0 + i * 5.0
		var on := not ringing or blink
		ci.draw_rect(Rect2(bx + i * 9, right.y - h, 6, h), Color(GREEN, 0.75 if on else 0.15))


## One pip per line of the call from `at` (top-left): heard lines dim, the current one lit, the rest faint.
static func pips(ci: CanvasItem, at: Vector2, n: int, current: int) -> void:
	var w := clampf(480.0 / maxf(n, 1) - 6.0, 6.0, 30.0)
	for i in n:
		var a := 1.0 if i == current else (0.4 if i < current else 0.12)
		ci.draw_rect(Rect2(snappedf(at.x + i * (w + 6), PX), at.y, snappedf(w, PX), 6), Color(GREEN, a))
