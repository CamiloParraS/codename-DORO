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
## since, except that the dead stay dead and Countermeasures stay as deployed, and the Rank counters
## (`rank`: kills, Alerts, found, Continues, time) run on: each restore is one Continue. Death opens the
## Game Over screen (game_over()), whose CONTINUE restores.
## replay: a Mission select replay, played against the record before its first clear; committing writes
## only its Mission Record (Campaign.missions) and a first S's item, never the slot's record or Recruits.
## A campaign commit banks the Recruits (Campaign.gear.settle); abort or quit banks nothing.
class_name MissionRun
extends Node

signal finished(new_record: Dictionary)

const SCREEN := preload("res://ui/post_mission/post_mission.gd")
const GAME_OVER := preload("res://ui/game_over/game_over.gd")
const MENU := "res://ui/main_menu/main_menu.tscn"

const LOG_PATH := "user://session_log.txt"  # each Mission appended at its end; the observer opens it
const LIVE_PATH := "user://session_log_live.txt"  # the running Mission, every trail point: a crash leaves it
const DIAGRAM_ORIGIN := 40.0  # tools/area_builder.gd _p: the log writes places in the builders' metres
## Tally events that count as doing a tutorial verb.
const TEACH_EVENTS := {dart = "tranq", spoof = "radio", takedown = "takedown", fulton = "fulton"}
const EXIT_NEAR := 5.0  # metres from an encounter_exit marker that name the way the Operative left

var tally := MissionTally.new()
var record := Aigis.new_record()
var mission := 0                   # the Mission this run plays: record.mission at _ready (a commit moves record on; the Core's scene stays)
var plan := {}                     # Aigis.plan_mission for this record: what the Area deploys
var return_to := ""                # scene to go back to once committed (Briefing, Free mode); "" stays
var campaign := false              # committing moves Campaign.record on (never in Free mode)
var replay := false                # a Mission select replay (campaign is false)
var rank := Rank.new()             # run-wide: a Checkpoint never restores it
var first_s := false               # set on commit: the slot's first S on this Mission (Requisition unlocks)
var telegraphs_seen := {}          # Telegraph kinds Metis has already called this Mission
var tutorial := Tutorial.new()     # Mission 1's first-use tips (campaign only)
var _enc_now := -1                 # the Encounter the Operative is in (encounter_at), -1 before the first frame
var _items := {}                   # Scanner charges and Magazines last frame: a drop is a use
var _holding := false              # some guard was held up last frame
var _carried: Node                 # what the Operative carried last frame, for the log
var _carried_name := ""
var step := 0                      # objective steps done
var ended := false
var hints := HintTracker.new()     # Metis's Hints for the current step
var _opened := false              # the opening call has been made
var _down := {}
var _known := {}
var _checkpoint := {}
var _game_over: Control


func _ready() -> void:
	add_to_group("mission_tally")
	add_to_group("mission_plan")
	add_to_group("checkpoint")
	mission = record.mission
	plan = Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), record.mission)
	process_mode = Node.PROCESS_MODE_ALWAYS
	for e in get_tree().get_nodes_in_group("extraction"):
		e.reached.connect(_on_extraction)
	for i in get_tree().get_nodes_in_group("intel"):
		i.reached.connect(_on_intel.bind(i))
	_show_intel.call_deferred()  # once the Extraction point has added its beacon
	if _logs():
		SessionLog.recover(LIVE_PATH, LOG_PATH)
	SessionLog.current.start_mission(record.mission, "%s, %s" % [get_parent().name, "campaign" if campaign else "replay" if replay else "free mode"])
	_fresh_chain()
	var intro: Dictionary = Campaign.MISSIONS[record.mission].get("intro", {})
	if not intro.is_empty() and not campaign:  # a title card holds play (and the clock) for its 2.3 s; the campaign's came before the Codec call (Briefing)
		_card([intro.name, intro.area, intro.stamp], true, func() -> void: get_tree().paused = false)
	take_checkpoint.call_deferred()  # once the Area has spawned its guards


## A new AlertChain for the Area, its search spots the Crawlspace mouths and Ladder feet.
## ponytail: no "far side of cover" spots yet; add markers in the area builder if searches look thin.
func _fresh_chain() -> void:
	AlertChain.area = AlertChain.new()
	for n: Node3D in get_parent().find_children("CarryBlock*", "StaticBody3D", true, false):  # one at each mouth
		AlertChain.area.spots.append(n.global_position)
	for l: Node3D in get_tree().get_nodes_in_group("ladders"):
		AlertChain.area.spots.append(l.get_node("Bottom").global_position)


