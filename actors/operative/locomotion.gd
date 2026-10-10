## Node-free movement and look rules for the Operative.
class_name Locomotion

const RUN := 5.0
const WALK := 2.0
const CROUCH := 1.8
const PITCH_MIN := -1.1
const PITCH_MAX := 0.5


static func speed(crouching: bool, walking: bool) -> float:
	return CROUCH if crouching else (WALK if walking else RUN)


## Returns the new (yaw, pitch) after a mouse delta. `sens` is radians per pixel.
static func look(yaw: float, pitch: float, relative: Vector2, sens: float, invert_y: bool) -> Vector2:
	var dy := relative.y * sens * (-1.0 if invert_y else 1.0)
	return Vector2(yaw - relative.x * sens, clampf(pitch - dy, PITCH_MIN, PITCH_MAX))
