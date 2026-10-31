## Radar rules, node-free: a north-up disc (world -Z is up the screen), 30 m to the rim, anything farther pinned
## to the rim, jammed while the phase is ALERT or EVASION. Sizes are HUD design px (1920x1080 canvas).
class_name RadarModel
extends RefCounted

const RANGE := 30.0  # metres from the Operative to the Radar's edge
const HALF := 155.0  # px, the disc's radius
const MARGIN := 70.0  # px from the canvas's right edge
const TOP := 52.0  # px from the canvas's top edge


## Offset from the Operative in metres (x, z) -> disc coords (length <= 1), pinned to the rim.
static func unit(offset: Vector2) -> Vector2:
	var u := offset / RANGE
	return u / maxf(1.0, u.length())


## Pixel offset from the disc's centre for a world offset; `inset` keeps the blip inside the rim.
static func blip(offset: Vector2, inset: float) -> Vector2:
	return unit(offset) * (HALF - inset)


## World position on the ground plane: (x, z).
static func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Unit vector the node faces (its -Z) on the ground plane, i.e. up the screen when facing north.
static func facing(basis: Basis) -> Vector2:
	return Vector2(-basis.z.x, -basis.z.z).normalized()


static func jammed(phase: String) -> bool:
	return phase == "ALERT" or phase == "EVASION"


## A guard with a pending Radio call flashes red on the Radar (150 ms on/off); cameras have no blip.
static func call_flash(calling: bool, ticks_msec: int) -> bool:
	return calling and int(ticks_msec / 150.0) % 2 == 0


const PING_TIME := 0.5  # s a noise ring takes to spread out to its range
const GUARD_PING_SHOW := 1.5  # s a guard's blip stays after it made a noise


## How visible a guard's blip is, 0..1: always while the Scanner runs, else it fades after the guard's last noise.
static func guard_alpha(ping_age: float, scanning: bool) -> float:
	if scanning:
		return 1.0
	return clampf(1.0 - ping_age / GUARD_PING_SHOW, 0.0, 1.0)


## Pixel radius of a noise ring `age` s after the noise, or -1 once it is gone.
static func ping_radius(noise_range: float, age: float) -> float:
	if age < 0.0 or age >= PING_TIME:
		return -1.0
	return minf(noise_range / RANGE, 1.0) * (HALF - 2) * age / PING_TIME


## Top-right, on the HUD design canvas (1080 tall, as wide as the window's aspect makes it).
static func rect(canvas: Vector2) -> Rect2:
	return Rect2(canvas.x - MARGIN - HALF * 2, TOP, HALF * 2, HALF * 2)
