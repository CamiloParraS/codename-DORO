## The modifiers a CharacterModel's skeleton runs over its clips: the head turning to a point, the neck's spring,
## feet on the ground and hands on a Fulton line. CharacterModel builds the body and plays the clips on it.
class_name CharacterRig
extends Node3D

const GAZE_LIMIT := deg_to_rad(70.0)   # how far the head turns off the body's heading, sideways and up or down
const GAZE_BLEND := 6.0                # per second, how fast the head comes onto a point or back to the clip
## Feet planted on the ground: a TwoBoneIK3D per leg pulls the foot to the floor under it, within this reach (m).
const FOOT_REACH := 0.3
const FOOT_BLEND := 12.0       # per second, how fast the feet take to the ground or let go of it
const FOOT_LIFT := 0.1         # m the foot bone can be off its standing height and still be planted; swinging feet are free
const LEGS := [["thigh_l", "calf_l", "foot_l"], ["thigh_r", "calf_r", "foot_r"]]
## Clips with both feet on the floor; the rest (a ladder, a fall, the carry) keep the clip's feet.
const FOOT_CLIPS := ["idle", "walk", "run", "crouch_idle", "crouch_walk", "aim", "crouch_aim", "fire", "reload", "hit",
	"look", "look_nervous", "talk", "talk_b", "point", "argue", "phone", "hand_to_ear", "startle"]
## Neck and head trail the body a little: the spring bones that give a hit and a turn some follow-through.
const SPRING_ROOT := "neck_01"
const SPRING_END := "Head"
## Clips where both hands hold a Fulton line straight over the head, gun stowed: a TwoBoneIK3D per arm pulls the
## wrists onto it, gun hand over off hand, this high above the model's origin (m). The "hang" clip lifts the
## hips 0.24 m, which is where these come from.
const GRAB_CLIPS := ["lift_off", "hang"]
const GRAB_AT := [2.22, 2.08]  # gun hand, off hand
const ARMS := [["upperarm_r", "lowerarm_r", "hand_r"], ["upperarm_l", "lowerarm_l", "hand_l"]]
const WRIST := 0.07  # m from the wrist bone to where the mitt closes

var skeleton: Skeleton3D
var _clip := ""
var _home: Node3D    # where the model lives while it rides someone's shoulder
var _ragdoll: Ragdoll
var _gun: Node3D     # the weapon in the right hand
var _look: LookAtModifier3D  # turns the head to _gaze, weighted by _gaze_w
var _gaze := Marker3D.new()
var _gaze_w := 0.0
var _gaze_on := false
var _spring: SpringBoneSimulator3D
var _feet: Array[TwoBoneIK3D] = []
var _foot_targets: Array[Marker3D] = []
var _foot_poles: Array[Marker3D] = []
var _foot_w := 0.0   # how much of the ground the feet take, 0..1
var _foot_dy := [0.0, 0.0]  # m each foot is lifted or lowered, eased
var _foot_h0 := [0.0, 0.0]  # m the foot bone stands above the sole line in the rest pose
var _arms: TwoBoneIK3D
var _grips: Array[Marker3D] = []  # wrist targets on the line
var _elbows: Array[Marker3D] = []


## Adds every modifier the skeleton has bones for; once the body is in.
func _rig() -> void:
	_add_look_at()
	_add_spring()
	_add_foot_ik()
	_add_arm_ik()


## Eases each modifier toward what the clip and the body's state want, once a frame.
func _drive_rig(delta: float) -> void:
	var limp := _ragdoll != null and _ragdoll.active()
	if _spring:
		_spring.active = not limp  # the physical bones carry the head while it lies
		var moving: bool = _clip in ["walk", "run", "crouch_walk"]  # the gait's own bob would shake the head
		_spring.influence = move_toward(_spring.influence, 0.0 if moving else 1.0, 4.0 * delta)
	if _look:
		_gaze_w = move_toward(_gaze_w, 1.0 if _gaze_on else 0.0, GAZE_BLEND * delta)
		_look.influence = _gaze_w
	_grab_line(delta)


