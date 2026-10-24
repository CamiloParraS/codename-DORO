## Prints "path|length|travel_x|travel_z|ymin|ymax" per FBX under the dirs given after `--`, hips scaled by rest height
## so 2x-exported files compare equal. Used to match numbered Mixamo downloads to the named pack files.
extends SceneTree


func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	for dir in OS.get_cmdline_user_args():
		_walk(dir)
	quit()


func _walk(dir: String) -> void:
	for d in DirAccess.get_directories_at(dir):
		_walk(dir + "/" + d)
	for f in DirAccess.get_files_at(dir):
		if f.get_extension().to_lower() != "fbx":
			continue
		var state := FBXState.new()
		var doc := FBXDocument.new()
		if doc.append_from_file(dir + "/" + f, state) != OK:
			continue
		var scene := doc.generate_scene(state)
		var players := scene.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			scene.free()
			continue
		var a: Animation = players[0].get_animation("mixamo_com") if players[0].has_animation("mixamo_com") else players[0].get_animation(players[0].get_animation_list()[-1])
		for t in a.get_track_count():
			if a.track_get_type(t) == Animation.TYPE_POSITION_3D and str(a.track_get_path(t)).ends_with("Hips"):
				var n := a.track_get_key_count(t)
				var p0: Vector3 = a.track_get_key_value(t, 0)
				var p1: Vector3 = a.track_get_key_value(t, n - 1)
				var lo := 1e9
				var hi := -1e9
				for i in n:
					var y: float = a.track_get_key_value(t, i).y
					lo = minf(lo, y)
					hi = maxf(hi, y)
				var s := 1.0 / p0.y
				print("%s/%s|%.2f|%.2f|%.2f|%.2f|%.2f" % [dir, f, a.length, (p1.x - p0.x) * s, (p1.z - p0.z) * s, lo * s, hi * s])
				break
		scene.free()
