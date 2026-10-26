## Swaps a greybox box prop's mesh for a model, scaled to fill the box's collision shape. Turned a quarter
## if the model's long side runs the other way from the box's.
## Put on a StaticBody3D with a "Shape" (BoxShape3D) and "Mesh" child.
class_name PropSkin
extends StaticBody3D

@export var model: PackedScene
## Not white: the model's palette goes grey and is dyed this weathered tone (the containers' own colours are loud).
@export var tint := Color.WHITE

static var _grey := {}  # source texture -> its desaturated copy


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
	if tint != Color.WHITE:
		for v: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
			for i in v.mesh.get_surface_count():
				var mat := v.mesh.surface_get_material(i) as StandardMaterial3D
				if mat and mat.albedo_texture:
					mat = mat.duplicate()
					mat.albedo_texture = _greyed(mat.albedo_texture)
					mat.albedo_color = tint
					v.set_surface_override_material(i, mat)
	$Mesh.queue_free()


## The palette in luminance (lifted so a dark red still reads as a mid tone), so the tint alone sets the hue.
static func _greyed(tex: Texture2D) -> Texture2D:
	if not _grey.has(tex):
		var img := tex.get_image()
		img.decompress()
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				var l := minf(c.get_luminance() * 2.2, 1.0)
				img.set_pixel(x, y, Color(l, l, l, c.a))
		_grey[tex] = ImageTexture.create_from_image(img)
	return _grey[tex]
