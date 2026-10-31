## Nikita rigged to the Quaternius UE skeleton (tools/rig_nikita.py), driven by the baked clips. Kinds differ by
## tint and gear; the Target is the PSX suit on its own skeleton. Faces -Z like the actors that own it.
class_name CharacterModel
extends Node3D

enum Kind { OPERATIVE, GUARD, TARGET }

const BODY := preload("res://assets/models/characters/Nikita_Rigged.glb")
## The Target is a PSX character on the Mixamo rig, with its own clips from tools/bake_target.gd (gitignored).
const TARGET_BODY := preload("res://assets/models/characters/target/target.fbx")
const TARGET_CLIPS := "res://assets/models/animations/target_clips.res"
## Guard looks: police, firefighter, doctor and hazmat textures of the PSX pack, baked onto Nikita's UVs
## (_raw/work/bake/bake.py). The Operative wears its own, baked the same way.
const GUARD_SKINS := [
	preload("res://assets/models/characters/guard/guard_21.png"),
	preload("res://assets/models/characters/guard/guard_firefighter.png"),
	preload("res://assets/models/characters/guard/guard_doctor.png"),
	preload("res://assets/models/characters/guard/guard_hazmat.png"),
]
const OPERATIVE_SKIN := preload("res://assets/models/characters/operative.png")
const CLIPS := preload("res://assets/models/animations/clips.res")
## Mixamo clips retargeted by tools/bake_mixamo.gd. Gitignored, so it may be missing: the Quaternius clips cover for it.
const MIXAMO := "res://assets/models/animations/mixamo_clips.res"
## Game clip -> Mixamo clip that replaces it. Locomotion is the Pro Rifle pack (rifle at low ready, paced near the
## game's speeds); hit, fire and reload are one-shots for react() (hit and fire are the Basic Shooter's short standing
## takes: the loose Hit Reaction flinches at kneeling height); carry_idle is the fireman hold standing still;
## kneel is a held-up guard with its hands up (it raises them, then holds); takedown is the choke grip, looped;
## dead falls on its back and holds the last frame; climb, use (a console) and the fulton kneel are operative_clip()
## tasks; throw and pick_up are one-shots for the Magazine and a resupply crate. look_nervous is the scan of an Evasion
## search, point a guard sent to check a place, argue a heated turn in the Target's chat and phone a check-in at a stop
## (argue and phone are long clips; phone is the standing call, as the pacing one walks the body off its spot, played from their start at normal speed).
const MIXAMO_CLIPS := {
	"idle": "pro_idle", "walk": "pro_walk_forward", "run": "pro_run_forward",
	"aim": "rifle_aiming_idle", "crouch_idle": "pro_idle_crouching", "crouch_aim": "pro_idle_crouching_aiming",
	"crouch_walk": "pro_walk_crouching_forward", "takedown": "hostage_situation_idle_-_villain",
	"hit": "bs_hit_reaction", "fire": "bs_firing_rifle", "reload": "reloading",
	"carry": "walking_1", "carry_idle": "carrying", "down": "sleeping_idle",
	"startle": "surprised", "look": "look_around", "kneel": "taken_hostage_-_victim",
	"talk": "talking", "talk_b": "talking_1",  # gestures for react() while a guard speaks
	"hand_to_ear": "talking_on_phone", "dead": "pro_death_from_the_front",
	"look_nervous": "nervously_look_around", "point": "pointing", "argue": "standing_arguing",
	"phone": "talking_on_phone",
	"climb": "climbing_ladder", "use": "button_pushing", "throw": "throw", "pick_up": "picking_up",
}
## Game clip -> Mixamo clip to swap in while the tranq pistol is in hand. Mixamo has no pistol fire,
## crouch-walk or low kneel takes, so those keep the rifle's. The pack's short pistol idle is the raised two-hand hold, which
## loops as the aim (the loose "Pistol Aim" holsters halfway through).
const PISTOL_CLIPS := {
	"idle": "pistol_idle", "walk": "hg_pistol_walk", "run": "hg_pistol_run",
	"aim": "hg_pistol_idle", "crouch_aim": "pistol_kneeling_idle",  # raised; no low-ready pistol kneel exists, so
	# crouch_idle keeps the rifle's, which holds the pistol low with the off hand free
}
## Animation advances in steps of this many seconds, so every clip moves with the choppy framerate of a PSX game.
const STEP := 0.0
## Gear parts shown per kind. Helmet and Vest are the guard Countermeasures: hidden until wear().
const DRESS := {
	Kind.OPERATIVE: ["Backpack", "Goggles", "Holster", "Knee_pads"],
	Kind.GUARD: ["Chest_rig", "Holster", "Knee_pads", "Shemag"],
}
## hand_to_ear is a 39 s phone call: played from its start at this speed, the hand is at the ear within a second
## (squeezed whole into a Radio call it would spasm at 20x).
const EAR_SPEED := 3.0
const CARRY_BONE := "spine_03"
const HAND_BONE := "hand_r"
const OFF_HAND := "hand_l"
## The rifle swings to point at the off hand while it is this far (m) from the gun hand, so it sits in both hands
## whatever the clip; past that (reload, takedown) the hand has let go and the rifle keeps its fixed grip.
const BRACE_REACH := Vector2(0.15, 0.75)
## The hand bone's local frame in the Mixamo aim pose: Y runs forward, Z up. This turns a gun file (muzzle +X,
## up +Y) to point level along the way the hand does.
const HAND_TO_GUN := Basis(Vector3(0.04, 0.995, -0.095), Vector3(-0.1, 0.095, 0.99), Vector3(0.994, -0.04, 0.105))
## Where a grip sits in the hand bone's frame: the bone's origin is the wrist, and the mitt closes this far along it.
const PALM := Vector3(0, 0.07, 0.02)
## Rifle clips that aim where the body faces. On Nikita's arms their off hand lands 20-35 degrees to the left, which
## _brace would follow, so _square_up() turns the chest back until the hands line up straight ahead.
const SQUARED := ["aim", "crouch_aim", "fire"]
const TWIST_BONE := "spine_01"
## Where a SQUARED rifle points, up from level (radians). The clips aim 12-18 degrees down on Nikita.
const AIM_PITCH := deg_to_rad(2.0)
## Metres the rifle's handguard sits above the line through its grip, along the gun's up: where the off hand holds.
const HANDGUARD := 0.09
## Weapon models by name; "grip" is where the hand holds them, in the file's own space.
const GUNS := {
	"tranq": {"scene": preload("res://assets/models/weapons/pistol.glb"), "grip": Vector3(-0.03, -0.03, 0), "muzzle": 0.35},
	"rifle": {"scene": preload("res://assets/models/weapons/rifle.glb"), "grip": Vector3(-0.2, -0.06, 0), "muzzle": 0.75},
}
const SUPPRESSOR := preload("res://assets/models/weapons/suppressor.glb")
const SUPPRESSOR_AT := Vector3(0.19, 0.072, 0)  # over the pistol's barrel, overlapping the slide end
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
const CARRIED := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, 1.2, -0.1))  # fixed pose on the shoulder

