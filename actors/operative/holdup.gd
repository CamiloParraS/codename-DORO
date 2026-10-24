## Hold-up rules, node-free (pw-feel 06): what frees a held-up guard, and which one answer he gives.
## The Operative ticks one per Hold-up; a paused tree (a full-screen Codec call) doesn't tick it.
class_name Holdup
extends RefCounted

const RANGE := 6.0      # metres: hold up an unaware guard this close; farther, he's free
const AIM_GRACE := 4.0  # seconds off aim (turned away, reloading, RMB let go) before he's free
const ASK_TIME := 2.0   # seconds of E held for his answer
const COMPASS := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]

var aim_off := 0.0


## One frame of a Hold-up. True when he goes free: an Alert, beyond RANGE, or AIM_GRACE s off aim.
func tick(delta: float, on_aim: bool, dist: float, alerted: bool) -> bool:
	aim_off = 0.0 if on_aim else aim_off + delta
	return alerted or dist > RANGE or aim_off > AIM_GRACE


## His one answer, the first that applies: a scripted one (scripted: a text key, "" = none), his Voiceprint
## if the Operative lacks it, the current objective's intel location if there is one, else a free Scanner reveal.
static func answer(scripted: String, voiceprint_new: bool, has_objective: bool) -> String:
	if scripted != "":
		return scripted
	if voiceprint_new:
		return "voiceprint"
	return "objective" if has_objective else "scan"


## "42 m south-east": how far and which way an offset points, flat, north-up (north is -Z, as on the Radar).
static func bearing(offset: Vector3) -> String:
	var flat := Vector2(offset.x, offset.z)
	var i := posmod(roundi(atan2(flat.x, -flat.y) / (PI / 4)), 8)
	return "%d m %s" % [roundi(flat.length()), COMPASS[i]]
