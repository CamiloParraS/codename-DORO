## Bakes the Targets' clips (PSX bodies) straight from Mixamo FBX files in _raw/. The male suit shares Mixamo's rig, so the
## tracks are copied as they are, with the hips travel scaled to the body's height; the female Lead Researcher rests differently
## and is retargeted bone by bone (_retarget). Gitignored like mixamo_clips.res; rebuild with  godot --headless --path . --script tools/bake_target.gd
extends SceneTree

## Body -> its bake.
const BODIES := {
	"res://assets/models/characters/target/target.fbx": "res://assets/models/animations/target_clips.res",
	"res://assets/models/characters/target/Character_23_Female_Doctor.fbx": "res://assets/models/animations/target_female_clips.res",
}
## Bodies whose bones rest differently from Mixamo's: their clips are retargeted rather than copied (_retarget).
const RETARGETED := ["res://assets/models/characters/target/Character_23_Female_Doctor.fbx"]
const FPS := 30.0
const SRC := "_raw/Models_Animations/animations/mixamo/"
## Game clip -> [file, loops]. Same names as the Quaternius set so CharacterModel.play() needs no special case.
const CLIPS := {
	"idle": ["_raw/work/aap/idle.fbx", true],
	"walk": [SRC + "Walking.fbx", true],
	"run": ["_raw/work/aap/running.fbx", true],
	"down": [SRC + "Sleeping Idle.fbx", false],
	"talk": [SRC + "Talking.fbx", false], "talk_b": [SRC + "Talking (1).fbx", false],  # gestures for react()
	# the guard reactions it shares through guard.gd: held up, startled, shot, searching, calling, killed
	"kneel": [SRC + "Taken Hostage - Victim.fbx", false], "startle": [SRC + "Surprised.fbx", false],
	"hit": ["_raw/work/mx_packs/Basic Shooter Pack/hit reaction.fbx", false], "look": [SRC + "Look Around.fbx", false],
	"hand_to_ear": [SRC + "Talking On Phone.fbx", false],
	"argue": [SRC + "Standing Arguing.fbx", false], "phone": [SRC + "Talking On Phone.fbx", false],
	"point": [SRC + "Pointing.fbx", false], "look_nervous": [SRC + "Nervously Look Around.fbx", false], "dead": ["_raw/work/mx_packs/Pro Rifle Pack/death from the front.fbx", false],
	# limp over the Operative's shoulder: the victim half of the pair with the Operative's "carrying" (a long take, so
	# CharacterModel plays it back and forth)
	"carried": [SRC + "carry anims/Being Carried (1).fbx", false],
}


## A looping clip's forward travel goes, or the model glides ahead and snaps back at each loop; the speed it was made
## at stays as the "speed" meta so CharacterModel.play() can pace the feet to the body.
func _strip_drift(a: Animation, track: int) -> void:
	var last := a.track_get_key_count(track) - 1
	var first: Vector3 = a.track_get_key_value(track, 0)
	var drift: Vector3 = a.track_get_key_value(track, last) - first
	drift.y = 0.0
	var pace := Vector2(drift.x, drift.z).length() / a.length
	if pace > 0.3:  # slower is an idle's sway, not a stride
		a.set_meta("speed", pace)
	for n in last + 1:
		a.track_set_key_value(track, n, a.track_get_key_value(track, n) - drift * (a.track_get_key_time(track, n) / a.length))


func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	for body in BODIES:
		_bake(body, BODIES[body])
	quit()


func _bake(body: String, out: String) -> void:
	var root := (load(body) as PackedScene).instantiate()
	var tgt: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
	var lib := AnimationLibrary.new()
	for clip in CLIPS:
		var state := FBXState.new()
		var doc := FBXDocument.new()
		if doc.append_from_file(ProjectSettings.globalize_path("res://") + CLIPS[clip][0], state) != OK:
			push_error("cannot read " + CLIPS[clip][0])
			continue
		var scene := doc.generate_scene(state)
		var src: Skeleton3D = scene.find_children("*", "Skeleton3D", true, false)[0]
		var a: Animation = (scene.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation("mixamo_com").duplicate()
		var k := tgt.get_bone_global_rest(0).origin.y / src.get_bone_global_rest(0).origin.y
		if body in RETARGETED:
			a = _retarget(src, a, tgt, String(root.get_path_to(tgt)), k)
		else:
			for i in a.get_track_count():
				if a.track_get_type(i) == Animation.TYPE_POSITION_3D:
					for n in a.track_get_key_count(i):
						a.track_set_key_value(i, n, a.track_get_key_value(i, n) * k)
		for i in a.get_track_count():
			if a.track_get_type(i) == Animation.TYPE_POSITION_3D and CLIPS[clip][1]:
				_strip_drift(a, i)
		a.loop_mode = Animation.LOOP_LINEAR if CLIPS[clip][1] else Animation.LOOP_NONE
		lib.add_animation(clip, a)
		scene.free()
	print("baked ", out, " ", lib.get_animation_list())
	ResourceSaver.save(lib, out)


## Copying Mixamo's tracks as they are only fits a body that rests the way Mixamo's does. On another rig (the female
## body: its hips and limbs rest turned), each bone takes the world rotation its Mixamo twin made since rest, as
## tools/bake_mixamo.gd does for Nikita; bones without a twin (the fingers) are left out.
func _retarget(src: Skeleton3D, from: Animation, tgt: Skeleton3D, prefix: String, k: float) -> Animation:
	var out := Animation.new()
	out.length = from.length
	var pairs := []  # [source bone, target bone, rotation track]
	for i in tgt.get_bone_count():
		var s := src.find_bone(tgt.get_bone_name(i))
		if s >= 0:
			var track := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(track, NodePath("%s:%s" % [prefix, tgt.get_bone_name(i)]))
			pairs.append([s, i, track])
	var hips := out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(hips, NodePath("%s:mixamorig_Hips" % prefix))
	var src_hips := src.find_bone("mixamorig_Hips")
	var times := []
	for n in int(from.length * FPS) + 1:
		times.append(n / FPS)
	if absf(times[-1] - from.length) > 0.001:
		times.append(from.length)
	for t in times:
		src.reset_bone_poses()
		for i in from.get_track_count():
			var bone := src.find_bone(String(from.track_get_path(i)).get_slice(":", 1))
			if bone < 0:
				continue
			if from.track_get_type(i) == Animation.TYPE_POSITION_3D:
				src.set_bone_pose_position(bone, from.position_track_interpolate(i, t))
			elif from.track_get_type(i) == Animation.TYPE_ROTATION_3D:
				src.set_bone_pose_rotation(bone, from.rotation_track_interpolate(i, t))
		var posed: Array[Transform3D] = []  # source bone -> world transform (Skeleton3D's own cache goes stale off the tree)
		for i in src.get_bone_count():
			var parent := src.get_bone_parent(i)
			posed.append((posed[parent] if parent >= 0 else Transform3D.IDENTITY) * src.get_bone_pose(i))
		var delta := {}  # target bone -> the world rotation its twin made since rest
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
			var parent := tgt.get_bone_parent(pr[1])
			var up: Basis = world[parent] if parent >= 0 else Basis.IDENTITY
			out.rotation_track_insert_key(pr[2], t, (up.inverse() * world[pr[1]]).get_rotation_quaternion())
		out.position_track_insert_key(hips, t, posed[src_hips].origin * k)
	return out
