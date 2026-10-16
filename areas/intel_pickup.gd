## Intel: walking into it completes the objective step that names it. MissionRun shows only the
## current step's pickup and ignores the rest.
extends "res://areas/extraction_point.gd"


func _enter_tree() -> void:
	add_to_group("intel")
