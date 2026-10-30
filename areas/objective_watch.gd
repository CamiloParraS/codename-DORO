## A Mission step done with a verb instead of walking into a pickup. Like intel_pickup.gd it is in group
## "intel" and emits `reached`; MissionRun only listens while it is the current step (monitoring on).
## verb "voiceprint": the Operative has recorded any of `guards`' voices (eavesdropping a chat).
## verb "answer": any of `guards` answered a Hold-up, was Fultoned (HQ gets it out of him), or lies Down
## (knocked out or dead) with the Operative standing over him (Guard.frisk: it's on the body), so no
## takedown can lock the Mission.
extends Area3D

signal reached

const SEARCH_REACH := 1.5

@export var verb := "voiceprint"
@export var guards := PackedStringArray()


func _enter_tree() -> void:
	add_to_group("intel")


func _physics_process(_delta: float) -> void:
	if monitoring and done():
		reached.emit()


func done() -> bool:
	var op: Node3D = get_tree().get_first_node_in_group("operative")
	if not op:
		return false
	if verb == "voiceprint":
		return Array(guards).any(func(n: String) -> bool: return n in op.voiceprints.held)
	var found := false
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		if g.name in guards:
			found = true
			if g.answered:
				return true
			if g.is_down() and op.global_position.distance_to(g.global_position) <= SEARCH_REACH:
				g.frisk(op)
				return true
	return not found  # Fultoned out of the Area
