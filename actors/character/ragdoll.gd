## A CharacterModel's skeleton as Jolt bodies. A guard that drops goes limp for as long as it lies there; a guard that
## is only hit flinches: the bones near the hit go physical for a moment while the clip keeps playing the rest. The
## physical bones are built on first use from the rest pose, and the body eases back into the clip when they stop.
class_name Ragdoll
extends Node

## Bone -> [bone its capsule runs toward ("" = up the bone by TIP), radius, mass, swing, twist] (degrees)
const BONES := {
	"pelvis": ["spine_02", 0.13, 10.0, 25.0, 15.0], "spine_02": ["neck_01", 0.14, 12.0, 25.0, 15.0],
	"Head": ["", 0.1, 4.0, 40.0, 30.0],
	"upperarm_l": ["lowerarm_l", 0.05, 2.0, 70.0, 30.0], "lowerarm_l": ["hand_l", 0.045, 1.5, 60.0, 10.0],
	"upperarm_r": ["lowerarm_r", 0.05, 2.0, 70.0, 30.0], "lowerarm_r": ["hand_r", 0.045, 1.5, 60.0, 10.0],
	"thigh_l": ["calf_l", 0.075, 6.0, 55.0, 15.0], "calf_l": ["foot_l", 0.06, 4.0, 50.0, 5.0],
	"thigh_r": ["calf_r", 0.075, 6.0, 55.0, 15.0], "calf_r": ["foot_r", 0.06, 4.0, 50.0, 5.0],
}
const TIP := 0.2         # m, how far the Head's capsule runs
const LAYER := 1 << 7    # the bodies are only hit by the world, never the Operative or other guards
const WORLD := 1
const BLEND := 0.6      # s, how long the clip takes the body back from the lying pose when it gets up
## Bone hit -> the bones that take it: the rest of the body keeps playing the clip.
const REGIONS := {
	"Head": ["Head", "spine_02"],
	"spine_02": ["spine_02", "Head", "upperarm_l", "upperarm_r"],
	"upperarm_l": ["upperarm_l", "lowerarm_l", "spine_02"], "lowerarm_l": ["upperarm_l", "lowerarm_l", "spine_02"],
	"upperarm_r": ["upperarm_r", "lowerarm_r", "spine_02"], "lowerarm_r": ["upperarm_r", "lowerarm_r", "spine_02"],
	"thigh_l": ["thigh_l", "calf_l"], "calf_l": ["thigh_l", "calf_l"],
	"thigh_r": ["thigh_r", "calf_r"], "calf_r": ["thigh_r", "calf_r"],
}
const FLINCH_PEAK := 0.8   # how much of the pose the physical bones take at the hit
const FLINCH_HOLD := 0.1   # s the hit bones stay at the peak before the clip takes them back
const FLINCH_FADE := 0.35  # s they take to let go
const PELVIS_BLEND := 1.4  # the hips rise this much slower than the limbs get up (x BLEND)

enum Mode { OFF, FLINCH, LIMP }

var skeleton: Skeleton3D
var _sim: PhysicalBoneSimulator3D
var _fade: Tween
var _mode := Mode.OFF
var _from := {}         # bone index -> Quaternion, the lying pose the clip is taking the body back from
var _from_hips := Vector3.ZERO
var _left := 0.0        # s of that blend still to go
var _total := 0.0


func _init(skel: Skeleton3D = null) -> void:
	skeleton = skel


## Is the body lying limp (a flinch is not).
func active() -> bool:
	return _mode == Mode.LIMP


## Where the body lies: the pelvis, in world space.
func center() -> Vector3:
	var pelvis: PhysicalBone3D = _sim.get_node_or_null("pelvis") if _sim else null
	return pelvis.global_position if pelvis else Vector3.INF


## Goes limp from the current pose; `push` (m/s) shoves the bone `at`, which is where a bullet landed.
func start(push := Vector3.ZERO, at := "pelvis") -> void:
	if _sim == null:
		_build()
	if _fade:
		_fade.kill()
	_left = 0.0
	_mode = Mode.LIMP
	_set_layer(LAYER)
	_sim.influence = 1.0
	_sim.physical_bones_start_simulation()
	var body: PhysicalBone3D = _sim.get_node_or_null(at)
	if body and push != Vector3.ZERO:
		body.apply_central_impulse(push * body.mass)


