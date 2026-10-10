## A guard: senses the Operative, feeds its GuardAlert, radios alerts, and exposes the moves its
## behaviour tree (guard_tree.tres) calls. Spawned by the Area at a guard post.
extends CharacterBody3D

const EYE := 1.6
const PATROL_SPEED := 1.8
const CHASE_SPEED := 4.5
const PAUSE := 1.5        # seconds at each patrol point
const REACHED := 1.0      # flat distance that counts as being at a point
const MARKS := ["", "?", "!", "?"]
const MARK_COLORS := [Color.WHITE, Color(1, 0.85, 0.2), Color(1, 0.2, 0.2), Color(1, 0.5, 0.1)]

var route: Array[Vector3] = []   # patrol points, walked in a loop
var target: Node3D               # the Operative
var alert := GuardAlert.new()
var seen_rate := 0.0
var last_reason := ""            # for the debug overlay
var _saw := ""                   # what _sense() saw this frame

var _wp := 0
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
	if target:
		var rate := _sense()
		var why := alert.tick(delta, rate, target.global_position, _saw, arrived())
		_changed(why)
		if why != "" and alert.state == GuardAlert.State.ALERT:  # raised by sight: radio everyone
			for g in get_tree().get_nodes_in_group("guards"):
				if g != self:
					g.on_radio(alert.last_known, name)
	# Manual update: the tree must set the velocity before the NavAgent (a later child) submits it.
	_bt.update(delta)


## Another guard radioed an alert.
func on_radio(pos: Vector3, who: String) -> void:
	_changed(alert.radio(pos, who))


## Sets seen_rate (0 = not seen) and, when seen, _saw to what was seen.
func _sense() -> float:
	seen_rate = 0.0
	var eye := global_position + Vector3.UP * EYE
	var chest: Vector3 = target.global_position + Vector3.UP * target.chest_height()
	var offset := chest - eye
	var facing := -global_basis.z
	var rate := GuardVision.fill_rate(offset, facing, target.crouching, target.moving, target.walking)
	if rate == 0.0:
		return 0.0
	var q := PhysicsRayQueryParameters3D.create(eye, chest, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or hit["collider"] != target:
		return 0.0
	seen_rate = rate
	_saw = GuardVision.describe(offset, facing, target.crouching, target.moving, target.walking)
	return rate


func _changed(why: String) -> void:
	if why == "":
		return
	last_reason = why
	_mark.text = MARKS[alert.state]
	_mark.modulate = MARK_COLORS[alert.state]
	_bt.restart()  # the tree picks the branch for the new state


## At alert.last_known, or as close as the navmesh gets (a spot on a crate, behind a wall).
func arrived() -> bool:
	var t := alert.last_known
	if _flat_dist(t) < REACHED:
		return true
	return _agent.target_position.is_equal_approx(t) and _agent.is_navigation_finished()


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


func search(delta: float, speed: float, sweep: float) -> void:
	if arrived():
		rotation.y += sin(_clock * 1.1) * sweep * delta
	else:
		_walk_to(alert.last_known, speed, delta)


func chase(delta: float) -> void:
	_walk_to(alert.last_known, CHASE_SPEED, delta)
	if seen_rate > 0.0:
		face(target.global_position, delta)


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
