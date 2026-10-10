## How fast a guard's meter fills when it sees the Operative. Pure: the guard does the
## line-of-sight ray to the chest and passes the offset from its eye to the chest.
class_name GuardVision

const FRONT_RANGE := 16.0
const FRONT_HALF := deg_to_rad(30.0)
const SIDE_RANGE := 6.0           # peripheral vision: wide but short, half rate
const SIDE_HALF := deg_to_rad(60.0)
const CLOSE := 3.0                # inside this (front cone) the meter fills x4
const BASE_RATE := 1.2


## Meter fill per second; 0 when the Operative is outside both cones.
## offset: guard eye → Operative chest. facing: the guard's forward.
static func fill_rate(offset: Vector3, facing: Vector3, crouching: bool, moving: bool, walking: bool) -> float:
	var dist := Vector2(offset.x, offset.z).length()
	var reach := _reach(offset, facing)
	if reach == 0.0:
		return 0.0
	var rate := BASE_RATE * clampf(1.2 - dist / reach, 0.15, 1.0)  # faster the closer
	rate *= 0.5 if crouching else 1.0
	if not moving:
		rate *= 0.6
	elif not (crouching or walking):
		rate *= 1.5  # running
	if reach == SIDE_RANGE:
		rate *= 0.5
	elif dist < CLOSE:
		rate *= 4.0
	return rate


## What the guard saw, for the reason string: "running, 9 m, in front".
static func describe(offset: Vector3, facing: Vector3, crouching: bool, moving: bool, walking: bool) -> String:
	var how := ""
	if not moving:
		how = "still, crouched" if crouching else "still, standing"
	elif crouching:
		how = "crouch-walking"
	else:
		how = "walking" if walking else "running"
	var cone := "in front" if _reach(offset, facing) == FRONT_RANGE else "corner of the eye"
	return "%s, %d m, %s" % [how, roundi(Vector2(offset.x, offset.z).length()), cone]


## The range of the cone the offset falls in (FRONT_RANGE, SIDE_RANGE), or 0.
static func _reach(offset: Vector3, facing: Vector3) -> float:
	var flat := Vector2(offset.x, offset.z)
	var dist := flat.length()
	var ang := absf(Vector2(facing.x, facing.z).angle_to(flat)) if dist > 0.01 else 0.0
	if ang <= FRONT_HALF and dist <= FRONT_RANGE:
		return FRONT_RANGE
	if ang <= SIDE_HALF and dist <= SIDE_RANGE:
		return SIDE_RANGE
	return 0.0