@export var kind := Kind.GUARD

var skeleton: Skeleton3D
var _anim := AnimationPlayer.new()
var _clip := ""
var _since_step := 0.0
var _busy := 0.0     # seconds left of a react() one-shot, which play() must not interrupt
var _home: Node3D    # where the model lives while it rides someone's shoulder
var _ragdoll: Ragdoll
var _look: LookAtModifier3D  # turns the head to _gaze, weighted by _gaze_w
var _gaze := Marker3D.new()
var _gaze_w := 0.0
var _gaze_on := false
var _gun: Node3D     # the weapon in the right hand
var _weapon := ""    # the name it was hold()n with, which picks the clip set
var _holder: Node3D  # model space on the shoulder bone; a carried guard's model hangs here
var _spring: SpringBoneSimulator3D
var _feet: Array[TwoBoneIK3D] = []
var _foot_targets: Array[Marker3D] = []
var _foot_poles: Array[Marker3D] = []
var _foot_w := 0.0   # how much of the ground the feet take, 0..1
var _foot_dy := [0.0, 0.0]  # m each foot is lifted or lowered, eased
var _foot_h0 := [0.0, 0.0]  # m the foot bone stands above the sole line in the rest pose


## Which clip the Operative shows. task is a clip for what it is busy at (climb, use, crouch_idle for a Fulton), or "".
static func operative_clip(choking: bool, carrying: bool, aiming: bool, crouching: bool, moving: bool, walking: bool, task := "") -> String:
	if choking:
		return "takedown"
	if task != "":
		return task
	if carrying:
		return "carry" if moving else "carry_idle"
	if aiming:
		return "crouch_aim" if crouching else "aim"
	if crouching:
		return "crouch_walk" if moving else "crouch_idle"
	if moving:
		return "walk" if walking else "run"
	return "idle"


