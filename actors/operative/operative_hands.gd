## What the Operative does with its hands, and the prompt that offers it: choke and kill takedowns, carrying,
## the resupply crate, Ladders, Hold-up and the Fulton.
extends "res://actors/operative/operative_body.gd"


func _interact() -> void:
	if carrying:  # drop it where we stand
		carrying.carrier = null
		carrying.global_position = global_position
		carrying = null
		return
	if held_up and not held_up.answered:
		return  # E is for questioning him (_hold_up)
	var aimed := _holdup_target() if not held_up else null
	if aimed:
		held_up = aimed
		_holdup = Holdup.new()
		held_up.hold_up()
		return
	var g := _nearest(true)
	if g:
		if not g.dead:
			g.neutralize(true)  # hoisting a Neutralized guard re-chokes it: the choke clock starts over
		carrying = g
		g.carrier = self
		return
	g = _nearest(false)
	if g:
		_choking = g
		_choke_left = choke_time
		_killing = false
		_victim_down = false
		g.held = true
		Mix.sfx_at(self, &"choke")
		if choke_noise > 0.0:
			Guard.broadcast(get_tree(), g.global_position, choke_noise, "a struggle", g)
	elif _crate_near():
		items.resupply([tranq, rifle])
		model.react("pick_up", 0.7, 3.3, 0.6)  # straight into the bend to the crate (the clip idles 0.6 s first); its long stand back up is cut
	elif _ladder_near():
		_mount(_ladder_near())


## Onto a Ladder from its foot, or from its top (starting just below it), standing, facing the rungs.
func _mount(l: Node3D) -> void:
	ladder = l
	crouching = false
	_apply_crouch()
	var bottom: Vector3 = l.get_node("Bottom").global_position
	var top: Vector3 = l.get_node("Top").global_position
	global_position = Vector3(bottom.x, top.y - 0.05, bottom.z) if global_position.y > bottom.y + 1.0 else bottom
	reset_physics_interpolation()
	velocity = Vector3.ZERO
	_step_off = 0.0
	model.rotation.y = atan2(-(top.x - bottom.x), -(top.z - bottom.z))


## On a Ladder: dir +1 climbs, -1 descends, at CLIMB_SPEED. Past the top he steps across onto the Top marker over
## STEP_OFF_TIME; at the foot he lets go.
func _climb(dir: float, delta: float) -> void:
	var bottom: Vector3 = ladder.get_node("Bottom").global_position
	var top: Vector3 = ladder.get_node("Top").global_position
	velocity = Vector3.ZERO
	if _step_off > 0.0:  # stepping off the top: no say in it until he stands on the Top marker
		_step_off -= delta
		var u := smoothstep(0.0, 1.0, 1.0 - maxf(_step_off, 0.0) / STEP_OFF_TIME)
		global_position = Vector3(bottom.x, top.y, bottom.z).lerp(top, u)
		if _step_off <= 0.0:
			global_position = top
			ladder = null
		return
	moving = dir != 0.0
	_climb_dir = dir
	prompt = Prompts.verb("crouch", "ui.prompt.drop_off")
	prompt_parts = [part("crouch", "drop_off")]
	var y := global_position.y + dir * CLIMB_SPEED * delta
	if dir > 0.0 and y >= top.y:
		global_position = Vector3(bottom.x, top.y, bottom.z)
		_step_off = STEP_OFF_TIME
	elif dir < 0.0 and y <= bottom.y:  # only on the way down: mounting puts him on the bottom rung, holding still
		global_position = bottom
		ladder = null
	else:
		global_position = Vector3(bottom.x, clampf(y, bottom.y, top.y), bottom.z)
		_rung_left -= absf(dir) * CLIMB_SPEED * delta
		if _rung_left <= 0.0:
			_rung_left = RUNG_SPACING
			# quieter under the finale (its ascent climbs the Core's rungs)
			Mix.sfx_at(self, &"ladder", Vector3.INF, -10.0 if get_tree().get_first_node_in_group("finale") else 0.0)


