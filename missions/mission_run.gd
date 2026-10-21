## A Mission in progress: feeds the tally from the guards, advances its objective steps (Campaign
## data for record.mission) as the Operative reaches each step's intel pickup, ends at the Extraction
## point once every step is done and every Target (group "targets") is dead or carried, then shows the
## post-Mission screen. Completing folds the tally into
## the record (Aigis.complete_mission), and in the campaign moves Campaign.record on; aborting discards it.
## Hooks elsewhere report events with get_tree().call_group("mission_tally", "event", name).
## Set record (and return_to) before it enters the tree: the plan is made from the record in _ready,
## before the Area reads it. Group "mission_plan": the F3 overlay reads record, plan and tally.
## Checkpoints (in memory only): one is taken once the Area is built, and one at each objective step.
## restore_checkpoint() (group "checkpoint": death, the pause screen) undoes everything
## since, except that the dead stay dead and Countermeasures stay as deployed.
class_name MissionRun
extends Node

signal finished(new_record: Dictionary)

const SCREEN := preload("res://ui/post_mission/post_mission.gd")

const LOG_PATH := "user://session_log.txt"  # rewritten at each Mission's end; the observer opens it

var tally := MissionTally.new()
var record := Aigis.new_record()
var plan := {}                     # Aigis.plan_mission for this record: what the Area deploys
var return_to := ""                # scene to go back to once committed (Briefing, Free mode); "" stays
var campaign := false              # committing moves Campaign.record on (never in Free mode)
var telegraphs_seen := {}          # Telegraph kinds Metis has already called this Mission
var tutorial := Tutorial.new()     # Mission 1's first-use tips (campaign only)
var step := 0                      # objective steps done
var ended := false
var hints := HintTracker.new()     # Metis's Hints for the current step
var _opened := false              # the opening call has been made
var _down := {}
var _known := {}
var _checkpoint := {}


func _ready() -> void:
	add_to_group("mission_tally")
	add_to_group("mission_plan")
	add_to_group("checkpoint")
	plan = Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), record.mission)
	process_mode = Node.PROCESS_MODE_ALWAYS
	for e in get_tree().get_nodes_in_group("extraction"):
		e.reached.connect(_on_extraction)
	for i in get_tree().get_nodes_in_group("intel"):
		i.reached.connect(_on_intel.bind(i))
	_show_intel()
	SessionLog.current.start_mission(record.mission)
	take_checkpoint.call_deferred()  # once the Area has spawned its guards


## Snapshot: the objective step, the Operative (position, ammo, Voiceprints), the tally (Habits and
## Lethality so far), Glaukopis's flags, which guards exist (reinforcements arrive later), which are
## dead and where they lie, and which cameras are destroyed.
## The Operative's snapshot keeps its Scanner charges and Magazines.
func take_checkpoint() -> void:
	SessionLog.current.progress()
	var dead := {}
	for g in get_tree().get_nodes_in_group("guards"):
		if g.dead:  # a body on the shoulder is kept as dropped where the Operative stands
			dead[g] = [g.carrier.global_transform if g.carrier else g.global_transform, g.known_down]
	var radio := get_tree().get_first_node_in_group("radio")
	_checkpoint = {
		step = step,
		operative = get_tree().get_first_node_in_group("operative").snapshot(),
		tally = copy(tally),
		guards = get_tree().get_nodes_in_group("guards"),
		glaukopis = copy(radio.glaukopis) if radio else null,
		dead = dead,
		destroyed = get_tree().get_nodes_in_group("cameras").filter(func(c): return c.destroyed),
	}


## Back to the last Checkpoint. Bodies dead then lie where they lay; every other guard (Neutralized,
## or killed since) is back at its post on patrol; reinforcements that arrived since are gone (the
## tally's spawned count rolls back with them). Cameras stay; one shot since works again, alert cleared.
func restore_checkpoint() -> void:
	if ended or _checkpoint.is_empty():
		return
	tally = copy(_checkpoint.tally)
	step = _checkpoint.step
	hints.new_step()
	_show_intel()
	var radio := get_tree().get_first_node_in_group("radio")
	if radio:
		radio.close()
		radio.glaukopis = copy(_checkpoint.glaukopis)
		radio.hq.reset()
	get_tree().get_first_node_in_group("operative").restore(_checkpoint.operative)
	for g in get_tree().get_nodes_in_group("guards"):
		if g not in _checkpoint.guards:
			g.remove_from_group("guards")  # queue_free waits for the frame's end
			g.queue_free()
		elif g in _checkpoint.dead:
			g.carrier = null
			g.global_transform = _checkpoint.dead[g][0]
			g.known_down = _checkpoint.dead[g][1]
		else:
			g.return_to_post()
	for c in get_tree().get_nodes_in_group("cameras"):
		if c not in _checkpoint.destroyed:
			c.repair()


