## The moves the behaviour tree (guard_tree.tres) calls: patrol, search, chase, flee, and carrying out a radio order.
extends "res://actors/guard/guard_body.gd"


# --- Moves called by the behaviour tree -------------------------------------------------------

func patrol(delta: float) -> void:
	if route.is_empty():
		if not stops.is_empty():
			_face_stop(stops[0], delta)  # a sentry scanning from its high point
		return
	if _glance > 0.0:  # stands still looking behind it
		_glance -= delta
		rotation.y = lerp_angle(rotation.y, _glance_yaw, 8 * delta)
		return
	if turn_every > 0.0:
		_turn_clock += delta
		if _turn_clock >= turn_every:
			_turn_clock = 0.0
			_glance = 1.5
			_glance_yaw = rotation.y + PI
	if _pause > 0.0:
		_pause -= delta
		_face_stop(_stop, delta)
		return
	var speed := CAUTION_SPEED if AlertChain.area.phase == AlertChain.Phase.CAUTION else PATROL_SPEED
	if _detour != null:
		_walk_to(_detour, speed, delta)
		if _flat_dist(_detour) < REACHED:
			_detour = null
			_pause = PAUSE
		return
	if radio_check_level > 0:
		_radio_clock += delta  # ticks only while walking: not at a stop, not mid-glance
		if _radio_clock >= Telegraph.RADIO_CHECK_EVERY and _glance <= 0.0:
			_radio_clock = 0.0
			if Telegraph.radio_check(radio_check_level, rng):  # Spoofing: stops mid-patrol to call HQ back
				_glance = Telegraph.DURATION
				_glance_yaw = rotation.y
				telegraph("radio_check", "((?))", "look", "HQ, confirm that last transmission.")
				return
	_walk_to(route[_wp], speed, delta)
	if _flat_dist(route[_wp]) < REACHED:
		_stop = stops[_wp] if _wp < stops.size() else {}
		_wp = (_wp + 1) % route.size()
		if _wp == 0 and not detours.is_empty() and AlertChain.area.phase == AlertChain.Phase.CAUTION:
			_detour = detours[_next_detour % detours.size()]  # one per loop, each in turn
			_next_detour += 1
		_pause = _stop.get("hold", PAUSE)
		if route.size() > 1 and Telegraph.head_check(head_check_level, rng):  # Stealth: looks back before it turns
			_glance = Telegraph.DURATION
			_glance_yaw = rotation.y
			telegraph("head_check", "?", "look", tr("radio.hm"))


## The shared Aigis telegraph: a cyan icon over the head and a pose for Telegraph.DURATION, so the
## Operative can read what Aigis changed. kind keys Metis's first-sighting call (Telegraph.METIS);
## mutter is an optional subtitle line when the Operative is within earshot.
func telegraph(kind: String, icon: String, clip: String, mutter := "") -> void:
	_tele_left = Telegraph.DURATION
	_tele_icon = icon
	model.react(clip, Telegraph.DURATION, 1.0)
	_refresh_mark()
	if not operative or _flat_dist(operative.global_position) > Chat.HEARD:
		return
	if mutter != "":
		radio_say(mutter)
	var run := get_tree().get_first_node_in_group("mission_plan")
	if run and Telegraph.METIS.has(kind) and Telegraph.first_sighting(run.telegraphs_seen, kind):
		get_tree().call_group("radio_log", "say", "METIS", tr(Telegraph.METIS[kind]))


## At a stop with a facing, turns to it (sweeping when it scans); a plain stop leaves the guard as it is.
func _face_stop(s: Dictionary, delta: float) -> void:
	if s.has("yaw"):
		rotation.y = lerp_angle(rotation.y, stop_yaw(s, _clock), 4 * delta)


## Where a stop faces at `clock`: its yaw, swept ±scan/2 degrees on a sine of SCAN_PERIOD.
static func stop_yaw(s: Dictionary, clock: float) -> float:
	return s.yaw + deg_to_rad(s.get("scan", 0.0)) / 2 * sin(TAU * clock / SCAN_PERIOD)


## Carries out the radio order: walk to the place and look around, or hold here. False once there is
## none left.
func follow_order(delta: float) -> bool:
	if order.is_empty():
		return false
	if order.kind == "go" and not _at(order.pos):
		_walk_to(order.pos, PATROL_SPEED, delta)
		return true
	order.time += delta
	rotation.y += sin(_clock * 0.9) * 1.5 * delta
	if order.time >= (HOLD_TIME if order.kind == "hold" else ORDER_LOOK):
		order = {}
	return true


func search(delta: float, speed: float, sweep: float) -> void:
	if _fleeing():
		_flee(delta)
	elif not arrived():
		_looked = false
		_walk_to(goal(), CHASE_SPEED if alert.rushing else speed, delta)  # a responder runs
	elif goal() != search_spot():
		face(search_spot(), delta)  # at a Ladder's foot, watching the roof
	else:
		if not _looked and alert.state == GuardAlert.State.EVASION:
			model.react("look_nervous", LOOK_CLIP, 1.0)  # Evasion: the jittery scan
			_looked = true  # one sweep per arrival
		rotation.y += sin(_clock * 1.1) * sweep * delta


func chase(delta: float) -> void:
	if _fleeing():
		_flee(delta)
		return
	if _holds():
		if seen_rate > 0.0:
			face(operative.global_position, delta)
		return
	_walk_to(goal(), CHASE_SPEED, delta)
	if seen_rate > 0.0:
		face(operative.global_position, delta)


## Engage.holds for this guard among the alerted ones: a guard that sees the Operative from afar stands
## and shoots; with nobody in sight for a while, only the nearest pushes up.
func _holds() -> bool:
	var squad := []
	var me := 0
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		if g.alert.state != GuardAlert.State.ALERT or g.is_down() or g.target:
			continue
		if g == self:
			me = squad.size()
		squad.append({pos = g.global_position, unseen = g.alert.unseen, last_known = g.alert.last_known,
			fresh = g.is_in_group("reinforcements") and not g.alert.saw})
	return Engage.holds(me, seen_rate > 0.0, _flat_dist(operative.global_position), squad)


func _flee(delta: float) -> void:
	if not arrived():
		_walk_to(safe_room, CHASE_SPEED, delta)


## A believed Spoofed order from `who`: "go" to pos or "hold" here. A suspicious or searching guard
## drops its search for it; an alerted one keeps hunting. True when it obeys.
func obey(kind: String, pos: Vector3, who: String) -> bool:
	if is_down() or alert.state == GuardAlert.State.ALERT:
		return false
	_changed(alert.stand_down(who, kind))
	if kind == "go":
		model.react("point", 1.2)
	order = {kind = kind, pos = pos, time = 0.0}
	_bt.restart()
	return true


## A believed "all clear" from `who`: back to patrol.
func stand_down(who: String) -> void:
	_changed(alert.stand_down(who))
