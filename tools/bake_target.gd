## Bakes the Target's clips (the PSX suit, Mixamo rig) straight from Mixamo FBX files in _raw/: same skeleton, so the
## tracks are copied as they are, with the hips travel scaled to this body's height. Gitignored like mixamo_clips.res;
## rebuild with  godot --headless --path . --script tools/bake_target.gd
extends SceneTree

const OUT := "res://assets/models/animations/target_clips.res"
const BODY := "res://assets/models/characters/target/target.fbx"
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
	var tgt: Skeleton3D = (load(BODY) as PackedScene).instantiate().find_children("*", "Skeleton3D", true, false)[0]
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
		for i in a.get_track_count():
			if a.track_get_type(i) == Animation.TYPE_POSITION_3D:
				for n in a.track_get_key_count(i):
					a.track_set_key_value(i, n, a.track_get_key_value(i, n) * k)
				if CLIPS[clip][1]:
					_strip_drift(a, i)
		a.loop_mode = Animation.LOOP_LINEAR if CLIPS[clip][1] else Animation.LOOP_NONE
		lib.add_animation(clip, a)
		scene.free()
	print("baked ", lib.get_animation_list())
	ResourceSaver.save(lib, OUT)
	quit()
