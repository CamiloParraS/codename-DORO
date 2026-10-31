## Where a Mission ends once its objectives are done. Its collision mask must include the Operative's layer.
extends Area3D

signal reached

const BEACON := [1.0, 30.0, 24.0]  # radius, height, fade_m
const BEACON_RING := 2.0


func _enter_tree() -> void:
	add_to_group("extraction")  # before MissionRun's _ready looks for it


func _ready() -> void:
	if is_in_group("extraction"):  # not an intel pickup, which has its own mesh
		add_child(_beacon())
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("operative"):
			reached.emit())


## Is the world point p over this point's floor (height ignored)?
func contains(p: Vector3) -> bool:
	var l := to_local(p).abs()
	var half := (get_node("Shape").shape as BoxShape3D).size / 2
	return l.x <= half.x and l.z <= half.z


## Is the Operative inside it right now (it only emits on entering).
func standing() -> bool:
	return get_overlapping_bodies().any(func(b: Node3D) -> bool: return b.is_in_group("operative"))


## A tall column over a wide ring, standing on the point's floor, so the Operative can find it from across the
## Area (ObjectiveMarker).
func _beacon() -> Node3D:
	var b := Node3D.new()
	b.name = "Beacon"
	var box := get_node("Shape").shape as BoxShape3D
	b.position.y = -(box.size.y / 2 if box else 0.0)  # the floor
	b.add_child(ObjectiveMarker.beam(BEACON[0], BEACON[1], BEACON[2]))
	var ring := ObjectiveMarker.ring(BEACON_RING)
	ring.position.y = 0.02
	b.add_child(ring)
	return b
