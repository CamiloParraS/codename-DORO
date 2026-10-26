## A guard: senses the Operative, feeds its GuardAlert, makes its Radio calls to the Area's AlertChain
## (shouting to the guards in earshot), and exposes the moves its behaviour tree (guard_tree.tres)
## calls. Spawned by the Area at a guard post.
extends CharacterBody3D
class_name Guard

const CHATTER_EVERY := 20.0  # seconds between a guard muttering about the Operative's Habits
const BODY_HITS_TO_KILL := 2  # rifle body hits that kill; a headshot kills outright
const EYE := 1.6
const PATROL_SPEED := 1.8
const CAUTION_SPEED := 2.2
const CHASE_SPEED := 5.0  # the Operative runs 4.8
const PAUSE := 1.5        # seconds at each patrol point
const SCAN_PERIOD := 6.0  # seconds for one sweep there and back at a scanning stop
const REACHED := 1.0      # flat distance that counts as being at a point
const NEUTRALIZED_TIME := 90.0  # seconds a Neutralized guard stays Down
const SAFE_REACH := 2.0         # flat distance at which a fleeing Target is in its safe room
const CHECK_REACH := 1.5        # flat distance at which a guard checks a Down guard
const HIT_TIME := 0.7          # seconds the hit reaction plays on a non-lethal hit
const HEAD_HEIGHT := 1.45       # hits above this (local y) are headshots
const ORDER_LOOK := 8.0         # seconds a guard sent to a place looks around it
const HOLD_TIME := 30.0         # seconds a guard told to hold its position stays put
const LOOK_CLIP := 6.0          # seconds of the look-around clip at an Evasion search spot
const ROOF_REACH := 15.0        # flat metres from a Ladder's top that count as the roof it serves
const FIRE_INTERVAL := 1.0     # seconds between an alerted guard's shots
const RISE_TIME := 4.0          # seconds a Fultoned guard takes to rise out of sight
const BALLOON_TIME := 6.0       # seconds after launch that guards can see the balloon
const BALLOON_SEEN := 20.0      # flat metres from the spot within which a guard who sees it comes to look
const MARKS := ["", "?", "!", "?"]
const MARK_COLORS := [Color.WHITE, Color(1, 0.85, 0.2), Color(1, 0.2, 0.2), Color(1, 0.5, 0.1)]

var route: Array[Vector3] = []   # patrol points, walked in a loop
var stops: Array[Dictionary] = []  # per route point (a sentry: its one spot): {yaw, scan[, hold]} from the Area; {} = a plain pause
var chat: Chat                   # a chatting pair's shared turns (seat 0 ticks them)
var chat_seat := 0
var gesture := Gesture.new()    # which talking clip its next line plays
var chat_partner: Guard
var target_chat: TargetChatter   # a Target's lines with his escort (chat_partner), once per Mission
var post: Transform3D            # where it was spawned: a Checkpoint restore puts it back here
var operative: Node3D               # the Operative
var alert := GuardAlert.new()
var checkin := Checkin.new()
var seen_rate := 0.0
var last_reason := ""            # for the debug overlay
var _saw := ""                   # what _sense() saw this frame
var neutral_left := 0.0          # seconds until a Neutralized guard wakes
var dead := false                # killed: Down for good, and a guard who checks it radios an alert
var hits := 0                    # rifle body hits taken
var stumble_left := 0.0          # after a body dart: seconds until Neutralized
var held := false                # being choked: stands still
var held_up := false             # Hold-up: frozen at gunpoint (Operative), until released
var answered := false            # gave its one Hold-up answer
var holdup_answer := ""          # what a Hold-up gets out of it (text key holdup.<answer>); "" = its Voiceprint
var carrier: Node3D:             # the Operative carrying this guard
	set(v):
		carrier = v
		model.ride(v.model.carry_mount() if v else null)
var order := {}                  # a believed radio order: {kind "go" / "hold", pos, time}
var known_down := false          # some guard has seen this one Down (Glaukopis's +60)
var helmet := false              # Headshots Countermeasure: a headshot counts as a body hit
var vest := false                # Combat L1: tranq body shots do nothing, rifle body hits take longer
var body_hits_to_kill := BODY_HITS_TO_KILL
var turn_every := 0.0            # Takedowns L1: seconds between glances behind (0 = never)
var head_check_level := 0        # Stealth Countermeasure: how often it glances back before turning (Telegraph)
var rng := RandomNumberGenerator.new()  # seed it for a repeatable run
var radio_check_level := 0       # Spoofing Countermeasure: how often it stops to call HQ back (Telegraph)
var instant_down := false        # Downs L2: seeing a Down guard raises the alert, no check
var target := false              # a Mission Target: unarmed, weighs 3, flees to safe_room on alert
var safe_room := Vector3.ZERO    # where a Target runs on alert and stays until evasion ends
var encounter := 0               # the Encounter its post belongs to (0 = none)
var detours: Array[Vector3] = [] # spots in its Encounter, one visited per patrol loop in Caution (the Area sets them)