func _ladder_near() -> Node3D:
	for l: Node3D in get_tree().get_nodes_in_group("ladders"):
		for end in ["Bottom", "Top"]:
			if global_position.distance_to(l.get_node(end).global_position) <= LADDER_REACH:
				return l
	return null


## X: kill the guard in reach from behind, or finish a Neutralized one on the floor.
func _begin_kill() -> void:
	var g := _nearest(false)
	_victim_down = g == null
	if _victim_down:
		g = _nearest(true, true)
	if g:
		_choking = g
		_choke_left = KILL_TIME
		_killing = true
		g.held = true
		Mix.sfx_at(self, &"choke")


## The grip ends with nothing done: E released, aim pressed, or the victim turned round or alerted.
func _let_go() -> void:
	_choking.held = false
	_choking = null
	_choke_left = 0.0


## In a grip or at a console the body is drawn into place at PULL_SPEED and turned to face it: behind a standing
## victim (GRIP_DIST), beside a Down one (DOWN_GRIP), or onto the console's stand spot. Overrides the velocity.
func _pull(delta: float) -> void:
	var to: Vector3
	var face: Vector3
	if _choking and _victim_down and _killing:
		var away := Vector3(global_position.x - _choking.global_position.x, 0, global_position.z - _choking.global_position.z)
		to = _choking.global_position + away.normalized() * DOWN_GRIP
		face = -away
	elif _choking:
		var back := Vector3(_choking.global_basis.z.x, 0, _choking.global_basis.z.z).normalized()
		to = _choking.global_position + back * GRIP_DIST
		face = -back
	elif using:
		to = using.stand_point()
		face = using.facing()
	else:
		return
	var d := Vector3(to.x - global_position.x, 0, to.z - global_position.z)
	var v := d / delta if d.length() <= PULL_SPEED * delta else d.normalized() * PULL_SPEED
	velocity.x = v.x
	velocity.z = v.z
	if face.length_squared() > 0.0001:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-face.x, -face.z), Locomotion.TURN_RATE * delta)


## The hold-E console the Operative stands at (its prompt is up), or null.
func _console_at() -> Node3D:
	for c in get_tree().get_nodes_in_group("intel"):
		if c.has_method("stand_point") and c.prompt_for(self) != "":
			return c
	return null


## Is the grip still good: a standing victim can still be choked, a Down one is still on the floor.
func _grip_holds() -> bool:
	return _choking.is_down() if _victim_down else _choking.can_be_choked(global_position)


