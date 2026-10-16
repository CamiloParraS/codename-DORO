## A guard: senses the Operative, feeds its GuardAlert, radios alerts, and exposes the moves its
## behaviour tree (guard_tree.tres) calls. Spawned by the Area at a guard post.
extends CharacterBody3D
class_name Guard

const BODY_HITS_TO_KILL := 2  # rifle body hits that kill; a headshot kills outright
const EYE := 1.6
const PATROL_SPEED := 1.8
const CHASE_SPEED := 4.5
const PAUSE := 1.5        # seconds at each patrol point
const REACHED := 1.0      # flat distance that counts as being at a point
const NEUTRALIZED_TIME := 90.0  # seconds a Neutralized guard stays Down
const CHECK_REACH := 1.5        # flat distance at which a guard checks a Down guard
const HEAD_HEIGHT := 1.45       # hits above this (local y) are headshots
const ORDER_LOOK := 8.0         # seconds a guard sent to a place looks around it
const HOLD_TIME := 30.0         # seconds a guard told to hold its position stays put
const FIRE_INTERVAL := 1.0     # seconds between an alerted guard's shots
const MARKS := ["", "?", "!", "?"]
const MARK_COLORS := [Color.WHITE, Color(1, 0.85, 0.2), Color(1, 0.2, 0.2), Color(1, 0.5, 0.1)]

var route: Array[Vector3] = []   # patrol points, walked in a loop
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
var carrier: Node3D              # the Operative carrying this guard
var order := {}                  # a believed radio order: {kind "go" / "hold", pos, time}
var known_down := false          # some guard has seen this one Down (Glaukopis's +60)
var helmet := false              # Headshots Countermeasure: a headshot counts as a body hit

var _wp := 0
var _fire_left := 0.0
var _pause := 0.0
var _clock := 0.0
@onready var _agent: NavigationAgent3D = $NavAgent
@onready var _mark: Label3D = $Mark
@onready var _bt: BTPlayer = $BTPlayer


func _ready() -> void:
	add_to_group("guards")
	_agent.velocity_computed.connect(_on_velocity_computed)


func _physics_process(delta: float) -> void:
	_clock += delta
	_agent.velocity = Vector3.ZERO  # stands still unless the tree walks it this frame
	if is_down():
		_down_tick(delta)
		return
	if held:
		return
	if stumble_left > 0.0:
		stumble_left -= delta
		if stumble_left <= 0.0:
			neutralize()
			return
	if operative:
		var down := _sense_down()  # before tick: a Down guard in sight holds off the drain
		_react(alert.see_down(delta, down[0], down[1]))
		var rate := _sense()
		_react(alert.tick(delta, rate, operative.global_position, _saw, arrived()))
		_shoot_back(delta)
		if alert.state in [GuardAlert.State.SUSPICION, GuardAlert.State.EVASION] and arrived():
			var down_guard := _down_within(CHECK_REACH)
			if down_guard:
				var why := alert.check_down(down_guard.dead)
				if not down_guard.dead:
					get_tree().call_group("mission_tally", "event", "woken")
					down_guard.wake(global_position)
				_react(why)
	if stumble_left > 0.0:
		return  # stumbling: stands still
	_check_in(delta)
	# Manual update: the tree must set the velocity before the NavAgent (a later child) submits it.
	_bt.update(delta)


## An alerted guard that sees the Operative within range fires every FIRE_INTERVAL; the shot lands by
## Health.hit_chance. It can't fire while stumbling or held (both return before this).
func _shoot_back(delta: float) -> void:
	var d := _flat_dist(operative.global_position)
	if alert.state != GuardAlert.State.ALERT or seen_rate <= 0.0 or d > Health.RANGE:
		_fire_left = FIRE_INTERVAL  # a reaction delay before the first shot
		return
	_fire_left -= delta
	if _fire_left > 0.0:
		return
	_fire_left = FIRE_INTERVAL
	_muzzle_flash()
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
	if checkin.tick(delta):
		var line: String = Checkin.LINES.pick_random()
		get_tree().call_group("radio_log", "say", name, line)
	if operative:
		operative.voiceprints.tick(delta, name, _flat_dist(operative.global_position), checkin.on_air(alert.state))
	_refresh_mark()


func _refresh_mark() -> void:
	var talk := checkin.on_air(alert.state)
	_mark.text = "((·))" if talk else MARKS[alert.state]
	_mark.modulate = Color.WHITE if talk else MARK_COLORS[alert.state]


func is_down() -> bool:
	return dead or neutral_left > 0.0


## Put out of action (a choke); choking a Neutralized guard again restarts the clock.
func neutralize() -> void:
	neutral_left = NEUTRALIZED_TIME
	stumble_left = 0.0
	held = false
	alert = GuardAlert.new()
	order = {}
	seen_rate = 0.0
	_mark.text = ""
	collision_layer = 0
	_lie(true)


## Killed (a rifle shot): Down for good. Counts for Lethality and Combat; a kill while any guard is
## alerted is an alert_kill.
func kill() -> void:
	if dead:
		return
	var alerted := get_tree().get_nodes_in_group("guards").any(func(g): return g.alert.state == GuardAlert.State.ALERT)
	neutralize()
	dead = true
	get_tree().call_group("mission_tally", "event", "kill")
	if alerted:
		get_tree().call_group("mission_tally", "event", "alert_kill")