## Whether the clip has both feet on the floor.
func _feet_down() -> bool:
	return _clip in FOOT_CLIPS


## A LookAtModifier3D on the head bone, aimed at the _gaze marker. Its axes come from the head's rest pose, since
## the rigs disagree on which way a bone points.
func _add_look_at() -> void:
	var head := skeleton.find_bone("Head")
	if head < 0:
		for i in skeleton.get_bone_count():
			if skeleton.get_bone_name(i).to_lower().ends_with("head"):
				head = i
				break
	if head < 0:
		return
	_gaze.top_level = true
	add_child(_gaze)
	var rest := skeleton.get_bone_global_rest(head).basis.orthonormalized()
	_look = LookAtModifier3D.new()
	skeleton.add_child(_look)
	_look.bone_name = skeleton.get_bone_name(head)
	_look.target_node = _look.get_path_to(_gaze)
	_look.forward_axis = _bone_axis(rest.inverse() * Vector3.BACK) as SkeletonModifier3D.BoneAxis  # the rig faces +Z
	_look.primary_rotation_axis = (_bone_axis(rest.inverse() * Vector3.UP) >> 1) as Vector3.Axis  # yaw, about the bone's own up
	_look.use_angle_limitation = true
	_look.primary_limit_angle = GAZE_LIMIT
	_look.secondary_limit_angle = GAZE_LIMIT / 2.0
	_look.influence = 0.0


## Spring bones on the neck and head, so a turn or a hit leaves the head a beat behind. Skipped on a rig without them.
func _add_spring() -> void:
	if skeleton.find_bone(SPRING_ROOT) < 0 or skeleton.find_bone(SPRING_END) < 0:
		return
	_spring = SpringBoneSimulator3D.new()
	skeleton.add_child(_spring)
	_spring.setting_count = 1
	_spring.set_root_bone_name(0, SPRING_ROOT)
	_spring.set_end_bone_name(0, SPRING_END)
	_spring.set_extend_end_bone(0, true)
	_spring.set_end_bone_direction(0, SkeletonModifier3D.BONE_DIRECTION_FROM_PARENT)
	_spring.set_end_bone_length(0, 0.2)
	_spring.set_center_from(0, SpringBoneSimulator3D.CENTER_FROM_NODE)  # walking moves the model, not the head's inertia
	_spring.set_center_node(0, _spring.get_path_to(self))
	_spring.set_stiffness(0, 3.0)
	_spring.set_drag(0, 0.6)
	_spring.set_gravity(0, 0.0)


## One TwoBoneIK3D for both legs: thigh, calf and foot reach a target set each frame by _plant_feet. Skipped on a rig
## without those bones (the Target's).
func _add_foot_ik() -> void:
	for leg: Array in LEGS:
		for bone: String in leg:
			if skeleton.find_bone(bone) < 0:
				return
	var ik := TwoBoneIK3D.new()
	skeleton.add_child(ik)
	ik.setting_count = LEGS.size()
	for i in LEGS.size():
		var target := Marker3D.new()
		var pole := Marker3D.new()
		for m in [target, pole]:
			m.top_level = true
			add_child(m)
		ik.set_root_bone_name(i, LEGS[i][0])
		ik.set_middle_bone_name(i, LEGS[i][1])
		ik.set_end_bone_name(i, LEGS[i][2])
		ik.set_target_node(i, ik.get_path_to(target))
		ik.set_pole_node(i, ik.get_path_to(pole))
		_foot_targets.append(target)
		_foot_poles.append(pole)
		_foot_h0[i] = skeleton.get_bone_global_rest(skeleton.find_bone(LEGS[i][2])).origin.y
	ik.influence = 0.0
	_feet.append(ik)


