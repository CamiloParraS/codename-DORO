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

var state := State.PATROL
var meter := 0.0           # 0..1 detection meter; only fills in PATROL / SUSPICION
var last_known := Vector3.ZERO
var timer := 0.0           # time spent at the spot in SUSPICION / EVASION
var unseen := 0.0          # time without sight in ALERT


## seen_rate: how fast the meter fills this frame (0 = not seen). why: what the guard saw.
## at_target: the guard has reached last_known (or as close as the navmesh gets).
func tick(delta: float, seen_rate: float, seen_pos: Vector3, why: String, at_target: bool) -> String:
	var seen := seen_rate > 0.0
	if seen:
		last_known = seen_pos
	match state:
		State.PATROL, State.SUSPICION:
			if seen:
				meter = minf(meter + seen_rate * delta, 1.0)
				timer = 0.0
			else:
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


## Another guard radioed an alert at pos.
func radio(pos: Vector3, who: String) -> String:
	if state == State.ALERT:
		return ""
	last_known = pos
	return _go(State.ALERT, "%s radioed an alert" % who)


func _go(to: State, reason: String) -> String:
	state = to
	timer = 0.0
	unseen = 0.0
	if to == State.ALERT:
		meter = 1.0
	elif to == State.PATROL:
		meter = 0.0
	return reason