## The HUD's action prompt, "[E] CARRY  [X] KILL": keys from the InputMap, verbs translated. prompt_parts
## carries the same choices for the HUD's text-free prompt.
func _update_prompt() -> void:
	var kill := Prompts.verb("kill_takedown", "ui.prompt.kill")
	var fulton := _fulton_part()
	if carrying:
		prompt = Prompts.verb("interact", "ui.prompt.drop")
		prompt_parts = [part("interact", "drop")]
	elif _choking:
		prompt = tr("ui.prompt.killing" if _killing else "ui.prompt.choking")
		prompt_parts = [part("", "kill", false, "busy")] if _killing else \
				[part("interact", "choke", true, "", 1.0 - _choke_left / maxf(choke_time, 0.01))]
	elif _fultoning:
		prompt = tr("ui.prompt.fultoning")
		prompt_parts = [part("fulton", "fulton", true, "", 1.0 - _fulton_left / maxf(fulton_time, 0.01))]
	elif held_up and not held_up.answered:
		prompt = _join(tr("ui.prompt.questioning") if _ask > 0.0 else Prompts.hold("interact", "ui.prompt.question"), _fulton_hint())
		prompt_parts = [part("interact", "question", true, "", _ask / Holdup.ASK_TIME), fulton]
	elif not held_up and _holdup_target():
		prompt = Prompts.verb("interact", "ui.prompt.hold_up")
		prompt_parts = [part("interact", "hold_up")]
	elif _nearest(true):
		prompt = _join(Prompts.verb("interact", "ui.prompt.carry"), kill if _nearest(true, true) else "", _fulton_hint())
		prompt_parts = [part("interact", "carry"), part("kill_takedown", "kill") if _nearest(true, true) else {}, fulton]
	elif _nearest(false):
		prompt = _join(Prompts.verb("interact", "ui.prompt.choke"), kill, _fulton_hint())
		prompt_parts = [part("interact", "choke"), part("kill_takedown", "kill"), fulton]
	elif _crate_near() and not items.crate_used:
		prompt = Prompts.verb("interact", "ui.prompt.resupply")
		prompt_parts = [part("interact", "resupply")]
	elif _ladder_near():
		prompt = Prompts.verb("interact", "ui.prompt.climb")
		prompt_parts = [part("interact", "climb")]
	else:
		prompt = ""
		prompt_parts = []
	for c in get_tree().get_nodes_in_group("intel"):  # a hold-E console: its line beside the carry and Fulton ones
		var line: String = c.prompt_for(self) if c.has_method("prompt_for") else ""
		prompt = _join(prompt, line)
		if line != "":
			prompt_parts.append(part("interact", "console", true, "", float(c.get("held")) / maxf(float(c.get("hold_time")), 0.01)))
	prompt_parts = prompt_parts.filter(func(p: Dictionary) -> bool: return not p.is_empty())


## One choice of the HUD's text-free prompt: the action whose key to show ("" = none, the move is under
## way), the pictogram, whether the key is held, and a state: "" offered, "busy" under way, "warn" barred.
## progress is how far a held key has filled its outline, 0..1.
static func part(action: String, icon: String, hold := false, state := "", progress := 0.0) -> Dictionary:
	return {action = action, icon = icon, hold = hold, state = state, progress = clampf(progress, 0.0, 1.0)}


## _fulton_hint as a prompt part: offered, barred (no open sky, or a Target too ill to fly), or none.
func _fulton_part() -> Dictionary:
	var g := _fulton_target()
	if not g:
		var barred := get_tree().get_nodes_in_group("guards").any(func(b: Guard) -> bool:
			return b.carry_only and b.fulton_state_ok() and _flat_dist(b) <= TAKEDOWN_REACH)
		return part("", "fulton", false, "warn") if barred else {}
	if fultons <= 0:
		return {}
	return part("fulton", "fulton", true) if fulton_ready() else part("", "fulton", false, "warn")


## Prompt parts two spaces apart, skipping empty ones.
static func _join(a: String, b: String, c := "") -> String:
	return "  ".join(PackedStringArray([a, b, c].filter(func(s: String) -> bool: return s != "")))


## What the Fulton key would do beside a Neutralized or kneeling guard.
func _fulton_hint() -> String:
	var g := _fulton_target()
	if not g:
		var barred := get_tree().get_nodes_in_group("guards").any(func(b: Guard) -> bool:
			return b.carry_only and b.fulton_state_ok() and _flat_dist(b) <= TAKEDOWN_REACH)
		return tr("ui.prompt.target_no_fulton") if barred else ""
	if fultons <= 0:
		return ""
	return Prompts.hold("fulton", "ui.prompt.fulton") if fulton_ready() else tr("ui.prompt.no_fulton")


## Could a balloon go up now: a guard it can take in reach, a balloon left, open sky over him.
func fulton_ready() -> bool:
	var g := _fulton_target()
	return g != null and fultons > 0 and NoFulton.open_sky(get_tree(), g.global_position)