## One TwoBoneIK3D for both arms, off until a GRAB_CLIPS clip puts the hands on a Fulton line. Skipped like the legs'.
func _add_arm_ik() -> void:
	for arm: Array in ARMS:
		for bone: String in arm:
			if skeleton.find_bone(bone) < 0:
				return
	_arms = TwoBoneIK3D.new()
	skeleton.add_child(_arms)
	_arms.setting_count = ARMS.size()
	for i in ARMS.size():
		var grip := Marker3D.new()
		var elbow := Marker3D.new()
		for m in [grip, elbow]:
			m.top_level = true
			add_child(m)
		_arms.set_root_bone_name(i, ARMS[i][0])
		_arms.set_middle_bone_name(i, ARMS[i][1])
		_arms.set_end_bone_name(i, ARMS[i][2])
		_arms.set_target_node(i, _arms.get_path_to(grip))
		_arms.set_pole_node(i, _arms.get_path_to(elbow))
		_grips.append(grip)
		_elbows.append(elbow)
	_arms.influence = 0.0


## Eases the hands onto the line over the head in a GRAB_CLIPS clip, the gun stowed; off again in any other.
func _grab_line(delta: float) -> void:
	var on := _clip in GRAB_CLIPS
	if _gun:
		_gun.visible = not on
	if not _arms:
		return
	_arms.influence = move_toward(_arms.influence, 1.0 if on else 0.0, 6.0 * delta)
	if _arms.influence <= 0.0:
		return
	var up := global_basis.y.normalized()
	var side := global_basis.x.normalized()
	for i in ARMS.size():
		var hand := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(ARMS[i][2]))
		var s := 1.0 if i == 0 else -1.0  # the model faces -Z, so the gun (right) hand is on +X
		# the wrist sits a palm's length below the grip, a hair to its own side of the line
		var at: Vector3 = global_position + up * (GRAB_AT[i] - WRIST) + side * s * 0.04
		_grips[i].global_transform = Transform3D(hand.basis, at)
		_elbows[i].global_position = at - up * 0.6 + side * s * 0.5  # elbows out to the sides, under the hands


## Sets each foot to the ground under it, but only while it is on the floor in the clip: a swinging foot keeps its arc.
## The clip's pose is read here, before the modifier turns it into the planted one.
func _plant_feet(delta: float) -> void:
	if _feet.is_empty():
		return
	var limp := _ragdoll != null and _ragdoll.active()
	var on := not limp and _home == null and is_visible_in_tree() and _feet_down()
	_foot_w = move_toward(_foot_w, 1.0 if on else 0.0, FOOT_BLEND * delta)
	_feet[0].influence = _foot_w
	if _foot_w <= 0.0:
		return
	var space := get_world_3d().direct_space_state
	var forward := -global_basis.z
	for i in LEGS.size():
		var pose := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(LEGS[i][2]))
		var knee := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(LEGS[i][1]))
		var want := 0.0
		var from := Vector3(pose.origin.x, global_position.y + FOOT_REACH + 0.3, pose.origin.z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * (FOOT_REACH * 2.0 + 0.3), Ragdoll.WORLD))
		if not hit.is_empty():
			var planted := clampf(1.0 - (pose.origin.y - global_position.y - _foot_h0[i]) / FOOT_LIFT, 0.0, 1.0)
			want = clampf(hit.position.y - global_position.y, -FOOT_REACH, FOOT_REACH) * planted
		_foot_dy[i] = lerpf(_foot_dy[i], want, minf(FOOT_BLEND * delta, 1.0))
		_foot_targets[i].global_transform = Transform3D(pose.basis, pose.origin + Vector3.UP * _foot_dy[i])
		_foot_poles[i].global_position = knee.origin + forward


## The BoneAxis (+X, -X, +Y, -Y, +Z, -Z) a bone-local direction points along most.
static func _bone_axis(v: Vector3) -> int:
	var a := v.abs().max_axis_index()
	return a * 2 + (1 if v[a] < 0.0 else 0)


## Turns the head to `point` (world space), or back to what the clip does for null. Eased in and out.
func gaze(point: Variant) -> void:
	_gaze_on = point != null
	if _gaze_on:
		_gaze.global_position = point
