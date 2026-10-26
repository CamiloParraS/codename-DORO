## The Operative: camera-relative movement (run / walk / crouch), a shoulder camera made of two spring arms,
## knock, choke takedown, carrying a Down guard, Hold-up, Fulton, the tranq pistol and the rifle. Grown from the stealth-core prototype.
extends CharacterBody3D

const KNOCK_COOLDOWN := 1.0
const RUNG_SPACING := 0.5  # metres climbed between rung sounds
const STEP_EVERY := 0.35  # seconds between loud footstep sounds
const STEP_EVERY_CROUCH := 0.6  # and between a crouched Operative's quiet ones (sound only: guards hear none)
const STEP_EVERY_CARRY := 0.6  # and between a carrying Operative's heavy ones (sound only: it reads as walking)
const TAKEDOWN_REACH := 1.5   # metres to a guard to choke it or pick it up
const CHOKE_TIME := 1.2
const KILL_TIME := 0.5        # X: the same grip as the choke, over in a moment
const RECOIL_MAX := 0.15      # radians the kick can stack up to while holding fire
const RECOIL_RECOVERY := 0.3 # radians per second it settles back
const CRATE_REACH := 2.0      # metres to a resupply crate's centre
const LADDER_REACH := 1.2     # metres to a Ladder's Bottom or Top marker to climb on
const CLIMB_SPEED := 1.8
const CARRY_BLOCK_LAYER := 4  # Crawlspace mouths: solid only to an Operative carrying a body
const NoFulton := preload("res://areas/no_fulton.gd")
const FULTON_TIME := 3.0      # seconds of the Fulton key held, standing still, beside a Neutralized guard (pw-feel 05)
const FULTONS := 3            # balloons per Mission, refilled at its start; Requisition raises it (equip)

const HIDE_BODY_BELOW := 0.8  # hide the body when the camera is pushed closer than this

var crouching := false
var walking := false
var moving := false
var carrying: Node3D     # the Down guard on the shoulder
var ladder: Node3D       # the Ladder being climbed (group "ladders", Bottom and Top markers)
var prompt := ""         # shown by the HUD
var aiming := false      # RMB held: over-the-shoulder aim, LMB fires
var radio_open := false  # the radial radio takes the mouse (RMB is "back" there, not aim)
var tranq := Tranq.new()
var rifle := Rifle.new()
var _gun: Gun = tranq  # the weapon in hand
var voiceprints := Voiceprints.new()
var items := Items.new()
var throwing := false    # F held on the Magazine: the arc shows, release throws, RMB cancels
var health := Health.new()
var shoulder := 1.0  # +1 right shoulder, -1 left
var held_up: Guard       # the guard at gunpoint
var fultons := FULTONS   # balloons left; a Continue returns to the Checkpoint's count
var fulton_time := FULTON_TIME  # Quick Hold shortens it
var camera: Camera3D

var _knock_left := 0.0
var _step_left := 0.0
var _choke_left := 0.0
var choke_time := CHOKE_TIME   # Takedowns L3 slows it
var choke_noise := 0.0         # Takedowns L3: metres the struggle is heard
var _choking: Node3D
var _killing := false      # the grip in progress is a kill (X), not a choke (E)
var _victim_down := false  # it was already Down when the kill began
var _yaw := 0.0
var _pitch := -0.25
var _recoil := 0.0
var _sway := Locomotion.SWAY_MOVING  # degrees of hitscan sway, see Locomotion.sway
var _pivot: Node3D
var _pitch_node: Node3D
var _shoulder_arm: SpringArm3D
var _back_arm: SpringArm3D
var _shape: CollisionShape3D
var model: CharacterModel
var _view := ItemView.new()
var _holdup := Holdup.new()  # the clock on held_up
var _ask := 0.0          # seconds of E held on held_up
var _fultoning: Guard
var _fulton_left := 0.0
var _rung_left := 0.0   # metres of ladder until the next rung sound


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
	add_child(_view)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## The Mission's kit (Requisition.kit or BASE), set before the Area enters the tree.
func equip(kit: Dictionary) -> void:
	items.max_charges = kit.scanner
	items.max_magazines = kit.magazines
	items.scan_time = kit.scan_time
	items.refill()
	tranq.total = kit.darts
	tranq.refill()
	rifle.suppressor_max = kit.suppressor
	rifle.suppressor = kit.suppressor
	fultons = kit.fultons
	fulton_time = kit.fulton_time


