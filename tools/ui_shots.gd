## The UI pass's screenshots: every screen at 854x480 and fullscreen, plus the HUD in the three moods
## (Harbour, Core, Annex) under Evasion and Alert. Needs a window (not --headless), and runs as a scene so
## the autoloads exist:
##   godot --path . tools/ui_shots.tscn -- <out dir> [es|radio]
## Extra args, in any order after the out dir:
##   only=a,b   shoot just the shots whose name is `a` or starts with `a` (`only=codec,hud`), and skip the setup the rest need
##   es         the Spanish pass          radio   the radio mode in all four Areas
##   full       also shoot fullscreen (any extra arg otherwise limits the run to 854x480)
## Every run ends by writing <out dir>/index.html: a contact sheet of all PNGs there (this run's marked new).
## The driver lives on the root, so it outlives scene changes.
extends Node

const MENU := "res://ui/main_menu/main_menu.tscn"

var out := ""
var lang := "en"
var radio_only := false
var sizes: Array = ["854x480", "full"]
var only: Array = []
var taken: Array[String] = []  # PNG file names written by this run


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() else ProjectSettings.globalize_path("user://ui_shots")
	if args.size() > 1:
		sizes = ["854x480"]
		for a: String in args.slice(1):
			if a == "radio":
				radio_only = true
			elif a == "full":
				sizes = ["854x480", "full"]
			elif a.begins_with("only="):
				only = Array(a.trim_prefix("only=").split(",", false))
			else:
				lang = a
	DirAccess.make_dir_recursive_absolute(out)
	var stand_in := Node.new()  # the "current scene" scene changes free, so this driver survives them
	get_tree().root.add_child.call_deferred(stand_in)
	(func() -> void: get_tree().current_scene = stand_in).call_deferred()
	_run.call_deferred()


func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


## Whether a shot called `name_` was asked for: no filter means all, else its name or a prefix of it.
func want(name_: String) -> bool:
	return only.is_empty() or only.any(func(f: String) -> bool: return name_.begins_with(f))


## Whether any of `names` was asked for: the test for a setup that only feeds those shots.
func any_of(names: Array) -> bool:
	return names.any(want)


func shoot(name_: String) -> void:
	if not want(name_):
		return
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
		taken.append(path.get_file())
		print("saved ", path, " ", img.get_size())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(854, 480))


func scene(path: String) -> Node:
	get_tree().paused = false
	Engine.time_scale = 1.0
	TranslationServer.set_locale(lang)  # before the scene builds its labels: a filtered run skips the main menu, which applies the settings file's language
	get_tree().change_scene_to_file(path)
	await wait(0.3)
	TranslationServer.set_locale(lang)
	return get_tree().current_scene


func _record(mission: int) -> Dictionary:
	var r := Aigis.preset_record("ghost", mission)
	return r


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(854, 480))
	if radio_only:
		await _radio_shots()
		_finish()
		return
	var all := lang == "en"
	# --- menus
	if all and any_of(["title", "main_menu", "mission_select", "settings"]):
		await scene(MENU)
		await wait(0.6)
		await shoot("title")
		var menu: Node = get_tree().current_scene
		menu._on_title = false
		menu._press.hide()
		menu._main()
		await wait(0.8)
		await shoot("main_menu")
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
	if all and want("free_mode"):
		await scene("res://ui/free_mode/free_mode.tscn")
		await wait(0.6)
		await shoot("free_mode")
	if all:
		await _cards()
	if all and any_of(["finale_debate", "finale_ending"]):
		var fin := Control.new()  # the finale: the ending over its still
		fin.set_script(load("res://ui/finale/finale.gd"))
		get_tree().root.add_child(fin)
		fin.start(_record(1), MENU)
		fin.model.stage = "debate"
		fin._play(Finale.debate(fin.model.band, fin.model.spoofing))
		await wait(1.5)
		await shoot("finale_debate")
		fin.model.stage = "ending"
		fin._play(Finale.ending(fin.model.band))
		await wait(1.5)
		await shoot("finale_ending")
		fin.queue_free()
		get_tree().paused = false
		Engine.time_scale = 1.0
	if all and want("debug_overlay"):
		DebugOverlay.visible = true
		await wait(0.5)
		await shoot("debug_overlay")
		DebugOverlay.visible = false
	# --- briefing, requisition, codec
	if any_of(["briefing", "requisition", "codec"]):
		await _briefing()
	# --- in play: the Harbour with Aigis awake
	if not any_of(["hud_normal", "hud_busy", "radio", "hud_caution", "pause", "game_over", "post_mission_rank", "post_mission_aigis"]):
		if all:
			await _moods()
		_finish()
		return
	await _play_shots(all)
	_finish()


