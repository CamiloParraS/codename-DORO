## A Mission in progress: feeds the tally from the guards, ends at the Extraction point once the
## objectives are done, then shows the post-Mission screen. Completing folds the tally into the
## record (Aigis.complete_mission); aborting discards it.
## Hooks elsewhere report events with get_tree().call_group("mission_tally", "event", name).
class_name MissionRun
extends Node

signal finished(new_record: Dictionary)

const SCREEN := preload("res://ui/post_mission/post_mission.gd")

var tally := MissionTally.new()
var record := Aigis.new_record()   # ponytail: the campaign loop (flow ticket) owns and saves this
var objectives_done := true        # ponytail: no objectives exist yet; the Mission data sets this
var ended := false
var _down := {}
var _known := {}


func _ready() -> void:
	add_to_group("mission_tally")
	process_mode = Node.PROCESS_MODE_ALWAYS
	for e in get_tree().get_nodes_in_group("extraction"):
		e.reached.connect(_on_extraction)


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
		_down[g] = d
		if g.known_down and not _known.get(g, false):
			tally.add("down_found")
		_known[g] = g.known_down
	tally.set_alert(alert)


func _on_extraction() -> void:
	if ended or not objectives_done:
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
		get_tree().paused = false
		finished.emit(after))


## Quit or abort: nothing is applied.
func abort() -> void:
	ended = true
	tally = MissionTally.new()
