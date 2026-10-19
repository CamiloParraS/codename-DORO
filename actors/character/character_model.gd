## Nikita rigged to the Quaternius UE skeleton (tools/rig_nikita.py), driven by the baked clips. Kinds differ by
## tint and gear; the Target is the PSX suit on its own skeleton. Faces -Z like the actors that own it.
class_name CharacterModel
extends Node3D

enum Kind { OPERATIVE, GUARD, TARGET }

const BODY := preload("res://assets/models/characters/Nikita_Rigged.glb")
## The Target is a PSX character on the Mixamo rig, with its own clips from tools/bake_target.gd (gitignored).
const TARGET_BODY := preload("res://assets/models/characters/target/target.fbx")
const TARGET_CLIPS := "res://assets/models/animations/target_clips.res"
## Guard looks: the Police 21/22 textures of the PSX pack, baked onto Nikita's UVs (_raw/work/bake/bake.py).
const GUARD_SKINS := [
	preload("res://assets/models/characters/guard/guard_21.png"),
	preload("res://assets/models/characters/guard/guard_22.png"),
]
const CLIPS := preload("res://assets/models/animations/clips.res")
## Mixamo clips retargeted by tools/bake_mixamo.gd. Gitignored, so it may be missing: the Quaternius clips cover for it.
const MIXAMO := "res://assets/models/animations/mixamo_clips.res"
## Game clip -> Mixamo clip that replaces it (idle has no Mixamo match and stays as it is).
## hit, fire and reload are new one-shots for react().
const MIXAMO_CLIPS := {
	"aim": "rifle_aiming_idle", "crouch_idle": "pistol_kneeling_idle",
	"crouch_walk": "rifle_crouch_walk", "takedown": "elbow_punching",
	"hit": "hit_reaction", "fire": "firing_rifle", "reload": "reloading",
	"walk": "walk_with_rifle", "run": "rifle_run",
	"carry": "carrying", "down": "sleeping_idle",
	"startle": "surprised", "look": "look_around",
}
## Game clip -> Mixamo clip to swap in while the tranq pistol is in hand. Mixamo has no pistol fire or
## crouch-walk takes, so those keep the rifle's (or the Quaternius ones) for now.
const PISTOL_CLIPS := {
	"idle": "pistol_idle",
	"walk": "pistol_walk_arc", "run": "pistol_run",
	"aim": "pistol_aim",
}
## Animation advances in steps of this many seconds, so every clip moves with the choppy framerate of a PSX game.
const STEP := 0.0
## The body is white and tinted per kind; the gear parts carry their own colours.
const TINTS := {
	Kind.OPERATIVE: Color(0.3, 0.36, 0.5),
	Kind.GUARD: Color(0.45, 0.5, 0.33),
}
## Gear parts shown per kind. Helmet and Vest are the guard Countermeasures: hidden until wear().
const DRESS := {
	Kind.OPERATIVE: ["Backpack", "Goggles", "Holster", "Knee_pads"],
	Kind.GUARD: ["Chest_rig", "Holster", "Knee_pads", "Shemag"],
}
const CARRY_BONE := "spine_03"
const HAND_BONE := "hand_r"
## The hand bone's local frame in the Mixamo aim pose: Y runs forward, Z up. This turns a gun file (muzzle +X,
## up +Y) to point level along the way the hand does.
const HAND_TO_GUN := Basis(Vector3(0.04, 0.995, -0.095), Vector3(-0.1, 0.095, 0.99), Vector3(0.994, -0.04, 0.105))
## Weapon models by name; "grip" is where the hand holds them, in the file's own space.
const GUNS := {
	"tranq": {"scene": preload("res://assets/models/weapons/pistol.glb"), "grip": Vector3(-0.03, -0.03, 0)},
	"rifle": {"scene": preload("res://assets/models/weapons/rifle.glb"), "grip": Vector3(-0.2, -0.06, 0)},
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


## Which clip the Operative shows.
static func operative_clip(choking: bool, carrying: bool, aiming: bool, crouching: bool, moving: bool, walking: bool) -> String:
	if choking:
		return "takedown"
	if carrying:
		return "carry" if moving else "idle"
	if aiming:
		return "aim"
	if crouching:
		return "crouch_walk" if moving else "crouch_idle"
	if moving:
		return "walk" if walking else "run"
	return "idle"


## Which clip a guard shows, by flat speed (m/s).
static func guard_clip(down: bool, speed: float) -> String:
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
		var tint := StandardMaterial3D.new()
		tint.albedo_color = TINTS[kind]
		if kind == Kind.GUARD:  # a PSX look, one of the skins by the guard's name
			tint.albedo_color = Color.WHITE
			tint.albedo_texture = GUARD_SKINS[String(get_parent().name).hash() % GUARD_SKINS.size()]
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
	_anim.play(clip, 0.1, speed if speed > 0.0 else length / _busy)


func play(clip: String) -> void:
	clip = _swapped(clip)
	if clip == _clip or _busy > 0.0:
		return
	_clip = clip
	_anim.play(clip, 0.2)


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
