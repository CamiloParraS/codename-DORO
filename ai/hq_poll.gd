## HQ's radio polls (Downs L1 / L3), node-free: every INTERVAL s HQ calls one guard. An up guard
## answers on the spot; a Down one has ANSWER_TIME s to be answered for (Report in), else silence.
## guards: [{name, pos, can_answer, dead, unseen (s since a guard last saw it)}].
## roll: a random 0..1, passed in so tests are deterministic.
class_name HqPoll
extends RefCounted

const INTERVAL := 45.0
const ANSWER_TIME := 10.0
const DOWN_WEIGHT := 3.0   # a guard who can't answer (Down, held, stumbling) is this many times likelier to be picked

var wait := INTERVAL
var who := ""              # the guard being waited on ("" = none pending)
var pos := Vector3.ZERO    # where it was last seen to be
var left := 0.0


## Advances the clock. Returns {} or {event "poll", who} or {event "silence", who, pos}.
func tick(delta: float, guards: Array, targeted: bool, roll: float) -> Dictionary:
	if who != "":
		for g in guards:
			if g.name == who:
				pos = g.pos
		left -= delta
		if left > 0.0:
			return {}
		var out := {event = "silence", who = who, pos = pos}
		who = ""
		return out
	wait -= delta
	if wait > 0.0:
		return {}
	wait = INTERVAL
	var picked := pick(guards, targeted, roll)
	if picked == "":
		return {}
	for g in guards:
		if g.name == picked and not g.can_answer:
			who = picked
			pos = g.pos
			left = ANSWER_TIME
	return {event = "poll", who = picked}


## The Operative answered as the polled guard and HQ believed it.
func answer() -> void:
	who = ""


## The living guard to poll: targeted = unseen longest, else a weighted random pick.
static func pick(guards: Array, targeted: bool, roll: float) -> String:
	var pool := guards.filter(func(g): return not g.dead)
	if pool.is_empty():
		return ""
	if targeted:
		var best: Dictionary = pool[0]
		for g in pool:
			if g.unseen > best.unseen:
				best = g
		return best.name
	var weights := pool.map(func(g): return 1.0 if g.can_answer else DOWN_WEIGHT)
	var at: float = roll * weights.reduce(func(a, b): return a + b)
	for i in pool.size():
		at -= weights[i]
		if at < 0.0:
			return pool[i].name
	return pool[-1].name


## The up guard closest to pos other than `except`, or "".
static func nearest(guards: Array, at: Vector3, except: String) -> String:
	var best := ""
	var best_d := INF
	for g in guards:
		if g.can_answer and g.name != except and g.pos.distance_to(at) < best_d:
			best = g.name
			best_d = g.pos.distance_to(at)
	return best