## Snapshot: the objective step, the Operative (position, ammo, Voiceprints), the tally (Habits and
## Lethality so far), Glaukopis's flags, which guards exist (reinforcements arrive later), which are
## dead and where they lie, and which cameras are destroyed.
## The Operative's snapshot keeps its Scanner charges and Magazines.
func take_checkpoint() -> void:
	SessionLog.current.progress()
	var dead := {}
	var downed := {}
	for g in get_tree().get_nodes_in_group("guards"):
		if g.dead:  # a body on the shoulder is kept as dropped where the Operative stands
			dead[g] = [g.carrier.global_transform if g.carrier else g.global_transform, g.known_down]
		elif g.is_down():  # Neutralized: stays Down where it lay, with the time it has left
			downed[g] = [g.carrier.global_transform if g.carrier else g.global_transform, g.neutral_left, g.known_down]
	var radio := get_tree().get_first_node_in_group("radio")
	_checkpoint = {
		step = step,
		operative = get_tree().get_first_node_in_group("operative").snapshot(),
		tally = copy(tally),
		guards = get_tree().get_nodes_in_group("guards"),
		glaukopis = copy(radio.glaukopis) if radio else null,
		dead = dead,
		downed = downed,
		destroyed = get_tree().get_nodes_in_group("cameras").filter(func(c): return c.destroyed),
	}


## Back to the last Checkpoint. Bodies dead then lie where they lay and guards Neutralized then stay Down
## where they lay, with the time they had left; every other guard (up then, or killed since) is back at its post on patrol; reinforcements that arrived since are gone (the
## tally's spawned count rolls back with them). Cameras stay; one shot since works again, alert cleared.
func restore_checkpoint() -> void:
	if ended or _checkpoint.is_empty():
		return
	rank.continues += 1
	SessionLog.current.note("checkpoint restored at step %d (continue %d)" % [_checkpoint.step, rank.continues])
	if _game_over:
		_game_over.get_parent().queue_free()
		_game_over = null
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
			g.reset_physics_interpolation()
			g.known_down = _checkpoint.dead[g][1]
		elif g in _checkpoint.downed:
			g.return_to_post()
			g.stay_down(_checkpoint.downed[g][0], _checkpoint.downed[g][1], _checkpoint.downed[g][2])
		else:
			g.return_to_post()
	for c in get_tree().get_nodes_in_group("cameras"):
		if c not in _checkpoint.destroyed:
			c.repair()
	_fresh_chain()  # after return_to_post(), whose wake would trigger Caution


## A deep copy of a node-free state object (a Gun, Voiceprints, the tally, Glaukopis).
static func copy(o: Object) -> Object:
	var c: Object = o.get_script().new()
	for p in o.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var v: Variant = o.get(p.name)
			c.set(p.name, v.duplicate(true) if v is Array or v is Dictionary else v)
	return c


## The Operative died: the Game Over screen, over a paused tree (time still counts for Rank).
func game_over() -> void:
	if ended or _game_over:
		return
	SessionLog.current.note("died at %s" % _where(get_tree().get_first_node_in_group("operative").global_position))
	_game_over = GAME_OVER.new()
	_game_over.continues = rank.continues
	_game_over.continued.connect(restore_checkpoint)
	_game_over.quit.connect(func() -> void:
		abort()
		get_tree().paused = false
		get_tree().change_scene_to_file(MENU))
	_overlay(_game_over)
	get_tree().paused = true


## A Mission card over the Area with the tree held; `then` runs when it ends (or the player skips it).
func _card(keys: Array, intro: bool, then: Callable) -> void:
	var card := MissionCard.build(keys, intro)
	card.done.connect(then)
	_overlay(card)
	get_tree().paused = true


func _overlay(screen: Control) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	layer.add_child(screen)
	add_child(layer)


## Guards (not Targets) Fultoned this run, as of the last Checkpoint restore: the Recruits a commit banks.
func fultoned() -> int:
	return int(tally.counts.get("fulton", 0))


## Requisition points for a carry_only Target (Campaign) brought out alive: none was killed.
func alive_target_bonus() -> int:
	var carry_only: bool = Campaign.MISSIONS[record.mission].get("carry_only", false)
	return Requisition.ALIVE_TARGET_BONUS if carry_only and int(tally.counts.get("target_kill", 0)) == 0 else 0


