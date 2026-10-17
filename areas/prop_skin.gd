## Swaps a greybox box prop's mesh for a model, scaled to fill the box's collision shape. Turned a quarter
## if the model's long side runs the other way from the box's.
## Put on a StaticBody3D with a "Shape" (BoxShape3D) and "Mesh" child.
class_name PropSkin
extends StaticBody3D

@export var model: PackedScene


func _ready() -> void:
	if not owner:  # the area builders add it unowned: they save the box, not the model
		return
	var size: Vector3 = ($Shape as CollisionShape3D).shape.size
	var m: Node3D = model.instantiate()
	add_child(m)
	var to_m := m.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for v: VisualInstance3D in m.find_children("*", "VisualInstance3D", true, false):
		var b: AABB = to_m * v.global_transform * v.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var turn := (box.size.x > box.size.z) != (size.x > size.z)
	var fit := Vector3(size.z, size.y, size.x) if turn else size  # the box's size in the model's own axes
	m.basis = Basis(Vector3.UP, PI / 2 if turn else 0.0) * Basis.from_scale(fit / box.size)
	m.position = -(m.basis * box.get_center())  # model centred on the box
	$Mesh.queue_free()
