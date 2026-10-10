## Greybox test room for movement and camera. Open test_room.tscn and press F6.
extends Node3D


func _ready() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	add_child(sun)
	_box(Vector3(0, -0.5, 0), Vector3(30, 1, 30))  # floor
	for p in [[0, -15, 30, 1], [0, 15, 30, 1], [-15, 0, 1, 30], [15, 0, 1, 30]]:  # walls
		_box(Vector3(p[0], 1.5, p[1]), Vector3(p[2], 3, p[3]))
	_box(Vector3(-3, 0.5, -4), Vector3(4, 1, 1))  # low cover
	_box(Vector3(5, 1.5, -2), Vector3(1, 3, 6))  # pillar wall to crowd the camera
	_box(Vector3(8, 1.5, 5), Vector3(5, 3, 1))
	var op: CharacterBody3D = load("res://actors/operative/operative.tscn").instantiate()
	op.position = Vector3(0, 0.1, 8)
	add_child(op)


func _box(pos: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	b.position = pos
	var cs := CollisionShape3D.new()
	cs.shape = BoxShape3D.new()
	(cs.shape as BoxShape3D).size = size
	b.add_child(cs)
	var m := MeshInstance3D.new()
	m.mesh = BoxMesh.new()
	(m.mesh as BoxMesh).size = size
	b.add_child(m)
	add_child(b)