func event(name_: String) -> void:
	if not ended:
		SessionLog.current.count(name_)  # the log is a playtest record: a Checkpoint restore doesn't roll it back
		if name_ not in ["dart", "rifle", "spoof", "spoof_exposed", "woken"]:  # counted; their own lines say who (radio.gd, guard.gd)
			SessionLog.current.note(name_.replace("_", " "))
		tally.add(name_)
		if TEACH_EVENTS.has(name_):
			_metis_line(tutorial.done(TEACH_EVENTS[name_], record.mission, campaign))
		if name_ == "kill" or name_ == "target_kill":
			rank.kills += 1


func _physics_process(delta: float) -> void:
	if ended:
		return
	if not get_tree().paused or _game_over:
		rank.seconds += delta
	if not get_tree().paused:
		_run_chain(delta)
	for g in get_tree().get_nodes_in_group("guards"):
		var d: bool = g.is_down()
		if d and not _down.get(g, false):
			tally.guard_down()
			SessionLog.current.note("%s down (%s) at %s" % [g.name, "dead" if g.dead else "neutralized", _where(g.global_position)])
			if g.target:
				if g.dead:
					_say_objective()
				for e in get_tree().get_nodes_in_group("extraction"):  # the Operative may already stand in it
					if e.standing():
						_on_extraction()
		elif not d and _down.get(g, false):
			SessionLog.current.note("%s up again at %s" % [g.name, _where(g.global_position)])
		_down[g] = d
		if g.known_down and not _known.get(g, false):
			tally.add("down_found")
			rank.found += 1
		_known[g] = g.known_down
	tally.alert_active = AlertChain.area.phase == AlertChain.Phase.ALERT
	if not get_tree().paused:
		var alerting: bool = AlertChain.area.phase in [AlertChain.Phase.ALERT, AlertChain.Phase.EVASION]
		SessionLog.current.tick(delta, alerting)
		_guide(delta, alerting)
	_teach()


## Ticks the AlertChain and passes its events to the guards. Only a completed call counts as an Alert
## for Rank (the tally's "alert"); its Reinforcements are the Area's to send (chain.alerts).
func _run_chain(delta: float) -> void:
	var chain := AlertChain.area
	var guards := get_tree().get_nodes_in_group("guards").filter(func(g: Guard) -> bool: return not g.is_down())
	var spotter: Guard = null
	for g: Guard in guards:
		if g.seen_rate > 0.0:
			spotter = g
	var cam_sees := get_tree().get_nodes_in_group("cameras").any(func(c: SecurityCamera) -> bool: return c.seeing)
	if spotter or cam_sees:
		var op: Node3D = get_tree().get_first_node_in_group("operative")
		var by := str(spotter.name) if spotter else "a camera"
		SessionLog.current.spotted(by, _where(op.global_position) if op else "?")
	var ev := chain.tick(delta, spotter != null or cam_sees)
	match ev:
		&"alert", &"realert":
			if ev == &"alert":
				tally.add("alert")
				rank.alerts += 1
				SessionLog.current.alert(_enc_now)
				SessionLog.current.note("alert called by %s" % (str(chain.caller.name) if chain.caller is Node else "a camera or HQ"))
			var pos := chain.call_pos if ev == &"alert" or not spotter else spotter.alert.last_known
			var who := str(chain.caller.name) if ev == &"alert" and chain.caller is Node else "HQ"
			for g: Guard in guards:
				g.on_radio(pos, who)
		&"evasion":
			for g: Guard in guards:
				g.on_phase(AlertChain.Phase.EVASION)
		&"caution":
			for g: Guard in guards:
				g.on_phase(AlertChain.Phase.CAUTION)
	var hunting := guards.any(func(g: Guard) -> bool: return g.alert.state >= GuardAlert.State.ALERT)
	if chain.phase in [AlertChain.Phase.ALERT, AlertChain.Phase.EVASION] and not hunting:
		chain.stand_down()


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


