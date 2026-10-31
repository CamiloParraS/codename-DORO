## The Operative: camera-relative movement (run / walk / crouch), a shoulder camera made of two spring arms,
## knock, choke takedown, carrying a Down guard, Hold-up, Fulton, the tranq pistol and the rifle. Grown from the stealth-core prototype.
extends "res://actors/operative/operative_hands.gd"


func _ready() -> void:
	add_to_group("operative")
	_yaw = rotation.y  # the Area's start facing goes to the camera; the body itself never turns
	rotation = Vector3.ZERO
	collision_mask = 1 | 2  # world and guards (guards sit on layer 2 so they don't block sight or the camera)
	_shape = CollisionShape3D.new()
	_shape.shape = CapsuleShape3D.new()
	add_child(_shape)

	model = CharacterModel.new()
	model.kind = CharacterModel.Kind.OPERATIVE
	add_child(model)
	model.rotation.y = _yaw
	model.hold("tranq")
	_apply_crouch()

	_pivot = Node3D.new()
	_pivot.top_level = true
	_pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # moved per frame below, camera and all
	add_child(_pivot)
	_pitch_node = Node3D.new()
	_pivot.add_child(_pitch_node)
	_shoulder_arm = _make_arm(0.55)
	_pitch_node.add_child(_shoulder_arm)
	_back_arm = _make_arm(Locomotion.CAM_DIST)
	_shoulder_arm.add_child(_back_arm)
	camera = Camera3D.new()
	camera.fov = 70
	camera.current = true
	_back_arm.add_child(camera)
	_apply_shoulder()
	add_child(_view)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _glance_left > 0.0:
			return
		var l := Locomotion.look(_yaw, _pitch, e.relative, GameSettings.current.sensitivity, GameSettings.current.invert_y)
		_yaw = l.x
		_pitch = l.y
	elif ladder:  # both hands on the rungs: the only move is to drop off
		if e.is_action_pressed("crouch") or e.is_action_pressed("interact"):
			ladder = null
	elif e.is_action_pressed("crouch") and (not crouching or _headroom()):
		crouching = not crouching
		_apply_crouch()
	elif throwing and e.is_action_released("item_use"):
		_throw_magazine()
	elif throwing and e.is_action_pressed("aim"):
		throwing = false
	elif e.is_action_pressed("item_next") or e.is_action_pressed("item_prev"):
		if not throwing:
			items.cycle(1 if e.is_action_pressed("item_next") else -1)
	elif e.is_action_pressed("item_use") and not _choking and not radio_open:
		if items.selected == Items.Kind.SCANNER:
			items.use_scanner()
		else:
			throwing = items.can_throw(carrying != null)
	elif e.is_action_pressed("shoulder_swap"):
		shoulder = -shoulder
		_apply_shoulder()
	elif e.is_action_pressed("knock") and _knock_left <= 0.0:
		_knock_left = KNOCK_COOLDOWN
		Guard.broadcast(get_tree(), global_position, GuardAlert.KNOCK_RANGE, "a knock")
		ping(GuardAlert.KNOCK_RANGE)
		Mix.sfx_at(self, &"knock")
	elif e.is_action_pressed("interact") and _choke_left <= 0.0:
		_interact()
	elif e.is_action_pressed("kill_takedown") and _choke_left <= 0.0 and not carrying:
		_begin_kill()
	elif e.is_action_pressed("weapon_tranq"):
		_gun = tranq
		model.hold("tranq")
	elif e.is_action_pressed("weapon_rifle"):
		_gun = rifle
		model.hold("rifle")
	elif e.is_action_pressed("reload"):
		if gun().reload(carrying != null):
			model.react("reload", Gun.RELOAD_TIME)
	elif e.is_action_pressed("fire") and aiming and not _choking and not gun().automatic:
		_fire()
	elif e.is_action_pressed("pause"):  # Areas without a pause screen (the test room)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	walking = Input.is_action_pressed("walk")
	aiming = Input.is_action_pressed("aim") and not _choking and not radio_open and not ladder
	looking = Input.is_action_pressed("look") and not (aiming or _choking or radio_open or ladder or carrying)
	camera.fov = lerpf(camera.fov, 50.0 if aiming else 75.0 if looking else 70.0, minf(1.0, 12 * delta))
	_shoulder_arm.spring_length = lerpf(_shoulder_arm.spring_length, 0.0 if looking else 0.55, minf(1.0, 14 * delta))
	_back_arm.spring_length = lerpf(_back_arm.spring_length, 0.0 if looking else Locomotion.CAM_DIST_AIM if aiming else Locomotion.CAM_DIST, minf(1.0, 14 * delta))
	_recoil = move_toward(_recoil, 0.0, RECOIL_RECOVERY * delta)
	health.tick(delta, get_tree().get_nodes_in_group("guards").any(func(g: Guard) -> bool: return g.alert.state == GuardAlert.State.ALERT))
	items.tick(delta)
	throwing = throwing and not carrying and not _choking and not ladder and not radio_open
	tranq.tick(delta, carrying != null)
	rifle.tick(delta, carrying != null)
	set_collision_mask_value(CARRY_BLOCK_LAYER, carrying != null)
	if ladder:
		_climb(Input.get_axis("move_back", "move_forward"), delta)
		return
	if aiming and not _choking and gun().automatic and Input.is_action_pressed("fire"):
		_fire()
	var v := Vector2.ZERO if looking else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _choking:
		_choke_left -= delta
		if not _grip_holds() or (not _killing and not Input.is_action_pressed("interact")):  # turned round, alerted, or E released
			_choking.held = false
			_choking = null
			_choke_left = 0.0
		elif _choke_left <= 0.0:
			Mix.sfx_at(self, &"takedown")
			Mixer.hit_stop(0.03)
			Mixer.rumble(0.2, 0.5, 0.12)
			if _choking == held_up:
				held_up = null  # a choke after a Hold-up is a takedown like any other
			if _killing:
				if not _victim_down:  # a kill from behind is a takedown too
					get_tree().call_group("mission_tally", "event", "takedown")
				_choking.kill()
			else:
				get_tree().call_group("mission_tally", "event", "takedown")
				_choking.neutralize()
			_choking = null
	_hold_up(delta)
	_fulton(delta)
	_update_prompt()
	moving = v != Vector2.ZERO
	_sway = Locomotion.sway(_sway, moving, crouching, delta)
	_knock_left -= delta
	ping_age += delta
	if moving and (not looks_walking() or carrying) and not _choking and not ladder:  # running is loud; crouched and carry steps are sound only
		var surface := _floor_surface()
		var loud := not crouching and not carrying
		if loud:
			Guard.broadcast(get_tree(), global_position, GuardAlert.footstep_range(surface), "footsteps")
		_step_left -= delta
		if _step_left <= 0.0:
			_step_left = STEP_EVERY_CARRY if carrying else (STEP_EVERY_CROUCH if crouching else STEP_EVERY)
			if loud:
				ping(GuardAlert.footstep_range(surface))
			var step := Mix.sfx_at(self, Mix.step_sound(surface), Vector3.INF, Mix.step_db(crouching, carrying != null))
			if carrying:
				step.pitch_scale *= Mix.CARRY_STEP_PITCH
			elif crouching:
				step.attenuation_filter_cutoff_hz = Mix.CROUCH_STEP_CUTOFF_HZ
	var dir := Basis(Vector3.UP, _yaw) * Vector3(v.x, 0, v.y)
	if moving:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-dir.x, -dir.z), Locomotion.TURN_RATE * delta)
	elif aiming:
		model.rotation.y = lerp_angle(model.rotation.y, _yaw, Locomotion.TURN_RATE * delta)
	var speed := Locomotion.CHOKE_SPEED if _choking else Locomotion.speed(crouching, looks_walking(), aiming)
	var eased := Locomotion.move(Vector2(velocity.x, velocity.z), Vector2(dir.x, dir.z) * speed, delta)
	velocity.x = eased.x
	velocity.z = eased.y
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20 * delta
	move_and_slide()


