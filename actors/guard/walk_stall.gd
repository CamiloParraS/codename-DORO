## Has a guard's walk to its goal stopped getting anywhere? Node-free. The guard steps it every frame it walks
## (its flat distance to the goal); once AFTER s pass without closing GAIN m, the walk is as close as it will
## get (the goal is off the navmesh, on a deck above, crowded by another guard) and the guard counts as arrived
## (Guard.arrived), so it searches from where it stands instead of standing there for good. A goal moved less
## than SAME_GOAL (a sighting point nudged by footsteps) is the same goal; a farther one starts over.
class_name WalkStall
extends RefCounted

const AFTER := 1.5      # s without progress
const GAIN := 0.3       # m closer that counts as progress
const SAME_GOAL := 1.0  # m a goal may move and still be the one it walks to

var _goal := Vector3.INF
var _best := INF        # the closest it has got to _goal
var _stalled := 0.0     # s since it last got GAIN closer


## One frame walking to `goal`, `dist` flat metres from it.
func step(goal: Vector3, dist: float, delta: float) -> void:
	if not _same(goal):
		_goal = goal
		_best = dist
		_stalled = 0.0
		return
	if dist < _best - GAIN:
		_best = dist
		_stalled = 0.0
	else:
		_stalled += delta


## Is the walk to `goal` stuck where it stands.
func stuck(goal: Vector3) -> bool:
	return _same(goal) and _stalled >= AFTER


func _same(goal: Vector3) -> bool:
	return _goal != Vector3.INF and _goal.distance_to(goal) <= SAME_GOAL
