## A CharacterModel's skeleton as Jolt bodies: a guard that drops goes limp for as long as it lies there. The physical
## bones are built on first use from the rest pose, and follow the animation again once the simulation stops.
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

var skeleton: Skeleton3D
var _sim: PhysicalBoneSimulator3D


func _init(skel: Skeleton3D = null) -> void:
	skeleton = skel


func active() -> bool:
	return _sim != null and _sim.is_simulating_physics()


## Where the body lies: the pelvis, in world space.
func center() -> Vector3:
	var pelvis: PhysicalBone3D = _sim.get_node_or_null("pelvis") if _sim else null
	return pelvis.global_position if pelvis else Vector3.INF


## Goes limp from the current pose; `push` (m/s) shoves the bone `at`, which is where a bullet landed.
func start(push := Vector3.ZERO, at := "pelvis") -> void:
	if _sim == null:
		_build()
	_sim.influence = 1.0
	_sim.physical_bones_start_simulation()
	var body: PhysicalBone3D = _sim.get_node_or_null(at)
	if body and push != Vector3.ZERO:
		body.apply_central_impulse(push * body.mass)


## Back to the animation.
func stop() -> void:
	if active():
		_sim.physical_bones_stop_simulation()


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
		pb.collision_layer = LAYER
		pb.collision_mask = WORLD
		pb.joint_type = PhysicalBone3D.JOINT_TYPE_CONE if bone != "pelvis" else PhysicalBone3D.JOINT_TYPE_NONE
		_sim.add_child(pb)
		pb.add_child(col)
		if bone != "pelvis":
			pb.set("joint_constraints/swing_span", spec[3])
			pb.set("joint_constraints/twist_span", spec[4])
