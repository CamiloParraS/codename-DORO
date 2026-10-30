## The radial radio (Q, time slowed): send a Spoofed transmission using a held Voiceprint.
## Gathers the facts on the ground for Glaukopis, then the recipients obey, or, if it is exposed, the
## recipient says so on the radio and they search near where the Operative transmitted from.
## Group "radio": the debug overlay reads glaukopis.last (doubt and reasons).
extends Control

const SLOW := 0.25           # time scale while the radial is open
const SEARCH_SPREAD := 5.0   # exposed: the search spot is within ± this of the transmit point
const REPLY_DELAY := 1.0     # seconds before the recipient answers
const R_IN := 20.0
const R_OUT := 52.0
const POINTER_MAX := 60.0
const RING_SAND := Color("c9bfa4")  # the radial's highlight: SAND desaturated
const RING_IN_SECS := 0.22  # the ring scales in over this, in 6 hard steps
const EDGE := 16.0           # px inset of an off-screen referent's pointer
const ACKS := {go = "radio.ack.go", hold = "radio.ack.hold", all_clear = "radio.ack.all_clear"}  # text keys; {place}
## RadioMenu's fixed option labels -> their text keys (guard and place names show as they are).
const LABELS := {"All units": "radio.opt.all_units", "Go check": "radio.opt.go", "Hold position": "radio.opt.hold",
	"All clear": "radio.opt.all_clear", "Report in": "radio.opt.report_in", "Send": "radio.opt.send", "HQ": "ui.who.hq"}

var glaukopis := Glaukopis.new():   # one per Mission: the Area scene holds this node
	set(v):
		glaukopis = v  # a Checkpoint restore swaps it: a send beat in flight never happened
		if is_instance_valid(_look):
			_look.clear_beat()
var menu: RadioMenu                # null while closed
var _pointer := Vector2.ZERO       # virtual pointer from mouse motion (the mouse stays captured)
var hq := HqRadio.new()            # Downs L1 / L3: HQ's polls
var _now := 0.0
var _last_alert := -INF
var _places := {}                  # name -> position
var _operative: Node3D
var _look: RadioLook               # the world dim and fills, in the Area
var _hot_key := ""                 # what is hot now, for the hover tick
var _age := 0.0                    # unscaled seconds since the radial opened
var _last_hover := -2


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("radio")
	add_child(hq)


func _exit_tree() -> void:
	if menu:
		Engine.time_scale = 1.0


func _process(delta: float) -> void:
	_now += delta
	for g in get_tree().get_nodes_in_group("guards"):
		if g.alert.state == GuardAlert.State.ALERT:
			_last_alert = _now
			break
	if menu:
		_age += delta / maxf(Engine.time_scale, 0.05)
		var h := _hover()
		if h != _last_hover and h >= 0:
			Mixer.play(&"tick")
		_last_hover = h
		var r := _referents()
		_look.show_referents(r.hot, r.cold, r.place_at, r.place_hot)
		var key: String = str(r.hot.map(func(g): return g.name)) + (r.place if r.place_hot else "")
		if key != _hot_key and (r.hot.size() or r.place_hot):  # the highlight snapped to a new referent
			Mixer.play(&"ui_click", Mix.RADIO)
			Mixer.play(&"radio_static", Mix.RADIO)
		_hot_key = key
		queue_redraw()


func _input(e: InputEvent) -> void:
	if not menu:
		if e.is_action_pressed("radio"):
			_open()
			get_viewport().set_input_as_handled()
		return
	if e is InputEventMouseMotion:
		_pointer = (_pointer + e.relative).limit_length(POINTER_MAX)
	elif e.is_action_pressed("radio") or e.is_action_pressed("pause"):
		close()
	elif e.is_action_pressed("aim"):
		_pointer = Vector2.ZERO
		if not menu.back():
			close()
	elif e.is_action_pressed("fire"):
		_choose(_hover())
	elif e is InputEventKey and e.pressed and not e.echo and e.keycode >= KEY_1 and e.keycode <= KEY_9:
		_choose(e.keycode - KEY_1)  # ponytail: menu-local digit keys, not InputMap actions
	else:
		return  # movement and the rest still reach the game, in slow motion
	get_viewport().set_input_as_handled()


