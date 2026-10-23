## A room with a roof (build_harbour.gd ROOMS): no Fulton balloon goes up from inside it.
extends Area3D


func _enter_tree() -> void:
	add_to_group("no_fulton")


## Is the world point p inside this room?
func contains(p: Vector3) -> bool:
	var l := to_local(p).abs()
	var half := (get_node("Shape").shape as BoxShape3D).size / 2
	return l.x <= half.x and l.y <= half.y and l.z <= half.z


## Can a balloon go up from p: not inside any room.
static func open_sky(tree: SceneTree, p: Vector3) -> bool:
	return not tree.get_nodes_in_group("no_fulton").any(func(r: Node) -> bool: return r.contains(p))