func _briefing() -> void:
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
	await shoot("codec_ring")
	codec._ringing = false  # answered
	codec._burst = 0.0
	codec.talk.press()  # reveal the first line
	codec.talk.press()
	await wait(2.0)
	codec.talk.press()
	await wait(0.2)
	await shoot("codec")


## The Harbour with Aigis awake: the HUD busy, the radio, pause, game over and the post-Mission screen, then the moods.
func _play_shots(all: bool) -> void:
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
	if all:
		await _moods()


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


## The radio mode at the confirm step in each Area: a guard and the farthest Radio point lit, the speaker too.
func _radio_shots() -> void:
	for m: Array in [["harbour", 0], ["relay", 1], ["annex", 2], ["core", 3]]:
		if not any_of(["radio_" + m[0], "radio_beat_" + m[0]]):
			continue
		await _area(m[1], maxi(m[1], 2))
		var op: Node = get_tree().get_first_node_in_group("operative")
		var radio: Node = get_tree().get_first_node_in_group("radio")
		var guards: Array = get_tree().get_nodes_in_group("guards")
		guards.sort_custom(func(a, b) -> bool: return a.global_position.distance_to(op.global_position) < b.global_position.distance_to(op.global_position))
		op.voiceprints.held.append(String(guards[-1].name))
		radio._open()
		var menu: RadioMenu = radio.menu
		var places: Array = radio._places.keys()
		places.sort_custom(func(a, b) -> bool: return radio._places[a].distance_to(op.global_position) > radio._places[b].distance_to(op.global_position))
		menu.choose(0)  # speaker: the farthest guard
		menu.choose(menu.options().find_custom(func(o) -> bool: return o[0] == String(guards[0].name)))  # nearest guard
		menu.choose(0)  # Go check
		menu.choose(menu.options().find_custom(func(o) -> bool: return o[0] == places[0]))
		await wait(1.0)
		await shoot("radio_" + m[0])
		radio._choose(0)  # Send: the beat plays
		await wait(0.55)
		await shoot("radio_beat_" + m[0])
		await wait(1.0)


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
	var after: Dictionary = run.record.duplicate(true)
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
		if not any_of(["hud_" + m[0], "phase_" + m[0]]):
			continue
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


## The Mission cards over black, held at full light: Mission 1's title card and its extraction card.
func _cards() -> void:
	var m: Dictionary = Campaign.MISSIONS[0]
	var cards := {
		mission_card_intro = [[m.intro.name, m.intro.area, m.intro.stamp], true],
		mission_card_outro = [[m.outro.title, m.outro.line], false],
	}
	TranslationServer.set_locale(lang)
	for n: String in cards:
		if not want(n):
			continue
		var card := MissionCard.build(cards[n][0], cards[n][1], false)
		get_tree().root.add_child(card)
		await wait(StoryMotion.CARD_FADE + 0.6)
		card.set_process(false)  # hold it: the card frees itself at 2.3 s
		await shoot(n)
		card.queue_free()


## Writes index.html (a contact sheet of every PNG in the out dir, this run's marked new) and quits.
func _finish() -> void:
	var stems := {}  # shot name -> {size: file}
	for f: String in DirAccess.get_files_at(out):
		if f.get_extension() != "png":
			continue
		var base := f.get_basename()
		var sz := base.get_slice("_", base.get_slice_count("_") - 1)
		if sz == "full" or (sz.get_slice_count("x") == 2 and sz.replace("x", "").is_valid_int()):
			stems.get_or_add(base.trim_suffix("_" + sz), {})[sz] = f
	var names := stems.keys()
	names.sort()
	var html := "<!doctype html><meta charset=utf-8><title>UI shots</title><style>"
	html += "body{background:#111;color:#ddd;font:14px sans-serif;margin:16px}h1{font-size:16px}"
	html += ".g{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:16px}"
	html += "figure{margin:0}figure img{width:100%;display:block;border:1px solid #333;image-rendering:pixelated}"
	html += "figcaption{padding:4px 0}.n{color:#7fd17f;margin-left:6px}.s a{color:#8ab;margin-right:8px}</style>"
	html += "<h1>UI shots, %s</h1><div class=g>" % Time.get_datetime_string_from_system(false, true)
	for n: String in names:
		var files: Dictionary = stems[n]
		var main: String = files.get("854x480", files.values()[0])
		var fresh := main in taken
		html += "<figure><a href='%s'><img src='%s' loading=lazy></a><figcaption>%s" % [main, main, n]
		html += "<span class=n>%s</span>" % ("new" if fresh else "")
		html += "<div class=s>"
		for sz: String in files:
			html += "<a href='%s'>%s</a>" % [files[sz], sz]
		html += "</div></figcaption></figure>"
	html += "</div>"
	var file := FileAccess.open(out.path_join("index.html"), FileAccess.WRITE)
	file.store_string(html)
	file.close()
	print("index ", out.path_join("index.html"))
	get_tree().quit()
