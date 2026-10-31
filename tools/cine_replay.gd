## Replays one take so it can be edited and judged without playing the campaign. Needs a window (not --headless); a scene, not --script, so the autoloads (Mixer) exist:
##   godot --path . tools/cine_replay.tscn -- <area> --list
##   godot --path . tools/cine_replay.tscn -- <area> <take> [--step=0.5 | --at=1,2.5,8] [--variant=gorgo] [--no-sheet]
##   godot --path . tools/cine_replay.tscn -- <area> <take> --live [--loops=2]
## <area>: test_room, harbour, relay_station, research_annex, core. <take>: a node under the Area's Cine (CineIntro,
## CineOutro, CineOutroAlone, CineDescent, CineAscent...).
## Stills (default, every 0.5 s through the Operative's camera, HUD off) go to user://shots/replay_<area>_<take>_<t>.png and
## are tiled, in time order, into replay_<area>_<take>_sheet.png: one image shows the whole move. Their times and the take's
## length are printed. --live plays the take in real time through Cine (letterbox, lower-third, skip) and loops it.
## Edit tools/cine/<area>.gd, rebuild the Area (tools/build_<area>.gd), run this again.
extends Node

const AREAS := {
	test_room = "res://areas/test_room/test_room.tscn", harbour = "res://areas/harbour/harbour.tscn",
	relay_station = "res://areas/relay_station/relay_station.tscn", research_annex = "res://areas/research_annex/research_annex.tscn",
	core = "res://areas/core/core.tscn",
}
const SHEET_COLUMNS := 4
const CELL_WIDTH := 480

var _flags := {}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var pos: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.trim_prefix("--").split("=", true, 1)
			_flags[kv[0]] = kv[1] if kv.size() > 1 else "1"
		else:
			pos.append(a)
	if pos.is_empty() or not AREAS.has(pos[0]):
		push_error("usage: -- <area> [take] [--list|--live|--step=s|--at=s,s|--variant=v]; areas: %s" % ", ".join(AREAS.keys()))
		get_tree().quit(1)
		return
	var scene: Node = load(AREAS[pos[0]]).instantiate()
	get_tree().root.add_child(scene)
	var cine := scene.get_node_or_null("Cine")
	if cine == null:
		push_error("%s has no Cine node (rebuild it with tools/build_%s.gd)" % [pos[0], pos[0]])
		get_tree().quit(1)
		return
	if _flags.has("list") or pos.size() < 2:
		for t in cine.get_children():
			if t is AnimationPlayer:
				print("%s/%s  %.1f s" % [pos[0], t.name, t.get_animation("take").length])
		get_tree().quit()
		return
	var take := cine.get_node_or_null(pos[1]) as AnimationPlayer
	if take == null:
		push_error("no take %s under %s/Cine (--list shows them)" % [pos[1], pos[0]])
		get_tree().quit(1)
		return
	await get_tree().create_timer(3.0).timeout  # PropSkins swap in, shaders compile; any title card is gone
	get_tree().paused = false
	if _flags.has("variant"):
		_show_variant(scene, _flags.variant)
	if _flags.has("live"):
		await _live(scene, pos[1])
	else:
		await _stills(scene, pos[0], take)
	get_tree().quit()


func _show_variant(scene: Node, variant: String) -> void:
	var set_node := scene.get_node_or_null(AscentLogic.SET)
	if set_node and set_node.has_method("show_variant"):
		set_node.show_variant(variant)
	else:
		push_warning("--variant only applies to the Core's Ascent; ignored")


func _times(length: float) -> Array[float]:
	var out: Array[float] = []
	if _flags.has("at"):
		for s in String(_flags.at).split(",", false):
			out.append(clampf(s.to_float(), 0.0, length))
		return out
	var step := maxf(float(_flags.get("step", "0.5")), 0.05)
	var t := 0.0
	while t < length:
		out.append(t)
		t += step
	out.append(length)
	return out


func _stills(scene: Node, area: String, take: AnimationPlayer) -> void:
	var hud := scene.get_node_or_null("HudLayer")
	if hud:
		hud.visible = false
	scene.get_node("Operative").set("cine", true)
	DirAccess.make_dir_recursive_absolute("user://shots")
	var clip: Animation = take.get_animation("take")
	var images: Array[Image] = []
	print("%s/%s is %.1f s" % [area, take.name, clip.length])
	for t in _times(clip.length):
		take.play("take")
		take.seek(t, true)
		take.pause()
		await get_tree().create_timer(0.8).timeout  # the host takes the pcam, the aim catches up
		var img := get_viewport().get_texture().get_image()
		var path := "user://shots/replay_%s_%s_%05.2f.png" % [area, take.name, t]
		img.save_png(path)
		images.append(img)
		print("  %5.2f s  %s" % [t, ProjectSettings.globalize_path(path)])
	for p in take.get_meta("pcams", []):
		take.get_node(p).set("priority", 0)
	take.stop()
	if not _flags.has("no-sheet") and images.size() > 1:
		var sheet := _sheet(images)
		var sheet_path := "user://shots/replay_%s_%s_sheet.png" % [area, take.name]
		sheet.save_png(sheet_path)
		print("sheet (%d frames, left to right, top to bottom): %s" % [images.size(), ProjectSettings.globalize_path(sheet_path)])


func _sheet(images: Array[Image]) -> Image:
	var cell_h := int(CELL_WIDTH * float(images[0].get_height()) / images[0].get_width())
	var rows := ceili(images.size() / float(SHEET_COLUMNS))
	var sheet := Image.create(CELL_WIDTH * SHEET_COLUMNS, cell_h * rows, false, Image.FORMAT_RGB8)
	for i in images.size():
		var img := images[i].duplicate() as Image
		img.convert(Image.FORMAT_RGB8)
		img.resize(CELL_WIDTH, cell_h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(img, Rect2i(0, 0, CELL_WIDTH, cell_h), Vector2i(i % SHEET_COLUMNS * CELL_WIDTH, i / SHEET_COLUMNS * cell_h))
	return sheet


func _live(scene: Node, key: String) -> void:
	var loops := int(_flags.get("loops", "1"))
	for i in loops:
		var runner := Cine.new()
		runner.name = "ReplayRunner"
		scene.add_child(runner)
		var done := [false]
		if not runner.play(scene, key, func() -> void: done[0] = true):
			push_error("Cine could not play %s" % key)
			return
		while not done[0]:
			await get_tree().process_frame
		if is_instance_valid(runner):
			runner.queue_free()
		await get_tree().create_timer(1.0).timeout