var _wp := 0
var _stop := {}          # the stop being held
var _turn_clock := 0.0
var _glance := 0.0       # seconds left of a glance behind
var _glance_yaw := 0.0
var _fire_left := 0.0
var _pause := 0.0
var _clock := 0.0
var chatter_sets: Array = []     # VoiceLines.chatter_sets: what this guard mutters about, if the Operative is near
var _chatter_clock := CHATTER_EVERY
var _radio_clock := 0.0
var _tele_left := 0.0    # seconds left of the shared Aigis telegraph icon
var _tele_icon := ""
var _looked := false    # did the look-around at this search spot already
var _prev_state := GuardAlert.State.PATROL
var _prev_calling := false
var voice := GuardVoice.new()  # its one voice player: barks and radio lines
var _was_calling := false      # on the radio last frame
var _vstate := GuardAlert.State.PATROL  # the state last frame, for state barks
var _vphase := AlertChain.Phase.NORMAL
var _vheld := false
var _vsearched := false        # said "search" on reaching this suspicion's spot
var _detour: Variant = null  # the Caution detour it walks now
var _next_detour := 0
var _spot_for: Variant = null  # the last known point its reserved search spot is for
var _balloon: Node3D           # Fultoned: the balloon on its way up
var _balloon_left := 0.0
var _balloon_spot := Vector3.ZERO
var _balloon_seen: Array[Guard] = []
@onready var _agent: NavigationAgent3D = $NavAgent
@onready var _mark: Label3D = $Mark
@onready var _bt: BTPlayer = $BTPlayer
@onready var model: CharacterModel = $Model


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
	_agent.velocity_computed.connect(_on_velocity_computed)


func _physics_process(delta: float) -> void:
	_clock += delta
	_tele_left -= delta
	if GuardAlert.flinches(_prev_state, alert.state) and not _prev_calling:  # a spotter flinched at his "!"
		model.react("startle", GuardAlert.FLINCH, 2.2)  # a pose only: the tree and shooting never wait on it
	_prev_state = alert.state
	_prev_calling = alert.calling
	var flat := Vector2(velocity.x, velocity.z).length()
	model.play("kneel" if held_up else CharacterModel.guard_clip(is_down(), flat), flat)
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
	if randf() < Health.hit_chance(d, operative.moving and not operative.looks_walking()):
		operative.take_hit()


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
	if chat and chat_seat == 0:
		var line := chat.tick(delta)
		var who: Guard = self if chat.speaker() == 0 else chat_partner
		# Chat isn't radio: a subtitle only when the Operative is close enough to overhear it.
		if line != "" and is_instance_valid(who) and who.chatting() and operative and who._flat_dist(operative.global_position) <= Chat.HEARD:
			get_tree().call_group("radio_log", "say", who.name, tr(line))
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
		get_tree().call_group("radio_log", "say", who.name, tr(line.key))
		who.speak_gesture(TargetChatter.TURN)


## Talks with its hands for one line of `seconds`; react() leaves it standing in idle after.
func speak_gesture(seconds: float) -> void:
	if not is_down() and not held_up:
		model.react(gesture.next(), seconds)


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
		radio_say(tr(VoiceLines.pick(chatter_sets, rng)))


## Barks off what changed this frame: a choke, the Radio call ending (squelch off), Caution ending, the
## guard's state. Silent when it is Down or rising on a balloon.
func _voice_tick(delta: float) -> void:
	var calling := AlertChain.area.calling(self)
	if _was_calling and not calling:
		Mixer.play(&"radio_off", Mix.RADIO)  # a cut call never gets here: _cut_call cleared _was_calling
	_was_calling = calling
	var phase := AlertChain.area.phase
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


## A choke, Hold-up, dart or Down stops the Radio call: the line is cut and no off squelch plays.
func _cut_call() -> void:
	_was_calling = false
	voice.cut_call()


## Talking where a Voiceprint can be recorded: a check-in on patrol, or its turn in a chat.
func on_air() -> bool:
	return checkin.on_air(alert.state) or chatting()


## Its turn in the chat, with both of the pair up and on patrol.
func chatting() -> bool:
	return chat != null and chat.speaker() == chat_seat and alert.state == GuardAlert.State.PATROL and partner_calm()


