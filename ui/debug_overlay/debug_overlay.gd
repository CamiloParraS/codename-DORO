## F3 debug overlay, on every screen (an autoload): why Aigis deployed what it did and why the guards
## act. Reads the first node in group "mission_plan" (record and plan; tally too inside a Mission),
## the guards' and cameras' last reasons, and Glaukopis's last judgement (group "radio").
extends CanvasLayer

var _left := Label.new()
var _right := Label.new()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.04, 0.86)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var rule := ColorRect.new()  # the cyan header rule: this is Aigis's view
	rule.color = HudPalette.CYAN
	rule.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rule.offset_bottom = 2
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
	for l: Label in [_left, _right]:
		l.add_theme_font_override("font", HudPalette.BODY)  # monospace: the columns line up
		l.add_theme_font_size_override("font_size", HudPalette.BODY_SIZE)
		l.add_theme_color_override("font_color", HudPalette.LIGHT)
		l.add_theme_constant_override("line_spacing", -2)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
	_left.position = Vector2(8, 6)
	_right.position = Vector2(330, 6)


func _input(e: InputEvent) -> void:
	if e.is_action_pressed("debug_overlay"):
		visible = not visible
	elif e.is_action_pressed("debug_mark"):
		_mark()


## F4: a screenshot of the game view and a session-log line with where the Operative and the camera are, in the
## builders' diagram metres, so "something looks wrong here" arrives as coordinates.
func _mark() -> void:
	var shown := visible
	visible = false
	await RenderingServer.frame_post_draw
	var path := "user://marks/%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	DirAccess.make_dir_recursive_absolute("user://marks")
	get_viewport().get_texture().get_image().save_png(path)
	visible = shown
	var line := "mark, shot %s" % ProjectSettings.globalize_path(path)
	var op := get_tree().get_first_node_in_group("operative") as Node3D
	if op:
		line += ", Operative at %s" % _diagram(op.global_position)
	var cam := get_viewport().get_camera_3d()
	if cam:
		var fwd := -cam.global_basis.z
		line += ", camera at %s bearing %d pitch %d" % [_diagram(cam.global_position), wrapi(roundi(rad_to_deg(atan2(fwd.x, -fwd.z))), 0, 360),
			roundi(rad_to_deg(asin(clampf(fwd.y, -1, 1))))]
	print(line)
	if SessionLog.current.missions.is_empty() or not SessionLog.current.missions.back().open:
		SessionLog.append(MissionRun.LOG_PATH, line + "\n")
	else:
		SessionLog.current.note(line)
		SessionLog.current.write_live(MissionRun.LIVE_PATH)


static func _diagram(p: Vector3) -> String:
	var d := MissionRun._diagram(p)
	return "(%.1f, %.1f, %.1f)" % [d.x, d.y, d.z]


func _process(_delta: float) -> void:
	if not visible:
		return
	var src := get_tree().get_first_node_in_group("mission_plan")
	if not src:
		_left.text = "no Mission or plan on this screen"
		_right.text = ""
		return
	var tally: MissionTally = src.get("tally")
	_left.text = _aigis(src.record, src.plan, tally)
	_right.text = _field(tally)


## Profile, Voices, Lethality and the plan.
func _aigis(record: Dictionary, plan: Dictionary, tally: MissionTally) -> String:
	var m: int = record.mission
	var gained: Dictionary = tally.points() if tally else {}
	var s := "PROFILE  Mission index %d (cap %d)\n" % [m, Aigis.cap(m)]
	for h: String in Aigis.HABITS:
		var p := int(record.points.get(h, 0))
		s += "  %-9s %3d pts L%d  unlocked %d deployed %d" % [h, p, Aigis.level(p, m), plan.unlocked[h], plan.deployed[h]]
		s += ("  +%d now\n" % gained[h]) if gained.get(h, 0) else "\n"
	s += "VOICES  " + "  ".join(PackedStringArray(Aigis.VOICES.map(func(v: String) -> String: return "%s %.1f" % [v, plan.weights[v]])))
	s += "\n  Dominant %s\n" % plan.dominant
	var ratio := Aigis.lethality_ratio(record)
	var after: Dictionary = Aigis.complete_mission(record, tally.counts) if tally else record
	var ratio_after := Aigis.lethality_ratio(after)
	s += "LETHALITY raw %d / %d  ratio %s  band %s\n" % [record.lethality, record.denominator, _ratio(ratio), Aigis.resolve_ending(ratio)]
	s += "  with this Mission: raw %d / %d  ratio %s  projected ending %s\n" % [after.lethality, after.denominator, _ratio(ratio_after), Aigis.resolve_ending(ratio_after)]
	s += "PLAN  budget %d  pinned %s\n" % [plan.budget, plan.pinned if plan.pinned else "none"]
	for p: Dictionary in plan.picks:
		var what: String = Aigis.LADDERS[p.habit][p.level - 1][1]
		s += "  %s %s [%s] %s\n" % [p.step, what, p.sponsor, ("%d pinned" if p.candidates.is_empty() else "%d") % p.score]
		if p.candidates.size() > 1:
			s += "     of " + ", ".join(PackedStringArray(p.candidates.map(func(c: Dictionary) -> String: return "%s %d" % [c.step, c.score]))) + "\n"
	if plan.picks.is_empty():
		s += "  nothing deployed\n"
	return s


## This Mission's tally, guard and camera reasons, and Glaukopis.
func _field(tally: MissionTally) -> String:
	if not tally:
		return ""
	var counts := PackedStringArray(tally.counts.keys().map(func(k: String) -> String: return "%s %d" % [k, tally.counts[k]]))
	var s := "TALLY  %s\n" % (", ".join(counts) if counts else "nothing yet")
	var session := SessionLog.current
	if not session.missions.is_empty():
		s += "TIME  %d s  idle %d s\n" % [session.seconds(), session.idle_seconds()]
	s += "GUARDS\n"
	for g in get_tree().get_nodes_in_group("guards") + get_tree().get_nodes_in_group("cameras"):
		var state: String = "DESTROYED" if g.get("destroyed") else "DOWN" if g.has_method("is_down") and g.is_down() else GuardAlert.State.keys()[g.alert.state]
		s += "  %s %s%s %s\n" % [g.name, state, " (helmet)" if g.get("helmet") else "", g.last_reason]
	var radio := get_tree().get_first_node_in_group("radio")
	if radio:
		var j: Dictionary = radio.glaukopis.last
		s += "GLAUKOPIS  expose at %d\n" % radio.glaukopis.expose_at
		if j.is_empty():
			s += "  no transmission yet\n"
		else:
			s += "  doubt %d  %s\n" % [j.doubt, "EXPOSED" if j.exposed else "believed"]
			for r: Array in j.reasons:
				s += "   +%d %s\n" % [r[0], r[1]]
	return s


static func _ratio(r: float) -> String:
	return "undefined" if is_nan(r) else "%.2f" % r