func _open() -> void:
	_operative = get_tree().get_first_node_in_group("operative")
	if not _operative:
		return
	var up: Array = get_tree().get_nodes_in_group("guards").filter(func(g): return not g.is_down()).map(func(g): return String(g.name))
	up.sort()
	_places.clear()
	for m: Node3D in get_tree().get_nodes_in_group("spoof_place"):
		_places[String(m.name).trim_prefix("Spoof").capitalize()] = m.global_position
	menu = RadioMenu.new(_operative.voiceprints.held.duplicate(), up, _places.keys(), hq.who())
	for g in get_tree().get_nodes_in_group("guards"):
		if g.role != "":
			menu.roles[String(g.name)] = g.role
	menu.hint_label = tr("radio.request_hint")
	_pointer = Vector2.ZERO
	Engine.time_scale = SLOW
	_operative.radio_open = true
	Mixer.play(&"radio_on", Mix.RADIO)
	if not is_instance_valid(_look):
		_look = RadioLook.new()
		get_tree().current_scene.add_child(_look)
	_look.open()
	_hot_key = ""
	_age = 0.0
	_last_hover = -2


func close() -> void:
	if menu:
		Mixer.play(&"radio_off", Mix.RADIO)
	menu = null
	Engine.time_scale = 1.0
	if is_instance_valid(_look):
		_look.close()
	if is_instance_valid(_operative):
		_operative.radio_open = false
	queue_redraw()


func _hover() -> int:
	var n := menu.options().size()
	return 0 if n == 1 else RadioMenu.slice(_pointer, n)  # a lone option needs no aiming


func _choose(i: int) -> void:
	_pointer = Vector2.ZERO
	if not menu.choose(i):
		return
	var pick := menu.pick
	if pick.has("hint"):
		close()
		get_tree().call_group("mission_plan", "request_hint")
		return
	var line := menu.line()
	close()
	_send(pick, line)
	if pick.order != "report_in":
		var speaker := _guard(pick.speaker)
		_look.beat(speaker.global_position if speaker else _operative.global_position,
			pick.recipients.map(_guard).filter(func(g): return g != null),
			_places[pick.place] if pick.order == "go" else Vector3.INF)


## Glaukopis judges the transmission on the facts on the ground; the recipients answer a moment later.
func _send(pick: Dictionary, line: String) -> void:
	if pick.order == "report_in":
		_report_in(pick.speaker, line)
		return
	var speaker := _guard(pick.speaker)
	var recipients: Array = pick.recipients.map(_guard).filter(func(g): return g != null)
	var j := _judge(pick.speaker, line, {
		recipients = pick.recipients, all_units = pick.all_units, order = pick.order, place = pick.place,
		seen_by = recipients.filter(func(r): return speaker != null and r != speaker and r.can_see(speaker)).map(func(r): return String(r.name)),
		sees_operative = recipients.filter(func(r): return r.seen_rate > 0.0).map(func(r): return String(r.name)),
	})
	var from := _operative.global_position
	var sent: Dictionary = glaukopis.history.back()  # its accepted list is fixed up once they answer
	get_tree().create_timer(REPLY_DELAY).timeout.connect(_answer.bind(pick, j.exposed, from, recipients, sent, glaukopis))


## Report in: the Operative answers HQ's poll as the polled guard; Glaukopis judges it like any
## Spoofed transmission. Believed, HQ is satisfied; exposed, a guard searches near the Operative.
func _report_in(who: String, line: String) -> void:
	var j := _judge(who, line, {recipients = [], all_units = false, order = "report_in", place = "",
		seen_by = [], sees_operative = []})
	var judge := glaukopis
	var from := _operative.global_position
	get_tree().create_timer(REPLY_DELAY).timeout.connect(func() -> void:
		if judge != glaukopis or hq.who() != who:  # a Checkpoint restore, or the poll is already settled
			return
		hq.answer()
		if j.exposed:
			hq.say(tr("radio.exposed").format({who = who}))
			var spot := from + Vector3(randf_range(-SEARCH_SPREAD, SEARCH_SPREAD), 0, randf_range(-SEARCH_SPREAD, SEARCH_SPREAD))
			hq.send_nearest(spot, who, "a Spoofed transmission", from)
		else:
			hq.say(tr("radio.hq_copy").format({who = who})))


