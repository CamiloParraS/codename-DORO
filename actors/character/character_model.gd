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
## tasks; throw and pick_up are one-shots for the Magazine and a resupply crate.
const MIXAMO_CLIPS := {
	"idle": "pro_idle", "walk": "pro_walk_forward", "run": "pro_run_forward",
	"aim": "rifle_aiming_idle", "crouch_idle": "pro_idle_crouching", "crouch_aim": "pro_idle_crouching_aiming",
	"crouch_walk": "pro_walk_crouching_forward", "takedown": "hostage_situation_idle_-_villain",
	"hit": "bs_hit_reaction", "fire": "bs_firing_rifle", "reload": "reloading",
	"carry": "walking_1", "carry_idle": "carrying", "down": "sleeping_idle",
	"startle": "surprised", "look": "look_around", "kneel": "taken_hostage_-_victim",
	"talk": "talking", "talk_b": "talking_1",  # gestures for react() while a guard speaks
	"hand_to_ear": "talking_on_phone", "dead": "pro_death_from_the_front",
	"climb": "climbing_ladder", "use": "button_pushing", "throw": "throw", "pick_up": "picking_up",
}
## Game clip -> Mixamo clip to swap in while the tranq pistol is in hand. Mixamo has no pistol fire or
## crouch-walk takes, so those keep the rifle's. The pack's short pistol idle is the raised two-hand hold, which
## loops as the aim (the loose "Pistol Aim" holsters halfway through).
const PISTOL_CLIPS := {
	"idle": "pistol_idle", "walk": "hg_pistol_walk", "run": "hg_pistol_run",
	"aim": "hg_pistol_idle", "crouch_idle": "pistol_kneeling_idle", "crouch_aim": "pistol_kneeling_idle",  # already raised
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
## Weapon models by name; "grip" is where the hand holds them, in the file's own space.
const GUNS := {
	"tranq": {"scene": preload("res://assets/models/weapons/pistol.glb"), "grip": Vector3(-0.03, -0.03, 0), "muzzle": 0.35},
	"rifle": {"scene": preload("res://assets/models/weapons/rifle.glb"), "grip": Vector3(-0.2, -0.06, 0), "muzzle": 0.75},
}
const SUPPRESSOR := preload("res://assets/models/weapons/suppressor.glb")
const SUPPRESSOR_AT := Vector3(0.19, 0.072, 0)  # over the pistol's barrel, overlapping the slide end
const CARRIED := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, 1.2, -0.1))  # fixed pose on the shoulder

@export var kind := Kind.GUARD

var skeleton: Skeleton3D
var _anim := AnimationPlayer.new()
var _clip := ""
var _since_step := 0.0
var _busy := 0.0     # seconds left of a react() one-shot, which play() must not interrupt
var _home: Node3D    # where the model lives while it rides someone's shoulder
var _gun: Node3D     # the weapon in the right hand
var _weapon := ""    # the name it was hold()n with, which picks the clip set
var _holder: Node3D  # model space on the shoulder bone; a carried guard's model hangs here


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
	play("idle")


func _process(delta: float) -> void:
	_busy -= delta
	_since_step += delta
	if _since_step >= STEP:
		_anim.advance(_since_step)
		_since_step = 0.0
		if _weapon == "rifle":
			_brace()


## Aims the rifle from the gun hand at the off hand, keeping its grip in the gun hand.
func _brace() -> void:
	var r := skeleton.get_bone_global_pose(skeleton.find_bone(HAND_BONE))
	var l := skeleton.get_bone_global_pose(skeleton.find_bone(OFF_HAND))
	var hand := r.basis.orthonormalized()
	var grip: Vector3 = GUNS.rifle.grip
	var reach := r.origin.distance_to(l.origin)
	if reach < BRACE_REACH.x or reach > BRACE_REACH.y:
		_gun.transform = Transform3D(HAND_TO_GUN, HAND_TO_GUN * -grip)
		return
	var x := (l.origin - r.origin) / reach  # the muzzle
	var z := x.cross(hand * HAND_TO_GUN.y).normalized()
	var aim := hand.inverse() * Basis(x, z.cross(x), z)
	_gun.transform = Transform3D(aim, aim * -grip)


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
	_gun.transform = Transform3D(HAND_TO_GUN, HAND_TO_GUN * -GUNS[weapon].grip)
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


## On `mount` (a carry_mount) the model lies in the fixed shoulder pose; null puts it back where it was.
func ride(mount: Node3D) -> void:
	if mount:
		if not _home:
			_home = get_parent_node_3d()
		reparent(mount, false)
		transform = CARRIED
		_clip = "down"
		_anim.play("down")
		_anim.seek(_anim.get_animation("down").length, true)
	elif _home:
		reparent(_home, false)
		transform = Transform3D.IDENTITY
		_home = null
