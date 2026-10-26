## The UI pass's screenshots: every screen at 854x480 and fullscreen, plus the HUD in the three moods
## (Harbour, Core, Annex) under Evasion and Alert. Needs a window (not --headless), and runs as a scene so
## the autoloads exist:
##   godot --path . tools/ui_shots.tscn -- <out dir> [es]
## "es" shoots the Spanish pass at 854x480 only. The driver lives on the root, so it outlives scene changes.
extends Node

const MENU := "res://ui/main_menu/main_menu.tscn"

var out := ""
var lang := "en"
var sizes: Array = ["854x480", "full"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() else ProjectSettings.globalize_path("user://ui_shots")
	if args.size() > 1:
		lang = args[1]
		sizes = ["854x480"]
	DirAccess.make_dir_recursive_absolute(out)
	var stand_in := Node.new()  # the "current scene" scene changes free, so this driver survives them
	get_tree().root.add_child.call_deferred(stand_in)
	(func() -> void: get_tree().current_scene = stand_in).call_deferred()
	_run.call_deferred()


func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func shoot(name_: String) -> void:
	for sz: String in sizes:
		if sz == "full":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(854, 480))
		await wait(0.5)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := "%s/%s_%s.png" % [out, name_, sz]
		img.save_png(path)
		print("saved ", path, " ", img.get_size())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(854, 480))


func scene(path: String) -> Node:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
	await wait(0.3)
	TranslationServer.set_locale(lang)  # the main menu applies the settings file's language
	return get_tree().current_scene


func _record(mission: int) -> Dictionary:
	var r := Aigis.preset_record("ghost", mission)
	return r


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(854, 480))
	var all := lang == "en"
	# --- menus
	if all:
		await scene(MENU)
		await wait(0.6)
		await shoot("main_menu")
		var menu: Node = get_tree().current_scene
		var slot := {record = _record(2), gear = Requisition.new(), missions = {
			"0": {pre = _record(0), best = {rank = "A", time = 412.0, kills = 0, alerts = 1}},
			"1": {pre = _record(1), best = {rank = "S", time = 355.0, kills = 0, alerts = 0}}}}
		menu._missions(0, slot)
		await wait(0.6)
		await shoot("mission_select")
		menu._main()
		menu._settings()
		await wait(0.6)
		await shoot("settings")
		await scene("res://ui/free_mode/free_mode.tscn")
		await wait(0.6)
		await shoot("free_mode")
	# --- briefing, requisition, codec
	Campaign.start()
	Campaign.slot = -1
	Campaign.record = _record(1)
	Campaign.gear = Requisition.new()
	Campaign.gear.points = 7
	Campaign.gear.signed = 4
	var brief: Node = await scene("res://ui/briefing/briefing.tscn")
	await wait(0.5)
	brief._blips.map(func(b: VoiceBlip) -> void: b.skip())
	brief.queue_redraw()
	await wait(0.6)
	await shoot("briefing")
	brief.open_requisition()
	await wait(0.6)
	await shoot("requisition")
	brief.get_node("Requisition").close()
	await wait(0.6)
	brief._open_codec()
	await wait(0.6)
	var codec: CodecScreen = brief.get_child(brief.get_child_count() - 1)
	codec.talk.press()  # reveal the first line
	codec.talk.press()
	await wait(2.0)
	codec.talk.press()
	await wait(0.2)
	await shoot("codec")
	# --- in play: the Harbour with Aigis awake
	await _area(0, 2)
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	var op: Node = get_tree().get_first_node_in_group("operative")
	var hud: Node = get_tree().get_first_node_in_group("radio_log")
	op.voiceprints.held.append_array(["GuardPA", "Kostas", "Dimos", "Eleni"])
	await wait(1.0)
	await shoot("hud_normal")
	hud.tip(tr("tutorial.holdup.prompt"))
	hud.live_call([["analyst", "live.m1.s1.01"]])
	hud.say("METIS", tr("hint.m1.s2.2"))
	hud.say("Foreman", tr("holdup.lift_code"))
	await wait(4.0)
	await shoot("hud_busy")
	get_tree().get_first_node_in_group("radio")._open()
	await wait(0.6)
	await shoot("radio")
	get_tree().get_first_node_in_group("radio").close()
	_phase("caution")
	await wait(0.4)
	await shoot("hud_caution")
	_phase("")
	if all:
		hud.get_parent().get_node("Pause")._show(true)
		await wait(0.6)
		await shoot("pause")
		hud.get_parent().get_node("Pause")._show(false)
		await wait(0.6)
	run.game_over()
	await wait(0.8)
	await shoot("game_over")
	await _post(run)
	if not all:
		get_tree().quit()
		return
	await _moods()
	get_tree().quit()


## Loads Mission `mission`'s Area through the campaign, then poses it as Mission `as_mission` so Aigis is awake.
func _area(mission: int, as_mission: int) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Campaign.record = _record(mission)
	Campaign.play(get_tree(), Campaign.record, MENU, true)
	await wait(3.0)
	TranslationServer.set_locale(lang)
	var run: Node = get_tree().get_first_node_in_group("mission_plan")
	run.record = _record(as_mission)
	run.record.mission = as_mission
	run.plan = Aigis.plan_mission(run.record.points, Aigis.lethality_ratio(run.record), as_mission)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _phase(which: String) -> void:
	var c := AlertChain.new()
	if which != "":
		var g: Node = get_tree().get_nodes_in_group("guards")[0]
		c.start_call(String(g.name), g.global_position)
		c.tick(2.0, false)
		c.tick(1.0, false)
		if which in ["evasion", "caution"]:
			c.tick(19.0, false)
			c.tick(15.0, false)
		if which == "caution":
			c.tick(15.0, false)
	AlertChain.area = c


func _post(run: Node) -> void:
	get_tree().paused = false
	for c in run.get_children():
		if c is CanvasLayer:
			c.queue_free()
	await wait(0.3)
	var s: Control = run.SCREEN.new()
	var r := Rank.new()
	r.seconds = 412.0
	r.alerts = 1
	r.found = 1
	s.rank = r
	s.par = Rank.par(1)
	var after := run.record.duplicate(true)
	after.points.stealth = int(after.points.get("stealth", 0)) + 150
	after.points.downs = maxi(int(after.points.get("downs", 0)) - 60, 0)
	s.strip = MissionTally.strip(run.record, after)
	s.voice_key = "post.pallas.clean"
	run._overlay(s)
	get_tree().paused = true
	await wait(3.5)
	await shoot("post_mission_rank")
	s.advance()
	await wait(2.5)
	await shoot("post_mission_aigis")
	s.queue_free()
	get_tree().paused = false


## The HUD in the three moods: Harbour, Core (darkest), Annex (brightest), each under Evasion and Alert.
func _moods() -> void:
	for m: Array in [["harbour", 0, 2], ["core", 3, 3], ["annex", 2, 2]]:
		await _area(m[1], m[2])
		var op: Node = get_tree().get_first_node_in_group("operative")
		op.voiceprints.held.append_array(["Kostas", "Dimos"])
		if m[0] != "harbour":
			_phase("")
			await wait(1.0)
			await shoot("hud_" + m[0])
		for ph in ["evasion", "alert"]:
			_phase(ph)
			await wait(0.6)
			await shoot("phase_%s_%s" % [m[0], ph])
