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


## True once per patrol stop of at least FIDGET_STOP, as the tree asks for it: the guard is standing there, free to
## fidget. Walking again re-arms it.
func at_new_stop() -> bool:
	if _pause <= 0.0:
		_stop_checked = false
		return false
	if _stop_checked or _pause < FIDGET_STOP or _glance > 0.0 or _tele_left > 0.0 or held_up:
		return false
	_stop_checked = true
	return true


## A look around for the rest of the stop.
func fidget() -> void:
	model.react("look", _pause, 1.0)


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
	else:
		if goal() != search_spot():
			face(search_spot(), delta)  # at a Ladder's foot, watching the roof
		else:
			if not _looked and alert.state == GuardAlert.State.EVASION:
				model.react("look_nervous", LOOK_CLIP, 1.0)  # Evasion: the jittery scan
				_looked = true  # one sweep per arrival
			rotation.y += sin(_clock * 1.1) * sweep * delta
			_check_corner()
		_move_on(delta)


## A suspicious guard (not a responder) that has looked round the spot for PEEK_AFTER s walks to the nearest
## corner by it that it can't see behind, once per spot, and looks round there for the rest of LOOK_TIME
## (GuardAlert counts the look-around only while it stands at its goal).
func _check_corner() -> void:
	if alert.state != GuardAlert.State.SUSPICION or alert.rushing or alert.calling:
		return
	if peeked() or alert.timer < PEEK_AFTER:
		return
	_peek = hidden_corner(alert.last_known)
	_peek_for = alert.last_known


## A hunting searcher (Evasion, or fanning on Alert) looks round its spot for Engage.SWEEP_TIME, marks it
## swept and takes the next free spot (AlertChain.searched): the squad keeps working outward. A Suspicion
## responder stays at its one spot.
func _move_on(delta: float) -> void:
	if alert.state != GuardAlert.State.EVASION and not _fanning:
		return
	_swept += delta
	if _swept >= Engage.SWEEP_TIME:
		_swept = 0.0
		_looked = false
		AlertChain.area.searched(self)


func chase(delta: float) -> void:
	if _fleeing():
		_flee(delta)
		return
	if _has_sight() and Engage.backs_off(true, _flat_dist(operative.global_position)):
		face(operative.global_position, delta)  # the retreat in the tree failed (cornered): stands and fires
		return
	var squad := _squad()
	var fan: bool = not _has_sight() and Engage.lost(squad[1])
	if fan != _fanning:  # lost the Operative, or someone has it again: either way the spot it held is free
		_fanning = fan
		_swept = 0.0
		AlertChain.area.release(self)
	if _fanning:
		search(delta, FAN_SPEED, 2.0)  # the squad lost it: each to its own spot round the last sighting
		return
	_held = Engage.holds(squad[0], _has_sight(), _flat_dist(operative.global_position), squad[1], _held)
	if _held:
		_look_for(delta)
		return
	_walk_to(goal(), CHASE_SPEED, delta)
	_look_for(delta)


## Sight with a grace of RETREAT_GRACE s, so a flicker of the vision cone doesn't change what the guard is doing.
func _has_sight() -> bool:
	return seen_rate > 0.0 or (alert.saw and alert.unseen < RETREAT_GRACE)  # a guard the radio alerted hasn't seen it


## Eyes on the Operative while in sight; without it, toward the last noise or sighting, and a sweep once there.
func _look_for(delta: float) -> void:
	if seen_rate > 0.0:
		face(operative.global_position, delta)
	elif not _has_sight() and (_held or arrived()):
		if _flat_dist(alert.last_known) > 0.3:
			face(alert.last_known, delta)
		else:
			rotation.y += sin(_clock * 1.1) * 1.5 * delta


## The Operative is inside the distance a guard keeps (the tree's Retreat starts on it).
func too_close() -> bool:
	return not _fleeing() and _has_sight() and Engage.backs_off(true, _flat_dist(operative.global_position))


## One step of a retreat, facing the Operative; true once it is Engage.RETREAT_TO m away.
func retreat(delta: float) -> bool:
	if _flat_dist(operative.global_position) >= Engage.RETREAT_TO:
		return true
	var away := global_position - operative.global_position
	away.y = 0.0
	_walk_to(global_position + away.normalized() * 3.0, RETREAT_SPEED, delta)
	face(operative.global_position, delta)
	return false


## [this guard's index, the alerted guards as Engage reads them]: who has sight (Engage.holds, Engage.lost).
func _squad() -> Array:
	var squad := []
	var me := 0
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		if g.alert.state != GuardAlert.State.ALERT or g.is_down() or g.target:
			continue
		if g == self:
			me = squad.size()
		squad.append({pos = g.global_position, unseen = g.alert.unseen, last_known = g.alert.last_known,
			fresh = g.is_in_group("reinforcements") and not g.alert.saw})
	return [me, squad]


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
