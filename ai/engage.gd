## How an alerted guard closes on the Operative, node-free. A guard that sees the Operative from within
## Health.RANGE (where it can shoot) and no nearer than KEEP_RANGE holds and fires instead of closing in, and one
## that finds it nearer steps back to keep its distance (one range, so there is no band where it walks in again). When no alerted guard has seen the
## Operative for PUSH_AFTER s, only the one nearest the last sighting pushes up.
class_name Engage
extends RefCounted

const RETREAT_TO := 9.0   # m: a retreat that has begun runs on to here, so it doesn't stop and walk back in at KEEP_RANGE
const KEEP_RANGE := 6.0   # m: a guard that sees the Operative closes no nearer than this and gives ground inside it
const RANGE_MARGIN := 4.0 # m: a guard not yet holding starts only this far inside Health.RANGE, so it doesn't flicker at the edge
const PUSH_AFTER := 5.0


## Does a guard that sees the Operative at `dist` metres step back from it.
static func backs_off(sees: bool, dist: float) -> bool:
	return sees and dist < KEEP_RANGE


## Does the guard `me` (an index into `squad`) hold its ground. squad: one {pos, unseen, last_known} per
## alerted guard, unseen being its seconds without sight (0 while it sees); `fresh` (optional) marks one that
## has not seen the Operative yet (a new reinforcement), which says nothing about who has sight. dist: flat metres to the
## Operative, used only when `sees`. was: it held last tick (it keeps holding out to Health.RANGE, but starts only RANGE_MARGIN inside).
static func holds(me: int, sees: bool, dist: float, squad: Array, was := false) -> bool:
	if sees:
		return dist >= KEEP_RANGE and dist <= Health.RANGE - (0.0 if was else RANGE_MARGIN)
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