## Hold-up: E with the gun aimed (Holdup.RANGE, Guard.can_be_held_up) freezes the guard; Holdup.tick frees him.
## E held Holdup.ASK_TIME s gets his one answer (Guard.answer); after that E chokes him. The clock runs in
## _physics_process, so a paused tree (a full-screen Codec call) stops it.
func _hold_up(delta: float) -> void:
	if held_up and (not is_instance_valid(held_up) or held_up.is_down() or not held_up.held_up):
		held_up = null
	if not held_up:
		_ask = 0.0
		return
	var on_aim := aiming and not gun().reloading() and _aimed_guard() == held_up
	if _holdup.tick(delta, on_aim, _flat_dist(held_up), held_up.alert.state >= GuardAlert.State.ALERT):
		held_up.release(global_position)
		held_up = null
		return
	if not held_up.answered and Input.is_action_pressed("interact"):
		_ask += delta
		if _ask >= Holdup.ASK_TIME:
			held_up.answer(self)
	else:
		_ask = 0.0


## The guard E would hold up now: aimed at (not carrying, choking or reloading), within range, unaware.
func _holdup_target() -> Guard:
	if not aiming or carrying or _choking or gun().reloading():
		return null
	var g := _aimed_guard()
	return g if g and _flat_dist(g) <= Holdup.RANGE and g.can_be_held_up(global_position) else null


## The standing guard under the crosshair, if any.
func _aimed_guard() -> Guard:
	var from := camera.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * 30.0, 1 | 2, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit["collider"] if not hit.is_empty() and hit["collider"] is Guard else null


## Fulton: hold the key fulton_time s, standing still, beside a Neutralized or kneeling (not dead) guard under
## open sky. Releasing, moving or the guard waking cancels and spends nothing.
func _fulton(delta: float) -> void:
	var g := _fulton_target() if Input.is_action_pressed("fulton") and not carrying and not moving and fultons > 0 else null
	if not g or not NoFulton.open_sky(get_tree(), g.global_position):
		_fultoning = null
		return
	if g != _fultoning:
		_fultoning = g
		_fulton_left = fulton_time
	_fulton_left -= delta
	if _fulton_left <= 0.0:
		launch_fulton(g)


## The balloon goes up (Guard.fulton): the guard leaves the Area for good but stays on HQ's poll roster. A
## Target counts as delivered (out of "targets") and feeds no Habit or Lethality.
func launch_fulton(g: Guard) -> void:
	_fultoning = null
	fultons -= 1
	g.remove_from_group("guards")
	g.remove_from_group("targets")
	var radio := get_tree().get_first_node_in_group("radio")
	if radio:
		radio.hq.gone[String(g.name)] = g.global_position
	g.fulton()
	get_tree().call_group("mission_tally", "event", "target_fulton" if g.target else "fulton")


## The nearest guard in reach a balloon could take (Guard.can_be_fultoned).
func _fulton_target() -> Guard:
	var best: Guard
	var best_d := TAKEDOWN_REACH
	for g: Guard in get_tree().get_nodes_in_group("guards"):
		var d := _flat_dist(g)
		if d <= best_d and g.can_be_fultoned():
			best = g
			best_d = d
	return best


## The clip for what it is busy at (CharacterModel.operative_clip): climbing, kneeling at a Fulton, or holding E at
## a console (a relay_console's held time).
func _task() -> String:
	if ladder:
		return "climb"
	if _fultoning:
		return "crouch_idle"
	for c in get_tree().get_nodes_in_group("intel"):
		if c.get("held"):
			return "use"
	return ""


func _crate_near() -> bool:
	for c: Node3D in get_tree().get_nodes_in_group("resupply_crate"):
		if _flat_dist(c) <= CRATE_REACH:
			return true
	return false


## Nearest guard within reach: a Down one to carry, or one that can be choked.
func _nearest(down: bool, alive := false) -> Node3D:
	var best: Node3D
	var best_d := TAKEDOWN_REACH
	for g in get_tree().get_nodes_in_group("guards"):
		var d := _flat_dist(g)
		if d <= best_d and ((g.is_down() and not (alive and g.dead)) if down else g.can_be_choked(global_position)):
			best = g
			best_d = d
	return best
