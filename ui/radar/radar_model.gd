## Radar rules, node-free: north-up (world -Z is up the screen), 30 m to the edge, anything farther pinned
## to the edge, jammed while the phase is ALERT or EVASION.
class_name RadarModel
extends RefCounted

const RANGE := 30.0  # metres from the Operative to the Radar's edge
const HALF := 40.0  # px, half the square's side
const MARGIN := 38.0  # px from the canvas's left edge: clear of the life bar and its label


## Offset from the Operative in metres (x, z) -> square coords in [-1, 1], pinned to the edge.
static func unit(offset: Vector2) -> Vector2:
	var u := offset / RANGE
	return u / maxf(1.0, maxf(absf(u.x), absf(u.y)))


static func in_range(offset: Vector2) -> bool:
	return maxf(absf(offset.x), absf(offset.y)) <= RANGE


static func jammed(phase: String) -> bool:
	return phase == "ALERT" or phase == "EVASION"


## Bottom-left, right of the life bar and its label.
static func rect(canvas: Vector2) -> Rect2:
	return Rect2(MARGIN, canvas.y - 18 - HALF * 2, HALF * 2, HALF * 2)