## Mission 1's tutorial: a prompt on the HUD and one Metis radio line the first time a verb matters in the
## Encounter that teaches it; a verb the player does unprompted is spent (or, LINE_ONLY, gets just the line).
func _teach() -> void:
	var op: Node3D = get_tree().get_first_node_in_group("operative")
	if not op:
		return
	var enc := encounter_at(op.global_position)
	if enc != _enc_now:
		SessionLog.current.enter_encounter(enc, _exit_near(op.global_position) if _enc_now > 0 else "")
		_enc_now = enc
	var world := {guard = INF, down = INF, spot = INF, holdup = INF, fulton = op.fulton_ready(), enc = enc}
	var points: int = SessionLog.current.missions.back().trail.size()
	SessionLog.current.place(_diagram(op.global_position), enc)
	if _logs() and SessionLog.current.missions.back().trail.size() > points:
		SessionLog.current.write_live(LIVE_PATH)
	var carried: Node = op.carrying
	if carried != _carried:
		SessionLog.current.note("picked up %s" % carried.name if carried else "put down %s" % _carried_name)
		_carried = carried
		_carried_name = str(carried.name) if carried else ""
	var holding := false
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		var key := "down" if g.is_down() else "guard" if g.alert.state in [GuardAlert.State.PATROL, GuardAlert.State.SUSPICION] else ""
		if key != "":
			world[key] = minf(world[key], _flat(op, g))
		if key == "guard" and g.holdup_answer != "":
			world.holdup = minf(world.holdup, _flat(op, g))
		if g.held_up and not _holding:
			SessionLog.current.note("held up %s" % g.name)
		holding = holding or g.held_up
	for s: Node3D in get_tree().get_nodes_in_group("eavesdrop_spot"):
		world.spot = minf(world.spot, _flat(op, s))
	var doing := {crouch = op.crouching, carry = op.carrying != null, eavesdrop = not op.voiceprints.held.is_empty(),
		holdup = holding, scanner = op.items.charges < _items.get("charges", op.items.charges),
		magazine = op.items.magazines < _items.get("magazines", op.items.magazines),
		caution = AlertChain.area.phase == AlertChain.Phase.CAUTION}
	_items = {charges = op.items.charges, magazines = op.items.magazines}
	if holding and not _holding:
		SessionLog.current.count("holdup")
	_holding = holding
	var verb := tutorial.update(record.mission, campaign, Tutorial.relevant(world))
	if verb != "":
		get_tree().call_group("tutorial_tip", "tip", tr(Tutorial.prompt_key(verb)))
		_metis_line(verb)
		SessionLog.current.tip(verb)
	for v: String in doing:
		if doing[v]:
			_metis_line(tutorial.done(v, record.mission, campaign))


func _metis_line(verb: String) -> void:
	if verb != "":
		get_tree().call_group("radio_log", "say", "METIS", tr(Tutorial.line_key(verb)))


## The encounter_exit marker within EXIT_NEAR of pos (its name: Gangway, SternDrop), or "".
func _exit_near(pos: Vector3) -> String:
	for m: Node3D in get_tree().get_nodes_in_group("encounter_exit"):
		if m.global_position.distance_to(pos) <= EXIT_NEAR:
			return m.name
	return ""


## The Encounter (its id) whose $Encounters marker rect holds pos, or 0. Areas without them have none.
func encounter_at(pos: Vector3) -> int:
	for m: Marker3D in get_tree().get_nodes_in_group("encounter"):
		var size: Vector2 = m.get_meta("size")
		var d := pos - m.global_position
		if d.x >= 0.0 and d.z >= 0.0 and d.x <= size.x and d.z <= size.y:
			return m.get_meta("id")
	return 0


## A world position as the Area builders write it: [x, y, h] in diagram metres.
static func _diagram(p: Vector3) -> Vector3:
	return Vector3(p.x + DIAGRAM_ORIGIN, p.z + DIAGRAM_ORIGIN, p.y)


static func _where(p: Vector3) -> String:
	var d := _diagram(p)
	return "(%d, %d, %d)" % [d.x, d.y, d.z]


