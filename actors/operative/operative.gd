## The Operative: camera-relative movement (run / walk / crouch), a shoulder camera made of two spring arms,
## knock, choke takedown, carrying a Down guard, the tranq pistol and the rifle. Grown from the stealth-core prototype.
extends CharacterBody3D

const KNOCK_COOLDOWN := 1.0
const TAKEDOWN_REACH := 1.5   # metres to a guard to choke it or pick it up
const CHOKE_TIME := 2.0
const KILL_TIME := 0.5        # X: the same grip as the choke, over in a moment
const RECOIL_MAX := 0.15      # radians the kick can stack up to while holding fire
const RECOIL_RECOVERY := 0.3 # radians per second it settles back
const CRATE_REACH := 2.0      # metres to a resupply crate's centre

const HIDE_BODY_BELOW := 0.8  # hide the body when the camera is pushed closer than this

## ponytail: hardcoded until the settings menu exists.
var sensitivity := 0.0025
var invert_y := false
var crouching := false
var walking := false
var moving := false
var carrying: Node3D     # the Down guard on the shoulder
var prompt := ""         # shown by the HUD
var aiming := false      # RMB held: over-the-shoulder aim, LMB fires
var radio_open := false  # the radial radio takes the mouse (RMB is "back" there, not aim)
var tranq := Tranq.new()
var rifle := Rifle.new()
var _gun: Gun = tranq  # the weapon in hand
var voiceprints := Voiceprints.new()
var health := Health.new()
var shoulder := 1.0  # +1 right shoulder, -1 left
var camera: Camera3D

var _knock_left := 0.0
var _choke_left := 0.0
var choke_time := CHOKE_TIME   # Takedowns L3 slows it
var choke_noise := 0.0         # Takedowns L3: metres the struggle is heard
var _choking: Node3D
var _killing := false      # the grip in progress is a kill (X), not a choke (E)
var _victim_down := false  # it was already Down when the kill began
var _yaw := 0.0
var _pitch := -0.25
var _recoil := 0.0
var _pivot: Node3D
var _pitch_node: Node3D
var _shoulder_arm: SpringArm3D
var _back_arm: SpringArm3D
var _shape: CollisionShape3D
var model: CharacterModel


func _ready() -> void:
	add_to_group("operative")
	collision_mask = 1 | 2  # world and guards (guards sit on layer 2 so they don't block sight or the camera)
	_shape = CollisionShape3D.new()
	_shape.shape = CapsuleShape3D.new()
	add_child(_shape)

	model = CharacterModel.new()
	model.kind = CharacterModel.Kind.OPERATIVE
	add_child(model)
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
		Guard.broadcast(get_tree(), global_position, GuardAlert.KNOCK_RANGE, "a knock")
	elif e.is_action_pressed("interact") and _choke_left <= 0.0:
		_interact()
	elif e.is_action_pressed("kill_takedown") and _choke_left <= 0.0 and not carrying:
		_begin_kill()
	elif e.is_action_pressed("weapon_tranq"):
		_gun = tranq
	elif e.is_action_pressed("weapon_rifle"):
		_gun = rifle
	elif e.is_action_pressed("reload"):
		gun().reload(carrying != null)
	elif e.is_action_pressed("fire") and aiming and not _choking and not gun().automatic:
		_fire()
	elif e.is_action_pressed("pause"):  # Areas without a pause screen (the test room)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	walking = Input.is_action_pressed("walk")
	aiming = Input.is_action_pressed("aim") and not _choking and not radio_open
	camera.fov = lerpf(camera.fov, 50.0 if aiming else 70.0, minf(1.0, 12 * delta))
	_recoil = move_toward(_recoil, 0.0, RECOIL_RECOVERY * delta)
	health.tick(delta)
	tranq.tick(delta, carrying != null)
	rifle.tick(delta, carrying != null)
	if aiming and not _choking and gun().automatic and Input.is_action_pressed("fire"):
		_fire()
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _choking:
		v = Vector2.ZERO  # a choke needs both hands
		_choke_left -= delta
		if not _grip_holds():  # it turned round or raised the alert
			_choking.held = false
			_choking = null
			_choke_left = 0.0
		elif _choke_left <= 0.0:
			if _killing:
				if not _victim_down:  # a kill from behind is a takedown too
					get_tree().call_group("mission_tally", "event", "takedown")
				_choking.kill()
			else:
				get_tree().call_group("mission_tally", "event", "takedown")
				_choking.neutralize()
			_choking = null
	_update_prompt()
	moving = v != Vector2.ZERO
	_knock_left -= delta
	if moving and not looks_walking() and not crouching:  # running is loud
		Guard.broadcast(get_tree(), global_position, GuardAlert.FOOTSTEP_RANGE, "footsteps")
	var dir := Basis(Vector3.UP, _yaw) * Vector3(v.x, 0, v.y)
	if moving:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z), 12 * delta)
	elif aiming:
		model.rotation.y = lerp_angle(model.rotation.y, _yaw, 12 * delta)
	var speed := Locomotion.speed(crouching, looks_walking())
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20 * delta
	move_and_slide()


## A guard's bullet landed. Dying restores the last Checkpoint (MissionRun).
func take_hit() -> void:
	if health.dead():
		return
	health.hit()
	if health.dead():
		get_tree().call_group.call_deferred("checkpoint", "restore_checkpoint")


