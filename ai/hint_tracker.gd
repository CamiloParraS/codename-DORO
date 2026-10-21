## Metis's Hints, node-free: when an idle or wandering player earns one, and which tier. Idle comes from
## SessionLog.idle_seconds() (no timer here; a baseline stands in for "timers reset after each Hint").
## Wandering = distance to the objective more than WANDER_DIST above the best so far for WANDER_FOR s.
## One Hint per GAP s, MAX_HINTS a step; a Hint due during Alert or Evasion is queued until it ends.
class_name HintTracker
extends RefCounted

const IDLE_AT := 90.0
const WANDER_DIST := 15.0
const WANDER_FOR := 45.0
const GAP := 60.0
const MAX_HINTS := 2

var _given := 0
var _since := GAP        # seconds since the last Hint (the first is never held back)
var _base := 0.0         # the logger's idle at the last Hint
var _best := INF
var _wander := 0.0
var _queued := false
var _idle := 0.0         # the logger's idle as last seen


## A new objective step: best distance, count and queue start over.
func new_step() -> void:
	_given = 0
	_since = GAP
	_base = 0.0
	_best = INF
	_wander = 0.0
	_queued = false


## Once per unpaused frame. Returns the tier to say (1 direction, 2 route), or 0.
func update(delta: float, idle: float, distance: float, alerting: bool) -> int:
	_since += delta
	_idle = idle
	if idle < _base:
		_base = 0.0  # the logger saw progress and restarted its idle
	if not alerting:  # the wander timer pauses in Alert and Evasion
		_best = minf(_best, distance)
		_wander = _wander + delta if distance > _best + WANDER_DIST else 0.0
	if idle - _base >= IDLE_AT or _wander >= WANDER_FOR:
		_queued = true
	if _queued and not alerting and _since >= GAP and _given < MAX_HINTS:
		return _fire()
	return 0


## "Request hint": the next tier now, if any is left. Counts toward the cap.
func request() -> int:
	return _fire() if _given < MAX_HINTS else 0


func _fire() -> int:
	_given += 1
	_since = 0.0
	_base = _idle
	_wander = 0.0
	_queued = false
	return _given
