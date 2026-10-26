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
}


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
		a.loop_mode = Animation.LOOP_LINEAR if CLIPS[clip][1] else Animation.LOOP_NONE
		lib.add_animation(clip, a)
		scene.free()
	print("baked ", lib.get_animation_list())
	ResourceSaver.save(lib, OUT)
	quit()
