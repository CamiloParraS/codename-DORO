## Node-free movement and look rules for the Operative.
class_name Locomotion

const RUN := 4.4
const WALK := 1.9
const CROUCH := 1.3
const CARRY := 2.6  # a body on the shoulder: slower than the run, quicker than a walk
## Falling: m/s² down, and how the run's way is lost in the air. Off the floor longer than AIR_GRACE (a curb or a
## stair edge stays inside it) the keys stop steering and AIR_DRAG bleeds the way off, so a drop lands close under the edge.
const GRAVITY := 35.0
const AIR_GRACE := 0.12
const AIR_DRAG := 12.0
## Hitscan sway in degrees (the crosshair doesn't move) and the seconds to settle after stopping.
const SWAY_MOVING := 0.6
const SWAY_STILL := 0.25
const SWAY_CROUCHED := 0.1
const SWAY_SETTLE := 0.8
## The aim point drifts about the crosshair by this many times the sway, in degrees (see drift).
const DRIFT_GAIN := 1.5
## Camera distance behind the shoulder, standing and aiming (metres).
const CAM_DIST := 2.4
const CAM_DIST_AIM := 1.8
const PITCH_MIN := -1.1
const PITCH_MAX := 0.5
## Velocity easing, in 1/s: a run takes ~0.25 s to reach full speed; the sharper
## cut is for slowing (stop, run→walk) so releasing keys never feels slidey.
const GET_GOING := 7.0
const SLOW_DOWN := 20.0
## Body turn rate toward the move direction or facing, in 1/s. Aiming, the body keeps up with the camera faster:
## at TURN_RATE it trailed the crosshair and the strafe read as floaty (playtest 1).
const TURN_RATE := 8.0
const AIM_TURN_RATE := 22.0
## The eight ways a strafe can go, clockwise from straight ahead: the suffix of the walk clip the legs play.
const STRAFE_DIRS := ["forward", "forward_right", "right", "backward_right", "backward", "backward_left", "left", "forward_left"]


## The heading (radians about +Y) the body turns toward: the camera's `yaw` while aiming, moving or not (WASD only
## strafes, so the gun points where the crosshair is), else the way it moves (`dir`, flat); NAN to hold its heading.
static func heading(aiming: bool, moving: bool, dir: Vector3, yaw: float) -> float:
	if aiming:
		return yaw
	if moving:
		return atan2(-dir.x, -dir.z)
	return NAN


## Which of STRAFE_DIRS a move `local` to the body goes (x right, y ahead): the nearest of the eight; "" for none.
static func strafe_dir(local: Vector2) -> String:
	if local == Vector2.ZERO:
		return ""
	return STRAFE_DIRS[posmod(roundi(atan2(local.x, local.y) / (PI / 4.0)), 8)]


## Aiming slows a standing Operative to walk speed; crouched keeps CROUCH; carrying a body is CARRY.
static func speed(crouching: bool, walking: bool, aiming := false, carrying := false) -> float:
	return CROUCH if crouching else CARRY if carrying else (WALK if walking or aiming else RUN)


## The horizontal velocity `air` s after leaving the floor: the eased move within AIR_GRACE, then only drag.
static func fall(current: Vector2, target: Vector2, air: float, delta: float) -> Vector2:
	if air <= AIR_GRACE:
		return move(current, target, delta)
	return current.lerp(Vector2.ZERO, minf(1.0, AIR_DRAG * delta))


## Gun sway in degrees: full while moving, settling linearly over SWAY_SETTLE to the still value.
static func sway(current: float, moving: bool, crouching: bool, delta: float) -> float:
	if moving:
		return SWAY_MOVING
	var target := SWAY_CROUCHED if crouching else SWAY_STILL
	return move_toward(current, target, (SWAY_MOVING - target) / SWAY_SETTLE * delta)


## Where the aim point has wandered to, in degrees (x right, y up), `t` seconds in: a slow wobble whose
## size follows the sway. The crosshair is drawn there and the shot goes there.
static func drift(sway_deg: float, t: float) -> Vector2:
	var w := Vector2(sin(t * 1.3) + 0.5 * sin(t * 2.9), sin(t * 1.7 + 1.0) + 0.5 * sin(t * 3.3)) / 1.5
	return w * sway_deg * DRIFT_GAIN


## Screen pixels from the centre for a drift of `d` degrees (y up), at the camera's `fov` and the screen's height.
static func drift_px(d: Vector2, fov_deg: float, screen_h: float) -> Vector2:
	var k := screen_h / 2.0 / tan(deg_to_rad(fov_deg / 2.0))
	return Vector2(tan(deg_to_rad(d.x)), -tan(deg_to_rad(d.y))) * k


## Returns the new (yaw, pitch) after a mouse delta. `sens` is radians per pixel.
static func look(yaw: float, pitch: float, relative: Vector2, sens: float, invert_y: bool) -> Vector2:
	var dy := relative.y * sens * (-1.0 if invert_y else 1.0)
	return Vector2(yaw - relative.x * sens, clampf(pitch - dy, PITCH_MIN, PITCH_MAX))


## Eases the horizontal velocity toward `target` so starts and stops carry a little weight:
## getting up to speed is gradual, and a reversal is eased rather than a snap about-face.
static func move(current: Vector2, target: Vector2, delta: float) -> Vector2:
	var rate := GET_GOING if target.length_squared() > current.length_squared() else SLOW_DOWN
	return current.lerp(target, minf(1.0, rate * delta))
