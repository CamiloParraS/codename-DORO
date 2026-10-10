## A guard's routine radio check-in timer: every 20-30 s it talks for TALK_TIME seconds. Node-free.
class_name Checkin
extends RefCounted

const MIN_WAIT := 20.0
const MAX_WAIT := 30.0
const TALK_TIME := 3.0
const LINES := ["Post clear.", "All quiet here.", "Nothing to report.", "Still on my rounds.", "Checking in. Quiet."]

var wait := randf_range(MIN_WAIT, MAX_WAIT)
var talking_left := 0.0


func talking() -> bool:
	return talking_left > 0.0


## Advances the timer; true on the frame a check-in starts.
func tick(delta: float) -> bool:
	if talking_left > 0.0:
		talking_left = maxf(talking_left - delta, 0.0)
		return false
	wait -= delta
	if wait > 0.0:
		return false
	wait = randf_range(MIN_WAIT, MAX_WAIT)
	talking_left = TALK_TIME
	return true
