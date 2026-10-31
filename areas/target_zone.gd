## Where a Neutralized Target left lying counts as dealt with, as it does in the Extraction point
## (MissionRun._targets_left): the Core room, whose Extraction point is only its terminal.
extends Area3D


func _enter_tree() -> void:
	add_to_group("target_zone")


## Is the world point p over this zone's floor (height ignored)?
func contains(p: Vector3) -> bool:
	var l := to_local(p).abs()
	var half := (get_node("Shape").shape as BoxShape3D).size / 2
	return l.x <= half.x and l.z <= half.z
