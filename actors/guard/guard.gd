## A guard: senses the Operative, feeds its GuardAlert, makes its Radio calls to the Area's AlertChain
## (shouting to the guards in earshot), and exposes the moves its behaviour tree (guard_tree.tres)
## calls. Spawned by the Area at a guard post.
extends "res://actors/guard/guard_downs.gd"
class_name Guard


func _seed() -> void:
	rng.seed = hash(name)


func _ready() -> void:
	add_to_group("guards")
	_seed.call_deferred()  # repeatable per guard, after the Area names it; tests reseed (a method, so a guard freed first is skipped)
	if target:
		add_to_group("targets")
	else:
		model.hold("rifle")
	add_child(voice)
	_glint = Fx.lamp(Color(1, 0.1, 0.08), 0.1)
	_glint.position = Vector3(0.18, 1.78, -0.05)  # at the ear
	_vest = Fx.lamp(Color(1, 0.7, 0.1), 0.12)
	_vest.position = Vector3(0, 1.35, -0.22)
	for l: Node3D in [_glint, _vest]:
		l.visible = false
		add_child(l)
	_agent.velocity_computed.connect(_on_velocity_computed)


func _physics_process(delta: float) -> void:
	_clock += delta
	_tele_left -= delta
	if GuardAlert.flinches(_prev_state, alert.state) and not _prev_calling:  # a spotter flinched at his "!"
		model.react("startle", GuardAlert.FLINCH, 2.2)  # a pose only: the tree and shooting never wait on it
	_prev_state = alert.state
	_prev_calling = alert.calling
	var flat := Vector2(velocity.x, velocity.z).length()
	ping_age += delta
	_step_left -= delta
	if flat > 1.0 and not is_down() and _step_left <= 0.0:  # footsteps, for the Radar: faster when running
		_step_left = 0.3 if flat > 3.0 else 0.5
		ping()
	model.gaze(_gaze_point())
	model.play("kneel" if held_up else CharacterModel.guard_clip(is_down(), flat, _fell), flat)
	_agent.velocity = Vector3.ZERO  # stands still unless the tree walks it this frame
	_voice_tick(delta)
	if _balloon:
		_balloon_tick(delta)
		return
	if is_down():
		_down_tick(delta)
		return
	if held or held_up or stumble_left > 0.0:
		AlertChain.area.stop_call(self)  # a choke, a Hold-up or a dart stops the call
		_cut_call()
	if held_up and _partners_see():  # seen kneeling: freed, turning on the Operative
		release(operative.global_position if operative else global_position)
	if held or held_up:
		return
	if stumble_left > 0.0:
		stumble_left -= delta
		if stumble_left <= 0.0:
			neutralize()
			return
	if operative:
		var down := _sense_down()  # before tick: a Down guard in sight holds off the drain
		_changed(alert.see_down(delta, down[0], down[1], instant_down))
		var rate := _sense()
		var responding := alert.rushing
		_changed(alert.tick(delta, rate, operative.global_position, _saw, arrived()))
		if responding and alert.state == GuardAlert.State.PATROL:
			AlertChain.area.caution()  # a stopped call's local search ended
		_shoot_back(delta)
		if alert.state in [GuardAlert.State.SUSPICION, GuardAlert.State.EVASION] and arrived():
			var down_guard := _down_within(CHECK_REACH)
			if down_guard:
				var why := alert.check_down(down_guard.dead)
				voice.say(&"partner")
				if not down_guard.dead:
					SessionLog.current.note("%s woke %s" % [name, down_guard.name])
					get_tree().call_group("mission_tally", "event", "woken")
					down_guard.wake(global_position)  # a Caution trigger
				_changed(why)
	if stumble_left > 0.0:
		return  # stumbling: stands still
	_radio_call()
	_check_in(delta)
	if AlertChain.area.calling(self):
		face(alert.last_known, delta)  # hand to ear, standing still, not shooting
		return
	# Manual update: the tree must set the velocity before the NavAgent (a later child) submits it.
	_bt.update(delta)