## Which clip a guard shows, by flat speed (m/s). dead is one killed on its feet: it falls instead of sleeping.
static func guard_clip(down: bool, speed: float, dead := false) -> String:
	if dead:
		return "dead"
	if down:
		return "down"
	if speed > 3.0:
		return "run"
	return "walk" if speed > 0.3 else "idle"


func _ready() -> void:
	var body: Node3D = (TARGET_BODY if kind == Kind.TARGET else BODY).instantiate()
	body.rotation.y = PI  # the rig faces +Z
	add_child(body)
	skeleton = body.find_children("*", "Skeleton3D", true, false)[0]
	body.add_child(_anim)
	var lib := _clips()
	lib.add_animation("RESET", _rest_pose())
	_anim.add_animation_library("", lib)
	_anim.deterministic = true  # bones a clip doesn't key (the Quaternius clips skip spine_01) go back to rest
	_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	if kind != Kind.TARGET:
		var tint := StandardMaterial3D.new()  # a PSX look: the Operative's skin, or a guard's by its name
		tint.albedo_texture = OPERATIVE_SKIN if kind == Kind.OPERATIVE else GUARD_SKINS[String(get_parent().name).hash() % GUARD_SKINS.size()]
		tint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		tint.roughness = 0.9
		_part("Nikita").material_override = tint
		for part in ["Helmet", "Vest", "Chest_rig", "Backpack", "Goggles", "Holster", "Knee_pads", "Shemag"]:
			_part(part).visible = part in DRESS[kind]
	_add_look_at()
	_add_spring()
	_add_foot_ik()
	play("idle")


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


## Sets each foot to the ground under it, but only while it is on the floor in the clip: a swinging foot keeps its arc.
## The clip's pose is read here, before the modifier turns it into the planted one.
func _plant_feet(delta: float) -> void:
	if _feet.is_empty():
		return
	var limp := _ragdoll != null and _ragdoll.active()
	var on := not limp and _home == null and is_visible_in_tree() and (_clip in FOOT_CLIPS or _clip in PISTOL_CLIPS.values())
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


func _process(delta: float) -> void:
	var limp := _ragdoll != null and _ragdoll.active()
	if _spring:
		_spring.active = not limp  # the physical bones carry the head while it lies
		var moving: bool = _clip in ["walk", "run", "crouch_walk"]  # the gait's own bob would shake the head
		_spring.influence = move_toward(_spring.influence, 0.0 if moving else 1.0, 4.0 * delta)
	if _look:
		_gaze_w = move_toward(_gaze_w, 1.0 if _gaze_on else 0.0, GAZE_BLEND * delta)
		_look.influence = _gaze_w
	_busy -= delta
	_since_step += delta
	if _since_step >= STEP:
		_anim.advance(_since_step)
		_since_step = 0.0
		if _weapon == "rifle":
			if _clip in SQUARED:
				for i in 2:  # a second pass takes up what the first left
					_square_up()
				_brace()
				_turn(Vector3.RIGHT, -(AIM_PITCH - _muzzle_pitch()))  # leaning back raises it, the hands with it
			_brace()


## Twists the upper body about the vertical so the line between the palms points the way the rig faces (+Z).
func _square_up() -> void:
	var r := skeleton.get_bone_global_pose(skeleton.find_bone(HAND_BONE)) * PALM
	var l := skeleton.get_bone_global_pose(skeleton.find_bone(OFF_HAND)) * Vector3(0, PALM.y, 0)
	_turn(Vector3.UP, -atan2(l.x - r.x, l.z - r.z))  # atan2 + is to the rig's left


## Rotates TWIST_BONE (the upper body) by `angle` about `axis`, both in skeleton space.
func _turn(axis: Vector3, angle: float) -> void:
	var bone := skeleton.find_bone(TWIST_BONE)
	var local := skeleton.get_bone_global_pose(skeleton.get_bone_parent(bone)).basis.orthonormalized().inverse() * axis
	skeleton.set_bone_pose_rotation(bone, Quaternion(local.normalized(), angle) * skeleton.get_bone_pose_rotation(bone))