## Glaukopis judges a transmission as `who` on the facts on the ground (`extra`: the order, the
## recipients and what they can see), then it is logged and tallied as a Spoof.
func _judge(who: String, line: String, extra: Dictionary) -> Dictionary:
	var facts := {now = _now, speaker = who, since_alert = _now - _last_alert}
	facts.merge(speaker_facts(_guard(who)))
	facts.merge(extra)
	var deployed := _deployed()
	glaukopis.expose_at = Deployment.expose_at(deployed)
	glaukopis.single_use = Deployment.single_use_voiceprints(deployed)
	var j := glaukopis.judge(facts)
	get_tree().call_group("radio_log", "say", who, line)
	get_tree().call_group("mission_tally", "event", "spoof")
	if j.exposed:
		get_tree().call_group("mission_tally", "event", "spoof_exposed")
	return j


func _answer(pick: Dictionary, exposed: bool, from: Vector3, recipients: Array, sent: Dictionary, judge: Glaukopis) -> void:
	if judge != glaukopis:  # a Checkpoint restore since: this transmission never happened
		return
	sent.accepted = []  # only the guards who obey below got the order
	var up := recipients.filter(func(r): return is_instance_valid(r) and not r.is_down())
	if up.is_empty():
		return
	if exposed:
		_search(up, tr("radio.exposed").format({who = pick.speaker}), from)
		return
	var acked := false
	for r in up:
		var ok: bool
		match pick.order:
			"go":
				ok = r.obey("go", _places[pick.place], pick.speaker)
			"hold":
				ok = r.obey("hold", r.global_position, pick.speaker)
			"all_clear":
				r.stand_down(pick.speaker)
				ok = true
		if ok:
			sent.accepted.append(String(r.name))
		if ok and not acked:
			acked = true
			r.radio_say(tr(ACKS[pick.order]).format({place = pick.place}))
	if acked and Deployment.radio_callback(_deployed()):
		get_tree().create_timer(REPLY_DELAY).timeout.connect(_callback.bind(pick.speaker, from, up, sent, judge))


## Spoofing L2: the recipients radio the speaker back. An alive, up speaker denies it, which exposes
## the transmission; a Down one doesn't answer (Glaukopis's +60 already covered a known Down).
func _callback(speaker: String, from: Vector3, up: Array, sent: Dictionary, judge: Glaukopis) -> void:
	var s := _guard(speaker)
	if judge != glaukopis or s == null or s.is_down():
		return
	judge.deny(speaker)
	sent.accepted = []  # exposed after all: nobody counts as having taken the order
	get_tree().call_group("mission_tally", "event", "spoof_exposed")
	_search(up.filter(func(r): return is_instance_valid(r) and not r.is_down()), tr("radio.never_called").format({who = speaker}), from)


## An exposed transmission: the first of `up` says so on the radio and they all search near `from`.
func _search(up: Array, line: String, from: Vector3) -> void:
	if up.is_empty():
		return
	up[0].radio_say(line)
	var spot := from + Vector3(randf_range(-SEARCH_SPREAD, SEARCH_SPREAD), 0, randf_range(-SEARCH_SPREAD, SEARCH_SPREAD))
	for r in up:
		r.on_noise(spot, "a Spoofed transmission")


func _deployed() -> Dictionary:
	var run := get_tree().get_first_node_in_group("mission_plan")
	return run.plan.deployed if run else {}


## What Glaukopis may hold against the voice's owner. A speaker no longer in the Area (Fultoned, or a
## reinforcement gone back out: the Voiceprint outlives him) is neither known Down nor busy.
static func speaker_facts(speaker: Node3D) -> Dictionary:
	if speaker == null:
		return {speaker_known_down = false, speaker_busy = false}
	return {
		speaker_known_down = speaker.is_down() and speaker.known_down,
		speaker_busy = not speaker.is_down() and speaker.alert.state != GuardAlert.State.PATROL,
	}


## The guard by name, or null once it has left the Area (Fultoned, or a reinforcement gone back out).
func _guard(guard_name: String) -> Node3D:
	for g in get_tree().get_nodes_in_group("guards"):
		if g.name == guard_name:
			return g
	return null


# --- Drawing: on the HUD's design canvas (DESIGN.md Radio) ------------------------------------------

const RING_IN := 72.0  # design px; the hover logic keeps R_IN / R_OUT in logical px
const RING_OUT := 156.0


