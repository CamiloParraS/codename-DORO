## A Quaternius body on the UE skeleton, driven by the baked clips. Nikita's Helmet and Vest ride on bones
## as props; the Target variant gets a red beret. Faces -Z like the actors that own it.
class_name CharacterModel
extends Node3D

enum Kind { OPERATIVE, GUARD, TARGET }

const BODY := preload("res://assets/models/characters/Superhero_Male_FullBody.gltf")
const NIKITA := preload("res://assets/models/nikita/NikitaMesh_A_Pose.gltf")
const CLIPS := preload("res://assets/models/animations/clips.res")
const TINTS := {
	Kind.OPERATIVE: Color(0.3, 0.36, 0.5),
	Kind.GUARD: Color(0.34, 0.38, 0.26),
	Kind.TARGET: Color(0.95, 0.4, 0.35),
}
## Nikita's parts: bone they ride on, colour. Helmet and Vest are the guard Countermeasures, the rest dress the kind.
const GEAR := {
	Helmet = ["Head", Color(0.22, 0.26, 0.2)],
	Vest = ["spine_03", Color(0.12, 0.14, 0.2)],
	Chest_rig = ["spine_03", Color(0.2, 0.2, 0.16)],
	Backpack = ["spine_03", Color(0.18, 0.2, 0.26)],
	Goggles = ["Head", Color(0.05, 0.05, 0.06)],
}
const DRESS := {Kind.OPERATIVE: ["Backpack", "Goggles"], Kind.GUARD: ["Chest_rig"], Kind.TARGET: []}
const CARRY_BONE := "spine_03"
const BERET_AT := Vector3(0, 1.8, 0.01)  # model space, on the crown
const CARRIED := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(0, 1.2, -0.1))  # fixed pose on the shoulder

@export var kind := Kind.GUARD

var skeleton: Skeleton3D
var _anim := AnimationPlayer.new()
var _clip := ""
var _home: Node3D    # where the model lives while it rides someone's shoulder
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
	var body := BODY.instantiate()
	body.rotation.y = PI  # the rig faces +Z
	add_child(body)
	skeleton = body.find_children("*", "Skeleton3D", true, false)[0]
	body.add_child(_anim)
	_anim.add_animation_library("", CLIPS)
	var mesh: MeshInstance3D = body.find_children("SuperHero_Male", "MeshInstance3D", true, false)[0]
	var mat: StandardMaterial3D = mesh.get_active_material(0).duplicate()
	mat.albedo_color = TINTS[kind]
	mesh.material_override = mat
	if kind == Kind.TARGET:
		var beret := MeshInstance3D.new()
		var dome := SphereMesh.new()
		dome.radius = 0.14
		dome.height = 0.14
		beret.mesh = dome
		var red := StandardMaterial3D.new()
		red.albedo_color = Color(0.6, 0.05, 0.05)
		beret.material_override = red
		beret.position = BERET_AT
		_on_bone("Head", beret)
	for item in DRESS[kind]:
		wear(item)
	play("idle")


func play(clip: String) -> void:
	if clip == _clip:
		return
	_clip = clip
	_anim.play(clip, 0.2)


## One of Nikita's GEAR parts, in place on the body.
func wear(item: String) -> void:
	var src := NIKITA.instantiate()
	var piece: MeshInstance3D = src.get_node(item)
	src.remove_child(piece)
	src.free()
	piece.name = item
	var paint := StandardMaterial3D.new()
	paint.albedo_color = GEAR[item][1]
	piece.material_override = paint
	_on_bone(GEAR[item][0], piece)


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
		_anim.seek(CLIPS.get_animation("down").length, true)
	elif _home:
		reparent(_home, false)
		transform = Transform3D.IDENTITY
		_home = null
