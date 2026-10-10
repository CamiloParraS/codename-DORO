## A security camera (Stealth L1): sweeps from its mount, fills the guards' meter with its front cone
## only, and radios an alert when the meter fills, with no suspicion step (GuardAlert.camera_tick).
## The tranq does nothing to it: a dart just stops on its body. Spawned by the Area on a camera mount,
## facing the way the mount faces.
class_name SecurityCamera
extends StaticBody3D

const SWEEP := deg_to_rad(35.0)   # either side of the mount's facing; narrow enough that a spot
const SWEEP_TIME := 10.0          # in the middle stays in the 30° cone ~2/3 of the time and fills
const PITCH := deg_to_rad(-25.0)  # looks down into the yard
const ARM := 0.5                  # the head sits this far out from the mount, clear of the wall
const LAMP := [Color(0.3, 1, 0.3), Color(1, 0.2, 0.2)]  # watching / alert

var operative: Node3D
var alert := GuardAlert.new()
var last_reason := ""            # for the debug overlay
var _t := 0.0
var _yaw := 0.0
var _head := Node3D.new()
var _lamp := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("cameras")
	collision_layer = 1
	collision_mask = 0
	_yaw = rotation.y
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.3, 0.3, 0.6)
	shape.position.z = -ARM
	add_child(shape)
	_head.rotation.x = PITCH
	_head.position.z = -ARM
	add_child(_head)
	var body := BoxMesh.new()
	body.size = Vector3(0.25, 0.25, 0.6)
	_mesh(body, Vector3.ZERO, Color(0.75, 0.75, 0.72))
	var lamp := SphereMesh.new()
	lamp.radius = 0.06
	lamp.height = 0.12
	_lamp.emission_enabled = true
	_mesh(lamp, Vector3(0, 0.1, -0.3), Color.BLACK, _lamp)


func _mesh(mesh: Mesh, at: Vector3, col: Color, mat := StandardMaterial3D.new()) -> void:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = at
	mat.albedo_color = col
	m.material_override = mat
	_head.add_child(m)


func _physics_process(delta: float) -> void:
	_t += delta
	rotation.y = _yaw + SWEEP * sin(_t * TAU / SWEEP_TIME)
	if not operative:
		return
	var rate := _sense()
	var why := alert.camera_tick(delta, rate[0], operative.global_position, rate[1])
	if why != "":
		last_reason = why
	if alert.state == GuardAlert.State.ALERT and (why != "" or rate[0] > 0.0):
		for g in get_tree().get_nodes_in_group("guards"):  # guards already alerted ignore it
			g.on_radio(alert.last_known, name)
	var c: Color = LAMP[0].lerp(LAMP[1], alert.meter)
	_lamp.albedo_color = c
	_lamp.emission = c


## [fill rate, what it saw]: the guards' vision, front cone only, with a clear line to the chest.
func _sense() -> Array:
	var eye := _head.global_position
	var chest: Vector3 = operative.global_position + Vector3.UP * operative.chest_height()
	var offset := chest - eye
	var facing := -global_basis.z
	if not GuardVision.in_front(offset, facing):
		return [0.0, ""]
	var q := PhysicsRayQueryParameters3D.create(eye, chest, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or hit["collider"] != operative:
		return [0.0, ""]
	var crouched: bool = operative.looks_crouched()
	var walking: bool = operative.looks_walking()
	return [
		GuardVision.fill_rate(offset, facing, crouched, operative.moving, walking),
		GuardVision.describe(offset, facing, crouched, operative.moving, walking),
	]
