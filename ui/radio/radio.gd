## The radial radio (Q, time slowed): send a Spoofed transmission using a held Voiceprint.
## Gathers the facts on the ground for Glaukopis, then the recipients obey, or, if it is exposed, the
## recipient says so on the radio and they search near where the Operative transmitted from.
## Group "radio": the debug overlay reads glaukopis.last (doubt and reasons).
extends Control

const SLOW := 0.25           # time scale while the radial is open
const SEARCH_SPREAD := 5.0   # exposed: the search spot is within ± this of the transmit point
const REPLY_DELAY := 1.0     # seconds before the recipient answers
const R_IN := 26.0
const R_OUT := 70.0
const POINTER_MAX := 60.0
const STEP_TITLES := {speaker = "SPEAK AS", to = "TO", order = "ORDER", place = "PLACE", confirm = "SEND"}
const ACKS := {go = "Copy, checking the %s.", hold = "Copy, holding.", all_clear = "Copy, standing down."}

var glaukopis := Glaukopis.new()   # one per Mission: the Area scene holds this node
var menu: RadioMenu                # null while closed
var _pointer := Vector2.ZERO       # virtual pointer from mouse motion (the mouse stays captured)
var hq := HqRadio.new()            # Downs L1 / L3: HQ's polls
var _now := 0.0
var _last_alert := -INF
var _places := {}                  # name -> position
var _operative: Node3D
var _font: Font = load("res://assets/fonts/press_start_2p_regular.ttf")


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
	_pointer = Vector2.ZERO
	Engine.time_scale = SLOW
	_operative.radio_open = true


func close() -> void:
	menu = null
	Engine.time_scale = 1.0
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
	var line := menu.line()
	close()
	_send(pick, line)


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
			hq.say("%s? You don't sound right. Who is this?" % who)
			var spot := from + Vector3(randf_range(-SEARCH_SPREAD, SEARCH_SPREAD), 0, randf_range(-SEARCH_SPREAD, SEARCH_SPREAD))
			hq.send_nearest(spot, who, "a Spoofed transmission", from)
		else:
			hq.say("Copy, %s." % who))


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
		_search(up, "%s? You don't sound right. Who is this?" % pick.speaker, from)
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
			r.radio_say(ACKS[pick.order] % pick.place if pick.order == "go" else ACKS[pick.order])
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
	_search(up.filter(func(r): return is_instance_valid(r) and not r.is_down()), "%s says they never called. Who is this?" % speaker, from)


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


# --- Drawing: HudPalette chrome -----------------------------------------------------------------

func _draw() -> void:
	if not menu:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	var c := size / 2
	var opts := menu.options()
	var n := opts.size()
	_centered(c + Vector2(0, -R_OUT - 30), _crumb(), HudPalette.CHROME)
	_centered(c + Vector2(0, 4), STEP_TITLES[menu.step], HudPalette.WHITE)
	_centered(c + Vector2(0, R_OUT + 34), "LMB OK  RMB BACK  Q CLOSE", HudPalette.CHROME_DIM)
	if n == 0:
		_centered(c + Vector2(0, 20), "NO VOICEPRINTS", HudPalette.CHROME_DIM)
		return
	var hover := _hover()
	var step := TAU / n
	for i in n:
		var mid := -PI / 2 + i * step
		var on := i == hover
		var gap := 0.04 if n > 1 else 0.0
		draw_arc(c, (R_IN + R_OUT) / 2, mid - step / 2 + gap, mid + step / 2 - gap, 24,
			Color(HudPalette.CHROME, 0.8) if on else Color(HudPalette.CHROME, 0.25), R_OUT - R_IN)
		var label: String = ("%d %s" % [i + 1, opts[i][0]]) if i < 9 else opts[i][0]
		var dir := Vector2.from_angle(mid)
		var p := c + dir * (R_OUT + 8) + Vector2(0, 4 + 4 * dir.y)
		if dir.x < -0.2:
			p.x -= label.length() * 8
		elif dir.x <= 0.2:
			p.x -= label.length() * 4
		_t(p, label, HudPalette.WHITE if on else HudPalette.CHROME_DIM)
	if _pointer.length() > 12.0:
		draw_circle(c + _pointer.normalized() * (R_IN - 6), 2.5, HudPalette.WHITE)


func _crumb() -> String:
	if menu.step == "confirm":
		return "%s: %s" % [menu.pick.speaker, menu.line()]
	var parts := PackedStringArray()
	if menu.pick.has("speaker") and menu.step != "speaker":
		parts.append(menu.pick.speaker)
	if menu.pick.has("recipients") and menu.step in ["order", "place"]:
		parts.append("All units" if menu.pick.all_units else menu.pick.recipients[0])
	if menu.step == "place":
		parts.append("Go check")
	return " > ".join(parts)


func _centered(pos: Vector2, s: String, col: Color) -> void:
	_t(pos - Vector2(s.length() * 4, 0), s, col)


func _t(pos: Vector2, s: String, col: Color) -> void:
	for o in [Vector2(1, 1), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]:  # same 4-way outline as hud.gd
		draw_string(_font, pos + o, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0, 0, 0, col.a))
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