## An alerted guard that sees the Operative within range fires every FIRE_INTERVAL; the shot lands by
## Health.hit_chance. It can't fire while stumbling or held (both return before this).
func _shoot_back(delta: float) -> void:
	if target:
		return  # unarmed
	var d := _flat_dist(operative.global_position)
	if alert.state != GuardAlert.State.ALERT or seen_rate <= 0.0 or d > Health.RANGE:
		_fire_left = FIRE_INTERVAL  # a reaction delay before the first shot
		return
	_fire_left -= delta
	if _fire_left > 0.0:
		return
	_fire_left = FIRE_INTERVAL
	_muzzle_flash()
	model.react("fire", FIRE_INTERVAL)
	var lands := randf() < Health.hit_chance(d, operative.moving and not operative.looks_walking())
	_shot_effects(lands)
	if lands:
		operative.take_hit()


## What the Operative sees and hears of a shot: the bang, a flash and tracer from the rifle's muzzle, then blood
## and a thud on a hit, or a miss that whizzes past to throw sparks off whatever it meets.
func _shot_effects(lands: bool) -> void:
	var w := get_parent()
	var from := model.muzzle(global_position + Vector3.UP * 1.3 - global_basis.z * 0.6)
	var chest: Vector3 = operative.global_position + Vector3.UP * operative.chest_height()
	Mix.sfx_at(self, &"shot_loud")
	Fx.flash(w, from, false)
	if lands:
		Fx.tracer(w, from, chest)
		Fx.puff(w, chest, Color(0.7, 0.1, 0.1), 6, 1.5)
		Mix.sfx_at(operative, &"bullet_hit")
		return
	var past: Vector3 = chest + Vector3(randf_range(-1, 1), randf_range(-0.4, 0.8), randf_range(-1, 1)).normalized() * MISS_BY
	var end: Vector3 = from + (past - from).normalized() * Health.RANGE * 2.0
	var q := PhysicsRayQueryParameters3D.create(from, end, 1 | 2, [get_rid(), operative.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var stop: Vector3 = hit.get("position", end)
	Fx.tracer(w, from, stop)
	var near := Geometry3D.get_closest_point_to_segment(chest, from, stop)
	if near.distance_to(chest) <= WHIZ_RANGE:  # not when a wall took it first
		Mix.sfx_at(self, &"bullet_whiz", near)
	if not hit.is_empty():
		Fx.puff(w, hit.position, Color(1, 0.75, 0.25), 6, 4.0, 0.3)  # sparks
		Fx.puff(w, hit.position, Color(0.6, 0.58, 0.55), 5, 1.2, 0.6)  # dust
		Mix.sfx_at(self, &"ricochet", hit.position)


## A brief light at chest height in front of the guard, so a shot is visible whether or not it lands.
func _muzzle_flash() -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.8, 0.4)
	l.light_energy = 8.0
	l.omni_range = 6.0
	l.position = Vector3(0, 1.3, -0.6)
	add_child(l)
	get_tree().create_timer(0.07).timeout.connect(l.queue_free)


## Routine radio check-in: subtitle + ((·)) while talking, and the Operative may record a Voiceprint.
func _check_in(delta: float) -> void:
	_chatter(delta)
	if checkin.tick(delta):
		get_tree().call_group("radio_log", "say", name, tr(Checkin.LINES.pick_random()))
		if _pause > 0.5 and alert.state == GuardAlert.State.PATROL and not held_up:  # at a stop: the call is on the phone
			model.react("phone", _pause, 1.0)
	if chat and chat_seat == 0:
		var line := chat.tick(delta)
		var who: Guard = self if chat.speaker() == 0 else chat_partner
		# Chat isn't radio: a subtitle only when the Operative is close enough to overhear it.
		if line != "" and is_instance_valid(who) and who.chatting() and operative and who._flat_dist(operative.global_position) <= Chat.HEARD:
			who.say_line(line)
		if line != "" and is_instance_valid(who):
			who.speak_gesture(Chat.TURN)
	if target_chat:
		_target_chat(delta)
	if operative:
		operative.voiceprints.tick(delta, name, _flat_dist(operative.global_position), on_air())
	_refresh_mark()


## The Target and his escort talk while both are up and on patrol and the Operative is within earshot.
func _target_chat(delta: float) -> void:
	var calm := alert.state == GuardAlert.State.PATROL and not is_down() and partner_calm()
	var line := target_chat.tick(delta, calm and operative != null and _flat_dist(operative.global_position) <= Chat.HEARD)
	if not line.is_empty():
		var who: Guard = self if line.seat == 0 else chat_partner
		who.say_line(line.key)
		who.speak_gesture(TargetChatter.TURN, true)


## Where the head turns, or null to leave it to the clip: the spot a suspicious or alerted guard is on, a chat
## partner, or an Operative in view and close by (a glance; it doesn't fill the detection meter).
func _gaze_point() -> Variant:
	if is_down() or held or held_up:
		return null
	match alert.state:
		GuardAlert.State.SUSPICION, GuardAlert.State.ALERT:
			return alert.last_known + Vector3.UP * EYE
		GuardAlert.State.PATROL:
			if (chat != null or target_chat != null) and partner_calm():
				return chat_partner.global_position + Vector3.UP * EYE
			if operative and _flat_dist(operative.global_position) <= GLANCE_RANGE and can_see(operative):
				return operative.global_position + Vector3.UP * EYE
			if _pause > 0.0:
				return _head_sweep(0.7, 1.3)  # at a stop: a slow look to either side
		GuardAlert.State.EVASION:
			if arrived() and goal() == search_spot():
				return _head_sweep(1.2, 1.9)  # at a search spot: the head scans wider than the body
	return null


## A point in front of the guard, the head's heading swinging `amount` radians either side `rate` times faster than
## the body's own sweep.
func _head_sweep(amount: float, rate: float) -> Vector3:
	var heading := (-global_basis.z).rotated(Vector3.UP, sin(_clock * rate) * amount)
	return global_position + Vector3.UP * EYE + heading * 3.0


## Talks with its hands for one line of `seconds`; react() leaves it standing in idle after.
func speak_gesture(seconds: float, heated := false) -> void:
	if not is_down() and not held_up:
		var clip := gesture.next(heated)
		model.react(clip, seconds, 1.0 if clip == Gesture.LONG else 0.0)


## Every CHATTER_EVERY s on patrol, a warning or confirmation about a Habit, as a subtitle, only when
## the Operative is within hearing range.
func _chatter(delta: float) -> void:
	if chatter_sets.is_empty() or alert.state != GuardAlert.State.PATROL or is_down():
		return
	_chatter_clock -= delta
	if _chatter_clock > 0.0:
		return
	_chatter_clock = CHATTER_EVERY * rng.randf_range(0.75, 1.25)
	if operative and VoiceLines.heard(_flat_dist(operative.global_position)):
		say_line(VoiceLines.pick(chatter_sets, rng))


## Barks off what changed this frame: a choke, the Radio call ending (squelch off), Caution ending, the
## guard's state. Silent when it is Down or rising on a balloon.
func _voice_tick(delta: float) -> void:
	var calling := AlertChain.area.calling(self)
	if _was_calling and not calling:
		Mixer.play(&"radio_off", Mix.RADIO)  # a cut call never gets here: _cut_call cleared _was_calling
	_was_calling = calling
	var phase := AlertChain.area.phase
	var live := not is_down() and not _balloon
	_glint.visible = calling and live
	_vest.visible = phase == AlertChain.Phase.CAUTION and live
	if _vphase == AlertChain.Phase.CAUTION and phase == AlertChain.Phase.NORMAL and not is_down() and not _balloon:
		voice.radio_line(&"resolved", "*")  # one guard of the lot says it
	_vphase = phase
	if held and not _vheld:
		voice.say(&"choke")
	_vheld = held
	if is_down() or _balloon or held or held_up:
		return
	var s := alert.state
	if s != _vstate:
		var from := _vstate
		_vstate = s
		_vsearched = false
		match s:
			GuardAlert.State.SUSPICION:
				if from == GuardAlert.State.PATROL and not alert.calling:
					voice.say(&"suspicion")
			GuardAlert.State.ALERT:
				voice.say(&"chase")
			GuardAlert.State.EVASION:
				voice.say(&"search")
			GuardAlert.State.PATROL:
				voice.say(&"giveup")
	elif s == GuardAlert.State.SUSPICION and not alert.calling and not _vsearched and arrived():
		_vsearched = true
		voice.say(&"search")  # a local search
	elif s == GuardAlert.State.PATROL and phase == AlertChain.Phase.CAUTION and rng.randf() < delta / 10.0:
		voice.say(&"caution")


## A guard that went "!" (alert.calling) and isn't on the radio yet starts its Radio call and shouts to
## the guards within SHOUT_RANGE. In Alert or Evasion there is no call: it joins the hunt. A responder
## whose spotter still calls waits: it never duplicates his call.
func _radio_call() -> void:
	var chain := AlertChain.area
	if not alert.calling or chain.calling(self):
		return
	if chain.phase == AlertChain.Phase.ALERT or chain.phase == AlertChain.Phase.EVASION:
		_changed(alert.radio(alert.last_known, name))
		if chain.phase == AlertChain.Phase.EVASION:
			_changed(alert.evade())
		return
	if not chain.start_call(self, alert.last_known, AlertChain.CALL_TIME, alert.heard):
		return
	model.react("startle", GuardAlert.FLINCH, 2.2)
	get_tree().create_timer(GuardAlert.FLINCH).timeout.connect(func() -> void:  # then a hand to the ear for the rest of the call
		if is_instance_valid(self) and not is_down() and AlertChain.area.calling(self):
			model.react("hand_to_ear", AlertChain.CALL_TIME - GuardAlert.FLINCH, CharacterModel.EAR_SPEED))
	_was_calling = true
	voice.call_in(func() -> bool: return AlertChain.area.calling(self))
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		if g != self and GuardAlert.in_earshot(g.global_position, global_position, AlertChain.SHOUT_RANGE):
			g.on_shout(alert.last_known, self)


## A spotter's "!" within earshot: run to his sighting point.
func on_shout(pos: Vector3, who: Guard) -> void:
	if can_radio():
		_changed(alert.respond(pos, who, who.name))


## The Area is in Alert (the AlertChain): hunt from pos.
func on_radio(pos: Vector3, who: String) -> void:
	if is_down():
		return
	_changed(alert.radio(pos, who))


## The AlertChain's Alert drained (to Evasion), or Evasion ended (to patrol, in Caution).
func on_phase(to: AlertChain.Phase) -> void:
	if is_down():
		return
	_changed(alert.evade() if to == AlertChain.Phase.EVASION else alert.give_up())


## A noise reached this guard.
func on_noise(pos: Vector3, what: String) -> void:
	if is_down():
		return
	_changed(alert.hear(pos, what))


## A loud gunshot reached this guard: straight to ALERT.
func on_shot(pos: Vector3) -> void:
	if is_down():
		return
	_changed(alert.shot(pos))


## Sets seen_rate (0 = not seen) and, when seen, _saw to what was seen.
func _sense() -> float:
	seen_rate = 0.0
	var eye := global_position + Vector3.UP * EYE
	var chest: Vector3 = operative.global_position + Vector3.UP * operative.chest_height()
	var offset := chest - eye
	var facing := -global_basis.z
	var caution := AlertChain.area.phase == AlertChain.Phase.CAUTION
	var rate := GuardVision.fill_rate(offset, facing, operative.looks_crouched(), operative.moving, operative.looks_walking(),
		AlertChain.CAUTION_REACH if caution else 1.0) * (AlertChain.CAUTION_FILL if caution else 1.0)
	if rate == 0.0:
		return 0.0
	var q := PhysicsRayQueryParameters3D.create(eye, chest, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or hit["collider"] != operative:
		return 0.0
	seen_rate = rate
	_saw = GuardVision.describe(offset, facing, operative.looks_crouched(), operative.moving, operative.looks_walking())
	return rate