## The held gun's muzzle pitch in skeleton space (radians, + up).
func _muzzle_pitch() -> float:
	var x := (skeleton.get_bone_global_pose(skeleton.find_bone(HAND_BONE)).basis * _gun.transform.basis).x.normalized()
	return asin(x.y)


## Aims the rifle from the gun hand at the off hand, keeping its grip in the gun hand.
func _brace() -> void:
	var r := skeleton.get_bone_global_pose(skeleton.find_bone(HAND_BONE))
	var l := skeleton.get_bone_global_pose(skeleton.find_bone(OFF_HAND))
	var hand := r.basis.orthonormalized()
	var grip: Vector3 = GUNS.rifle.grip
	var palm := r * PALM
	var off := l * Vector3(0, PALM.y, 0)  # the off hand's palm (its bone points along the fingers too)
	var reach := palm.distance_to(off)
	if reach < BRACE_REACH.x or reach > BRACE_REACH.y:
		_gun.transform = Transform3D(HAND_TO_GUN, PALM + HAND_TO_GUN * -grip)
		return
	var x := (off - palm) / reach  # the muzzle
	var z := x.cross(hand * HAND_TO_GUN.y).normalized()
	x = (off - z.cross(x) * HANDGUARD - palm).normalized()  # dipped so the handguard, not the grip line, meets the hand
	z = x.cross(hand * HAND_TO_GUN.y).normalized()
	var aim := hand.inverse() * Basis(x, z.cross(x), z)
	_gun.transform = Transform3D(aim, PALM + aim * -grip)


func _rest_pose() -> Animation:
	var rest := Animation.new()
	for i in skeleton.get_bone_count():
		var t := rest.add_track(Animation.TYPE_ROTATION_3D)
		rest.track_set_path(t, NodePath("%s:%s" % [_anim.get_parent().get_path_to(skeleton), skeleton.get_bone_name(i)]))
		rest.rotation_track_insert_key(t, 0.0, skeleton.get_bone_rest(i).basis.get_rotation_quaternion())
	return rest


func _clips() -> AnimationLibrary:
	if kind == Kind.TARGET:
		return load(TARGET_CLIPS) if ResourceLoader.exists(TARGET_CLIPS) else AnimationLibrary.new()
	if not ResourceLoader.exists(MIXAMO):
		return CLIPS
	var mixamo: AnimationLibrary = load(MIXAMO)
	var lib := AnimationLibrary.new()
	for c in CLIPS.get_animation_list():
		lib.add_animation(c, CLIPS.get_animation(c))
	for c in MIXAMO_CLIPS:
		lib.add_animation(c, mixamo.get_animation(MIXAMO_CLIPS[c]))
	for c in PISTOL_CLIPS.values():  # kept under their own names; play() swaps them in
		lib.add_animation(c, mixamo.get_animation(c))
	return lib


## Plays a one-shot over whatever the model was doing, squeezed into `seconds` (0 = its own length).
## speed > 0 plays the start of a long clip at that speed for `seconds` instead of squeezing it whole.
## Does nothing without the Mixamo bake.
func react(clip: String, seconds := 0.0, speed := 0.0) -> void:
	clip = _swapped(clip)
	if not _anim.has_animation(clip):
		return
	var length := _anim.get_animation(clip).length
	_busy = seconds if seconds > 0.0 else length
	_clip = clip
	_anim.speed_scale = 1.0
	_anim.play(clip, 0.1, speed if speed > 0.0 else length / _busy)


## Plays a looping clip. ground_speed (m/s) paces a clip baked with a "speed" meta so the feet keep up with the body.
func play(clip: String, ground_speed := 0.0) -> void:
	clip = _swapped(clip)
	if _busy > 0.0:
		return
	if not _anim.has_animation(clip):  # carry_idle, crouch_aim, dead and the tasks are Mixamo only
		clip = {"dead": "down", "crouch_aim": "crouch_idle"}.get(clip, "idle")
	if clip != _clip:
		_clip = clip
		_anim.play(clip, 0.2)
	var natural: float = _anim.get_animation(clip).get_meta("speed", 0.0)
	# ponytail: clamped so a mismatched clip (carry walk at full walk speed) skates a little instead of flailing
	_anim.speed_scale = clampf(ground_speed / natural, 0.6, 1.5) if natural > 0.0 and ground_speed > 0.0 else 1.0


