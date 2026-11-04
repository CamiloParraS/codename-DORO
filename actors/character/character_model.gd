## Nikita rigged to the Quaternius UE skeleton (tools/rig_nikita.py), driven by the baked clips. Kinds differ by
## tint and gear; the Target is the PSX suit on its own skeleton. Faces -Z like the actors that own it.
class_name CharacterModel
extends CharacterRig

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
## Painted gear, on the part's own UVs in Nikita_Rigged.glb (the body skin is OPERATIVE_SKIN, on Nikita's sheet).
const GEAR_SKINS := {
	"Backpack": preload("res://assets/models/characters/backpack.jpg"),
	"Goggles": preload("res://assets/models/characters/goggles.jpg"),
}
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
	"lift_off": "pro_jump_up",  # an outro's Fulton: yanked off the ground (then "hang", cut from HANG_FROM below)
}
const HANG_FROM := "freehang_climb"  # "hang" is its first HANG_LEN s: the rest climbs over a ledge
const HANG_LEN := 0.35
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
## Off screen (CharacterRig._watch_screen) the clip steps this coarsely: the pose only feeds a muzzle and a ragdoll's start.
const OFFSCREEN_STEP := 0.25
## Gear parts shown per kind. Helmet and Vest are the guard Countermeasures: hidden until wear().
const DRESS := {
	Kind.OPERATIVE: ["Backpack", "Goggles", "Holster", "Knee_pads"],
	Kind.GUARD: ["Chest_rig", "Holster", "Knee_pads", "Shemag"],
}
## hand_to_ear is a 39 s phone call: played from its start at this speed, the hand is at the ear within a second
## (squeezed whole into a Radio call it would spasm at 20x).
const EAR_SPEED := 3.0
## m/s the climbing_ladder clip climbs at: its gripping hand slides down the body this fast. pace() scales the clip
## from it so the hands hold the rungs instead of sliding up them.
const CLIMB_SPEED := 0.7
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
## One-shots that play from the hips up (UPPER_ROOT and the bones under it) over whatever the legs are doing, so a
## reload, a shot or a radio call doesn't stop the walk. The rest of react()'s clips (a bend to a crate, a startle,
## a scan) take the whole body and hold play() off until they end.
const UPPER_CLIPS := ["reload", "fire", "throw", "hit", "hand_to_ear", "talk", "talk_b", "point"]
const UPPER_ROOT := "spine_01"
const UPPER_FADE := 0.12  # s an upper-body one-shot takes to come over the base clip, and to leave it
## Spans of a clip (fractions of its length) where the off hand lets go of the rifle: the reload's goes to the pouch
## and the mag well while the gun hand keeps the rifle as it was. It eases off and back on over LET_GO_FADE.
const LET_GO := {"reload": [0.17, 0.76]}
const LET_GO_FADE := 0.07
## Weapon models by name; "grip" is where the hand holds them, in the file's own space.
const GUNS := {
	"tranq": {"scene": preload("res://assets/models/weapons/pistol.glb"), "grip": Vector3(-0.03, -0.03, 0), "muzzle": 0.35},
	"rifle": {"scene": preload("res://assets/models/weapons/rifle.glb"), "grip": Vector3(-0.2, -0.06, 0), "muzzle": 0.75},
}
const SUPPRESSOR := preload("res://assets/models/weapons/suppressor.glb")
const SUPPRESSOR_AT := Vector3(0.19, 0.072, 0)  # over the pistol's barrel, overlapping the slide end
const CARRIED := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, 1.2, -0.1))  # fixed pose on the shoulder
@export var kind := Kind.GUARD

var _anim := AnimationPlayer.new()
var _since_step := 0.0
var _busy := 0.0     # seconds left of a whole-body react() one-shot, which play() must not interrupt
var _weapon := ""    # the name it was hold()n with, which picks the clip set
var _holder: Node3D  # a carried guard's model hangs here, under this model
var _held := Transform3D()  # the rifle in the gun hand's frame as the off hand last held it
var _upper_bones := {}     # bone name -> index, for UPPER_ROOT and everything under it
var _shot := ""            # the upper-body one-shot over the base clip, "" for none
var _shot_t := 0.0         # s into its clip
var _shot_speed := 1.0
var _shot_left := 0.0      # s before it starts to fade out
var _shot_w := 0.0         # how much of the upper body it takes, 0..1
var _shot_tracks := []     # [track, bone] for its rotation tracks on the upper body
var _upper_hold := ""      # a looping clip the upper body holds over the base clip (hold_upper), "" for none
var _upper_hold_t := 0.0
var _upper_hold_w := 0.0         # eases in and out over UPPER_FADE
var _upper_hold_tracks := []


