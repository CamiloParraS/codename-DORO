## What takes a guard out and brings it back: bullets, darts, chokes, a Hold-up, the Fulton, waking, a Checkpoint
## restore, and the partners who see it drop.
extends "res://actors/guard/guard_moves.gd"


## Put out of action (a choke); choking a Neutralized guard again restarts the clock. A guard that
## drops (up until now) is seen by its partners.
func neutralize() -> void:
	var dropped := not is_down()
	AlertChain.area.stop_call(self)
	_cut_call()
	_vstate = GuardAlert.State.PATROL
	AlertChain.area.release(self)
	neutral_left = NEUTRALIZED_TIME
	stumble_left = 0.0
	held = false
	held_up = false
	alert = GuardAlert.new()
	order = {}
	seen_rate = 0.0
	collision_layer = 0
	_lie(true)
	_refresh_mark()
	if dropped:
		if _shot_from != Vector3.INF:  # knocked back from the shooter, at the place it was hit
			var away := (global_position - _shot_from) * Vector3(1, 0, 1)
			var speed := HEAD_SHOT_PUSH if _shot_head else SHOT_PUSH
			model.drop(away.normalized() * speed + Vector3.UP * 1.0, "Head" if _shot_head else "spine_02")
		else:
			model.drop(model.global_basis.z * DROP_PUSH + Vector3.UP * 0.2)  # falls back, away from where it faced
		Mix.sfx_at(self, &"body_fall")
		_partners_see()


## Killed (a rifle shot): Down for good. Counts for Lethality and Combat; a kill while any guard is
## alerted is an alert_kill.
func kill(from := Vector3.INF, head := false) -> void:
	if dead:
		return
	_shot_from = from
	_shot_head = head
	var alerted := get_tree().get_nodes_in_group("guards").any(func(g): return g.alert.state == GuardAlert.State.ALERT)
	_fell = not is_down()
	neutralize()
	_shot_from = Vector3.INF
	dead = true
	_refresh_mark()
	get_tree().call_group("mission_tally", "event", "target_kill" if target else "kill")
	if alerted:
		get_tree().call_group("mission_tally", "event", "alert_kill")


## A rifle bullet from `from`: a headshot kills at once (a helmet makes it a body hit), the second body
## hit kills, and a first one leaves it suspicious where the shot came from.
func shoot(head: bool, from: Vector3) -> void:
	if head:
		get_tree().call_group("mission_tally", "event", "headshot")
	hits += 1
	if bullet_kills(head, helmet, hits, body_hits_to_kill):
		kill(from, head)
	else:
		model.react("hit", HIT_TIME)
		model.flinch(_away_from(from) * FLINCH_PUSH + Vector3.UP * 0.3, "Head" if head else "spine_02")
		if is_inside_tree():
			move_and_collide(((global_position - from) * Vector3(1, 0, 1)).normalized() * HIT_STAGGER)
		voice.say(&"pain")
		_changed(alert.hear(from, "a bullet"))


## The flat direction away from `from`, which a hit shoves along.
func _away_from(from: Vector3) -> Vector3:
	return ((global_position - from) * Vector3(1, 0, 1)).normalized()


## A rifle bullet into a Down guard's ragdoll, at the bone it hit: the body is shoved.
func shot_down(from: Vector3, bone: String) -> void:
	var away := (global_position - from) * Vector3(1, 0, 1)
	model.shove(away.normalized() * SHOT_PUSH * 0.7 + Vector3.UP * 0.5, bone)


## Does a rifle bullet kill: an unhelmeted headshot always, otherwise the BODY_HITS_TO_KILL-th hit.
static func bullet_kills(head: bool, has_helmet: bool, hit_count: int, to_kill := BODY_HITS_TO_KILL) -> bool:
	return (head and not has_helmet) or hit_count >= to_kill


## A tranq dart from `from`: a headshot Neutralizes at once (a helmet makes it a body shot), a body
## shot after BODY_DELAY, meanwhile the guard stumbles, is suspicious and can't radio.
func tranquilize(head: bool, from: Vector3) -> void:
	if head:
		get_tree().call_group("mission_tally", "event", "headshot")  # the habit counts, helmet or not
	if head and not helmet:
		neutralize()
		return
	Mix.sfx_at(self, &"dart_vest" if vest else &"dart_hit")
	if stumble_left > 0.0:
		return
	if not vest:  # a vest stops the dart: the guard only hears it hit
		stumble_left = Tranq.BODY_DELAY
		model.react("hit", HIT_TIME)
		model.flinch(_away_from(from) * FLINCH_PUSH * 0.6, "Head" if head else "spine_02")
		voice.say(&"pain")
	_changed(alert.hear(from, "a dart"))


## Headshots Countermeasure: a visible helmet; headshots count as body hits from now on.
func wear_helmet() -> void:
	helmet = true
	model.wear("Helmet")