## A deep copy of a node-free state object (a Gun, Voiceprints, the tally, Glaukopis).
static func copy(o: Object) -> Object:
	var c: Object = o.get_script().new()
	for p in o.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var v: Variant = o.get(p.name)
			c.set(p.name, v.duplicate(true) if v is Array or v is Dictionary else v)
	return c


func event(name_: String) -> void:
	if not ended:
		SessionLog.current.count(name_)  # the log is a playtest record: a Checkpoint restore doesn't roll it back
		tally.add(name_)


func _physics_process(delta: float) -> void:
	if ended:
		return
	var alert := false
	for g in get_tree().get_nodes_in_group("guards"):
		alert = alert or g.alert.state == GuardAlert.State.ALERT
		var d: bool = g.is_down()
		if d and not _down.get(g, false):
			tally.guard_down()
			if g.target:
				if g.dead:
					_say_objective()
				for e in get_tree().get_nodes_in_group("extraction"):  # the Operative may already stand in it
					if e.standing():
						_on_extraction()
		_down[g] = d
		if g.known_down and not _known.get(g, false):
			tally.add("down_found")
		_known[g] = g.known_down
	tally.set_alert(alert)
	if not get_tree().paused:
		var alerting: bool = alert or get_tree().get_nodes_in_group("guards").any(func(g: Guard) -> bool: return g.alert.state == GuardAlert.State.EVASION)
		SessionLog.current.tick(delta, alerting)
		_guide(delta, alerting)
	_teach(delta)


## Metis's live calls: the opening call once the Operative spawns unseen, then a Hint when it is idle or wandering.
func _guide(delta: float, alerting: bool) -> void:
	var op: Node3D = get_tree().get_first_node_in_group("operative")
	if not op:
		return
	if not _opened:
		if not get_tree().get_nodes_in_group("guards").any(func(g: Guard) -> bool: return g.seen_rate > 0.0):
			_opened = true
			get_tree().call_group("codec_live", "live_call", Campaign.MISSIONS[record.mission].open)
		return
	if step >= _steps().size():
		return
	var intel := _step_intel()
	var dist := _flat(op, intel) if intel else INF
	_hint(hints.update(delta, SessionLog.current.idle_seconds(), dist, alerting))


## "Request hint" in the radio menu: the next tier now, or Metis says there is no more.
func request_hint() -> void:
	if ended or step >= _steps().size():
		return
	var tier := hints.request()
	if tier == 0:
		get_tree().call_group("radio_log", "say", "METIS", tr("hint.none"))
	_hint(tier)


func _hint(tier: int) -> void:
	if tier > 0:
		get_tree().call_group("codec_live", "live_call", [["analyst", _steps()[step].hint[tier - 1]]])


## Mission 1's tutorial: a prompt on the HUD and one Metis radio line the first time each verb matters.
func _teach(delta: float) -> void:
	var op: Node3D = get_tree().get_first_node_in_group("operative")
	if not op:
		return
	var world := {guard = INF, down = INF, spot = INF, prints = op.voiceprints.held.size(),
		scanner = op.items.charges, magazines = op.items.magazines, tranq = op.gun() == op.tranq}
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		var key := "down" if g.is_down() else "guard" if g.alert.state in [GuardAlert.State.PATROL, GuardAlert.State.SUSPICION] else ""
		if key != "":
			world[key] = minf(world[key], _flat(op, g))
	for s: Node3D in get_tree().get_nodes_in_group("eavesdrop_spot"):
		world.spot = minf(world.spot, _flat(op, s))
	var verb := tutorial.update(delta, record.mission, campaign, Tutorial.relevant(world))
	if verb != "":
		get_tree().call_group("tutorial_tip", "tip", tr(Tutorial.prompt_key(verb)))
		get_tree().call_group("radio_log", "say", "METIS", tr(Tutorial.line_key(verb)))