## The clip to actually play: with the pistol out, its takes replace the shared ones where they exist.
func _swapped(clip: String) -> String:
	if _weapon != "tranq":
		return clip
	var swapped: String = PISTOL_CLIPS.get(clip, clip)
	return swapped if _anim.has_animation(swapped) else clip


## Puts the named weapon ("tranq" or "rifle") in the right hand; anything else empties it.
func hold(weapon: String) -> void:
	_weapon = weapon if GUNS.has(weapon) else ""
	if _gun:
		_gun.get_parent().queue_free()
		_gun = null
	if not GUNS.has(weapon):
		return
	var at := BoneAttachment3D.new()
	at.bone_name = HAND_BONE
	skeleton.add_child(at)
	_gun = GUNS[weapon].scene.instantiate()
	_gun.transform = Transform3D(HAND_TO_GUN, PALM + HAND_TO_GUN * -GUNS[weapon].grip)
	at.add_child(_gun)
	if weapon == "tranq":
		var can := SUPPRESSOR.instantiate()
		can.position = SUPPRESSOR_AT
		_gun.add_child(can)


## World position of the held gun's muzzle (the gun file points down +X), or `fallback` with nothing in hand.
func muzzle(fallback: Vector3) -> Vector3:
	if not _gun:
		return fallback
	return _gun.global_position + _gun.global_basis.x.normalized() * GUNS[_weapon].muzzle


## Puts on a Countermeasure piece: "Helmet" or "Vest".
func wear(item: String) -> void:
	var piece := _part(item)  # the Target's body has no Countermeasure gear
	if piece:
		piece.visible = true


func _part(part: String) -> MeshInstance3D:
	return skeleton.find_child(part, true, false)


## Hangs `node` (placed in model space) on a bone so it follows the pose.
func _on_bone(bone: String, node: Node3D) -> void:
	var at := BoneAttachment3D.new()
	at.bone_name = bone
	skeleton.add_child(at)
	node.transform = skeleton.get_bone_global_rest(skeleton.find_bone(bone)).affine_inverse() * node.transform
	at.add_child(node)


## Where a carried guard's model hangs: the shoulder bone, in model space.
func carry_mount() -> Node3D:
	if not _holder:
		_holder = Node3D.new()
		_on_bone(CARRY_BONE, _holder)
	return _holder


## A hit that does not put it down: the bones around `at` go physical for a moment, shoved by `push` (m/s), while the
## clip keeps playing the rest of the body. The Target's rig has no physical bones.
func flinch(push: Vector3, at := "spine_02") -> void:
	if kind == Kind.TARGET or _home:
		return
	if _ragdoll == null:
		_ragdoll = Ragdoll.new(skeleton)
		add_child(_ragdoll)
	_ragdoll.flinch(push, at)


## Goes limp where it stands, as a Ragdoll with bone `at` shoved by `push` (m/s). The Target's rig has no physical bones.
func drop(push := Vector3.ZERO, at := "pelvis") -> void:
	if kind == Kind.TARGET or _home:
		return
	if _ragdoll == null:
		_ragdoll = Ragdoll.new(skeleton)
		add_child(_ragdoll)
	_ragdoll.start(push, at)


## Where a ragdoll lies (world space), or Vector3.INF when it isn't one.
func ragdoll_center() -> Vector3:
	return _ragdoll.center() if _ragdoll and _ragdoll.active() else Vector3.INF


## Shoves a body that is already lying as a ragdoll, at the bone `at`.
func shove(push: Vector3, at: String) -> void:
	if _ragdoll:
		_ragdoll.shove(push, at)


## Back under the clip's control, from a ragdoll or not; it eases over `fade` seconds.
func get_up(fade := Ragdoll.BLEND) -> void:
	if _ragdoll:
		_ragdoll.stop(fade)


## On `mount` (a carry_mount) the model lies in the fixed shoulder pose; null puts it back where it was.
func ride(mount: Node3D) -> void:
	if mount:
		get_up(0.0)  # it is about to be moved onto the shoulder, so there is nothing to ease
		if not _home:
			_home = get_parent_node_3d()
		reparent(mount, false)
		physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF  # the bone moves per frame, not per tick
		transform = CARRIED
		_clip = "down"
		_anim.play("down")
		_anim.seek(_anim.get_animation("down").length, true)
	elif _home:
		reparent(_home, false)
		physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_INHERIT
		transform = Transform3D.IDENTITY
		reset_physics_interpolation()
		_home = null
		drop()  # put down: it slumps to the ground