## A hit that does not put it down: the bones around `at` go physical and take `push` (m/s), then the clip takes
## them back. Does nothing to a body that is lying limp.
func flinch(push: Vector3, at: String) -> void:
	if _mode == Mode.LIMP:
		return
	if _sim == null:
		_build()
	if _fade:
		_fade.kill()
	var names: Array[StringName] = []
	for bone: String in REGIONS.get(at, REGIONS["spine_02"]):
		names.append(StringName(bone))
	_mode = Mode.FLINCH
	_sim.influence = FLINCH_PEAK
	_sim.physical_bones_start_simulation(names)
	var body: PhysicalBone3D = _sim.get_node_or_null(at)
	if body == null:
		body = _sim.get_node_or_null(String(names[0]))
	if body:
		body.apply_central_impulse(push * body.mass)
	_fade = create_tween()
	_fade.tween_interval(FLINCH_HOLD)
	_fade.tween_property(_sim, "influence", 0.0, FLINCH_FADE)
	_fade.tween_callback(_settle)


func _settle() -> void:
	_sim.physical_bones_stop_simulation()
	_mode = Mode.OFF


## Shoves a bone of a body already lying there (a bullet into a Down guard).
func shove(push: Vector3, at: String) -> void:
	var body: PhysicalBone3D = _sim.get_node_or_null(at) if _sim else null
	if body and active():
		body.apply_central_impulse(push * body.mass)


## Back to the animation: the pose it lay in is kept and the clip takes the body back from it over `fade` seconds
## (0 = at once), the hips last, instead of snapping to the clip.
func stop(fade := BLEND) -> void:
	if not active():
		return
	if _fade:
		_fade.kill()
	_from.clear()
	_left = 0.0
	if fade > 0.0:
		for i in skeleton.get_bone_count():
			_from[i] = skeleton.get_bone_pose_rotation(i)
		_from_hips = skeleton.get_bone_pose_position(skeleton.find_bone("pelvis"))
		_total = fade
		_left = fade * PELVIS_BLEND
	_sim.physical_bones_stop_simulation()
	_mode = Mode.OFF
	_set_layer(0)


## Called after the clip has posed the skeleton: while a get-up is under way, pulls the pose back toward the lying one.
func blend(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	var hips := skeleton.find_bone("pelvis")
	for i: int in _from:
		var k := _left / (_total * (PELVIS_BLEND if i == hips else 1.0))
		k = clampf(k, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)  # smoothstep: the limbs leave the floor first
		skeleton.set_bone_pose_rotation(i, skeleton.get_bone_pose_rotation(i).slerp(_from[i], k))
		if i == hips:
			skeleton.set_bone_pose_position(i, skeleton.get_bone_pose_position(i).lerp(_from_hips, k))
	if _left <= 0.0:
		_from.clear()


## The bodies are only a target for a bullet while the guard lies there; a standing or flinching one is hit as a guard.
func _set_layer(layer: int) -> void:
	for pb in _sim.get_children():
		if pb is PhysicalBone3D:
			pb.collision_layer = layer


func _build() -> void:
	_sim = PhysicalBoneSimulator3D.new()
	skeleton.add_child(_sim)
	for bone: String in BONES:
		var id := skeleton.find_bone(bone)
		if id < 0:
			continue
		var spec: Array = BONES[bone]
		var rest := skeleton.get_bone_global_rest(id)
		var along := Vector3.UP * TIP  # bone-local direction and length of the capsule
		if spec[0] != "":
			along = rest.affine_inverse() * skeleton.get_bone_global_rest(skeleton.find_bone(spec[0])).origin
		var shape := CapsuleShape3D.new()
		shape.radius = spec[1]
		shape.height = maxf(along.length(), spec[1] * 2.0 + 0.01)
		var col := CollisionShape3D.new()
		col.shape = shape
		var up := along.normalized()
		var side := up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
		col.transform = Transform3D(Basis(side.cross(up), up, side), along * 0.5)  # a capsule stands along its Y
		var pb := PhysicalBone3D.new()
		pb.name = bone
		pb.bone_name = bone
		pb.mass = spec[2]
		pb.linear_damp = 0.3
		pb.angular_damp = 3.0
		pb.collision_layer = 0
		pb.collision_mask = WORLD
		pb.joint_type = PhysicalBone3D.JOINT_TYPE_CONE if bone != "pelvis" else PhysicalBone3D.JOINT_TYPE_NONE
		_sim.add_child(pb)
		pb.add_child(col)
		if bone != "pelvis":
			pb.set("joint_constraints/swing_span", spec[3])
			pb.set("joint_constraints/twist_span", spec[4])
