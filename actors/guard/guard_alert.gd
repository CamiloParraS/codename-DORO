## One guard's alert state machine: patrol → suspicion → alert → evasion → patrol.
## Pure and node-free. The guard feeds it what it sensed; each call returns a reason string
## (for the debug overlay) when the state changes, "" otherwise.
class_name GuardAlert
extends RefCounted

enum State { PATROL, SUSPICION, ALERT, EVASION }

const SUSPECT_AT := 0.35   # meter level where a guard goes "?"
const DRAIN := 0.25        # meter drain per second while the Operative is out of sight
const LOOK_TIME := 5.0     # seconds a suspicious guard looks around the spot before giving up
const LOSE_TIME := 3.0     # seconds out of sight before ALERT drops to EVASION
const SEARCH_TIME := 12.0  # seconds of searching the last known position before back to patrol
const FOOTSTEP_RANGE := 6.0  # noise ranges in metres, no wall occlusion
const KNOCK_RANGE := 10.0
const FLINCH := 0.35       # seconds of the startle on going to alert; cosmetic, never holds up the response
const ORDER_REASONS := {all_clear = "%s called all clear", go = "%s sent it to check a place", hold = "%s told it to hold position"}

var state := State.PATROL
var meter := 0.0           # 0..1 detection meter; only fills in PATROL / SUSPICION
var last_known := Vector3.ZERO
var timer := 0.0           # time spent at the spot in SUSPICION / EVASION
var unseen := 0.0          # time without sight in ALERT
var _saw_down := false     # see_down() filled the meter since the last tick: no drain


## seen_rate: how fast the meter fills this frame (0 = not seen). why: what the guard saw.
## at_target: the guard has reached last_known (or as close as the navmesh gets).
func tick(delta: float, seen_rate: float, seen_pos: Vector3, why: String, at_target: bool) -> String:
	var seen := seen_rate > 0.0
	var body := _saw_down
	_saw_down = false
	if seen:
		last_known = seen_pos
	match state:
		State.PATROL, State.SUSPICION:
			if seen:
				meter = minf(meter + seen_rate * delta, 1.0)
				timer = 0.0
			elif not body:
				meter = maxf(meter - DRAIN * delta, 0.0)
			if meter >= 1.0:
				return _go(State.ALERT, "spotted you (%s)" % why)
			if state == State.PATROL and meter >= SUSPECT_AT:
				return _go(State.SUSPICION, "saw something (%s)" % why)
			if state == State.SUSPICION and not seen and at_target:
				timer += delta
				if timer >= LOOK_TIME:
					return _go(State.PATROL, "found nothing, back to patrol")
		State.ALERT:
			unseen = 0.0 if seen else unseen + delta
			if unseen >= LOSE_TIME:
				return _go(State.EVASION, "lost sight of you, searching")
		State.EVASION:
			if seen:
				return _go(State.ALERT, "found you again (%s)" % why)
			if at_target:
				timer += delta
				if timer >= SEARCH_TIME:
					return _go(State.PATROL, "gave up the search")
	return ""


## A security camera's tick: the same meter and drain, but no suspicion step: a full meter goes
## straight to ALERT (the camera radios it). It drops back to PATROL, meter empty, after LOSE_TIME
## unseen. The camera passes its front-cone rate only.
func camera_tick(delta: float, seen_rate: float, seen_pos: Vector3, why: String) -> String:
	var seen := seen_rate > 0.0
	if seen:
		last_known = seen_pos
	if state == State.ALERT:
		unseen = 0.0 if seen else unseen + delta
		if unseen >= LOSE_TIME:
			return _go(State.PATROL, "camera lost you")
		return ""
	meter = minf(meter + seen_rate * delta, 1.0) if seen else maxf(meter - DRAIN * delta, 0.0)
	if meter >= 1.0:
		return _go(State.ALERT, "camera spotted you (%s)" % why)
	return ""


## A noise reached this guard: suspicion at the source, never alert.
## A guard already suspicious or searching just moves its search there.
func hear(pos: Vector3, what: String) -> String:
	if state == State.ALERT:
		return ""
	last_known = pos
	timer = 0.0
	if state == State.PATROL:
		meter = maxf(meter, SUSPECT_AT)
		return _go(State.SUSPICION, "heard %s" % what)
	return ""


## The guard sees a Down guard at pos (rate: the same vision fill as for the Operative). It fills the
## same meter at the same rate, only up to suspicion, then walks over to check; alerted guards
## ignore bodies. Call it before tick() in the same frame: a body in sight holds off the drain.
## instant (Downs L2): suspicion becomes an alert at once, with no walking over to check.
func see_down(delta: float, rate: float, pos: Vector3, instant := false) -> String:
	if rate <= 0.0 or state == State.ALERT:
		return ""
	_saw_down = true
	last_known = pos
	timer = 0.0
	if state == State.PATROL:
		meter = maxf(meter, minf(meter + rate * delta, SUSPECT_AT))
		if meter >= SUSPECT_AT:
			return _go(State.ALERT, "found a Down guard") if instant else _go(State.SUSPICION, "saw a Down guard")
	elif instant:
		return _go(State.ALERT, "found a Down guard")
	return ""


## Standing at a Down guard: a dead one raises the alert (the guard radios it); a Neutralized one
## is woken by the caller, and the checker stays suspicious.
func check_down(dead: bool) -> String:
	if state == State.PATROL or state == State.ALERT:
		return ""
	if dead:
		return _go(State.ALERT, "found a dead guard")
	timer = 0.0
	return "woke a Neutralized guard"


## A guard just woke from being Neutralized: suspicious where it lies, remembering nothing.
func wake(pos: Vector3) -> String:
	last_known = pos
	meter = SUSPECT_AT
	return _go(State.SUSPICION, "woke up")


## Does a guard at ear hear a noise of this radius at pos: 3D distance, through walls.
static func in_earshot(ear: Vector3, pos: Vector3, radius: float) -> bool:
	return ear.distance_to(pos) <= radius


## Another guard radioed an alert at pos.
func radio(pos: Vector3, who: String) -> String:
	if state == State.ALERT:
		return ""
	last_known = pos
	return _go(State.ALERT, "%s radioed an alert" % who)


## A believed radio order from `who` ("all_clear", or "go" / "hold" for a guard that drops its
## search to carry it out): back to patrol from any state. The reason names the order; an all clear
## to a patrolling guard changes nothing ("").
func stand_down(who: String, order := "all_clear") -> String:
	var why: String = ORDER_REASONS[order] % who
	if state == State.PATROL:
		return "" if order == "all_clear" else why
	return _go(State.PATROL, why)


## Does going from `from` to `to` earn the guard a flinch: entering ALERT.
static func flinches(from: State, to: State) -> bool:
	return to == State.ALERT and from != State.ALERT


func _go(to: State, reason: String) -> String:
	state = to
	timer = 0.0
	unseen = 0.0
	if to == State.ALERT:
		meter = 1.0
	elif to == State.PATROL:
		meter = 0.0
	return reason