static func _flat(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()


## What to do now, for the pause screen: the steps, then the Targets, then Extraction.
func objective() -> String:
	if step >= _steps().size() and not _targets_left().is_empty():
		return tr("objective.targets") + ": " + ", ".join(_targets_left().map(func(t: Guard) -> String: return t.name))
	return Campaign.objective(record.mission, step)


## Where the Radar points now, as {pos: Vector3, target: bool}: the current step's intel, then each Target
## still to kill or carry, then Extraction.
func radar_blips() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if step < _steps().size():
		var intel := _step_intel()
		if intel:
			out.append({pos = intel.global_position, target = false})
	elif not _targets_left().is_empty():
		for t: Guard in _targets_left():
			out.append({pos = t.global_position, target = true})
	else:
		for e: Node3D in get_tree().get_nodes_in_group("extraction"):
			out.append({pos = e.global_position, target = false})
	return out


## Targets neither dead nor on the Operative's shoulder (a Neutralized one left lying doesn't count,
## unless it lies in the Extraction point: the Core room is one, so a choke there needs no carry).
func _targets_left() -> Array:
	return get_tree().get_nodes_in_group("targets").filter(func(t: Guard) -> bool:
		return not (t.dead or t.carrier or (t.is_down() and _at_extraction(t))))


func _at_extraction(t: Guard) -> bool:
	return get_tree().get_nodes_in_group("extraction").any(func(e: Node) -> bool: return e.contains(t.global_position))


func _say_objective() -> void:
	get_tree().call_group("radio_log", "say", "INTEL", objective())  # ponytail: placeholder until the live Codec calls


## The current step's intel pickup in the Area, or null.
func _step_intel() -> Node3D:
	for i: Node3D in get_tree().get_nodes_in_group("intel"):
		if i.name == _steps()[step].intel:
			return i
	return null


func _steps() -> Array:
	return Campaign.MISSIONS[record.mission].steps


## Only the current step's intel is shown.
func _show_intel() -> void:
	for i: Node3D in get_tree().get_nodes_in_group("intel"):
		i.visible = step < _steps().size() and i.name == _steps()[step].intel
		i.set_deferred("monitoring", i.visible)  # a hidden pickup is inert: it can't open the Core's lift early


## The current step's intel reached: the step is done, and that's a Checkpoint.
func _on_intel(intel: Node) -> void:
	if ended or step >= _steps().size() or intel.name != _steps()[step].intel:
		return
	get_tree().call_group("codec_live", "live_call", _steps()[step].call)
	step += 1
	hints.new_step()
	_show_intel()
	_say_objective()
	take_checkpoint()


func _on_extraction() -> void:
	if ended or step < _steps().size() or not _targets_left().is_empty():
		return
	_finish()
	var after := Aigis.complete_mission(record, tally.counts)
	var screen := SCREEN.new()
	screen.strip = MissionTally.strip(record, after)
	screen.seconds = SessionLog.current.seconds()
	screen.voice_key = VoiceLines.post_key(Aigis.resolve_ending(Aigis.lethality_ratio(after)), VoiceLines.lethality_zero(tally.counts))
	var layer := CanvasLayer.new()
	layer.layer = 2
	layer.add_child(screen)
	add_child(layer)
	get_tree().paused = true
	screen.committed.connect(func() -> void:
		record = after
		if campaign:
			Campaign.record = after
			if saves_on_commit(after):
				save_slot()
		get_tree().paused = false
		finished.emit(after)
		if return_to:
			get_tree().change_scene_to_file(return_to))


## The Core's commit is the last Mission: its slot is marked complete at the Core terminal instead.
static func saves_on_commit(after: Dictionary) -> bool:
	return after.mission < Campaign.MISSIONS.size()


func save_slot() -> void:
	if campaign and Campaign.slot >= 0:
		SaveSlots.write(Campaign.slot, record, int(Time.get_unix_time_from_system()))


## Quit or abort: nothing is applied.
func abort() -> void:
	_finish()
	tally = MissionTally.new()


## The Mission is over: no more play, and the session log is on disk.
func _finish() -> void:
	ended = true
	SessionLog.current.finish_mission()
	SessionLog.current.write(LOG_PATH)


## Quitting (or leaving the scene) mid-Mission still writes the log.
func _exit_tree() -> void:
	if not ended:
		_finish()
