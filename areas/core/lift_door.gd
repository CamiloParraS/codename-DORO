## The freight lift's door: shut until the Operative reaches IntelLift (the lift's step). It sits outside the
## NavRegion, so the navmesh is baked open and only bodies are held back.
extends StaticBody3D


func _ready() -> void:
	for i in get_tree().get_nodes_in_group("intel"):
		if i.name == "IntelLift":
			i.reached.connect(func() -> void:
				var host := get_parent() as Node3D  # the door is freed, so the sound rides on the Area
				if host:
					Mix.sfx_at(host, &"lift_door", global_position)
				queue_free())
