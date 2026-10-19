## The freight lift's door: shut until the Operative reaches IntelLift (the lift's step). It sits outside the
## NavRegion, so the navmesh is baked open and only bodies are held back.
extends StaticBody3D


func _ready() -> void:
	for i in get_tree().get_nodes_in_group("intel"):
		if i.name == "IntelLift":
			i.reached.connect(queue_free)
