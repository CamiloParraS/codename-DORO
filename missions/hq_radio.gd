## HQ's side of the radio for one Mission (the Radio node holds this one): Downs L1 / L3 polls. About
## every 45 s HQ radios "<X>, report"; an up guard answers, a Down one is given 10 s, then the nearest
## up guard goes to its last position in suspicion. L3 polls the guard no other guard has seen longest.
## A Fultoned guard stays on the roster (gone) as one who can't answer, so the Operative can Report in for him.
class_name HqRadio
extends Node

const SIGHT_EVERY := 1.0   # Downs L3: seconds between the guards' sight checks on each other

var poll := HqPoll.new()
var gone := {}             # Fultoned guard name -> where he went up; a Checkpoint keeps it, like the Area does
var _seen := {}            # guard name -> _now when another guard last saw it
var _sight_clock := 0.0
var _now := 0.0


func _process(delta: float) -> void:
	_now += delta
	var run := get_tree().get_first_node_in_group("mission_plan")
	var mode := Deployment.hq_poll(run.plan.deployed) if run else ""
	if mode == "":
		return
	var guards := get_tree().get_nodes_in_group("guards")
	if mode == "targeted":
		_sight_checks(delta, guards)
	var info := _info(guards)
	var e := poll.tick(delta, info, mode == "targeted", randf())
	match e.get("event", ""):
		"poll":
			say(tr("radio.hq_report").format({who = e.who}))
			if poll.who == "":
				_by_name(info, e.who).node.radio_say(tr(Checkin.LINES.pick_random()))
		"silence":
			send_nearest(e.pos, e.who, "no answer from %s" % e.who)


## The guard HQ is waiting on ("" = no poll pending).
func who() -> String:
	return poll.who


## Report in was believed.
func answer() -> void:
	poll.answer()


func say(line: String) -> void:
	get_tree().call_group("radio_log", "say", "HQ", line)


## The up guard nearest `at` (other than `except`) goes to `spot` in suspicion.
func send_nearest(spot: Vector3, except: String, what: String, at := spot) -> void:
	var info := _info(get_tree().get_nodes_in_group("guards"))
	var near := HqPoll.nearest(info, at, except)
	if near != "":
		_by_name(info, near).node.on_noise(spot, what)


## A Checkpoint restore: HQ forgets its poll and what the guards had seen.
func reset() -> void:
	poll = HqPoll.new()
	_seen.clear()
	_sight_clock = 0.0


func _info(guards: Array) -> Array:
	var out := guards.map(func(g: Guard) -> Dictionary: return {
		name = String(g.name), pos = g.global_position, can_answer = g.can_radio(), dead = g.dead,
		unseen = _now - _seen.get(String(g.name), 0.0), node = g})
	for n: String in gone:
		out.append({name = n, pos = gone[n], can_answer = false, dead = false, unseen = _now - _seen.get(n, 0.0), node = null})
	return out


func _by_name(info: Array, guard_name: String) -> Dictionary:
	return info.filter(func(i: Dictionary) -> bool: return i.name == guard_name)[0]


## Every SIGHT_EVERY s, each up guard looks for the others (the cones and a clear line, same as
## Guard.can_see). ponytail: O(n²) raycasts once a second; slower if the guard count grows.
func _sight_checks(delta: float, guards: Array) -> void:
	_sight_clock += delta
	if _sight_clock < SIGHT_EVERY:
		return
	_sight_clock = 0.0
	for a: Guard in guards:
		if a.is_down():
			continue
		for b: Guard in guards:
			if b != a and a.can_see(b):
				_seen[String(b.name)] = _now
