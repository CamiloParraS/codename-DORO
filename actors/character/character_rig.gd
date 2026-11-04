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
## Clips that need both hands free, so the gun is put away: a ladder's rungs.
const STOW_CLIPS := ["climb"]
const ARMS := [["upperarm_r", "lowerarm_r", "hand_r"], ["upperarm_l", "lowerarm_l", "hand_l"]]
const WRIST := 0.07  # m from the wrist bone to where the mitt closes

## A carried body lies on its back across the carrier's forearms, in front of his chest: its head to his left, its feet to
## his right (the model's up runs to -X, its front faces the sky). The origin is at the feet; the back sits ~0.12 m under it.
const CRADLE := Transform3D(Basis(Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, -1, 0)), Vector3(1.0, 1.22, -0.4))
## m the model drops when it hangs from a Fulton line: the cable ends at the node's origin, so the chest hangs from it.
const HUNG_DROP := 1.35
## Limbs of a limp body (cradled or hung): [upper, lower, end] bones per limb. Nikita's rig, then the Target's Mixamo one.
const LIMP_BONES := {
	"quaternius": {"arm_l": ["upperarm_l", "lowerarm_l", "hand_l"], "arm_r": ["upperarm_r", "lowerarm_r", "hand_r"],
		"leg_l": ["thigh_l", "calf_l", "foot_l"], "leg_r": ["thigh_r", "calf_r", "foot_r"], "neck": ["neck_01", "Head"]},
	"mixamo": {"arm_l": ["mixamorig_LeftArm", "mixamorig_LeftForeArm", "mixamorig_LeftHand"],
		"arm_r": ["mixamorig_RightArm", "mixamorig_RightForeArm", "mixamorig_RightHand"],
		"leg_l": ["mixamorig_LeftUpLeg", "mixamorig_LeftLeg", "mixamorig_LeftFoot"],
		"leg_r": ["mixamorig_RightUpLeg", "mixamorig_RightLeg", "mixamorig_RightFoot"], "neck": ["mixamorig_Neck", "mixamorig_Head"]},
}

var skeleton: Skeleton3D
var _limp := ""  # "cradle" (lying across a carrier's arms), "hung" (posed on a Fulton line) or "ragdoll" (hanging from one): limp, whatever the clip
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
var _screen: VisibleOnScreenNotifier3D  # set by _watch_screen; none on the Operative, who is always in frame
var _shown := true  # on screen (or limp): the modifiers run and the clip moves every frame

## Box around a watched body, past its feet: a body just out of frame may still throw its shadow into it.
const SCREEN_MARGIN := 1.5


## Which clip the Operative shows. task is a clip for what it is busy at (climb, use, crouch_idle for a Fulton), or "".
## strafe (Locomotion.STRAFE_DIRS) is the way an aiming Operative moves relative to his facing: the legs walk that way.
static func operative_clip(choking: bool, carrying: bool, aiming: bool, crouching: bool, moving: bool, walking: bool, task := "", strafe := "") -> String:
	if choking:
		return "takedown"
	if task != "":
		return task
	if carrying:
		return "carry" if moving else "carry_idle"
	if aiming and not moving:  # moving, the legs walk and operative_upper() holds the aim over them
		return "crouch_aim" if crouching else "aim"
	if aiming and strafe != "":  # the legs step the way he goes, so a sideways move isn't a forward walk skating
		return ("crouch_walk_" if crouching else "walk_") + strafe
	if crouching:
		return "crouch_walk" if moving else "crouch_idle"
	if moving:
		return "walk" if walking or aiming else "run"  # aiming slows him to a walk (Locomotion.speed)
	return "idle"


## The aim the Operative's upper body holds over a walk (aiming on the move: he strafes facing the crosshair), or "".
static func operative_upper(choking: bool, carrying: bool, aiming: bool, crouching: bool, moving: bool, task := "") -> String:
	if not aiming or not moving or choking or carrying or task != "":
		return ""
	return "crouch_aim" if crouching else "aim"


## Which clip a guard shows, by flat speed (m/s). dead is one killed on its feet: it falls instead of sleeping.
static func guard_clip(down: bool, speed: float, dead := false) -> String:
	if dead:
		return "dead"
	if down:
		return "down"
	if speed > 3.0:
		return "run"
	return "walk" if speed > 0.3 else "idle"


## Adds every modifier the skeleton has bones for; once the body is in.
func _rig() -> void:
	_add_look_at()
	_add_spring()
	_add_foot_ik()
	_add_arm_ik()


## Watches whether the body is in the camera's frame; off it, _drive_rig turns the modifiers off.
func _watch_screen() -> void:
	_screen = VisibleOnScreenNotifier3D.new()
	_screen.aabb = AABB(Vector3(-SCREEN_MARGIN, -0.5, -SCREEN_MARGIN), Vector3(SCREEN_MARGIN * 2.0, 2.5 + SCREEN_MARGIN, SCREEN_MARGIN * 2.0))
	add_child(_screen)