## Where the thrown Magazine would land: the arc along the camera's heading, cut short by the first wall
## or floor it meets (guards are on another layer, so hitting one does nothing). Points from the hand to the landing.
func _flight() -> PackedVector3Array:
	var pts := Items.arc(global_position + Vector3.UP * 1.4, -camera.global_basis.z, 40)
	var space := get_world_3d().direct_space_state
	for i in range(1, pts.size()):
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(pts[i - 1], pts[i], 1, [get_rid()]))
		if not hit.is_empty():
			return pts.slice(0, i) + PackedVector3Array([hit["position"]])
	return pts


func _throw_magazine() -> void:
	throwing = false
	if items.throw(carrying != null):
		model.react("throw", 0.8, 1.75)  # the clip's wind-up and release; its slow recovery is cut
		var land := _flight()[-1]
		Guard.broadcast(get_tree(), land, GuardAlert.KNOCK_RANGE, "a thrown magazine")
		Mix.sfx_at(self, &"mag_land", land)


## Hitscan: the crosshair picks the aim point, the shot leaves the muzzle for it. Tranq: a hit on a standing guard's head Neutralizes it, on the body
## starts the stumble. Rifle: kills (see Guard.shoot), destroys cameras, and a broken suppressor makes
## the shot heard.
func _fire() -> void:
	var arm := gun()
	var quiet := arm.suppressed()
	if not arm.fire(carrying != null):
		return
	get_tree().call_group("mission_tally", "event", "rifle" if arm.lethal else "dart")
	if not quiet:
		Guard.broadcast(get_tree(), global_position, Rifle.NOISE_RANGE, "a gunshot", null, true)
	Mix.sfx_at(self, Mix.shot_sound(quiet, arm.lethal))
	model.react("fire", 0.3)
	_recoil = minf(_recoil + arm.kick, RECOIL_MAX)
	_yaw += randf_range(-0.3, 0.3) * arm.kick
	var sp := arm.spread(carrying != null)
	var dir := -camera.global_basis.z
	sp += deg_to_rad(_sway)
	var wander := aim_drift()
	dir = (dir + camera.global_basis.x * tan(deg_to_rad(wander.x)) + camera.global_basis.y * tan(deg_to_rad(wander.y))).normalized()
	dir = (dir + camera.global_basis.x * randf_range(-sp, sp) + camera.global_basis.y * randf_range(-sp, sp)).normalized()
	# The crosshair decides where; the shot is seen leaving the muzzle and flying to that point.
	var cam := camera.global_position
	var space := get_world_3d().direct_space_state
	var seen := space.intersect_ray(PhysicsRayQueryParameters3D.create(cam, cam + dir * 60.0, 1 | 2, [get_rid()]))
	var point := Gun.aim_point(cam, dir, seen.get("position"), 60.0)
	var from := model.muzzle(cam + dir * 0.9)
	dir = Gun.muzzle_dir(from, point, dir)
	Fx.flash(get_parent(), from, quiet)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 60.0, 1 | 2 | Ragdoll.LAYER, [get_rid()])
	var hit := space.intersect_ray(q)
	Fx.tracer(get_parent(), from, hit.get("position", from + dir * 60.0))
	if hit.is_empty():
		return
	var c: Node3D = hit["collider"]
	if c is PhysicalBone3D:  # a Down guard's ragdoll
		var down := _guard_of(c)
		_impact(hit["position"], true, arm.lethal)
		if down and arm.lethal:
			down.shot_down(global_position, (c as PhysicalBone3D).bone_name)
		return
	_impact(hit["position"], c.is_in_group("guards"), arm.lethal)
	if arm.lethal and c.is_in_group("cameras"):
		c.destroy()
	elif c.is_in_group("guards") and not c.is_down():
		var head: bool = hit["position"].y - c.global_position.y >= Guard.HEAD_HEIGHT
		if arm.lethal:
			c.shoot(head, global_position)
		else:
			c.tranquilize(head, global_position)


