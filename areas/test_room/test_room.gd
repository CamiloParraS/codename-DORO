## Greybox test room for movement and camera. Open test_room.tscn and press F6.
extends Node3D


func _ready() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	_box(Vector3(0, -0.5, 0), Vector3(30, 1, 30), "dirt_03")  # floor
	for p in [[0, -15, 30, 1], [0, 15, 30, 1], [-15, 0, 1, 30], [15, 0, 1, 30]]:  # walls
		_box(Vector3(p[0], 1.5, p[1]), Vector3(p[2], 3, p[3]), "brick_07")
	_box(Vector3(-3, 0.5, -4), Vector3(4, 1, 1), "wood_07")  # low cover
	_box(Vector3(5, 1.5, -2), Vector3(1, 3, 6), "stone_07")  # pillar wall to crowd the camera
	_box(Vector3(8, 1.5, 5), Vector3(5, 3, 1), "metal_05")
	var op: CharacterBody3D = load("res://actors/operative/operative.tscn").instantiate()
	op.position = Vector3(0, 0.1, 8)
	add_child(op)
	_take()


func _box(pos: Vector3, size: Vector3, texture: String) -> void:
	var b := StaticBody3D.new()
	b.position = pos
	var cs := CollisionShape3D.new()
	cs.shape = BoxShape3D.new()
	(cs.shape as BoxShape3D).size = size
	b.add_child(cs)
	var m := MeshInstance3D.new()
	m.mesh = BoxMesh.new()
	(m.mesh as BoxMesh).size = size
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/psx_surface.gdshader")
	mat.set_shader_parameter("albedo_tex", load("res://assets/textures/%s_128.png" % texture))
	m.material_override = mat
	b.add_child(m)
	add_child(b)


## A 3 s rail that arcs round the Operative and settles behind its shoulder: the Cine framework's fixture (tests/test_cine.gd).
func _take() -> void:
	var points: Array[Vector3] = [Vector3(7, 3.5, 12), Vector3(3, 2.6, 13), Vector3(0.6, 2.0, 11.2)]
	var looks: Array[Vector3] = [Vector3(0, 1.5, 6), Vector3(0, 1.5, 7), Vector3(0, 1.5, 6)]
	var times: Array[float] = [0.0, 1.5, 3.0]
	AreaCine.rail(AreaCine.root(self), "CineTest", points, looks, times, {min_s = 2.0, max_s = 6.0})
