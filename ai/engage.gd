## How an alerted guard closes on the Operative, node-free. A guard that sees the Operative from within
## Health.RANGE (where it can shoot) and no nearer than KEEP_RANGE holds and fires instead of closing in, and one
## that finds it nearer steps back to keep its distance (one range, so there is no band where it walks in again).
## When no alerted guard has seen the Operative for PUSH_AFTER s the squad has lost it (lost()): each guard
## fans out to its own search spot round the last sighting (AlertChain.reserve) instead of standing there.
class_name Engage
extends RefCounted

const RETREAT_TO := 9.0   # m: a retreat that has begun runs on to here, so it doesn't stop and walk back in at KEEP_RANGE
const KEEP_RANGE := 6.0   # m: a guard that sees the Operative closes no nearer than this and gives ground inside it
const RANGE_MARGIN := 4.0 # m: a guard not yet holding starts only this far inside Health.RANGE, so it doesn't flicker at the edge
const PUSH_AFTER := 5.0
const SWEEP_TIME := 4.0   # s a guard looks round a search spot before it moves on to the next


## Does a guard that sees the Operative at `dist` metres step back from it.
static func backs_off(sees: bool, dist: float) -> bool:
	return sees and dist < KEEP_RANGE


## Does a guard that sees the Operative at `dist` flat metres hold its ground and fire. was: it held last
## tick (it keeps holding out to Health.RANGE, but starts only RANGE_MARGIN inside). Out of sight nobody holds.
## me and squad are kept for the callers; see lost() for what the squad does without sight.
static func holds(_me: int, sees: bool, dist: float, _squad: Array, was := false) -> bool:
	return sees and dist >= KEEP_RANGE and dist <= Health.RANGE - (0.0 if was else RANGE_MARGIN)


## Has the squad lost the Operative: no alerted guard has seen it for PUSH_AFTER s. squad: one {unseen} per
## alerted guard, unseen being its seconds without sight (0 while it sees); one marked `fresh` (a new
## reinforcement that has not seen the Operative yet) says nothing about who has sight.
static func lost(squad: Array) -> bool:
	var gap := INF
	for s: Dictionary in squad:
		if not s.get("fresh", false):
			gap = minf(gap, s.unseen)
	return gap >= PUSH_AFTER