static func _psx_material(texture: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = texture
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.9
	return m


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
		# a PSX look: the Operative's skin, or a guard's by its name
		_part("Nikita").material_override = _psx_material(OPERATIVE_SKIN if kind == Kind.OPERATIVE else GUARD_SKINS[String(get_parent().name).hash() % GUARD_SKINS.size()])
		for part in GEAR_SKINS:  # guards never show these, so the painted kit only reaches the Operative
			_part(part).material_override = _psx_material(GEAR_SKINS[part])
		for part in ["Helmet", "Vest", "Chest_rig", "Backpack", "Goggles", "Holster", "Knee_pads", "Shemag"]:
			_part(part).visible = part in DRESS[kind]
	_rig()
	if kind != Kind.OPERATIVE:
		_watch_screen()
	var root := skeleton.find_bone(UPPER_ROOT)
	for i in skeleton.get_bone_count():
		var b := i
		while b >= 0 and b != root:
			b = skeleton.get_bone_parent(b)
		if b == root:
			_upper_bones[skeleton.get_bone_name(i)] = i
	play("idle")


func _process(delta: float) -> void:
	_drive_rig(delta)
	_busy -= delta
	_since_step += delta
	if _since_step >= (STEP if _shown else OFFSCREEN_STEP):
		_anim.advance(_since_step)
		_layer(_since_step)
		_limp_pose()
		_cradle_arms(_holder)
		_since_step = 0.0
		if _weapon == "rifle":
			if (_clip in SQUARED or _upper_hold_w > 0.5) and (_shot == "" or _shot in SQUARED):  # not with a reload laid over the aim
				for i in 2:  # a second pass takes up what the first left
					_square_up()
				_brace()
				_turn(Vector3.RIGHT, -(AIM_PITCH - _muzzle_pitch()))  # leaning back raises it, the hands with it
			_brace()


## Lays the upper-body one-shot over the pose the base clip just set: each upper bone turns toward the shot's
## rotation by its weight, which eases in, holds, and eases back out when its time is up.
func _layer(delta: float) -> void:
	_layer_held(delta)
	if _shot == "":
		return
	_shot_t += delta * _shot_speed
	_shot_left -= delta
	_shot_w = move_toward(_shot_w, 1.0 if _shot_left > 0.0 else 0.0, delta / UPPER_FADE)
	if _shot_w <= 0.0:
		_shot = ""
		return
	var a := _anim.get_animation(_shot)
	var t := clampf(_shot_t, 0.0, a.length)
	for tb: Array in _shot_tracks:
		var q := a.rotation_track_interpolate(tb[0], t)
		skeleton.set_bone_pose_rotation(tb[1], skeleton.get_bone_pose_rotation(tb[1]).slerp(q, _shot_w))


## Lays the held upper clip over the base clip, under any one-shot: it loops, and eases in and out.
func _layer_held(delta: float) -> void:
	_upper_hold_w = move_toward(_upper_hold_w, 1.0 if _upper_hold != "" else 0.0, delta / UPPER_FADE)
	if _upper_hold_tracks.is_empty() or _upper_hold_w <= 0.0:
		return
	var a := _anim.get_animation(_upper_hold_tracks[0])
	_upper_hold_t = fmod(_upper_hold_t + delta, maxf(a.length, 0.01))
	for i in range(1, _upper_hold_tracks.size()):
		var tb: Array = _upper_hold_tracks[i]
		var q := a.rotation_track_interpolate(tb[0], _upper_hold_t)
		skeleton.set_bone_pose_rotation(tb[1], skeleton.get_bone_pose_rotation(tb[1]).slerp(q, _upper_hold_w))


## Holds `clip`'s upper body over whatever the legs play (the aim over a strafe); "" lets go. Without the clip
## (no Mixamo bake) it does nothing.
func hold_upper(clip: String) -> void:
	clip = _swapped(clip) if clip != "" else ""
	if clip != "" and not _anim.has_animation(clip):
		clip = ""
	if clip == _upper_hold:
		return
	_upper_hold = clip
	if clip != "":  # the clip's name first, then its [track, bone]s; kept while it eases out
		_upper_hold_tracks = [clip] + _upper_tracks(_anim.get_animation(clip))
		_upper_hold_t = 0.0


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
	var braced := Transform3D(HAND_TO_GUN, PALM + HAND_TO_GUN * -grip)
	if reach >= BRACE_REACH.x and reach <= BRACE_REACH.y:
		var x := (off - palm) / reach  # the muzzle
		var z := x.cross(hand * HAND_TO_GUN.y).normalized()
		x = (off - z.cross(x) * HANDGUARD - palm).normalized()  # dipped so the handguard, not the grip line, meets the hand
		z = x.cross(hand * HAND_TO_GUN.y).normalized()
		var aim := hand.inverse() * Basis(x, z.cross(x), z)
		braced = Transform3D(aim, PALM + aim * -grip)
	var w := _let_go()
	if w <= 0.0:
		_held = braced
	_gun.transform = braced.interpolate_with(_held, w)


## How far the off hand is off the rifle in a LET_GO one-shot, 0 (holding) to 1 (let go), eased at both ends.
func _let_go() -> float:
	if not LET_GO.has(_shot):
		return 0.0
	var u := _shot_t / maxf(_anim.get_animation(_shot).length, 0.01)
	var span: Array = LET_GO[_shot]
	return smoothstep(0.0, 1.0, minf(u - span[0], span[1] - u) / LET_GO_FADE) * _shot_w


## Pistol takes stand on both feet too.
func _feet_down() -> bool:
	return super() or _clip in PISTOL_CLIPS.values()


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
	for d: String in Locomotion.STRAFE_DIRS:  # the Pro Rifle pack's eight-way walks, for a strafe's legs
		for pair: Array in [["walk_", "pro_walk_"], ["crouch_walk_", "pro_walk_crouching_"]]:
			if mixamo.has_animation(pair[1] + d):
				lib.add_animation(pair[0] + d, mixamo.get_animation(pair[1] + d))
	for c in PISTOL_CLIPS.values():  # kept under their own names; play() swaps them in
		lib.add_animation(c, mixamo.get_animation(c))
	if mixamo.has_animation(HANG_FROM):  # a ledge climb's first beat, arms up, swung back and forth: hanging from a line
		var hang := mixamo.get_animation(HANG_FROM).duplicate() as Animation
		hang.length = HANG_LEN
		hang.loop_mode = Animation.LOOP_PINGPONG
		lib.add_animation("hang", hang)
	return lib


## Plays a one-shot over whatever the model was doing, squeezed into `seconds` (0 = its own length).
## speed > 0 plays the start of a long clip at that speed for `seconds` instead of squeezing it whole.
## from (s) skips the clip's own lead-in. An UPPER_CLIPS clip leaves the legs to play(); any other takes the
## whole body. Does nothing without the Mixamo bake.
func react(clip: String, seconds := 0.0, speed := 0.0, from := 0.0) -> void:
	if _limp != "":
		return
	var upper := clip in UPPER_CLIPS and kind != Kind.TARGET
	clip = _swapped(clip)
	if not _anim.has_animation(clip):
		return
	var length := _anim.get_animation(clip).length - from
	var time := seconds if seconds > 0.0 else length
	var rate := speed if speed > 0.0 else length / time
	if upper:
		if _shot != clip:
			_shot_tracks = _upper_tracks(_anim.get_animation(clip))
		_shot = clip
		_shot_t = from
		_shot_speed = rate
		_shot_left = time
		return
	_end_shot()
	_busy = time
	_clip = clip
	_anim.speed_scale = 1.0
	_anim.play(clip, 0.1, rate)
	if from > 0.0:
		_anim.seek(from)


## [track, bone] for each rotation track `a` keys on the upper body.
func _upper_tracks(a: Animation) -> Array:
	var out := []
	for i in a.get_track_count():
		var bone := String(a.track_get_path(i).get_concatenated_subnames())
		if a.track_get_type(i) == Animation.TYPE_ROTATION_3D and _upper_bones.has(bone):
			out.append([i, _upper_bones[bone]])
	return out


## Drops an upper-body one-shot at once: a whole-body clip, a ride or a fall takes over.
func _end_shot() -> void:
	_shot = ""
	_shot_w = 0.0


## Plays a looping clip. ground_speed (m/s) paces a clip baked with a "speed" meta so the feet keep up with the body.
func play(clip: String, ground_speed := 0.0) -> void:
	if _limp != "":
		return  # lying in someone's arms or hanging from a line, it is limp whatever the guard asks for
	clip = _swapped(clip)
	if _busy > 0.0:
		return
	if not _anim.has_animation(clip):  # carry_idle, crouch_aim, dead and the tasks are Mixamo only
		var walk := "crouch_walk" if clip.begins_with("crouch_walk_") else "walk" if clip.begins_with("walk_") else "idle"  # a strafe without its clip
		clip = {"dead": "down", "crouch_aim": "crouch_idle"}.get(clip, walk)
	if clip != _clip:
		_clip = clip
		_anim.play(clip, 0.2)
	var natural: float = _anim.get_animation(clip).get_meta("speed", 0.0)
	# ponytail: clamped so a mismatched clip (carry walk at full walk speed) skates a little instead of flailing
	_anim.speed_scale = clampf(ground_speed / natural, 0.6, 1.5) if natural > 0.0 and ground_speed > 0.0 else 1.0


## Plays the current clip at `rate` times its speed, after play(): 0 holds the pose, below 0 runs it backwards
## (a ladder climbed down).
func pace(rate: float) -> void:
	_anim.speed_scale = rate


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


## Knocks a worn Countermeasure piece off the head ("Helmet"): hidden on the body, a loose copy where it
## sat tumbles away at `push` m/s (Fx.tumble).
func knock_off(item: String, push: Vector3) -> void:
	var piece := _part(item)
	if not piece or not piece.visible or not is_inside_tree():
		return
	piece.visible = false
	var head := skeleton.find_bone("Head")
	var posed := skeleton.get_bone_global_pose(head) * skeleton.get_bone_global_rest(head).affine_inverse()
	var at := skeleton.global_transform * posed * skeleton.global_transform.affine_inverse() * piece.global_transform
	var copy := piece.duplicate() as MeshInstance3D
	copy.skin = null
	copy.skeleton = NodePath()
	copy.visible = true
	Fx.tumble(get_tree().current_scene if get_tree().current_scene else get_tree().root, copy, at, push)


func _part(part: String) -> MeshInstance3D:
	return skeleton.find_child(part, true, false)


## Hangs `node` (placed in model space) on a bone so it follows the pose.
func _on_bone(bone: String, node: Node3D) -> void:
	var at := BoneAttachment3D.new()
	at.bone_name = bone
	skeleton.add_child(at)
	node.transform = skeleton.get_bone_global_rest(skeleton.find_bone(bone)).affine_inverse() * node.transform
	at.add_child(node)


## Where a carried guard's model hangs: the carrier's model root, where the CRADLE pose lays it across his arms.
func carry_mount() -> Node3D:
	if not _holder:
		_holder = Node3D.new()
		add_child(_holder)
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
	_end_shot()
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


## On `mount` (a carry_mount) the model hangs limp over the shoulder; null puts it back where it was.
func ride(mount: Node3D) -> void:
	if mount:
		_end_shot()
		get_up(0.0)  # it is about to be moved onto the shoulder, so there is nothing to ease
		if not _home:
			_home = get_parent_node_3d()
		reparent(mount, false)
		physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF  # the carrier's pose moves per frame, not per tick
		# laid on its back across the carrier's arms: the rest pose, then _limp_pose() lets the limbs and head hang
		transform = CRADLE
		_limp = "cradle"
		_clip = "limp"
		_anim.speed_scale = 1.0
		_anim.play("RESET")
		_pose_now()  # not a frame of the standing rest pose first
	elif _home:
		_limp = ""
		reparent(_home, false)
		physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_INHERIT
		transform = Transform3D.IDENTITY
		reset_physics_interpolation()
		_home = null
		drop()  # put down: it slumps to the ground


## Applies the rest pose and the limp limbs this very frame, so a body that has just been put in someone's arms
## or on a line never shows the standing pose.
func _pose_now() -> void:
	_anim.advance(0.0)
	_limp_pose()


## Hangs from a Fulton line by the waist: the hips follow the line (the clip's rest pose) and every other bone is a
## ragdoll swinging from them. Returns the height (m above the model's origin) the cable must end at: the hips.
## The Target's rig has no physical bones, so it hangs by the chest in a posed limp instead.
func hang() -> float:
	_end_shot()
	get_up(0.0)
	_clip = "limp"
	_anim.speed_scale = 1.0
	_anim.play("RESET")
	if kind == Kind.TARGET:
		_limp = "hung"
		_pose_now()
		return HUNG_DROP
	_limp = "ragdoll"
	_anim.advance(0.0)  # standing at the line first, then the body goes physical
	if _ragdoll == null:
		_ragdoll = Ragdoll.new(skeleton)
		add_child(_ragdoll)
	_ragdoll.hang()
	return _bone_height("pelvis", 1.0)


func _bone_height(bone: String, fallback: float) -> float:
	var i := skeleton.find_bone(bone)
	if i < 0:
		return fallback
	return to_local(skeleton.to_global(skeleton.get_bone_global_rest(i).origin)).y
