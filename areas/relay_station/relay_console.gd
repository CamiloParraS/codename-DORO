## The relay console: Mission 2's sabotage step. Standing still beside it with E held for hold_time s
## (in the open, so exposed) sabotages it, which completes the step like an intel pickup does. SWEEP_DELAY s
## later HQ radios the sweep and every guard not already alerted searches where it stands: suspicion, never alert.
## Any hold-E step reuses it (the Harbour's lift panel: 4 s, no sweep).
extends Area3D

signal reached

const HOLD_TIME := 5.0
const SWEEP_DELAY := 30.0
const LINE := "Relay's offline. All units, sweep the station."

@export var hold_time := HOLD_TIME
@export var prompt := "hold E to sabotage"
@export var sweeps := true
var held := 0.0
var done := false
var _operative: Node3D


func _enter_tree() -> void:
	add_to_group("intel")


func _ready() -> void:
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("operative"):
			_operative = b)
	body_exited.connect(func(b: Node3D) -> void:
		if b == _operative:
			_operative = null)


func _physics_process(delta: float) -> void:
	if not _operative or done:
		held = 0.0
		return
	tick(delta, Input.is_action_pressed("interact") and not _operative.moving)


## The line it adds to the Operative op's prompt (Operative._update_prompt), "" when he isn't at it.
func prompt_for(op: Node3D) -> String:
	return prompt if op == _operative and not done else ""


## One frame of holding (or not): the progress resets when released.
func tick(delta: float, holding: bool) -> void:
	if done:
		return
	held = held + delta if holding else 0.0
	if held >= hold_time:
		done = true
		reached.emit()
		if sweeps:
			get_tree().create_timer(SWEEP_DELAY).timeout.connect(sweep)


## HQ orders the sweep.
func sweep() -> void:
	get_tree().call_group("radio_log", "say", "HQ", LINE)
	for g in get_tree().get_nodes_in_group("guards"):
		g.on_noise(g.global_position, "HQ's sweep order")
