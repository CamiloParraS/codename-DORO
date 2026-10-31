## The guard's state and the ground floor its layers stand on (guard_moves.gd, guard_downs.gd, then guard.gd,
## class_name Guard, extend it): tuning, marks over the head, what it can see, where it is going and how it walks.
extends CharacterBody3D

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
const DROP_PUSH := 1.2          # m/s on the pelvis of a guard that goes Down
const SHOT_PUSH := 4.5          # m/s where a rifle bullet lands: the head takes it faster, as it weighs less
const HEAD_SHOT_PUSH := 6.0
const FLINCH_PUSH := 2.5        # m/s a hit that does not drop it shoves the bone it landed on
const HIT_STAGGER := 0.3        # m a non-lethal rifle hit knocks a guard back
const GLANCE_RANGE := 5.0       # m, how close the Operative is for a patrolling guard to turn its head to them
const LOOK_CLIP := 6.0          # seconds of the look-around clip at an Evasion search spot
const ROOF_REACH := 15.0        # flat metres from a Ladder's top that count as the roof it serves
const FIRE_INTERVAL := 1.0     # seconds between an alerted guard's shots
const MISS_BY := 0.7           # metres a missed shot passes from the Operative's chest
const WHIZ_RANGE := 2.0        # metres: a miss passing this close to the Operative's chest whizzes past it
const RISE_TIME := 4.0          # seconds a Fultoned guard takes to rise out of sight
const BALLOON_TIME := 6.0       # seconds after launch that guards can see the balloon
const BALLOON_SEEN := 20.0      # flat metres from the spot within which a guard who sees it comes to look
const SLEEP_ICON := preload("res://assets/ui/icons/sleep.svg")
const MARK_ICONS := preload("res://assets/ui/icons/marks.svg")  # frames, in the order of MARK_FRAMES
const HANDS_UP_SCALE := 0.6  # the kneeling figure is a bigger glyph than a ? or !, so it is drawn smaller
const MARK_FRAMES := {"?": 0, "!": 1, "hands up": 2, "!>": 3, "((?))": 4, "((·))": 5}
const MARKS := ["", "?", "!", "?"]
const MARK_COLORS := [HudPalette.LIGHT, HudPalette.LIGHT, HudPalette.MARK_RED, HudPalette.SAND]  # the shape (? or !) carries the state; hue backs it

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
var _fell := false               # killed on its feet: the model plays the fall, not the sleeping pose
var hits := 0                    # rifle body hits taken
var stumble_left := 0.0          # after a body dart: seconds until Neutralized
var _shot_from := Vector3.INF   # where the bullet that kills it came from, while it goes Down
var _shot_head := false
var held := false                # being choked: stands still
var held_up := false             # Hold-up: frozen at gunpoint (Operative), until released
var answered := false            # gave its one Hold-up answer
var holdup_answer := ""          # what a Hold-up gets out of it (text key holdup.<answer>); "" = its Voiceprint
var carrier: Node3D:             # the Operative carrying this guard
	set(v):
		carrier = v
		_fell = false  # dropped again, it lies in the plain down pose instead of falling a second time
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
var carry_only := false          # a Target a Fulton would kill (Campaign `carry_only`): carried out on foot
var target := false              # a Mission Target: unarmed, weighs 3, flees to safe_room on alert
var safe_room := Vector3.ZERO    # where a Target runs on alert and stays until evasion ends
var role := ""                   # its post's role (patroller, observer...), "" = none
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
var _glint: Node3D             # a red radio glint at the head while on the Radio call
var _vest: Node3D              # an amber vest light while the Area is in Caution
@onready var _agent: NavigationAgent3D = $NavAgent
@onready var _mark: Label3D = $Mark
var _sleep: Sprite3D  # the asleep mark, see _sleep_mark()
var _mark_art: Sprite3D  # the pixel art for what _mark says, see _sync_mark()
@onready var _bt: BTPlayer = $BTPlayer
@onready var model: CharacterModel = $Model


