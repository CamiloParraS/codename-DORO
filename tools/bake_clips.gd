## Bakes the Quaternius Universal Animation Library clips the game uses into one AnimationLibrary.
## Both libraries and the Superhero body share the UE skeleton, so the tracks bind as they are.
## Run with the two UAL*_Standard.glb files copied into assets/models/animations/, then delete them:
##   godot --headless --path . --script tools/bake_clips.gd
extends SceneTree

const DIR := "res://assets/models/animations/"
# game clip -> [file, source clip, loops]
const CLIPS := {
	"idle": ["UAL1_Standard.glb", "Idle", true],
	"walk": ["UAL1_Standard.glb", "Walk", true],
	"run": ["UAL1_Standard.glb", "Jog_Fwd", true],
	"crouch_idle": ["UAL1_Standard.glb", "Crouch_Idle", true],
	"crouch_walk": ["UAL1_Standard.glb", "Crouch_Fwd", true],
	"aim": ["UAL1_Standard.glb", "Pistol_Aim_Neutral", true],
	"takedown": ["UAL1_Standard.glb", "Punch_Cross", false],
	"down": ["UAL1_Standard.glb", "Death01", false],
	"carry": ["UAL2_Standard.glb", "Walk_Carry", true],
}


func _init() -> void:
	var lib := AnimationLibrary.new()
	var scenes := {}
	for clip in CLIPS:
		var file: String = CLIPS[clip][0]
		if not scenes.has(file):
			scenes[file] = (load(DIR + file) as PackedScene).instantiate()
		var player: AnimationPlayer = scenes[file].find_children("*", "AnimationPlayer", true, false)[0]
		var a: Animation = player.get_animation(CLIPS[clip][1]).duplicate()
		a.loop_mode = Animation.LOOP_LINEAR if CLIPS[clip][2] else Animation.LOOP_NONE
		lib.add_animation(clip, a)
	print("baked ", lib.get_animation_list())
	ResourceSaver.save(lib, DIR + "clips.res")
	quit()
