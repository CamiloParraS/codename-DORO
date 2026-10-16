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

var tally := MissionTally.new()
var record := Aigis.new_record()
var plan := {}                     # Aigis.plan_mission for this record: what the Area deploys
var return_to := ""                # scene to go back to once committed (Briefing, Free mode); "" stays
var campaign := false              # committing moves Campaign.record on (never in Free mode)
var step := 0                      # objective steps done
var ended := false
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
	take_checkpoint.call_deferred()  # once the Area has spawned its guards


## Snapshot: the objective step, the Operative (position, ammo, Voiceprints), the tally (Habits and
## Lethality so far), Glaukopis's flags, which guards exist (reinforcements arrive later), which are
## dead and where they lie, and which cameras are destroyed.
## ponytail: Scanner charges and Magazines join when those exist.
func take_checkpoint() -> void:
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
		tally.add(name_)


func _physics_process(_delta: float) -> void:
	if ended:
		return
	var alert := false
	for g in get_tree().get_nodes_in_group("guards"):
		alert = alert or g.alert.state == GuardAlert.State.ALERT
		var d: bool = g.is_down()
		if d and not _down.get(g, false):
			tally.guard_down()
			if g.target and g.dead:
				_say_objective()
		_down[g] = d
		if g.known_down and not _known.get(g, false):
			tally.add("down_found")
		_known[g] = g.known_down
	tally.set_alert(alert)


## What to do now, for the pause screen: the steps, then the Targets, then Extraction.
func objective() -> String:
	if step >= _steps().size() and not _targets_left().is_empty():
		return "KILL OR CARRY OUT: " + ", ".join(_targets_left().map(func(t: Guard) -> String: return t.name))
	return Campaign.objective(record.mission, step)


## Targets neither dead nor on the Operative's shoulder (a Neutralized one left lying doesn't count).
func _targets_left() -> Array:
	return get_tree().get_nodes_in_group("targets").filter(func(t: Guard) -> bool: return not (t.dead or t.carrier))


func _say_objective() -> void:
	get_tree().call_group("radio_log", "say", "INTEL", objective())  # ponytail: placeholder until the live Codec calls


func _steps() -> Array:
	return Campaign.MISSIONS[record.mission].steps


## Only the current step's intel is shown.
func _show_intel() -> void:
	for i: Node3D in get_tree().get_nodes_in_group("intel"):
		i.visible = step < _steps().size() and i.name == _steps()[step].intel


## The current step's intel reached: the step is done, and that's a Checkpoint.
func _on_intel(intel: Node) -> void:
	if ended or step >= _steps().size() or intel.name != _steps()[step].intel:
		return
	step += 1
	_show_intel()
	_say_objective()
	take_checkpoint()


func _on_extraction() -> void:
	if ended or step < _steps().size() or not _targets_left().is_empty():
		return
	ended = true
	var after := Aigis.complete_mission(record, tally.counts)
	var screen := SCREEN.new()
	screen.strip = MissionTally.strip(record, after)
	var layer := CanvasLayer.new()
	layer.layer = 2
	layer.add_child(screen)
	add_child(layer)
	get_tree().paused = true
	screen.committed.connect(func() -> void:
		record = after
		if campaign:
			Campaign.record = after
		get_tree().paused = false
		finished.emit(after)
		if return_to:
			get_tree().change_scene_to_file(return_to))


## Quit or abort: nothing is applied.
func abort() -> void:
	ended = true
	tally = MissionTally.new()