## Its partner (chat or escort) is still in the Area (a Fultoned one is freed), up and on patrol.
func partner_calm() -> bool:
	return is_instance_valid(chat_partner) and not chat_partner.is_down() and chat_partner.alert.state == GuardAlert.State.PATROL


func _refresh_mark() -> void:
	var talk := on_air()
	if _tele_left > 0.0 and (alert.state == GuardAlert.State.PATROL or _tele_icon == Telegraph.FLANK_ICON):
		_mark.text = _tele_icon
		_mark.modulate = HudPalette.AIGIS
		return
	var bang := alert.calling or alert.rushing  # "!" before the Alert: a spotter calling, a responder running
	var state := GuardAlert.State.ALERT if bang else alert.state
	_mark.text = "((·))" if talk else MARKS[state]
	_mark.modulate = Color.WHITE if talk else MARK_COLORS[state]


func is_down() -> bool:
	return dead or neutral_left > 0.0


## Could it answer an HQ poll right now: up, not being choked, not stumbling from a dart.
func can_radio() -> bool:
	return not is_down() and not held and not held_up and stumble_left <= 0.0


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
	_mark.text = ""
	collision_layer = 0
	_lie(true)
	if dropped:
		Mix.sfx_at(self, &"body_fall")
		_partners_see()


## Killed (a rifle shot): Down for good. Counts for Lethality and Combat; a kill while any guard is
## alerted is an alert_kill.
func kill() -> void:
	if dead:
		return
	var alerted := get_tree().get_nodes_in_group("guards").any(func(g): return g.alert.state == GuardAlert.State.ALERT)
	neutralize()
	dead = true
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
		kill()
	else:
		model.react("hit", HIT_TIME)
		voice.say(&"pain")
		_changed(alert.hear(from, "a bullet"))


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
	var what := Holdup.answer(holdup_answer, not str(name) in op.voiceprints.held, intel != "")
	Mixer.blip(0.8)  # a guard's voice blip under his line
	match what:
		"voiceprint":
			op.voiceprints.held.append(str(name))
			get_tree().call_group("mission_tally", "event", "interrogated_voiceprint")
		"objective":  # where, on the INTEL line (MissionRun._say_objective's)
			get_tree().call_group("radio_log", "say", "INTEL", intel)
		"scan":
			op.items.scan_left = op.items.scan_time
	radio_say(tr("holdup." + what))


## Can a Fulton take it: Neutralized (darted, choked) or kneeling at gunpoint; never the dead.
func can_be_fultoned() -> bool:
	return (is_down() and not dead) or held_up


## Fultoned: a balloon lifts it out of the Area for good (the Operative already took it out of "guards").
## It rises over RISE_TIME s; for BALLOON_TIME s every guard within BALLOON_SEEN m of the spot with a line
## of sight to the balloon comes to look (_balloon_tick). Silent.
func fulton() -> void:
	held_up = false
	_mark.text = ""
	_balloon_left = BALLOON_TIME
	Mix.sfx_at(self, &"fulton_launch")
	var lift := Mix.sfx_at(self, &"fulton_lift")
	lift.pitch_scale = 1.0
	create_tween().tween_property(lift, "pitch_scale", 1.6, RISE_TIME)  # pitched up as it rises
	_balloon_spot = global_position
	_balloon = MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.8
	ball.height = 1.6
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.9, 0.85, 0.75)
	ball.material = m
	_balloon.mesh = ball
	_balloon.position.y = 3.0
	add_child(_balloon)
	var t := create_tween()
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


## Does it have a clear line of sight to point p (a Fulton balloon: seen whichever way it faces).
func sees_point(p: Vector3) -> bool:
	if is_down():
		return false
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * EYE, p, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _lie(on: bool) -> void:
	$Shape.rotation.x = PI / 2 if on else 0.0
	$Shape.position.y = 0.35 if on else 0.9


func _down_tick(delta: float) -> void:
	if carrier:  # the model lies in a fixed pose on the shoulder bone; the body just follows
		global_position = carrier.global_position
	elif not dead:
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


## Could it see `other` drop: in its front cone within PARTNER_RANGE, with a clear line to the chest.
func sees_drop(other: Node3D) -> bool:
	var eye := global_position + Vector3.UP * EYE
	var chest := other.global_position + Vector3.UP * 1.3
	if _flat_dist(other.global_position) > GuardAlert.PARTNER_RANGE or not GuardVision.in_front(chest - eye, -global_basis.z):
		return false
	return _clear(eye, chest, other)


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
			g.on_shot(pos) if alarming else g.on_noise(pos, what)


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
			model.react("hand_to_ear", AlertChain.CALL_TIME - GuardAlert.FLINCH))
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


