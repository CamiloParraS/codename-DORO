## Retargets the Mixamo FBX clips in _raw/ onto Nikita's UE skeleton and bakes them into mixamo_clips.res, keyed at
## KEY_FPS (CharacterModel steps playback for the PSX look). The result is gitignored (Mixamo's terms
## forbid redistributing the animation files): every clone rebuilds it with
##   godot --headless --path . --script tools/bake_mixamo.gd
## Both rigs rest in a T-pose facing +Z, so each mapped bone just copies the world-space rotation its Mixamo twin
## made since rest. Fingers are skipped (Nikita has mitts); the hips translation is scaled to Nikita's leg length.
## A looping clip keeps the ground speed it was made at as the "speed" meta (m/s), so playback can match the feet to
## how fast the body really moves.
extends SceneTree

## Folder -> prefix for its clip names. The packs are unzipped from mixamo/*.zip; their prefixes keep them apart from
## the loose downloads of the same name.
const SRC := {
	"_raw/Models_Animations/animations/mixamo/": "", "_raw/Models_Animations/animations/mixamo/carry anims/": "",
	"_raw/work/mx_packs/Pro Rifle Pack/": "pro_", "_raw/work/mx_packs/Pistol_Handgun Locomotion Pack/": "hg_",
}
const OUT := "res://assets/models/animations/mixamo_clips.res"
const BODY := "res://assets/models/characters/Nikita_Rigged.glb"
const KEY_FPS := 30.0
const LOOPS := ["idle", "walk", "strafe", "aim", "carrying", "pistol_run", "rifle_run", "pro_run", "pro_sprint"]  # clips whose name contains one of these loop
const BONES := {
	"Hips": "pelvis", "Spine": "spine_01", "Spine1": "spine_02", "Spine2": "spine_03", "Neck": "neck_01",
	"Head": "Head", "LeftShoulder": "clavicle_l", "LeftArm": "upperarm_l", "LeftForeArm": "lowerarm_l",
	"LeftHand": "hand_l", "RightShoulder": "clavicle_r", "RightArm": "upperarm_r", "RightForeArm": "lowerarm_r",
	"RightHand": "hand_r", "LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l", "LeftToeBase": "ball_l",
	"RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r", "RightToeBase": "ball_r",
}


func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var tgt: Skeleton3D = (load(BODY) as PackedScene).instantiate().find_children("*", "Skeleton3D", true, false)[0]
	var lib := AnimationLibrary.new()
	for rel in SRC:
		_bake_dir(ProjectSettings.globalize_path("res://") + rel, SRC[rel], lib, tgt)
	print("baked ", lib.get_animation_list())
	ResourceSaver.save(lib, OUT)
	quit()


func _bake_dir(dir: String, prefix: String, lib: AnimationLibrary, tgt: Skeleton3D) -> void:
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() != "fbx":
			continue
		var state := FBXState.new()
		var doc := FBXDocument.new()
		if doc.append_from_file(dir + file, state) != OK:
			push_error("cannot read " + file)
			continue
		var scene := doc.generate_scene(state)
		var src: Skeleton3D = scene.find_children("*", "Skeleton3D", true, false)[0]
		var player: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
		if not player.has_animation("mixamo_com"):  # the packs' Remy.fbx is the mesh alone
			scene.free()
			continue
		var name := prefix + file.get_basename().to_lower().replace(" (", "_").replace(")", "").replace(" ", "_")
		var a := _retarget(src, player.get_animation("mixamo_com"), tgt, LOOPS.any(func(l): return name.contains(l)))
		a.loop_mode = Animation.LOOP_LINEAR if LOOPS.any(func(l): return name.contains(l)) else Animation.LOOP_NONE
		lib.add_animation(name, a)
		scene.free()


func _retarget(src: Skeleton3D, from: Animation, tgt: Skeleton3D, loops: bool) -> Animation:
	var pairs := []  # [source bone, target bone, track index of its rotation, track index of its position or -1]
	var out := Animation.new()
	out.length = from.length
	var k := tgt.get_bone_global_rest(tgt.find_bone("pelvis")).origin.y / src.get_bone_global_rest(src.find_bone("mixamorig_Hips")).origin.y
	for m in BONES:
		var s := src.find_bone("mixamorig_" + m)
		var t := tgt.find_bone(BONES[m])
		var track := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(track, NodePath("Armature/Skeleton3D:" + BONES[m]))
		pairs.append([s, t, track])
	var hips := out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(hips, NodePath("Armature/Skeleton3D:pelvis"))

	var times := []
	for n in int(from.length * KEY_FPS) + 1:
		times.append(n / KEY_FPS)
	if absf(times[-1] - from.length) > 0.001:
		times.append(from.length)
	var rest_hips := src.get_bone_global_rest(src.find_bone("mixamorig_Hips")).origin
	var pelvis := tgt.find_bone("pelvis")
	var above := tgt.get_bone_global_rest(tgt.get_bone_parent(pelvis)).affine_inverse()
	var moves: Array[Vector3] = []
	for t in times:
		src.reset_bone_poses()
		for i in from.get_track_count():
			var bone := src.find_bone(String(from.track_get_path(i)).get_slice(":", 1))
			if bone < 0:
				continue
			var type := from.track_get_type(i)
			if type == Animation.TYPE_POSITION_3D:
				src.set_bone_pose_position(bone, from.position_track_interpolate(i, t))
			elif type == Animation.TYPE_ROTATION_3D:
				src.set_bone_pose_rotation(bone, from.rotation_track_interpolate(i, t))
		var posed: Array[Transform3D] = []  # source bone -> world transform (Skeleton3D's own cache goes stale off the tree)
		for i in src.get_bone_count():
			var parent := src.get_bone_parent(i)
			posed.append((posed[parent] if parent >= 0 else Transform3D.IDENTITY) * src.get_bone_pose(i))
		var delta := {}  # target bone -> the world rotation its Mixamo twin made since rest
		for pr in pairs:
			delta[pr[1]] = posed[pr[0]].basis.orthonormalized() * src.get_bone_global_rest(pr[0]).basis.orthonormalized().inverse()
		var world := {}  # target bone -> its new world basis (bones are listed parents first)
		for i in tgt.get_bone_count():
			if delta.has(i):
				world[i] = delta[i] * tgt.get_bone_global_rest(i).basis
			else:
				var parent := tgt.get_bone_parent(i)
				world[i] = (world[parent] if parent >= 0 else Basis.IDENTITY) * tgt.get_bone_rest(i).basis
		for pr in pairs:
			var up: Basis = world[tgt.get_bone_parent(pr[1])]
			out.rotation_track_insert_key(pr[2], t, (up.inverse() * world[pr[1]]).get_rotation_quaternion())
		var moved := (posed[0].origin - rest_hips) * k
		moves.append(moved)
	var pace := Vector2(moves[-1].x - moves[0].x, moves[-1].z - moves[0].z).length() / from.length
	if loops and pace > 0.3:  # slower is an idle's sway, not a stride
		out.set_meta("speed", pace)
	for n in times.size():
		var m: Vector3 = moves[n]
		if loops:  # the clip's forward travel goes, or the model glides ahead and snaps back at each loop
			var drift: Vector3 = moves[-1] - moves[0]
			m -= Vector3(drift.x, 0, drift.z) * (times[n] / from.length)
		out.position_track_insert_key(hips, times[n], above * (tgt.get_bone_global_rest(pelvis).origin + m))
	return out
