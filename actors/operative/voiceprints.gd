## The Operative's Voiceprints: capture progress per guard while close to one during a check-in, and
## the set held. Per Mission (not kept between Missions). Node-free.
class_name Voiceprints
extends RefCounted

const RANGE := 6.0
const CAPTURE_TIME := 2.5

var held: Array[String] = []        # guard names, in capture order
var progress := {}                  # guard name -> seconds of check-in audio heard, carried over


## Call each frame for a guard. Returns true on the frame the Voiceprint is recorded.
func tick(delta: float, who: String, distance: float, talking: bool) -> bool:
	if not talking or distance > RANGE or who in held:
		return false
	progress[who] = progress.get(who, 0.0) + delta
	if progress[who] < CAPTURE_TIME:
		return false
	progress.erase(who)
	held.append(who)
	return true