## Combat L1: a visible vest.
func wear_vest() -> void:
	vest = true
	model.wear("Vest")


## Back on its feet, suspicious and remembering nothing (a Caution trigger). from: where it looks first.
func wake(from: Vector3) -> void:
	AlertChain.area.caution()  # a Checkpoint restore makes a fresh chain after return_to_post()
	neutral_left = 0.0
	known_down = false
	hits = 0
	if carrier:  # no longer Down: off the Operative's shoulder
		carrier.carrying = null
		carrier = null
	model.get_up()
	collision_layer = 2
	_lie(false)
	_changed(alert.wake(from))


## Checkpoint restore: alive (even if killed since), standing at its post, alert cleared, starting its
## patrol over. A helmet (a Countermeasure) stays on.
func return_to_post() -> void:
	dead = false
	wake(global_position)  # up, off any shoulder, solid again
	alert = GuardAlert.new()  # remembering nothing, not even waking
	stumble_left = 0.0
	held = false
	held_up = false
	answered = false
	order = {}
	seen_rate = 0.0
	last_reason = ""
	global_transform = post
	reset_physics_interpolation()  # a jump back to post, not a glide
	velocity = Vector3.ZERO
	_wp = 0
	_stop = {}
	_pause = 0.0
	_glance = 0.0
	_looked = false
	_detour = null
	_next_detour = 0
	_fire_left = FIRE_INTERVAL
	_agent.target_position = post.origin
	_refresh_mark()
	_bt.restart()


## Checkpoint restore of a Neutralized guard (after return_to_post): Down again where it lay, with
## `left` seconds to go. Nobody sees it drop, and it makes no sound.
func stay_down(at: Transform3D, left: float, was_known: bool) -> void:
	global_transform = at
	reset_physics_interpolation()
	neutral_left = left
	known_down = was_known
	collision_layer = 0
	_lie(true)
	_refresh_mark()


## Can the Operative at `from` choke this guard: not Down, not alerted, outside its front cone.
func can_be_choked(from: Vector3) -> bool:
	if is_down() or alert.state >= GuardAlert.State.ALERT:
		return false
	return not GuardVision.in_front(from - global_position, -global_basis.z)


## Can the Operative at `from` hold it up: as for a choke (up, not alerted, not facing it), and it
## doesn't see him and isn't radioing.
func can_be_held_up(from: Vector3) -> bool:
	return not held_up and seen_rate <= 0.0 and not alert.calling and not AlertChain.area.calling(self) and can_be_choked(from)


## Held up: it kneels where it stands (the "kneel" clip). A startle first, and a mark.
func hold_up() -> void:
	held_up = true
	velocity = Vector3.ZERO
	voice.say(&"holdup")
	model.react("startle", GuardAlert.FLINCH)
	_mark.text = "hands up"
	_mark.modulate = MARK_COLORS[GuardAlert.State.SUSPICION]
	_sync_mark()


## Freed (out of range, aim lost, an Alert, a partner saw it): "?", it grabs its gun and starts a
## stoppable Radio call on where the Operative stood.
func release(from: Vector3) -> void:
	if not held_up:
		return
	held_up = false
	if not is_down():
		model.react("startle", GuardAlert.FLINCH)
		_changed(alert.freed(from))


## Its one Hold-up answer for the Operative op (Holdup.answer): holdup_answer if scripted, else its
## Voiceprint, else where the current objective's intel is, else a free 10 s Scanner reveal.
func answer(op: Node3D) -> void:
	if answered:
		return
	answered = true
	var run := get_tree().get_first_node_in_group("mission_plan")
	var intel: String = run.intel_hint(global_position) if run else ""
	var voice_new: bool = not str(name) in op.voiceprints.held
	var what := Holdup.answer(holdup_answer, voice_new, intel != "")
	Mixer.blip(0.8)  # a guard's voice blip under his line
	if voice_new:  # his voice is copied whatever he says, a scripted answer (the foreman's) included
		op.voiceprints.held.append(str(name))
		get_tree().call_group("mission_tally", "event", "interrogated_voiceprint")
	match what:
		"objective":  # where, on the INTEL line (MissionRun._say_objective's)
			get_tree().call_group("radio_log", "say", "INTEL", intel)
		"scan":
			op.items.scan_left = op.items.scan_time
	radio_say(tr("holdup." + what))


## Searched while Down: what a Hold-up would have got out of him is on the body (his scripted answer; a
## guard without one has nothing to give).
func frisk(_op: Node3D) -> void:
	if answered:
		return
	answered = true
	if holdup_answer != "":
		get_tree().call_group("radio_log", "say", "INTEL", tr("search." + holdup_answer))


## Can a Fulton take it: Neutralized (darted, choked) or kneeling at gunpoint; never the dead.
func can_be_fultoned() -> bool:
	return fulton_state_ok() and not carry_only


