## F3 debug overlay, on every screen (an autoload): why Aigis deployed what it did and why the guards
## act. Reads the first node in group "mission_plan" (record and plan; tally too inside a Mission),
## the guards' and cameras' last reasons, and Glaukopis's last judgement (group "radio").
## F3 again swaps the developer text for the Aigis report, three large blocks (Profile, Voices, Plan) built to be
## read across a room; a third press hides it.
extends CanvasLayer

const FS := 22  # design px, on the 1080 canvas every screen shares
const RIGHT_X := 1000.0  # design px

var _root := Control.new()  # scaled from the 1080 design canvas, like the other full-screen pages
var _left := Label.new()
var _right := Label.new()
var _report := Control.new()  # the presentation view, drawn from the same record and plan
var _report_on := false
var _bg := ColorRect.new()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_bg.color = Color(HudPalette.DARK_INK, 0.92)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var rule := ColorRect.new()  # the cyan header rule: this is Aigis's view
	rule.color = HudPalette.CYAN
	rule.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rule.offset_bottom = 2
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
	var mono := SystemFont.new()  # monospace so the columns line up; no face is shipped for it
	mono.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "Menlo", "DejaVu Sans Mono"])
	mono.allow_system_fallback = true
	for l: Label in [_left, _right]:
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.add_theme_font_override("font", mono)
		l.add_theme_font_size_override("font_size", FS)
		l.add_theme_color_override("font_color", HudPalette.LIGHT)
		l.add_theme_constant_override("line_spacing", 2)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(l)
	_left.position = Vector2(32, 20)
	_right.position = Vector2(RIGHT_X, 20)
	_report.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_report.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_report.draw.connect(_draw_report)
	_root.add_child(_report)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var d := get_viewport().get_visible_rect().size
	var k := d.y / HudPalette.DESIGN_H
	_root.scale = Vector2(k, k)
	_root.size = d / k


func _input(e: InputEvent) -> void:
	if e.is_action_pressed("debug_overlay"):
		if not visible:
			visible = true
			_report_on = false
		elif not _report_on:
			_report_on = true
		else:
			visible = false
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
	var d := MissionPlaces.diagram(p)
	return "(%.1f, %.1f, %.1f)" % [d.x, d.y, d.z]


func _process(_delta: float) -> void:
	_left.visible = not _report_on
	_right.visible = not _report_on
	_report.visible = _report_on
	_bg.color.a = 1.0 if _report_on else 0.92  # the report is read from afar: nothing ghosts through
	if not visible:
		return
	if _report_on:
		_report.queue_redraw()
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
		if g.has_method("bt_trace") and state != "DOWN":
			s += "      %s\n" % g.bt_trace()
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