var ping_age := 99.0  # s since this guard last made a noise (a step, a line): the Radar shows him while it is young
var _step_left := 0.0


## This guard made a noise the Radar can pick up.
func ping() -> void:
	ping_age = 0.0


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


## The pixel "zZz" over a knocked-out guard, built on first use; small, so it reads as a hint and not a label.
func _sleep_mark() -> Sprite3D:
	if _sleep == null:
		_sleep = Sprite3D.new()
		_sleep.texture = SLEEP_ICON
		_sleep.pixel_size = 0.0035
		_sleep.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_sleep.no_depth_test = true
		_sleep.shaded = false
		_sleep.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_sleep.position = _mark.position
		add_child(_sleep)
	return _sleep


func _refresh_mark() -> void:
	_set_mark()
	_sync_mark()


## Shows the pixel art for the Label3D's text (which stays the state of record); no art for an empty or unknown text.
func _sync_mark() -> void:
	if _mark_art == null:
		_mark_art = Fx.pixel_sprite(MARK_ICONS, 0.045)
		_mark_art.hframes = MARK_FRAMES.size()
		_mark_art.no_depth_test = true
		_mark_art.render_priority = 5
		_mark_art.position = _mark.position
		add_child(_mark_art)
		_mark.visible = false
	_mark_art.visible = MARK_FRAMES.has(_mark.text)
	if _mark_art.visible:
		_mark_art.frame = MARK_FRAMES[_mark.text]
		_mark_art.scale = Vector3.ONE * (HANDS_UP_SCALE if _mark.text == "hands up" else 1.0)
		_mark_art.modulate = _mark.modulate


func _set_mark() -> void:
	if _sleep != null:
		_sleep.visible = false
	if dead:  # no symbol: zZz is only for the knocked out
		_mark.text = ""
		return
	if neutral_left > 0.0:  # asleep, and it wears off
		_mark.text = ""
		_sleep_mark().visible = true
		return
	var talk := on_air()
	if _tele_left > 0.0 and (alert.state == GuardAlert.State.PATROL or _tele_icon == Telegraph.FLANK_ICON):
		_mark.text = _tele_icon
		_mark.modulate = HudPalette.CYAN
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


## Does it have a clear line of sight to point p (a Fulton balloon: seen whichever way it faces).
func sees_point(p: Vector3) -> bool:
	if is_down():
		return false
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * EYE, p, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _lie(on: bool) -> void:
	$Shape.rotation.x = PI / 2 if on else 0.0
	$Shape.position.y = 0.35 if on else 0.9


## Could it see `other` drop: in its front cone within PARTNER_RANGE, with a clear line to the chest.
func sees_drop(other: Node3D) -> bool:
	var eye := global_position + Vector3.UP * EYE
	var chest := other.global_position + Vector3.UP * 1.3
	if _flat_dist(other.global_position) > GuardAlert.PARTNER_RANGE or not GuardVision.in_front(chest - eye, -global_basis.z):
		return false
	return _clear(eye, chest, other)


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

## A spoken conversation line (chat, escort, field chatter): subtitle plus its clip or mumble, from this guard.
func say_line(key: String) -> void:
	get_tree().call_group("radio_log", "say", name, tr(key))
	voice.speak(key, tr(key))


## A line on the radio (an ack, an exposure line): a subtitle only. It isn't a check-in, so no ((·))
## and no Voiceprint capture.
func radio_say(line: String) -> void:
	get_tree().call_group("radio_log", "say", name, line)


## Could this guard see `other` right now: its vision cones and a clear line to the chest.
func can_see(other: Node3D) -> bool:
	var eye := global_position + Vector3.UP * EYE
	var chest := other.global_position + Vector3.UP * 1.3
	return GuardVision.fill_rate(chest - eye, -global_basis.z, false, false, false) > 0.0 and _clear(eye, chest, other)


func _clear(eye: Vector3, chest: Vector3, other: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(eye, chest, 1, [get_rid(), other.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


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
