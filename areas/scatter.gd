## Many copies of one mesh (a forest, a rock field, pilings), filled into its MultiMesh at load. The area
## builders run headless, where a MultiMesh keeps no instance data to save, so they save the transforms here.
@tool
extends MultiMeshInstance3D

## 12 floats per copy: the basis' x, y and z columns, then the origin.
@export var transforms := PackedFloat32Array()


func _ready() -> void:
	var t := transforms
	@warning_ignore("integer_division")
	multimesh.instance_count = t.size() / 12
	for i in multimesh.instance_count:
		var k := i * 12
		multimesh.set_instance_transform(i, Transform3D(Vector3(t[k], t[k + 1], t[k + 2]), Vector3(t[k + 3], t[k + 4], t[k + 5]),
			Vector3(t[k + 6], t[k + 7], t[k + 8]), Vector3(t[k + 9], t[k + 10], t[k + 11])))
