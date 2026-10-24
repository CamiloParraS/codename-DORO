## The Area's Alert chain, node-free: Radio calls → Alert → Evasion → Caution → Normal, and the search
## spots the searchers share. Guards and cameras start and stop calls; MissionRun ticks it once a frame
## and passes the events on to the guards. Only a completed call is an Alert (`alerts` counts them for
## Rank and Reinforcements); a stopped call, a local search and Caution aren't.
class_name AlertChain
extends RefCounted

enum Phase { NORMAL, ALERT, EVASION, CAUTION }

const CALL_TIME := 2.0         # a guard's Radio call
const CAMERA_CALL_TIME := 1.5  # a camera's window
const SHOUT_RANGE := 15.0      # the spotter's "!" reaches guards this close, through walls
const ALERT_TIME := 20.0       # the Alert counter: full while any guard sees the Operative, drains unseen
const EVASION_TIME := 30.0
const CAUTION_TIME := 60.0
const SEARCH_REACH := 10.0     # search spots within this of the last known point
const CAUTION_REACH := 1.25    # vision reach in Caution
const CAUTION_FILL := 1.3      # meter fill rate in Caution

static var area := AlertChain.new()  # the running Area's chain; MissionRun makes a fresh one per Area

var phase := Phase.NORMAL
var left := 0.0       # seconds left of the phase (the Alert counter in ALERT)
var alerts := 0       # completed calls: Alerts for Rank, one Reinforcement dispatch each
var call_pos := Vector3.ZERO  # where the last completed call reported the Operative
var caller: Variant = null    # who made it
var spots: Array = [] # search spot candidates (Vector3): Crawlspace mouths, Ladder feet
var _calls := {}      # caller -> [seconds left, sighting point]
var _held := {}       # searcher -> reserved spot (Vector3)


## A guard or camera starts radioing a sighting at pos. Refused during Alert and Evasion (the guard joins
## the hunt instead), while it already calls, and for a responder whose spotter (`heard`) still calls.
func start_call(who: Variant, pos: Vector3, time := CALL_TIME, heard: Variant = null) -> bool:
	if phase == Phase.ALERT or phase == Phase.EVASION or _calls.has(who) or (heard != null and _calls.has(heard)):
		return false
	_calls[who] = [time, pos]
	return true


## A dart, choke or kill (a camera: out of the cone, destroyed). The other calls run on.
func stop_call(who: Variant) -> void:
	_calls.erase(who)


func calling(who: Variant) -> bool:
	return _calls.has(who)


## A Caution trigger: a stopped call's search ended, a Neutralized partner found, a guard woke. Refreshes
## to CAUTION_TIME, never stacks; ignored in Alert and Evasion, which end in Caution anyway.
func caution() -> void:
	if phase == Phase.NORMAL or phase == Phase.CAUTION:
		phase = Phase.CAUTION
		left = CAUTION_TIME


## One frame. seen: any guard sees the Operative. Returns &"alert" (a call completed: count it, send
## Reinforcements, every guard hunts), &"realert" (a sighting in Evasion: hunt again, nothing counted),
## &"evasion", &"caution", &"normal" or &"".
func tick(delta: float, seen: bool) -> StringName:
	var done: Variant = null
	for who: Variant in _calls:
		_calls[who][0] -= delta
		if _calls[who][0] <= 0.0 and done == null:
			done = who
	if done != null:
		call_pos = _calls[done][1]
		caller = done
		_calls.clear()  # the first to complete clears the rest
		alerts += 1
		phase = Phase.ALERT
		left = ALERT_TIME
		return &"alert"
	match phase:
		Phase.ALERT:
			left = ALERT_TIME if seen else left - delta
			if left <= 0.0:
				phase = Phase.EVASION
				left = EVASION_TIME
				_held.clear()
				return &"evasion"
		Phase.EVASION:
			if seen:
				phase = Phase.ALERT
				left = ALERT_TIME
				return &"realert"
			left -= delta
			if left <= 0.0:
				phase = Phase.CAUTION
				left = CAUTION_TIME
				return &"caution"
		Phase.CAUTION:
			left -= delta
			if left <= 0.0:
				phase = Phase.NORMAL
				return &"normal"
	return &""


## The spot `who` searches around `point`: the first searcher holds the point itself, the others each
## get a distinct candidate within SEARCH_REACH of it, nearest first; with none left, the point. Asking
## again returns the same spot until release().
func reserve(who: Variant, point: Vector3) -> Vector3:
	if _held.has(who):
		return _held[who]
	var taken := _held.values()
	var spot := point
	if point in taken:
		var near := spots.filter(func(s: Vector3) -> bool: return s.distance_to(point) <= SEARCH_REACH and not s in taken)
		near.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(point) < b.distance_to(point))
		if not near.is_empty():
			spot = near[0]
	_held[who] = spot
	return spot


## Nobody hunts any more (a believed all-units all clear, or every hunter Down): straight back to Normal.
func stand_down() -> void:
	_calls.clear()
	_held.clear()
	phase = Phase.NORMAL
	left = 0.0


## The searcher left the search or was Neutralized.
func release(who: Variant) -> void:
	_held.erase(who)
