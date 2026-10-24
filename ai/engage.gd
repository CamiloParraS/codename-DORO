## How an alerted guard closes on the Operative, node-free. A guard that sees the Operative from beyond
## HOLD_RANGE (and within Health.RANGE, where it can shoot) holds and fires instead of closing in. When no
## alerted guard has seen the Operative for PUSH_AFTER s, only the one nearest the last sighting pushes up.
class_name Engage
extends RefCounted

const HOLD_RANGE := 10.0
const PUSH_AFTER := 5.0


## Does the guard `me` (an index into `squad`) hold its ground. squad: one {pos, unseen, last_known} per
## alerted guard, unseen being its seconds without sight (0 while it sees); `fresh` (optional) marks one that
## has not seen the Operative yet (a new reinforcement), which says nothing about who has sight. dist: flat metres to the
## Operative, used only when `sees`.
static func holds(me: int, sees: bool, dist: float, squad: Array) -> bool:
	if sees:
		return dist > HOLD_RANGE and dist <= Health.RANGE
	var gap := INF
	var ref := Vector3.ZERO
	for s: Dictionary in squad:
		if not s.get("fresh", false) and s.unseen < gap:
			gap = s.unseen
			ref = s.last_known
	if gap < PUSH_AFTER:
		return false
	var nearest := 0
	for i in squad.size():
		if squad[i].pos.distance_to(ref) < squad[nearest].pos.distance_to(ref):
			nearest = i
	return nearest != me