func _draw() -> void:
	if not menu:
		return
	var k := size.y / HudPalette.DESIGN_H
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var c := _centre() / k
	draw_circle(c, RING_OUT + 46, Color(HudPalette.DARK_INK, 0.55))  # the radial's own backing; the world dim is the 3D look's
	_draw_referents(k)
	var opts := menu.options()
	var n := opts.size()
	var crumb := _crumb()
	if menu.step == "confirm":
		HudPalette.hud_text(self, c + Vector2(0, -RING_OUT - 60), crumb, 20, HudPalette.LIGHT_2, HudPalette.FIGURE_MED, 1)
	else:
		HudPalette.hud_label(self, c + Vector2(0, -RING_OUT - 60), crumb, 17, HudPalette.LIGHT_2, 0.14, HudPalette.LABEL, 1)
	_hints(c + Vector2(0, RING_OUT + 40))
	if n == 0:
		HudPalette.hud_label(self, c + Vector2(0, 7), tr("radio.no_voiceprints"), 17, HudPalette.LIGHT_3, 0.14, HudPalette.LABEL, 1)
		return
	var grow := floorf(clampf(_age / RING_IN_SECS, 0.0, 1.0) * 6.0) / 6.0  # six hard steps from 88% to full size
	var scale := 0.88 + 0.12 * grow
	draw_set_transform(c * k * (1.0 - scale), 0.0, Vector2(k, k) * scale)
	modulate.a = grow
	var hover := _hover()
	var step := TAU / n
	var mean := (RING_IN + RING_OUT) / 2
	for i in n:
		var mid := -PI / 2 + i * step
		var on := i == hover
		var gap := 0.04 if n > 1 else 0.0
		draw_arc(c, mean, mid - step / 2 + gap, mid + step / 2 - gap, 48,
			Color(RING_SAND, 0.72) if on else Color(HudPalette.LIGHT, 0.12), RING_OUT - RING_IN, true)
		var num := "%d " % (i + 1) if i < 9 else ""
		var label := _label(opts[i][0])
		var f := HudPalette.tracked(HudPalette.LABEL, 20, 0.12)
		var nw := f.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var w := nw + f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var dir := Vector2.from_angle(mid)
		var p := c + dir * (RING_OUT + 12) + Vector2(0, 7 + 10 * dir.y)
		if dir.x < -0.2:
			p.x -= w
		elif dir.x <= 0.2:
			p.x -= w / 2
		var ink := RING_SAND if on else HudPalette.LIGHT_3
		HudPalette.hud_text(self, p, num, 20, Color(ink, ink.a * 0.7), f)
		HudPalette.hud_text(self, p + Vector2(nw, 0), label, 20, ink, f)
	HudPalette.hud_label(self, c + Vector2(0, 7), tr("radio.step." + menu.step), 20, RING_SAND, 0.24, HudPalette.LABEL, 1, false)
	if _pointer.length() > 12.0:
		draw_circle(c + _pointer.normalized() * (RING_IN - 8), 5, HudPalette.LIGHT)


