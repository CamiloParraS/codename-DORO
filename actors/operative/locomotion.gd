## Node-free movement and look rules for the Operative.
class_name Locomotion

const RUN := 5.0
const WALK := 2.0
const CROUCH := 1.8
const PITCH_MIN := -1.1
const PITCH_MAX := 0.5
## Velocity easing, in 1/s: a run takes ~0.15 s to reach full speed; the sharper
## cut is for slowing (stop, run→walk) so releasing keys never feels slidey.
const GET_GOING := 10.0
const SLOW_DOWN := 16.0


static func speed(crouching: bool, walking: bool) -> float:
	return CROUCH if crouching else (WALK if walking else RUN)


## Returns the new (yaw, pitch) after a mouse delta. `sens` is radians per pixel.
static func look(yaw: float, pitch: float, relative: Vector2, sens: float, invert_y: bool) -> Vector2:
	var dy := relative.y * sens * (-1.0 if invert_y else 1.0)
	return Vector2(yaw - relative.x * sens, clampf(pitch - dy, PITCH_MIN, PITCH_MAX))


## Eases the horizontal velocity toward `target` so starts and stops carry a little weight:
## getting up to speed is gradual, and a reversal is eased rather than a snap about-face.
static func move(current: Vector2, target: Vector2, delta: float) -> Vector2:
	var rate := GET_GOING if target.length_squared() > current.length_squared() else SLOW_DOWN
	return current.lerp(target, minf(1.0, rate * delta))