static func _flat(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()


## What to do now, for the pause screen: the steps, then the Targets, then Extraction.
func objective() -> String:
	if step >= _steps().size() and not _targets_left().is_empty():
		return tr("objective.targets") + ": " + ", ".join(_targets_left().map(func(t: Guard) -> String: return t.name))
	return Campaign.objective(record.mission, step)


## The objective and where its intel lies from `from` ("<objective> · 42 m north-east", Holdup.bearing), or ""
## past the steps: what a held-up guard gives up when the Operative already holds his Voiceprint.
func intel_hint(from: Vector3) -> String:
	var intel := _step_intel() if step < _steps().size() else null
	return objective() + " · " + Holdup.bearing(intel.global_position - from) if intel else ""


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
## unless it lies in the Extraction point or a target_zone: the Core room is one, so a choke there needs no carry).
func _targets_left() -> Array:
	return get_tree().get_nodes_in_group("targets").filter(func(t: Guard) -> bool:
		return not (t.dead or t.carrier or (t.is_down() and _at_extraction(t))))


func _at_extraction(t: Guard) -> bool:
	return (get_tree().get_nodes_in_group("extraction") + get_tree().get_nodes_in_group("target_zone")).any(func(e: Node) -> bool: return e.contains(t.global_position))


func _say_objective() -> void:
	get_tree().call_group("radio_log", "say", "INTEL", objective())  # ponytail: placeholder until the live Codec calls


## The current step's intel pickup in the Area, or null.
func _step_intel() -> Node3D:
	for i: Node3D in get_tree().get_nodes_in_group("intel"):
		if i.name == _steps()[step].intel:
			return i
	return null


func _steps() -> Array:
	return Campaign.MISSIONS[mission].steps


## Only the current step's intel is shown, and the Extraction beacon only once every step is done.
func _show_intel() -> void:
	for i: Node3D in get_tree().get_nodes_in_group("intel"):
		i.visible = step < _steps().size() and i.name == _steps()[step].intel
		i.set_deferred("monitoring", i.visible)  # a hidden pickup is inert: it can't open the Core's lift early
	for e in get_tree().get_nodes_in_group("extraction"):
		var beacon: Node3D = e.get_node_or_null("Beacon")
		if beacon:
			beacon.visible = step >= _steps().size() and not ended  # the Core's scene outlives the Mission


## The current step's intel reached: the step is done, and that's a Checkpoint.
func _on_intel(intel: Node) -> void:
	if ended or step >= _steps().size() or intel.name != _steps()[step].intel:
		return
	get_tree().call_group("codec_live", "live_call", _steps()[step].call)
	SessionLog.current.note("step %d done (%s)" % [step + 1, intel.name])
	step += 1
	hints.new_step()
	_show_intel()
	_say_objective()
	take_checkpoint()


func _on_extraction() -> void:
	if ended or step < _steps().size() or not _targets_left().is_empty():
		return
	SessionLog.current.note("extracted")
	_finish()
	_show_intel()
	var after := Aigis.complete_mission(record, tally.counts)
	var par := Rank.par(record.mission)
	var screen := SCREEN.new()
	screen.rank = rank
	screen.par = par
	screen.mission_name = tr("ui.mission.%d" % record.mission)
	screen.rank_only = not campaign  # replays and Free mode: the Rank page only
	screen.strip = MissionTally.strip(record, after)
	screen.voice_key = VoiceLines.post_key(Aigis.resolve_ending(Aigis.lethality_ratio(after)), VoiceLines.lethality_zero(tally.counts))
	var show := func() -> void:
		_overlay(screen)
		get_tree().paused = true
	var outro: Dictionary = Campaign.MISSIONS[record.mission].get("outro", {})
	if outro.is_empty():
		show.call()
	else:  # fade out on the extraction beat, then the post-Mission screen
		_card([outro.title, outro.line], false, show)
		get_tree().paused = true
	screen.committed.connect(func() -> void:
		if campaign or replay:
			first_s = Campaign.commit_record(record.mission, record, rank.stats(par))
			Campaign.gear.settle(record.mission, fultoned(), first_s, campaign, alive_target_bonus())
		if replay:
			save_slot()  # the Mission Record only: Campaign.record is untouched
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
	if campaign or replay:
		Campaign.save()


## Quit or abort: nothing is applied.
func abort() -> void:
	if not ended:
		SessionLog.current.note("left the Mission at step %d" % step)
	_finish()
	tally = MissionTally.new()


## The Mission is over: no more play, and the session log is on disk.
func _finish() -> void:
	ended = true
	SessionLog.current.finish_mission()
	if _logs():
		SessionLog.current.write(LOG_PATH)
		DirAccess.remove_absolute(LIVE_PATH)


## Only a played window keeps the log: the suite and the headless playthroughs build MissionRuns too.
static func _logs() -> bool:
	return DisplayServer.get_name() != "headless"


## Quitting (or leaving the scene) mid-Mission still writes the log.
func _exit_tree() -> void:
	if not ended:
		SessionLog.current.note("quit at step %d" % step)
		_finish()