## Down (not dead) or kneeling: a balloon could take him, whatever the Mission says about it.
func fulton_state_ok() -> bool:
	return (is_down() and not dead) or held_up


## Fultoned: a balloon lifts it out of the Area for good (the Operative already took it out of "guards").
## It rises over RISE_TIME s; for BALLOON_TIME s every guard within BALLOON_SEEN m of the spot with a line
## of sight to the balloon comes to look (_balloon_tick). Silent.
func fulton() -> void:
	held_up = false
	_mark.text = ""
	_sync_mark()
	_balloon_left = BALLOON_TIME
	Mix.sfx_at(self, &"fulton_launch")
	var lift := Mix.sfx_at(self, &"fulton_lift")
	lift.pitch_scale = 1.0
	create_tween().tween_property(lift, "pitch_scale", 1.6, RISE_TIME)  # pitched up as it rises
	_balloon_spot = global_position
	_balloon = Fx.balloon()
	_balloon.position.y = 3.0
	add_child(_balloon)
	create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).tween_property(_balloon, "scale", Vector3.ONE, Fx.INFLATE)
	var t := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)  # per tick, so physics interpolation smooths it
	t.tween_property(self, "global_position", global_position + Vector3.UP * 1.5, 1.0)
	t.tween_property(self, "global_position", global_position + Vector3.UP * 40.0, RISE_TIME - 1.0)
	t.tween_callback(hide)


func _balloon_tick(delta: float) -> void:
	_balloon_left -= delta
	if _balloon_left <= 0.0:
		queue_free()
		return
	var at := _balloon.global_position
	for o: Guard in get_tree().get_nodes_in_group("guards"):
		if o not in _balloon_seen and o._flat_dist(_balloon_spot) <= BALLOON_SEEN and o.sees_point(at):
			_balloon_seen.append(o)
			o.on_noise(_balloon_spot, "a balloon")
			o.voice.say(&"balloon")


func _down_tick(delta: float) -> void:
	if carrier:  # the model lies in a fixed pose on the shoulder bone; the body just follows
		global_position = carrier.global_position
	else:
		var lies := model.ragdoll_center()  # the body slides where it falls: the hitbox goes with it
		if lies != Vector3.INF:
			global_position = Vector3(lies.x, global_position.y, lies.z)
	if not carrier and not dead:
		neutral_left -= delta
		if neutral_left <= 0.0:
			wake(global_position)


func _down_within(reach: float) -> Node3D:
	for g in get_tree().get_nodes_in_group("guards"):
		if g != self and g.is_down() and not g.carrier and _flat_dist(g.global_position) <= reach:
			return g
	return null


## Strongest sighting of a Down guard: [fill rate, position]. Same vision as for the Operative,
## with the Down guard counted as standing still. Kept apart from seen_rate, which is only the Operative.
## Every Down guard in sight becomes known_down, not just the strongest.
func _sense_down() -> Array:
	var best := [0.0, Vector3.ZERO]
	var eye := global_position + Vector3.UP * EYE
	for g in get_tree().get_nodes_in_group("guards"):
		if g == self or not g.is_down():
			continue
		var chest: Vector3 = g.global_position + Vector3.UP * 0.4
		var offset := chest - eye
		var rate := GuardVision.fill_rate(offset, -global_basis.z, false, false, false)
		if rate <= 0.0:
			continue
		var q := PhysicsRayQueryParameters3D.create(eye, chest, 1, [get_rid(), operative.get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			continue
		g.known_down = true
		if rate > best[0]:
			best = [rate, g.global_position]
	return best


## Every guard up that sees this one drop or kneel (its front cone, within PARTNER_RANGE, a clear
## line) reacts to it. True when any did.
func _partners_see() -> bool:
	var any := false
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		if g != self and g.can_radio() and g.sees_drop(self):
			g.on_drop(self)
			any = true
	return any


## A partner dropped (or knelt) in sight: "?" and his name called out to the guards within
## PARTNER_RANGE, who go "?" at the caller; GuardAlert makes it a Radio call PARTNER_DELAY s later.
func on_drop(who: Guard) -> void:
	var why := alert.see_drop(who.global_position, who.name)
	if why == "":
		return
	_changed(why)
	radio_say("%s!" % who.name)
	voice.say(&"partner")
	broadcast(get_tree(), global_position, GuardAlert.PARTNER_RANGE, "%s call out" % name, self)


## Every guard within radius of pos hears it (GuardAlert.in_earshot: through walls).
## alarming (a loud shot): they go straight to ALERT instead of suspicion.
static func broadcast(tree: SceneTree, pos: Vector3, radius: float, what: String, except: Guard = null, alarming := false) -> void:
	for g in tree.get_nodes_in_group("guards"):
		if g != except and GuardAlert.in_earshot(g.global_position, pos, radius):
			if alarming:
				g.on_shot(pos)
			else:
				g.on_noise(pos, what)
