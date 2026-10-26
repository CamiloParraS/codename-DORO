## The Core terminal: once the Mission is done, E beside it hands off to the finale (a node in group
## "finale" with begin()). Until the finale exists it leaves to `leave_to`, the scene the Mission came from.
extends Area3D

var leave_to := ""
var _operative: Node3D


func _ready() -> void:
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("operative"):
			_operative = b)
	body_exited.connect(func(b: Node3D) -> void:
		if b == _operative:
			_operative = null)


func _physics_process(_delta: float) -> void:
	if _operative and _done():
		_operative.prompt = Prompts.verb("interact", "ui.prompt.access_core")
		if Input.is_action_just_pressed("interact"):
			use()


func _done() -> bool:
	var run := get_tree().get_first_node_in_group("mission_plan")
	return run != null and run.ended


func use() -> void:
	if not _done():
		return
	var run := get_tree().get_first_node_in_group("mission_plan")
	if run.has_method("save_slot"):
		run.save_slot()  # marks the slot complete
	var finale := get_tree().get_first_node_in_group("finale")
	if finale:
		finale.begin()  # ponytail: ticket 32 puts the finale in this group
	elif leave_to != "":
		get_tree().change_scene_to_file(leave_to)
