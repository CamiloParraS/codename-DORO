## The Operative's state and the ground floor its layers stand on (operative_hands.gd, then operative.gd, extend it):
## the kit, posture as guards read it, the camera rig, noise, taking a hit and the Checkpoint snapshot.
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
var looking := false  # first-person look (hold Z): eye view, feet planted
var ladder: Node3D       # the Ladder being climbed (group "ladders", Bottom and Top markers)
var prompt := ""         # shown by the HUD
var prompt_parts: Array = []  # the same prompt for the HUD, text-free: Operative.part() dicts
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
var _glance_left := 0.0  # s the camera is still being turned toward _glance_yaw (see glance)
var _glance_yaw := 0.0
var look_basis: Basis:  # where the camera looks (the body itself never turns), for the Radar's arrow
	get: return Basis(Vector3.UP, _yaw)
var _recoil := 0.0
var ping_range := 0.0  # metres of the last noise made, for the Radar's ring
var ping_age := 99.0   # s since it
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


## Where the aim has wandered to from the crosshair, degrees; none unless aiming.
func aim_drift() -> Vector2:
	return Locomotion.drift(_sway, Time.get_ticks_msec() / 1000.0) if aiming else Vector2.ZERO


## A camera kick of `rad` radians, settling by RECOIL_RECOVERY like a shot's.
func kick(rad: float) -> void:
	_recoil += rad


## A noise of `noise_range` metres was made: the Radar spreads a ring for it.
func ping(noise_range: float) -> void:
	ping_range = noise_range
	ping_age = 0.0


## A guard's bullet landed. Dying opens the Game Over screen (MissionRun).
func take_hit() -> void:
	if health.dead():
		return
	health.hit()
	model.react("hit")
	kick(0.12)
	Mixer.hit_stop(0.04)
	Mixer.rumble(0.6, 1.0, 0.2)
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
	reset_physics_interpolation()
	velocity = Vector3.ZERO
	_yaw = s.yaw
	_pitch = s.pitch
	_recoil = 0.0
	crouching = s.crouching
	_apply_crouch()
	tranq = MissionRun.copy(s.tranq)
	rifle = MissionRun.copy(s.rifle)
	_gun = rifle as Gun if s.rifle_in_hand else tranq as Gun
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


## Room to stand up: nothing solid overhead within standing height (a Crawlspace's ceiling).
func _headroom() -> bool:
	var from := global_position + Vector3.UP * 0.5
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * 1.3, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _flat_dist(n: Node3D) -> float:
	return Vector2(n.global_position.x - global_position.x, n.global_position.z - global_position.z).length()


## Turns the camera toward `at` for `secs` (the mouse is ignored meanwhile), to point out something the level wants seen.
func glance(at: Vector3, secs: float) -> void:
	var d := at - global_position
	_glance_yaw = atan2(-d.x, -d.z)
	_glance_left = secs