func _changed(why: String) -> void:
	if why == "":
		return
	last_reason = why
	order = {}  # whatever it was told, it now has its own reason to act
	AlertChain.area.release(self)  # a new state: any search spot it held is free
	_spot_for = null
	_refresh_mark()
	_bt.restart()  # the tree picks the branch for the new state


## At the goal, or as close as the navmesh gets (a spot on a crate, behind a wall).
func arrived() -> bool:
	if _fleeing():
		return _flat_dist(safe_room) < SAFE_REACH or _at(safe_room)
	return _at(goal())


## A Target on alert or in evasion runs to its safe room and stays there until the evasion ends.
func _fleeing() -> bool:
	return flees(target, alert.state)


static func flees(is_target: bool, state: int) -> bool:
	return is_target and state >= GuardAlert.State.ALERT


## Where the spot it searches is reached from: the foot of the Ladder when it's up on that Ladder's roof
## (guards never climb, they watch the base), otherwise the spot itself. A `walkable` Ladder lands on
## ground guards walk to (the Relay station's), so they go to the spot.
func goal() -> Vector3:
	return ladder_foot(search_spot(), get_tree().get_nodes_in_group("ladders"))


## What it searches: in Evasion or a responder's local search, the spot it reserved near the last known
## point (AlertChain.reserve); otherwise the last known point.
func search_spot() -> Vector3:
	if alert.state != GuardAlert.State.EVASION and not alert.rushing:
		return alert.last_known
	if _spot_for != alert.last_known:  # the search moved (a noise): give up the old spot
		AlertChain.area.release(self)
		_spot_for = alert.last_known
	return AlertChain.area.reserve(self, alert.last_known)


static func ladder_foot(p: Vector3, ladders: Array) -> Vector3:
	for l: Node3D in ladders:
		if l.has_meta("walkable"):
			continue
		var top: Vector3 = l.get_node("Top").global_position
		if p.y > top.y - 0.5 and Vector2(p.x - top.x, p.z - top.z).length() < ROOF_REACH:
			return l.get_node("Bottom").global_position
	return p


func _at(t: Vector3) -> bool:
	if _flat_dist(t) < REACHED:
		return true
	return _agent.target_position.is_equal_approx(t) and _agent.is_navigation_finished()


# --- Radio -------------------------------------------------------------------------------------

## A line on the radio (an ack, an exposure line): a subtitle only. It isn't a check-in, so no ((·))
## and no Voiceprint capture.
func radio_say(line: String) -> void:
	get_tree().call_group("radio_log", "say", name, line)


## A believed Spoofed order from `who`: "go" to pos or "hold" here. A suspicious or searching guard
## drops its search for it; an alerted one keeps hunting. True when it obeys.
func obey(kind: String, pos: Vector3, who: String) -> bool:
	if is_down() or alert.state == GuardAlert.State.ALERT:
		return false
	_changed(alert.stand_down(who, kind))
	order = {kind = kind, pos = pos, time = 0.0}
	_bt.restart()
	return true


## A believed "all clear" from `who`: back to patrol.
func stand_down(who: String) -> void:
	_changed(alert.stand_down(who))


## Could this guard see `other` right now: its vision cones and a clear line to the chest.
func can_see(other: Node3D) -> bool:
	var eye := global_position + Vector3.UP * EYE
	var chest := other.global_position + Vector3.UP * 1.3
	return GuardVision.fill_rate(chest - eye, -global_basis.z, false, false, false) > 0.0 and _clear(eye, chest, other)


func _clear(eye: Vector3, chest: Vector3, other: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(eye, chest, 1, [get_rid(), other.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


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
			model.react("look", LOOK_CLIP, 1.0)
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


func face(pos: Vector3, delta: float) -> void:
	var d := pos - global_position
	if Vector2(d.x, d.z).length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 8 * delta)


func _walk_to(pos: Vector3, speed: float, delta: float) -> void:
	if not _agent.target_position.is_equal_approx(pos):
		_agent.target_position = pos
	var next := _agent.get_next_path_position()
	var dir := Vector3(next.x - global_position.x, 0, next.z - global_position.z)
	if dir.length() < 0.05:
		return
	dir = dir.normalized()
	_agent.velocity = dir * speed  # avoidance answers in _on_velocity_computed
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 8 * delta)


func _on_velocity_computed(safe: Vector3) -> void:
	velocity = Vector3(safe.x, 0, safe.z)
	move_and_slide()


func _flat_dist(pos: Vector3) -> float:
	return Vector2(pos.x - global_position.x, pos.z - global_position.z).length()