## The "surface" tag of the floor under the feet ("" = concrete), set on a box by the Area generators.
func _floor_surface() -> StringName:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.5, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return StringName(hit.collider.get_meta("surface", "")) if hit and hit.collider else &""


## Where guards aim their line-of-sight ray.
func chest_height() -> float:
	return 0.6 if looks_crouched() else 1.3


## Carrying, the Operative reads to guards as standing and walking.
func looks_crouched() -> bool:
	return crouching and not carrying


func looks_walking() -> bool:
	return walking or carrying != null or ladder != null


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
	camera.fov = lerpf(camera.fov, 50.0 if aiming else 70.0, minf(1.0, 12 * delta))
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
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _choking:
		_choke_left -= delta
		if not _grip_holds() or (not _killing and not Input.is_action_pressed("interact")):  # turned round, alerted, or E released
			_choking.held = false
			_choking = null
			_choke_left = 0.0
		elif _choke_left <= 0.0:
			Mix.sfx_at(self, &"takedown")
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
	if moving and (not looks_walking() or carrying) and not _choking and not ladder:  # running is loud; crouched and carry steps are sound only
		if not crouching and not carrying:
			Guard.broadcast(get_tree(), global_position, GuardAlert.FOOTSTEP_RANGE, "footsteps")
		_step_left -= delta
		if _step_left <= 0.0:
			_step_left = STEP_EVERY_CARRY if carrying else (STEP_EVERY_CROUCH if crouching else STEP_EVERY)
			var step := Mix.sfx_at(self, Mix.step_sound(_floor_surface()), Vector3.INF, Mix.step_db(crouching, carrying != null))
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


## A guard's bullet landed. Dying opens the Game Over screen (MissionRun).
func take_hit() -> void:
	if health.dead():
		return
	health.hit()
	model.react("hit")
	if health.dead():
		get_tree().call_group.call_deferred("checkpoint", "game_over")