## A rifle bullet from `from`: a headshot kills at once (a helmet makes it a body hit), the second body
## hit kills, and a first one leaves it suspicious where the shot came from.
func shoot(head: bool, from: Vector3) -> void:
	if head:
		get_tree().call_group("mission_tally", "event", "headshot")
	hits += 1
	if bullet_kills(head, helmet, hits):
		kill()
	else:
		_changed(alert.hear(from, "a bullet"))


## Does a rifle bullet kill: an unhelmeted headshot always, otherwise the BODY_HITS_TO_KILL-th hit.
static func bullet_kills(head: bool, has_helmet: bool, hit_count: int) -> bool:
	return (head and not has_helmet) or hit_count >= BODY_HITS_TO_KILL


## A tranq dart from `from`: a headshot Neutralizes at once (a helmet makes it a body shot), a body
## shot after BODY_DELAY, meanwhile the guard stumbles, is suspicious and can't radio.
func tranquilize(head: bool, from: Vector3) -> void:
	if head:
		get_tree().call_group("mission_tally", "event", "headshot")  # the habit counts, helmet or not
	if head and not helmet:
		neutralize()
		return
	if stumble_left > 0.0:
		return
	stumble_left = Tranq.BODY_DELAY
	_changed(alert.hear(from, "a dart"))


## Headshots Countermeasure: a visible helmet; headshots count as body hits from now on.
func wear_helmet() -> void:
	helmet = true
	var m := MeshInstance3D.new()
	m.name = "Helmet"
	var dome := SphereMesh.new()
	dome.radius = 0.4
	dome.height = 0.4
	dome.is_hemisphere = true
	m.mesh = dome
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.26, 0.2)
	m.material_override = mat
	m.position.y = 0.62  # on the crown of the Body capsule, lies down with it
	$Body.add_child(m)


## Back on its feet, suspicious and remembering nothing. from: where it looks first.
func wake(from: Vector3) -> void:
	neutral_left = 0.0
	known_down = false
	hits = 0
	if carrier:  # no longer Down: off the Operative's shoulder
		carrier.carrying = null
		carrier = null
	collision_layer = 2
	_lie(false)
	_changed(alert.wake(from))


## Can the Operative at `from` choke this guard: not Down, not alerted, outside its front cone.
func can_be_choked(from: Vector3) -> bool:
	if is_down() or alert.state >= GuardAlert.State.ALERT:
		return false
	return not GuardVision.in_front(from - global_position, -global_basis.z)


func _lie(on: bool) -> void:
	$Body.rotation.x = PI / 2 if on else 0.0
	$Shape.rotation.x = PI / 2 if on else 0.0
	$Body.position.y = 0.35 if on else 0.9
	$Shape.position.y = 0.35 if on else 0.9


func _down_tick(delta: float) -> void:
	if carrier:  # fixed shoulder pose: lying across the Operative's shoulders
		global_position = carrier.global_position + Vector3.UP * 1.0
		rotation.y = carrier.carry_yaw() + PI / 2
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


## Every guard within radius of pos hears it (GuardAlert.in_earshot: through walls).
static func broadcast(tree: SceneTree, pos: Vector3, radius: float, what: String) -> void:
	for g in tree.get_nodes_in_group("guards"):
		if GuardAlert.in_earshot(g.global_position, pos, radius):
			g.on_noise(pos, what)


## Applies a state change, and radios everyone when it raised an alert by sight.
func _react(why: String) -> void:
	_changed(why)
	if why != "" and alert.state == GuardAlert.State.ALERT and stumble_left <= 0.0:
		for g in get_tree().get_nodes_in_group("guards"):
			if g != self:
				g.on_radio(alert.last_known, name)


## Another guard radioed an alert.
func on_radio(pos: Vector3, who: String) -> void:
	if is_down():
		return
	_changed(alert.radio(pos, who))


## A noise reached this guard.
func on_noise(pos: Vector3, what: String) -> void:
	if is_down():
		return
	_changed(alert.hear(pos, what))


## Sets seen_rate (0 = not seen) and, when seen, _saw to what was seen.
func _sense() -> float:
	seen_rate = 0.0
	var eye := global_position + Vector3.UP * EYE
	var chest: Vector3 = operative.global_position + Vector3.UP * operative.chest_height()
	var offset := chest - eye
	var facing := -global_basis.z
	var rate := GuardVision.fill_rate(offset, facing, operative.looks_crouched(), operative.moving, operative.looks_walking())
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
	_refresh_mark()
	_bt.restart()  # the tree picks the branch for the new state


## At alert.last_known, or as close as the navmesh gets (a spot on a crate, behind a wall).
func arrived() -> bool:
	return _at(alert.last_known)


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
	if GuardVision.fill_rate(chest - eye, -global_basis.z, false, false, false) <= 0.0:
		return false
	var q := PhysicsRayQueryParameters3D.create(eye, chest, 1, [get_rid(), other.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


# --- Moves called by the behaviour tree -------------------------------------------------------

func patrol(delta: float) -> void:
	if route.is_empty():
		return
	if _pause > 0.0:
		_pause -= delta
		return
	_walk_to(route[_wp], PATROL_SPEED, delta)
	if _flat_dist(route[_wp]) < REACHED:
		_wp = (_wp + 1) % route.size()
		_pause = PAUSE


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
	if arrived():
		rotation.y += sin(_clock * 1.1) * sweep * delta
	else:
		_walk_to(alert.last_known, speed, delta)


func chase(delta: float) -> void:
	_walk_to(alert.last_known, CHASE_SPEED, delta)
	if seen_rate > 0.0:
		face(operative.global_position, delta)


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
