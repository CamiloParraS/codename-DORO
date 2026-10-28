## One guard's alert state machine: patrol → suspicion → alert → evasion → patrol.
## Pure and node-free. The guard feeds it what it sensed; each call returns a reason string
## (for the debug overlay) when the state changes, "" otherwise. A full meter doesn't alert: the guard
## goes "!" and starts a Radio call (`calling`); only the Area's AlertChain, once a call completes,
## sends guards to ALERT (radio()), on to EVASION (evade()) and back to patrol (give_up()).
class_name GuardAlert
extends RefCounted

enum State { PATROL, SUSPICION, ALERT, EVASION }

const SUSPECT_AT := 0.35   # meter level where a guard goes "?"
const DRAIN := 0.25        # meter drain per second while the Operative is out of sight
const LOOK_TIME := 5.0     # seconds a suspicious guard looks around the spot before giving up
const NOISE_GRACE := 1.0   # a noise later than this into Suspicion adds NOISE_FILL to the meter
const NOISE_FILL := 0.35
const CAMERA_LOSE_TIME := 3.0  # a camera drops its alert this quickly: it never searches
const FOOTSTEP_RANGE := 6.0  # noise ranges in metres, no wall occlusion
const KNOCK_RANGE := 10.0
const SURFACE_LOUDNESS := {&"metal": 1.3}  # floor tag -> footstep range multiplier; anything else is 1.0
const PARTNER_RANGE := 15.0  # a guard seen dropping within this, in the front cone; the name call carries as far
const PARTNER_DELAY := 3.0   # seconds from a partner's "?" to his "!"
const FLINCH := 0.35       # seconds of the startle on going "!"; cosmetic, never holds up the response
const ORDER_REASONS := {all_clear = "%s called all clear", go = "%s sent it to check a place", hold = "%s told it to hold position"}

var state := State.PATROL
var meter := 0.0           # 0..1 detection meter; only fills in PATROL / SUSPICION
var last_known := Vector3.ZERO
var timer := 0.0           # time spent at the spot in SUSPICION
var since := 0.0           # time since entering the state
var unseen := 0.0          # time without sight in ALERT (Engage reads it)
var saw := false           # has seen the Operative since entering ALERT
var calling := false       # went "!" to radio it in: SUSPICION, standing still, until the chain decides
var rushing := false       # a responder to a shout, running to the sighting point (SUSPICION)
var heard: Variant = null  # the spotter whose shout it answers
var partner := ""          # the dropped guard it's about to radio in (see_drop), "" = none
var partner_left := 0.0    # seconds until that "!"
var _saw_down := false     # see_down() filled the meter since the last tick: no drain


## seen_rate: how fast the meter fills this frame (0 = not seen). why: what the guard saw.
## at_target: the guard has reached last_known (or as close as the navmesh gets).
func tick(delta: float, seen_rate: float, seen_pos: Vector3, why: String, at_target: bool) -> String:
	var seen := seen_rate > 0.0
	var body := _saw_down
	_saw_down = false
	if seen:
		last_known = seen_pos
	since += delta
	match state:
		State.PATROL, State.SUSPICION:
			if calling:
				return ""
			if partner != "":
				partner_left -= delta
				if partner_left <= 0.0:
					return _call("%s is down" % partner)
			if seen:
				meter = minf(meter + seen_rate * delta, 1.0)
				timer = 0.0
			elif not body:
				meter = maxf(meter - DRAIN * delta, 0.0)
			if meter >= 1.0:
				return _call("spotted you (%s)" % why)
			if state == State.PATROL and meter >= SUSPECT_AT:
				return _go(State.SUSPICION, "saw something (%s)" % why)
			if state == State.SUSPICION and not seen and at_target:
				timer += delta
				if timer >= LOOK_TIME:
					return _go(State.PATROL, "found nothing, back to patrol")
		State.ALERT:
			unseen = 0.0 if seen else unseen + delta
			saw = saw or seen
		State.EVASION:
			if seen:
				return _go(State.ALERT, "found you again (%s)" % why)
	return ""


## A security camera's tick: the same meter and drain, but no suspicion step: a full meter goes
## straight to ALERT (the camera's own; it starts the camera's Radio call). It drops back to PATROL,
## meter empty, after CAMERA_LOSE_TIME unseen. The camera passes its front-cone rate only.
func camera_tick(delta: float, seen_rate: float, seen_pos: Vector3, why: String) -> String:
	var seen := seen_rate > 0.0
	if seen:
		last_known = seen_pos
	if state == State.ALERT:
		unseen = 0.0 if seen else unseen + delta
		if unseen >= CAMERA_LOSE_TIME:
			return _go(State.PATROL, "camera lost you")
		return ""
	meter = minf(meter + seen_rate * delta, 1.0) if seen else maxf(meter - DRAIN * delta, 0.0)
	if meter >= 1.0:
		return _go(State.ALERT, "camera spotted you (%s)" % why)
	return ""


## The AlertChain's Alert drained: a hunting guard searches.
func evade() -> String:
	return _go(State.EVASION, "lost sight of you, searching") if state == State.ALERT else ""


## The Alert is over (Evasion ended): a hunting or searching guard goes back to patrol.
func give_up() -> String:
	return _go(State.PATROL, "gave up the search") if state >= State.ALERT else ""