## Out of every camera's frame, with a camera to judge by (none in the headless tests).
func _off_screen() -> bool:
	return _screen != null and get_viewport().get_camera_3d() != null and not _screen.is_on_screen()


## Eases each modifier toward what the clip and the body's state want, once a frame.
func _drive_rig(delta: float) -> void:
	var limp := _ragdoll != null and _ragdoll.active()
	var shown := limp or not _off_screen()  # a ragdoll keeps its full rate: it reads the pose it falls from
	if shown != _shown:
		_shown = shown
		for m: SkeletonModifier3D in [_look, _arms] + _feet:
			if m:
				m.active = shown
	if _spring:
		_spring.active = shown and not limp  # the physical bones carry the head while it lies
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


## Eases the hands onto the line over the head in a GRAB_CLIPS clip, off again in any other. The gun is stowed
## in those and in STOW_CLIPS.
func _grab_line(delta: float) -> void:
	var on := _clip in GRAB_CLIPS
	if _gun:
		_gun.visible = not on and _clip not in STOW_CLIPS
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


## Bone names of this rig's limbs (LIMP_BONES), or {} on a rig that has neither set.
func _limp_bones() -> Dictionary:
	for set: String in LIMP_BONES:
		if skeleton.find_bone(LIMP_BONES[set].neck[1]) >= 0:
			return LIMP_BONES[set]
	return {}


## Turns `bone` (skeleton bone names) so the line from it to `child` points along `dir` (world space).
func _aim(bone: String, child: String, dir: Vector3) -> void:
	var i := skeleton.find_bone(bone)
	var c := skeleton.find_bone(child)
	if i < 0 or c < 0:
		return
	var pose := skeleton.get_bone_global_pose(i)
	var cur := (skeleton.get_bone_global_pose(c).origin - pose.origin).normalized()
	var want := (skeleton.global_basis.orthonormalized().inverse() * dir).normalized()
	if cur.is_zero_approx() or want.is_zero_approx() or cur.dot(want) < -0.9999:
		return
	pose.basis = Basis(Quaternion(cur, want)) * pose.basis
	skeleton.set_bone_global_pose(i, pose)


## Over the rest pose of a limp body (cradled or hung): arms and legs hang down, the head lolls, all swaying a little.
func _limp_pose() -> void:
	if _limp != "cradle" and _limp != "hung":  # a ragdoll hangs by itself
		return
	var b := _limp_bones()
	if b.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0
	var sway := sin(t * 1.7) * 0.1
	var right := global_basis.x.normalized()
	var top := global_basis.y.normalized()   # up the body, to the head
	var fwd := -global_basis.z.normalized()  # the way its chest faces
	var down := Vector3.DOWN
	for k in 2:
		var side := right * (-1.0 if k == 0 else 1.0)
		var arm: Array = b["arm_l" if k == 0 else "arm_r"]
		var leg: Array = b["leg_l" if k == 0 else "leg_r"]
		if _limp == "cradle":
			_aim(arm[0], arm[1], down + side * 0.15 + top * sway)
			_aim(arm[1], arm[2], down + side * 0.05 + top * sway * 1.5)
			_aim(leg[0], leg[1], -top + down * 0.35 + side * 0.08)  # the thighs trail along the body, the knees give
			_aim(leg[1], leg[2], down - top * 0.2 + top * sway)
		else:
			_aim(arm[0], arm[1], down + side * 0.25 + fwd * sway)
			_aim(arm[1], arm[2], down + side * 0.1 + fwd * sway * 1.5)
			_aim(leg[0], leg[1], down + side * 0.06)
			_aim(leg[1], leg[2], down - fwd * 0.12 + fwd * sway)
	var neck: Array = b.neck
	# the head falls back off the arm; hung, it drops onto the chest
	_aim(neck[0], neck[1], top + down * 0.9 if _limp == "cradle" else Vector3.UP + fwd * 0.7)


## The carrier's arms under the body he carries: upper arms down, forearms level in front of him, held out as a cradle.
func _cradle_arms(holder: Node3D) -> void:
	if holder == null or holder.get_child_count() == 0:
		return
	var b := _limp_bones()
	if b.is_empty():
		return
	var right := global_basis.x.normalized()
	var fwd := -global_basis.z.normalized()
	for k in 2:
		var s := -1.0 if k == 0 else 1.0
		var arm: Array = b["arm_l" if k == 0 else "arm_r"]
		_aim(arm[0], arm[1], Vector3.DOWN * 0.9 + fwd * 0.3 + right * s * 0.1)
		_aim(arm[1], arm[2], fwd - right * s * 0.25 + Vector3.UP * 0.05)