## The Aigis report: Profile (points toward each level), Voices (weights) and Plan (what is deployed and by whom),
## then the lethality line. Bars instead of numbers, 30 px and up, in the post-Mission page's palette.
func _draw_report() -> void:
	var c := _report
	var d := _root.size
	var disp := HudPalette.DISPLAY
	var src := get_tree().get_first_node_in_group("mission_plan")
	HudPalette.hud_text(c, Vector2(80, 96), tr("ui.debug.report").to_upper(), 54, HudPalette.CYAN, HudPalette.tracked(disp, 54, 0.14), 0, false)
	if not src:
		HudPalette.hud_text(c, Vector2(80, 190), tr("ui.debug.none").to_upper(), 34, HudPalette.LIGHT_3, HudPalette.tracked(disp, 34, 0.2), 0, false)
		return
	var record: Dictionary = src.record
	var plan: Dictionary = src.plan
	var tally: MissionTally = src.get("tally")
	var gained: Dictionary = tally.points() if tally else {}
	var m: int = record.mission
	_report_head(c, Vector2(80, 190), tr("ui.debug.profile"), 560)
	for i in Aigis.HABITS.size():
		var h: String = Aigis.HABITS[i]
		var p := int(record.points.get(h, 0))
		var y := 262.0 + i * 96.0
		HabitGlyphs.draw(c, h, Vector2(80, y - 24), HudPalette.CYAN, 4.0)
		HudPalette.hud_text(c, Vector2(144, y + 10), tr("ui.habit." + h).to_upper(), 34, HudPalette.LIGHT, HudPalette.tracked(disp, 34, 0.06), 0, false)
		var bar := Rect2(144, y + 24, 400, 12)
		c.draw_rect(bar, Color(HudPalette.LIGHT, 0.14))
		c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(p / 300.0, 0.0, 1.0), bar.size.y)), HudPalette.SAND)
		for t in [1, 2]:  # the level thresholds
			c.draw_rect(Rect2(bar.position.x + bar.size.x * t / 3.0 - 1, bar.position.y - 4, 2, bar.size.y + 8), HudPalette.GROUND)
		var shown := "L%d" % Aigis.level(p, m)
		if gained.get(h, 0):
			shown += "  +%d" % gained[h]
		HudPalette.hud_text(c, Vector2(580, y + 10), shown, 34, HudPalette.SAND, HudPalette.tracked(disp, 34, 0.04), 0, false)
	_report_head(c, Vector2(760, 190), tr("ui.debug.voices"), 480)
	var top := 1.0
	for v: String in Aigis.VOICES:
		top = maxf(top, float(plan.weights[v]))
	for i in Aigis.VOICES.size():
		var v: String = Aigis.VOICES[i]
		var y := 262.0 + i * 96.0
		var lead: bool = v == plan.dominant
		var col := HudPalette.CYAN if lead else HudPalette.LIGHT_2
		HudPalette.hud_text(c, Vector2(760, y + 10), tr("ui.voice." + v).to_upper(), 34, col, HudPalette.tracked(disp, 34, 0.12), 0, false)
		var bar := Rect2(760, y + 24, 400, 12)
		c.draw_rect(bar, Color(HudPalette.LIGHT, 0.14))
		c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(plan.weights[v]) / top, bar.size.y)), col)
	_report_head(c, Vector2(1300, 190), tr("ui.debug.plan"), 540)
	HudPalette.hud_text(c, Vector2(1300, 262), tr("ui.debug.budget").format({n = plan.budget}).to_upper(), 34, HudPalette.LIGHT, HudPalette.tracked(disp, 34, 0.12), 0, false)
	var y := 330.0
	for p: Dictionary in plan.picks:
		HudPalette.hud_text(c, Vector2(1300, y), String(Aigis.LADDERS[p.habit][p.level - 1][1]), 30, HudPalette.LIGHT, HudPalette.FIGURE_MED, 0, false)
		HudPalette.hud_text(c, Vector2(1300, y + 30), "%s  %s" % [tr("ui.voice." + p.sponsor).to_upper(), tr("ui.habit." + p.habit).to_upper()], 20, HudPalette.LIGHT_3, HudPalette.tracked(disp, 20, 0.2), 0, false)
		y += 78.0
	if plan.picks.is_empty():
		HudPalette.hud_text(c, Vector2(1300, y), tr("ui.debug.nothing").to_upper(), 30, HudPalette.LIGHT_3, HudPalette.tracked(disp, 30, 0.2), 0, false)
	var ratio := Aigis.lethality_ratio(record)
	var line := tr("ui.debug.lethality").format({ratio = _ratio(ratio), band = Aigis.resolve_ending(ratio).to_upper()})
	c.draw_rect(Rect2(80, d.y - 120, d.x - 160, 1), Color(HudPalette.LIGHT, 0.2))
	HudPalette.hud_text(c, Vector2(80, d.y - 60), line.to_upper(), 34, HudPalette.LIGHT, HudPalette.tracked(disp, 34, 0.16), 0, false)


func _report_head(c: Control, at: Vector2, title: String, width: float) -> void:
	HudPalette.hud_text(c, at, title.to_upper(), 26, HudPalette.LIGHT_2, HudPalette.tracked(HudPalette.DISPLAY, 26, 0.3), 0, false)
	c.draw_rect(Rect2(at.x, at.y + 14, width, 2), Color(HudPalette.LIGHT, 0.4))
