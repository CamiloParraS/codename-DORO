## The Operative: camera-relative movement (run / walk / crouch) and a shoulder camera made of
## two spring arms (a sideways shoulder arm, then the back arm). Lifted from the stealth-core prototype.
extends CharacterBody3D

const KNOCK_COOLDOWN := 1.0
const TAKEDOWN_REACH := 1.5   # metres to a guard to choke it or pick it up
const CHOKE_TIME := 2.0

const HIDE_BODY_BELOW := 0.8  # hide the body when the camera is pushed closer than this

## ponytail: hardcoded until the settings menu exists.
var sensitivity := 0.0025
var invert_y := false
var crouching := false
var walking := false
var moving := false
var carrying: Node3D     # the Down guard on the shoulder
var prompt := ""         # shown by the HUD
var shoulder := 1.0  # +1 right shoulder, -1 left
var camera: Camera3D

var _knock_left := 0.0
var _choke_left := 0.0
var _choking: Node3D
var _yaw := 0.0
var _pitch := -0.25
var _pivot: Node3D
var _pitch_node: Node3D
var _shoulder_arm: SpringArm3D
var _back_arm: SpringArm3D
var _shape: CollisionShape3D
var _visual: MeshInstance3D


func _ready() -> void:
	add_to_group("operative")
	collision_mask = 1 | 2  # world and guards (guards sit on layer 2 so they don't block sight or the camera)
	_shape = CollisionShape3D.new()
	_shape.shape = CapsuleShape3D.new()
	add_child(_shape)

	_visual = MeshInstance3D.new()
	_visual.mesh = CapsuleMesh.new()
	(_visual.mesh as CapsuleMesh).radius = 0.35
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.25, 0.35)
	_visual.material_override = mat
	add_child(_visual)
	_apply_crouch()

	_pivot = Node3D.new()
	_pivot.top_level = true
	add_child(_pivot)
	_pitch_node = Node3D.new()
	_pivot.add_child(_pitch_node)
	_shoulder_arm = _make_arm(0.55)
	_pitch_node.add_child(_shoulder_arm)
	_back_arm = _make_arm(3.2)
	_shoulder_arm.add_child(_back_arm)
	camera = Camera3D.new()
	camera.fov = 70
	camera.current = true
	_back_arm.add_child(camera)
	_apply_shoulder()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Where guards aim their line-of-sight ray.
func chest_height() -> float:
	return 0.6 if looks_crouched() else 1.3


## Carrying, the Operative reads to guards as standing and walking.
func looks_crouched() -> bool:
	return crouching and not carrying


func looks_walking() -> bool:
	return walking or carrying != null


func carry_yaw() -> float:
	return _visual.rotation.y


func _make_arm(length: float) -> SpringArm3D:
	var arm := SpringArm3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.2
	arm.shape = s
	arm.spring_length = length
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())
	return arm


func _apply_shoulder() -> void:
	# A spring arm extends along its local +Z: turn the first one sideways, the second one back.
	_shoulder_arm.rotation.y = PI / 2 * shoulder
	_back_arm.rotation.y = -PI / 2 * shoulder


func _apply_crouch() -> void:
	var cap := _shape.shape as CapsuleShape3D
	cap.radius = 0.35
	cap.height = 1.0 if crouching else 1.7
	_shape.position.y = cap.height / 2
	(_visual.mesh as CapsuleMesh).height = cap.height
	_visual.position.y = cap.height / 2


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var l := Locomotion.look(_yaw, _pitch, e.relative, sensitivity, invert_y)
		_yaw = l.x
		_pitch = l.y
	elif e.is_action_pressed("crouch"):
		crouching = not crouching
		_apply_crouch()
	elif e.is_action_pressed("shoulder_swap"):
		shoulder = -shoulder
		_apply_shoulder()
	elif e.is_action_pressed("knock") and _knock_left <= 0.0:
		_knock_left = KNOCK_COOLDOWN
		GuardAlert.broadcast(get_tree(), global_position, GuardAlert.KNOCK_RANGE, "a knock")
	elif e.is_action_pressed("interact") and _choke_left <= 0.0:
		_interact()
	elif e.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	walking = Input.is_action_pressed("walk")
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _choking:
		v = Vector2.ZERO  # a choke needs both hands
		_choke_left -= delta
		if not _choking.can_be_choked(global_position):  # it turned round or raised the alert
			_choking.held = false
			_choking = null
			_choke_left = 0.0
		elif _choke_left <= 0.0:
			_choking.neutralize()
			_choking = null
	_update_prompt()
	moving = v != Vector2.ZERO
	_knock_left -= delta
	if moving and not looks_walking() and not crouching:  # running is loud
		GuardAlert.broadcast(get_tree(), global_position, GuardAlert.FOOTSTEP_RANGE, "footsteps")
	var dir := Basis(Vector3.UP, _yaw) * Vector3(v.x, 0, v.y)
	if moving:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-dir.x, -dir.z), 12 * delta)
	var speed := Locomotion.speed(crouching, looks_walking())
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20 * delta
	move_and_slide()


func _interact() -> void:
	if carrying:  # drop it where we stand
		carrying.carrier = null
		carrying.global_position = global_position
		carrying = null
		return
	var g := _nearest(true)
	if g:
		carrying = g
		g.carrier = self
		return
	g = _nearest(false)
	if g:
		_choking = g
		_choke_left = CHOKE_TIME
		g.held = true


func _update_prompt() -> void:
	if carrying:
		prompt = "E drop"
	elif _choking:
		prompt = "choking..."
	elif _nearest(true):
		prompt = "E carry"
	elif _nearest(false):
		prompt = "E choke"
	else:
		prompt = ""


## Nearest guard within reach: a Down one to carry, or one that can be choked.
func _nearest(down: bool) -> Node3D:
	var best: Node3D
	var best_d := TAKEDOWN_REACH
	for g in get_tree().get_nodes_in_group("guards"):
		var d := Vector2(g.global_position.x - global_position.x, g.global_position.z - global_position.z).length()
		if d <= best_d and (g.is_down() if down else g.can_be_choked(global_position)):
			best = g
			best_d = d
	return best


func _process(delta: float) -> void:
	var head := 0.95 if crouching else 1.45
	_pivot.global_position = _pivot.global_position.lerp(global_position + Vector3.UP * head, minf(1.0, 15 * delta))
	_pivot.rotation = Vector3(0, _yaw, 0)
	_pitch_node.rotation.x = _pitch
	_visual.visible = _back_arm.get_hit_length() > HIDE_BODY_BELOW