## What a Checkpoint keeps of the Operative: where it stands and looks, its guns and Voiceprints.
func snapshot() -> Dictionary:
	return {
		xform = global_transform, yaw = _yaw, pitch = _pitch, crouching = crouching,
		tranq = MissionRun.copy(tranq), rifle = MissionRun.copy(rifle), rifle_in_hand = _gun == rifle,
		voiceprints = MissionRun.copy(voiceprints),
	}


## Back to a snapshot, empty-handed and unhurt.
func restore(s: Dictionary) -> void:
	if carrying:
		carrying.carrier = null
		carrying = null
	if _choking:
		_choking.held = false
		_choking = null
	_choke_left = 0.0
	global_transform = s.xform
	velocity = Vector3.ZERO
	_yaw = s.yaw
	_pitch = s.pitch
	_recoil = 0.0
	crouching = s.crouching
	_apply_crouch()
	tranq = MissionRun.copy(s.tranq)
	rifle = MissionRun.copy(s.rifle)
	_gun = rifle if s.rifle_in_hand else tranq
	voiceprints = MissionRun.copy(s.voiceprints)
	health = Health.new()
	_pivot.global_position = global_position + Vector3.UP * (0.95 if crouching else 1.45)


## The weapon in hand.
func gun() -> Gun:
	return _gun


## Hitscan from the screen centre. Tranq: a hit on a standing guard's head Neutralizes it, on the body
## starts the stumble. Rifle: kills (see Guard.shoot), destroys cameras, and a broken suppressor makes
## the shot heard.
func _fire() -> void:
	var arm := gun()
	var quiet := arm.suppressed()
	if not arm.fire(carrying != null):
		return
	if not quiet:
		Guard.broadcast(get_tree(), global_position, Rifle.NOISE_RANGE, "a gunshot")
	_recoil = minf(_recoil + arm.kick, RECOIL_MAX)
	_yaw += randf_range(-0.3, 0.3) * arm.kick
	var sp := arm.spread(carrying != null)
	var dir := -camera.global_basis.z
	dir = (dir + camera.global_basis.x * randf_range(-sp, sp) + camera.global_basis.y * randf_range(-sp, sp)).normalized()
	var from := camera.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 60.0, 1 | 2, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var c: Node3D = hit["collider"]
	if arm.lethal and c.is_in_group("cameras"):
		c.destroy()
	elif c.is_in_group("guards") and not c.is_down():
		var head: bool = hit["position"].y - c.global_position.y >= Guard.HEAD_HEIGHT
		if arm.lethal:
			c.shoot(head, global_position)
		else:
			c.tranquilize(head, global_position)


func _interact() -> void:
	if carrying:  # drop it where we stand
		carrying.carrier = null
		carrying.global_position = global_position
		carrying = null
		return
	var g := _nearest(true)
	if g:
		if not g.dead:
			g.neutralize()  # hoisting a Neutralized guard re-chokes it: the 90 s start over
		carrying = g
		g.carrier = self
		return
	g = _nearest(false)
	if g:
		_choking = g
		_choke_left = choke_time
		_killing = false
		g.held = true
		if choke_noise > 0.0:
			Guard.broadcast(get_tree(), g.global_position, choke_noise, "a struggle", g)
	elif _crate_near():
		tranq.refill()
		rifle.refill()  # ponytail: item counts join when the Scanner and Magazine exist


## X: kill the guard in reach from behind, or finish a Neutralized one on the floor.
func _begin_kill() -> void:
	var g := _nearest(false)
	_victim_down = g == null
	if _victim_down:
		g = _nearest(true, true)
	if g:
		_choking = g
		_choke_left = KILL_TIME
		_killing = true
		g.held = true


## Is the grip still good: a standing victim can still be choked, a Down one is still on the floor.
func _grip_holds() -> bool:
	return _choking.is_down() if _victim_down else _choking.can_be_choked(global_position)


func _update_prompt() -> void:
	if carrying:
		prompt = "E drop"
	elif _choking:
		prompt = "killing..." if _killing else "choking..."
	elif _nearest(true):
		prompt = "E carry · X kill" if _nearest(true, true) else "E carry"
	elif _nearest(false):
		prompt = "E choke · X kill"
	elif _crate_near():
		prompt = "E resupply"
	else:
		prompt = ""


func _crate_near() -> bool:
	for c: Node3D in get_tree().get_nodes_in_group("resupply_crate"):
		if _flat_dist(c) <= CRATE_REACH:
			return true
	return false


func _flat_dist(n: Node3D) -> float:
	return Vector2(n.global_position.x - global_position.x, n.global_position.z - global_position.z).length()


## Nearest guard within reach: a Down one to carry, or one that can be choked.
func _nearest(down: bool, alive := false) -> Node3D:
	var best: Node3D
	var best_d := TAKEDOWN_REACH
	for g in get_tree().get_nodes_in_group("guards"):
		var d := _flat_dist(g)
		if d <= best_d and ((g.is_down() and not (alive and g.dead)) if down else g.can_be_choked(global_position)):
			best = g
			best_d = d
	return best


func _process(delta: float) -> void:
	var head := 0.95 if crouching else 1.45
	_pivot.global_position = _pivot.global_position.lerp(global_position + Vector3.UP * head, minf(1.0, 15 * delta))
	_pivot.rotation = Vector3(0, _yaw, 0)
	_pitch_node.rotation.x = _pitch + _recoil
	model.play(CharacterModel.operative_clip(_choking != null, carrying != null, aiming, crouching, moving, looks_walking()))
	model.visible = _back_arm.get_hit_length() > HIDE_BODY_BELOW