## What a Checkpoint keeps of the Operative: where it stands and looks, its guns and Voiceprints.
func snapshot() -> Dictionary:
	return {
		xform = global_transform, yaw = _yaw, pitch = _pitch, crouching = crouching,
		tranq = MissionRun.copy(tranq), rifle = MissionRun.copy(rifle), rifle_in_hand = _gun == rifle,
		voiceprints = MissionRun.copy(voiceprints), items = MissionRun.copy(items), fultons = fultons,
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
	held_up = null  # the guards go back to their posts
	_fultoning = null
	ladder = null
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
	model.hold("rifle" if s.rifle_in_hand else "tranq")
	voiceprints = MissionRun.copy(s.voiceprints)
	items = MissionRun.copy(s.items)
	fultons = s.fultons
	items.scan_left = 0.0
	throwing = false
	health = Health.new()
	_pivot.global_position = global_position + Vector3.UP * (0.95 if crouching else 1.45)


## The weapon in hand.
func gun() -> Gun:
	return _gun


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
		var land := _flight()[-1]
		Guard.broadcast(get_tree(), land, GuardAlert.KNOCK_RANGE, "a thrown magazine")
		Mix.sfx_at(self, &"mag_land", land)


## Hitscan from the screen centre. Tranq: a hit on a standing guard's head Neutralizes it, on the body
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
	dir = (dir + camera.global_basis.x * randf_range(-sp, sp) + camera.global_basis.y * randf_range(-sp, sp)).normalized()
	var from := camera.global_position
	Fx.flash(get_parent(), from + dir * 0.9 + camera.global_basis.x * 0.25 - camera.global_basis.y * 0.2, quiet)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 60.0, 1 | 2, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var c: Node3D = hit["collider"]
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
func _impact(at: Vector3, on_guard: bool, lethal: bool) -> void:
	var w := get_parent()
	if on_guard:
		Fx.puff(w, at, Color(0.6, 0.95, 0.9) if not lethal else Color(0.7, 0.1, 0.1), 6, 1.5)
	elif lethal:
		Fx.puff(w, at, Color(1, 0.75, 0.25), 6, 4.0, 0.3)  # sparks
		Fx.puff(w, at, Color(0.6, 0.58, 0.55), 5, 1.2, 0.6)  # dust
	else:
		Fx.puff(w, at, Color(0.7, 0.7, 0.65), 4, 1.0, 0.5)


func _interact() -> void:
	if carrying:  # drop it where we stand
		carrying.carrier = null
		carrying.global_position = global_position
		carrying = null
		return
	if held_up and not held_up.answered:
		return  # E is for questioning him (_hold_up)
	var aimed := _holdup_target() if not held_up else null
	if aimed:
		held_up = aimed
		_holdup = Holdup.new()
		held_up.hold_up()
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
		Mix.sfx_at(self, &"choke")
		if choke_noise > 0.0:
			Guard.broadcast(get_tree(), g.global_position, choke_noise, "a struggle", g)
	elif _crate_near():
		items.resupply([tranq, rifle])
	elif _ladder_near():
		_mount(_ladder_near())


## Onto a Ladder from its foot, or from its top (starting just below it), standing, facing the rungs.
func _mount(l: Node3D) -> void:
	ladder = l
	crouching = false
	_apply_crouch()
	var bottom: Vector3 = l.get_node("Bottom").global_position
	var top: Vector3 = l.get_node("Top").global_position
	global_position = Vector3(bottom.x, top.y - 0.05, bottom.z) if global_position.y > bottom.y + 1.0 else bottom
	velocity = Vector3.ZERO
	model.rotation.y = atan2(-(top.x - bottom.x), -(top.z - bottom.z))


## On a Ladder: dir +1 climbs, -1 descends, at CLIMB_SPEED. Off onto the Top marker past the top, or at the foot.
func _climb(dir: float, delta: float) -> void:
	moving = dir != 0.0
	velocity = Vector3.ZERO
	prompt = Prompts.verb("crouch", "ui.prompt.drop_off")
	var bottom: Vector3 = ladder.get_node("Bottom").global_position
	var top: Vector3 = ladder.get_node("Top").global_position
	var y := global_position.y + dir * CLIMB_SPEED * delta
	if y >= top.y:
		global_position = top
		ladder = null
	elif y <= bottom.y:
		global_position = bottom
		ladder = null
	else:
		global_position = Vector3(bottom.x, y, bottom.z)
		_rung_left -= absf(dir) * CLIMB_SPEED * delta
		if _rung_left <= 0.0:
			_rung_left = RUNG_SPACING
			Mix.sfx_at(self, &"ladder")


func _ladder_near() -> Node3D:
	for l: Node3D in get_tree().get_nodes_in_group("ladders"):
		for end in ["Bottom", "Top"]:
			if global_position.distance_to(l.get_node(end).global_position) <= LADDER_REACH:
				return l
	return null


## Room to stand up: nothing solid overhead within standing height (a Crawlspace's ceiling).
func _headroom() -> bool:
	var from := global_position + Vector3.UP * 0.5
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * 1.3, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


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
		Mix.sfx_at(self, &"choke")


## Is the grip still good: a standing victim can still be choked, a Down one is still on the floor.
func _grip_holds() -> bool:
	return _choking.is_down() if _victim_down else _choking.can_be_choked(global_position)


## The HUD's action prompt, "[E] CARRY  [X] KILL": keys from the InputMap, verbs translated.
func _update_prompt() -> void:
	var kill := Prompts.verb("kill_takedown", "ui.prompt.kill")
	if carrying:
		prompt = Prompts.verb("interact", "ui.prompt.drop")
	elif _choking:
		prompt = tr("ui.prompt.killing" if _killing else "ui.prompt.choking")
	elif _fultoning:
		prompt = tr("ui.prompt.fultoning")
	elif held_up and not held_up.answered:
		prompt = _join(tr("ui.prompt.questioning") if _ask > 0.0 else Prompts.hold("interact", "ui.prompt.question"), _fulton_hint())
	elif not held_up and _holdup_target():
		prompt = Prompts.verb("interact", "ui.prompt.hold_up")
	elif _nearest(true):
		prompt = _join(Prompts.verb("interact", "ui.prompt.carry"), kill if _nearest(true, true) else "", _fulton_hint())
	elif _nearest(false):
		prompt = _join(Prompts.verb("interact", "ui.prompt.choke"), kill, _fulton_hint())
	elif _crate_near() and not items.crate_used:
		prompt = Prompts.verb("interact", "ui.prompt.resupply")
	elif _ladder_near():
		prompt = Prompts.verb("interact", "ui.prompt.climb")
	else:
		prompt = ""
	for c in get_tree().get_nodes_in_group("intel"):  # a hold-E console: its line beside the carry and Fulton ones
		var line: String = c.prompt_for(self) if c.has_method("prompt_for") else ""
		prompt = _join(prompt, line)


## Prompt parts two spaces apart, skipping empty ones.
static func _join(a: String, b: String, c := "") -> String:
	return "  ".join(PackedStringArray([a, b, c].filter(func(s: String) -> bool: return s != "")))


## What the Fulton key would do beside a Neutralized or kneeling guard.
func _fulton_hint() -> String:
	var g := _fulton_target()
	if not g or fultons <= 0:
		return ""
	return Prompts.hold("fulton", "ui.prompt.fulton") if fulton_ready() else tr("ui.prompt.no_fulton")


## Could a balloon go up now: a guard it can take in reach, a balloon left, open sky over him.
func fulton_ready() -> bool:
	var g := _fulton_target()
	return g != null and fultons > 0 and NoFulton.open_sky(get_tree(), g.global_position)


## Hold-up: E with the gun aimed (Holdup.RANGE, Guard.can_be_held_up) freezes the guard; Holdup.tick frees him.
## E held Holdup.ASK_TIME s gets his one answer (Guard.answer); after that E chokes him. The clock runs in
## _physics_process, so a paused tree (a full-screen Codec call) stops it.
func _hold_up(delta: float) -> void:
	if held_up and (not is_instance_valid(held_up) or held_up.is_down() or not held_up.held_up):
		held_up = null
	if not held_up:
		_ask = 0.0
		return
	var on_aim := aiming and not gun().reloading() and _aimed_guard() == held_up
	if _holdup.tick(delta, on_aim, _flat_dist(held_up), held_up.alert.state >= GuardAlert.State.ALERT):
		held_up.release(global_position)
		held_up = null
		return
	if not held_up.answered and Input.is_action_pressed("interact"):
		_ask += delta
		if _ask >= Holdup.ASK_TIME:
			held_up.answer(self)
	else:
		_ask = 0.0


## The guard E would hold up now: aimed at (not carrying, choking or reloading), within range, unaware.
func _holdup_target() -> Guard:
	if not aiming or carrying or _choking or gun().reloading():
		return null
	var g := _aimed_guard()
	return g if g and _flat_dist(g) <= Holdup.RANGE and g.can_be_held_up(global_position) else null


## The standing guard under the crosshair, if any.
func _aimed_guard() -> Guard:
	var from := camera.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * 30.0, 1 | 2, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit["collider"] if not hit.is_empty() and hit["collider"] is Guard else null


## Fulton: hold the key fulton_time s, standing still, beside a Neutralized or kneeling (not dead) guard under
## open sky. Releasing, moving or the guard waking cancels and spends nothing.
func _fulton(delta: float) -> void:
	var g := _fulton_target() if Input.is_action_pressed("fulton") and not carrying and not moving and fultons > 0 else null
	if not g or not NoFulton.open_sky(get_tree(), g.global_position):
		_fultoning = null
		return
	if g != _fultoning:
		_fultoning = g
		_fulton_left = fulton_time
	_fulton_left -= delta
	if _fulton_left <= 0.0:
		launch_fulton(g)


## The balloon goes up (Guard.fulton): the guard leaves the Area for good but stays on HQ's poll roster. A
## Target counts as delivered (out of "targets") and feeds no Habit or Lethality.
func launch_fulton(g: Guard) -> void:
	_fultoning = null
	fultons -= 1
	g.remove_from_group("guards")
	g.remove_from_group("targets")
	var radio := get_tree().get_first_node_in_group("radio")
	if radio:
		radio.hq.gone[String(g.name)] = g.global_position
	g.fulton()
	get_tree().call_group("mission_tally", "event", "target_fulton" if g.target else "fulton")


## The nearest guard in reach a balloon could take (Guard.can_be_fultoned).
func _fulton_target() -> Guard:
	var best: Guard
	var best_d := TAKEDOWN_REACH
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		var d := _flat_dist(g)
		if d <= best_d and g.can_be_fultoned():
			best = g
			best_d = d
	return best


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
	model.play(CharacterModel.operative_clip(_choking != null, carrying != null, aiming, crouching, moving, looks_walking()), Vector2(velocity.x, velocity.z).length())
	_view.show_items(global_position, items.scanning(), _flight() if throwing else PackedVector3Array())
	model.visible = _back_arm.get_hit_length() > HIDE_BODY_BELOW
