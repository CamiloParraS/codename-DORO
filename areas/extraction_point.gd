## Where a Mission ends once its objectives are done. Its collision mask must include the Operative's layer.
extends Area3D

signal reached


func _enter_tree() -> void:
	add_to_group("extraction")  # before MissionRun's _ready looks for it


func _ready() -> void:
	if is_in_group("extraction"):  # not an intel pickup, which has its own mesh
		add_child(_beacon())
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("operative"):
			reached.emit())


## A tall faint column standing on the point, so the Operative can find it from across the Area.
func _beacon() -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.3, 1.0, 0.5, 0.2)
	var c := CylinderMesh.new()
	c.top_radius = 1.0
	c.bottom_radius = 1.0
	c.height = 30.0
	c.material = mat
	var m := MeshInstance3D.new()
	m.name = "Beacon"
	m.mesh = c
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var box := get_node("Shape").shape as BoxShape3D
	m.position.y = c.height / 2 - (box.size.y / 2 if box else 0.0)  # from the floor up
	return m
