class_name AlertBeat
extends RefCounted
## The cue a change in the Mission's highest guard state fires: "?" on Suspicion, "!" on Alert (with a
## hit-stop), relief when Evasion ends. Node-free; the Mix autoload feeds it every frame and applies scale().

const STOP_TIME := 0.2    # real seconds of hit-stop
const STOP_SCALE := 0.05  # Engine.time_scale during it

var _top := GuardAlert.State.PATROL
var _stop_until := -1.0
var _n := 0  # guards up last frame


## `states` are the GuardAlert.State values of the guards that are up; `now` is real time in seconds.
## Returns &"question", &"alert", &"relief" or &"" (the Mix key of the sound to play).
func update(states: Array, now: float) -> StringName:
	var top: int = states.max() if not states.is_empty() else GuardAlert.State.PATROL
	var prev := _top
	_top = top
	var left := states.size() < _n  # a guard went (downed, scene change): not an Evasion ending
	_n = states.size()
	if top == prev:
		return &""
	if top == GuardAlert.State.ALERT:
		_stop_until = now + STOP_TIME
		return &"alert"
	if top == GuardAlert.State.SUSPICION and prev == GuardAlert.State.PATROL:
		return &"question"
	if prev == GuardAlert.State.EVASION and top < GuardAlert.State.EVASION and not left:
		return &"relief"
	return &""


## The time scale to run at. `cancel` (paused, Operative dead) ends the hit-stop for good.
func scale(now: float, cancel: bool) -> float:
	if cancel:
		_stop_until = -1.0
	return STOP_SCALE if now < _stop_until else 1.0