## Heard spotter `who`'s shout for a sighting at pos: "!" and run there. It never starts its own call
## for it while that call runs. Guards already calling, responding, hunting or searching ignore it.
func respond(pos: Vector3, who: Variant, name_: String) -> String:
	if calling or rushing or state >= State.ALERT:
		return ""
	_go(State.SUSPICION, "")
	meter = maxf(meter, SUSPECT_AT)
	last_known = pos
	rushing = true
	heard = who
	return "%s shouted, running over" % name_


## Saw guard `name_` drop (darted, choked, killed) or kneel at gunpoint at pos: "?" there, and "!"
## PARTNER_DELAY s later (a sighting meanwhile is an ordinary spotting). A later drop doesn't restart it.
## Guards already calling or hunting ignore it.
func see_drop(pos: Vector3, name_: String) -> String:
	if calling or state >= State.ALERT or partner != "":
		return ""
	_go(State.SUSPICION, "")
	meter = maxf(meter, SUSPECT_AT)
	last_known = pos
	partner = name_
	partner_left = PARTNER_DELAY
	return "saw %s drop" % name_


## A noise reached this guard: suspicion at the source, never an alert by itself. A suspicious guard
## moves its look point there without restarting the look-around, and a noise more than NOISE_GRACE s
## into Suspicion adds NOISE_FILL to the meter, so repeated noise escalates (footsteps never do: only sight alerts). A searching guard moves
## its search there.
func hear(pos: Vector3, what: String) -> String:
	if state == State.ALERT or calling:
		return ""
	last_known = pos
	if state == State.PATROL:
		meter = maxf(meter, SUSPECT_AT)
		return _go(State.SUSPICION, "heard %s" % what)
	if state == State.SUSPICION and since > NOISE_GRACE and what != "footsteps":
		meter = minf(meter + NOISE_FILL, 1.0)
		if meter >= 1.0:
			return _call("heard %s again" % what)
	elif state == State.EVASION:
		timer = 0.0
	return ""


## Freed from a Hold-up by the Operative at pos: a Radio call on him (stoppable like any other).
func freed(pos: Vector3) -> String:
	if state == State.ALERT or calling:
		return ""
	last_known = pos
	return _call("freed from a hold-up")


## A loud gunshot at pos reached this guard: a Radio call, not suspicion. A searching guard searches there.
func shot(pos: Vector3) -> String:
	if state == State.ALERT or calling:
		return ""
	last_known = pos
	if state == State.EVASION:
		return ""
	return _call("heard a gunshot")


## The guard sees a Down guard at pos (rate: the same vision fill as for the Operative). It fills the
## same meter at the same rate, only up to suspicion, then walks over to check; alerted guards
## ignore bodies. Call it before tick() in the same frame: a body in sight holds off the drain.
## instant (Downs L2): suspicion becomes a Radio call at once, with no walking over to check.
func see_down(delta: float, rate: float, pos: Vector3, instant := false) -> String:
	if rate <= 0.0 or state == State.ALERT or calling:
		return ""
	_saw_down = true
	last_known = pos
	timer = 0.0
	if state == State.PATROL:
		meter = maxf(meter, minf(meter + rate * delta, SUSPECT_AT))
		if meter >= SUSPECT_AT:
			return _call("found a Down guard") if instant else _go(State.SUSPICION, "saw a Down guard")
	elif instant and state == State.SUSPICION:
		return _call("found a Down guard")
	return ""


## Standing at a Down guard: a dead one starts a Radio call (in Evasion the hunt is on already); a
## Neutralized one is woken by the caller (a Caution trigger), and the checker stays suspicious.
func check_down(dead: bool) -> String:
	if state == State.PATROL or state == State.ALERT or calling:
		return ""
	if dead:
		return "" if state == State.EVASION else _call("found a dead guard")
	timer = 0.0
	return "woke a Neutralized guard"


## A guard just woke from being Neutralized: suspicious where it lies, remembering nothing.
func wake(pos: Vector3) -> String:
	last_known = pos
	meter = SUSPECT_AT
	return _go(State.SUSPICION, "woke up")


## How far a run's footsteps carry on a floor `surface` tag: metal rings.
static func footstep_range(surface: StringName) -> float:
	return FOOTSTEP_RANGE * SURFACE_LOUDNESS.get(surface, 1.0)


## Does a guard at ear hear a noise of this radius at pos: 3D distance, through walls.
static func in_earshot(ear: Vector3, pos: Vector3, radius: float) -> bool:
	return ear.distance_to(pos) <= radius


## The Area is in Alert (a call completed, or `who` joins the hunt): hunt from pos.
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


## "!": stands still and radios it in (SUSPICION, meter full) until the AlertChain says otherwise.
func _call(reason: String) -> String:
	_go(State.SUSPICION, reason)
	meter = 1.0
	calling = true
	return reason


func _go(to: State, reason: String) -> String:
	state = to
	timer = 0.0
	since = 0.0
	unseen = 0.0
	saw = false
	calling = false
	rushing = false
	heard = null
	partner = ""
	if to == State.ALERT:
		meter = 1.0
	elif to == State.PATROL:
		meter = 0.0
	return reason
