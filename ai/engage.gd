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
const CALLOUT_EVERY := 2.0  # s between the squad's callouts of where the Operative is, to a guard without sight
const FLANK_DIST := 7.0   # m to the side of the spotter's line of fire a flanker runs to
const FLANK_PAST := 3.0   # m beyond the Operative along that line: behind the cover the spotter can't see past
const FLANK_MIN := 10.0   # m: a blind guard nearer than this to the sighting goes straight in
const FLANK_SNAP := 2.5   # m a flank point may move when put on the navmesh (more: it was in a wall), else no flank
const SWEEP_TIME := 4.0   # s a guard looks round a search spot before it moves on to the next


## Does a guard that sees the Operative at `dist` metres step back from it.
static func backs_off(sees: bool, dist: float) -> bool:
	return sees and dist < KEEP_RANGE


## Does a guard that sees the Operative at `dist` flat metres hold its ground and fire. was: it held last
## tick (it keeps holding out to Health.RANGE, but starts only RANGE_MARGIN inside). Out of sight nobody holds.
## me and squad are kept for the callers; see lost() for what the squad does without sight.
static func holds(_me: int, sees: bool, dist: float, _squad: Array, was := false) -> bool:
	return sees and dist >= KEEP_RANGE and dist <= Health.RANGE - (0.0 if was else RANGE_MARGIN)


## Where the squad has eyes on the Operative: {at: the last_known of the alerted guard that saw it most
## recently, if that was under GuardAlert.SIGHT_GRACE s ago, from: where that guard stands}; null when
## nobody sees it. Only a guard that has seen it since its Alert began (`saw`) is a source: a radioed one
## only knows where the call said. Blind guards take it as a callout every CALLOUT_EVERY s, not live.
static func lead(squad: Array) -> Variant:
	var best: Variant = null
	var gap := GuardAlert.SIGHT_GRACE
	for s: Dictionary in squad:
		if s.get("saw", false) and s.unseen < gap:
			gap = s.unseen
			best = {at = s.last_known, from = s.pos}
	return best


## Where a blind guard at `me` flanks an Operative seen at `at` by a squadmate at `from`: FLANK_DIST to the
## side of the spotter's line of fire it is already on, and FLANK_PAST beyond the Operative, so it comes at
## it from the side and behind, where cover facing the spotter doesn't help. null when it is within FLANK_MIN of `at` (it goes straight in) or the
## spotter stands on the spot.
static func flank_point(at: Vector3, from: Vector3, me: Vector3) -> Variant:
	var line := at - from
	line.y = 0.0
	var to_me := me - at
	to_me.y = 0.0
	if line.length() < 0.5 or to_me.length() < FLANK_MIN:
		return null
	var side := Vector3(-line.z, 0.0, line.x).normalized()
	if side.dot(to_me) < 0.0:
		side = -side
	return at + side * FLANK_DIST + line.normalized() * FLANK_PAST


## Has the squad lost the Operative: no alerted guard has seen it for PUSH_AFTER s. squad: one {unseen} per
## alerted guard, unseen being its seconds without sight (0 while it sees); one marked `fresh` (a new
## reinforcement that has not seen the Operative yet) says nothing about who has sight.
static func lost(squad: Array) -> bool:
	var gap := INF
	for s: Dictionary in squad:
		if not s.get("fresh", false):
			gap = minf(gap, s.unseen)
	return gap >= PUSH_AFTER
