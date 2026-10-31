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
const RING_RADII := [6.0, 11.0]  # m: the ring of open-ground search spots round the last known point
const RING_DIRS := 8
const RING_SLACK := 2.5        # m a ring spot may move when snapped to the floor, and the most it may climb or drop
const SPOT_APART := 2.5        # m: spots closer than this are the same place (and a searched one stays searched)
const OUTWARD := 1.2           # a spot's distance from the point weighs this much against the searcher's walk to it
const CAUTION_REACH := 1.25    # vision reach in Caution
const CAUTION_FILL := 1.3      # meter fill rate in Caution

static var area := AlertChain.new()  # the running Area's chain; MissionRun makes a fresh one per Area

var phase := Phase.NORMAL
var left := 0.0       # seconds left of the phase (the Alert counter in ALERT)
var alerts := 0       # completed calls: Alerts for Rank, one Reinforcement dispatch each
var call_pos := Vector3.ZERO  # where the last completed call reported the Operative
var caller: Variant = null    # who made it
var spots: Array = [] # search spot candidates (Vector3): Crawlspace mouths, Ladder feet
var nav_map := RID()  # the Area's navmesh (MissionRun sets it): ring spots are snapped onto its floor
var snap := Callable()  # a test's stand-in for the navmesh; never a lambda on AlertChain.area (static: freed after its script, it crashes the quit)
var _calls := {}      # caller -> [seconds left, sighting point]
var _held := {}       # searcher -> reserved spot (Vector3)
var _searched := []   # spots swept since the last sighting: nobody is sent there again until the next one
var _ring_for := Vector3.INF  # the point _ring was built round
var _ring := []


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
		_fresh_search()
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
				_fresh_search()
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


## The spot `who` searches around `point`. The candidates are the point itself, the fixed spots within
## SEARCH_REACH of it, and the ring round it (ring()), less the ones another searcher holds or someone has
## already swept. The first searcher holds the point; the others take the free candidate nearest the
## point and, given `from` (where the searcher stands), nearest themselves too (OUTWARD weighs the point
## against the walk), so a squad works outward from the sighting, each on its own side. With every candidate
## swept the sweep starts over; with every one held, it's the point. Asking again returns the same spot
## until release() or searched().
func reserve(who: Variant, point: Vector3, from := Vector3.INF) -> Vector3:
	if _held.has(who):
		return _held[who]
	var free := _free(point)
	if free.is_empty() and not _searched.is_empty():
		_searched.clear()  # every place swept: go round again
		free = _free(point)
	var spot := point
	if not free.is_empty():
		var cost := func(s: Vector3) -> float:
			return OUTWARD * s.distance_to(point) + (0.0 if from == Vector3.INF else s.distance_to(from))
		free.sort_custom(func(a: Vector3, b: Vector3) -> bool: return cost.call(a) < cost.call(b))
		spot = free[0]
	_held[who] = spot
	return spot


## `who` has swept its spot: nobody is sent there again until the next sighting, and its next reserve()
## picks another.
func searched(who: Variant) -> void:
	if _held.has(who):
		_searched.append(_held[who])
		_held.erase(who)


## The open-ground spots round `point`: RING_DIRS directions at each of RING_RADII, put on the floor by
## _on_floor(). A spot that moved more than RING_SLACK across or up (inside a wall, up on a roof) is dropped,
## and of two within SPOT_APART only the first is kept. Built once per point.
func ring(point: Vector3) -> Array:
	if _ring_for == point:
		return _ring
	_ring_for = point
	_ring = []
	for r: float in RING_RADII:
		for i in RING_DIRS:
			var a := TAU * (i + (0.5 if r != RING_RADII[0] else 0.0)) / RING_DIRS  # the outer ring offset half a step
			var want := point + Vector3(cos(a), 0.0, sin(a)) * r
			var p := _on_floor(want)
			if Vector2(p.x - want.x, p.z - want.z).length() > RING_SLACK or absf(p.y - point.y) > RING_SLACK:
				continue
			if not _ring.any(func(q: Vector3) -> bool: return q.distance_to(p) < SPOT_APART):
				_ring.append(p)
	return _ring


## `p` on the walkable floor: `snap` when a test gives one, else the navmesh's closest point, else as it is.
func _on_floor(p: Vector3) -> Vector3:
	if snap.is_valid():
		return snap.call(p)
	return NavigationServer3D.map_get_closest_point(nav_map, p) if nav_map.is_valid() else p


## Candidates round `point` nobody holds or has swept.
func _free(point: Vector3) -> Array:
	var taken := _held.values()
	var all := [point] + spots.filter(func(s: Vector3) -> bool: return s.distance_to(point) <= SEARCH_REACH)
	all.append_array(ring(point))
	return all.filter(func(s: Vector3) -> bool:
		return not s in taken and not _searched.any(func(q: Vector3) -> bool: return q.distance_to(s) < SPOT_APART))


## A new sighting: what was swept before says nothing now.
func _fresh_search() -> void:
	_searched.clear()


## Nobody hunts any more (a believed all-units all clear, or every hunter Down): straight back to Normal.
func stand_down() -> void:
	_calls.clear()
	_held.clear()
	_searched.clear()
	phase = Phase.NORMAL
	left = 0.0


## The searcher left the search or was Neutralized.
func release(who: Variant) -> void:
	_held.erase(who)