## Under the ring: OK, back and close, each as its key and a word.
func _hints(top_centre: Vector2) -> void:
	var pairs := [[Prompts.key("fire"), tr("radio.ok")], [Prompts.key("aim"), tr("ui.back")], [Prompts.key("radio"), tr("radio.close")]]
	var f := HudPalette.tracked(HudPalette.LABEL, 15, 0.14)
	var widths := []
	var total := 0.0
	for p: Array in pairs:
		var kw := maxf(30.0, HudPalette.FIGURE.get_string_size(p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 16)
		var w: float = kw + 8 + f.get_string_size(String(p[1]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		widths.append(w)
		total += w
	total += 22.0 * (pairs.size() - 1)
	var x := top_centre.x - total / 2
	for i in pairs.size():
		var kw := HudPalette.keycap(self, Vector2(x, top_centre.y), pairs[i][0], true)
		HudPalette.hud_text(self, Vector2(x + kw + 8, top_centre.y + 21), String(pairs[i][1]).to_upper(), 15, HudPalette.LIGHT_3, f)
		x += widths[i] + 22.0


## An option as shown: upper case, the fixed ones translated.
func _label(s: String) -> String:
	return (tr(LABELS[s]) if LABELS.has(s) else menu.shown(s)).to_upper()


func _crumb() -> String:
	if menu.step == "confirm":
		return "%s: %s" % [menu.shown(menu.pick.speaker).to_upper(), menu.line()]
	var parts := PackedStringArray()
	if menu.pick.has("speaker") and menu.step != "speaker":
		parts.append(_label(menu.pick.speaker))
	if menu.pick.has("recipients") and menu.step in ["order", "place"]:
		parts.append(_label("All units" if menu.pick.all_units else menu.pick.recipients[0]))
	if menu.step == "place":
		parts.append(_label("Go check"))
	return " › ".join(parts)


# --- Referents: brackets, edge pointers, the Radar blink ------------------------------------------

## The radial is left of centre: at the middle it covers most of what it names.
func _centre() -> Vector2:
	return Vector2(R_OUT + 120, size.y / 2 - 10)


## RadioMenu.referents for the hovered option, with names mapped to guards still in the Area.
func _referents() -> Dictionary:
	var r := menu.referents(_hover())
	var out := {hot = [], cold = [], place = r.place, place_at = _places.get(r.place, Vector3.INF), place_hot = r.place_hot}
	for k in ["hot", "cold"]:
		out[k] = r[k].map(_guard).filter(func(g): return g != null)
	return out


## In design px (`k` = logical px per design px): brackets and a name on the hovered option's guards and
## Radio point, edge pointers toward the ones off screen, and their blink on the Radar.
func _draw_referents(k: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var r := _referents()
	var spots := []  # [feet, height, hot, name]
	for key in ["hot", "cold"]:
		for g: Node3D in r[key]:
			spots.append([g.global_position, 1.8, key == "hot", menu.shown(String(g.name))])
	if r.place_at != Vector3.INF:
		spots.append([r.place_at, 2.0, r.place_hot, r.place])
	var blink := int(Time.get_ticks_msec() / 200) % 2 == 0
	var radar := RadarModel.rect(size / k)  # the Radar lives on the HUD's design canvas
	var origin := RadarModel.flat(_operative.global_position)
	var jammed := RadarModel.jammed(HudModel.phase(AlertChain.area)[0])
	for s in spots:
		var col := Color(HudPalette.LIGHT, (1.0 if int(Time.get_ticks_msec() / 600) % 2 == 0 else 0.55) if s[2] else 0.5)  # hot brackets blink at 1.2 s
		var feet: Vector3 = s[0]
		if cam.is_position_behind(feet) or not Rect2(Vector2.ZERO, size).grow(-EDGE).has_point(cam.unproject_position(feet)):
			_edge_pointer(cam, feet, col, k)
		if s[2]:
			if not cam.is_position_behind(feet):
				var foot := cam.unproject_position(feet) / k
				var h := maxf(absf(foot.y - cam.unproject_position(feet + Vector3.UP * s[1]).y / k), 30.0)
				var box := Rect2(foot - Vector2(h * 0.35, h), Vector2(h * 0.7, h))
				_brackets(box, col)
				HudPalette.hud_label(self, box.position + Vector2(box.size.x / 2, -12), s[3], 16, col, 0.14, HudPalette.LABEL, 1)
			if blink and not jammed:
				var p := radar.get_center() + RadarModel.blip(RadarModel.flat(feet) - origin, 12)
				draw_rect(Rect2(p - Vector2(6, 6), Vector2(12, 12)), HudPalette.LIGHT)


## A triangle at the screen edge toward an off-screen point, mirrored through the centre when behind the camera.
func _edge_pointer(cam: Camera3D, at: Vector3, col: Color, k: float) -> void:
	var c := size / 2
	var p := cam.unproject_position(at)
	if cam.is_position_behind(at):
		p = c - (p - c)
	var d := (p - c).normalized()
	var half := size / 2 - Vector2.ONE * EDGE
	var e := (c + d * minf(half.x / maxf(absf(d.x), 1e-4), half.y / maxf(absf(d.y), 1e-4))) / k
	draw_colored_polygon(PackedVector2Array([e + d * 24, e + d.rotated(2.4) * 18, e + d.rotated(-2.4) * 18]), col)


## 22 px L-shapes in 2 px ink at the box's four corners.
func _brackets(b: Rect2, col: Color) -> void:
	var l := minf(22.0, minf(b.size.x, b.size.y) * 0.3)
	for corner in [b.position, Vector2(b.end.x, b.position.y), b.end, Vector2(b.position.x, b.end.y)]:
		var sx := 1.0 if corner.x == b.position.x else -1.0
		var sy := 1.0 if corner.y == b.position.y else -1.0
		draw_polyline(PackedVector2Array([corner + Vector2(l * sx, 0), corner, corner + Vector2(0, l * sy)]), col, 2.0)