## What a shot leaves where it lands: a dart puffs pale on a guard, a bullet throws sparks and dust off a wall.
## The guard whose skeleton `bone` belongs to, or null.
func _guard_of(bone: Node) -> Guard:
	var n := bone.get_parent()
	while n and not n is Guard:
		n = n.get_parent()
	return n as Guard


func _impact(at: Vector3, on_guard: bool, lethal: bool) -> void:
	var w := get_parent()
	if on_guard:
		Fx.puff(w, at, Color(0.6, 0.95, 0.9) if not lethal else Color(0.7, 0.1, 0.1), 6, 1.5)
	elif lethal:
		Fx.puff(w, at, Color(1, 0.75, 0.25), 6, 4.0, 0.3)  # sparks
		Fx.puff(w, at, Color(0.6, 0.58, 0.55), 5, 1.2, 0.6)  # dust
	else:
		Fx.puff(w, at, Color(0.7, 0.7, 0.65), 4, 1.0, 0.5)


func _process(delta: float) -> void:
	if _glance_left > 0.0:
		_glance_left -= delta
		_yaw = lerp_angle(_yaw, _glance_yaw, minf(1.0, 4.0 * delta))
	var head := 0.95 if crouching else 1.45
	# follows the body where it is drawn (between physics ticks), not where the last tick left it: a step-wise
	# follow made a moving character judder against the camera, which reads as a blur
	_pivot.global_position = _pivot.global_position.lerp(get_global_transform_interpolated().origin + Vector3.UP * head, minf(1.0, 15 * delta))
	_pivot.rotation = Vector3(0, _yaw, 0)
	_pitch_node.rotation.x = _pitch + _recoil
	model.play(CharacterModel.operative_clip(_choking != null, carrying != null, aiming, crouching, moving, looks_walking(), _task()), Vector2(velocity.x, velocity.z).length())
	_view.show_items(global_position, items.scanning(), _flight() if throwing else PackedVector3Array())
	model.visible = not looking and _back_arm.get_hit_length() > HIDE_BODY_BELOW
