## Minimal pause screen (Esc): the current objective; resume, or restart from the last Checkpoint
## (group "checkpoint", the MissionRun).
## ponytail: the menus ticket grows it into the full pause menu (abort, settings, quit).
extends Control

var _font: Font = load("res://assets/fonts/press_start_2p_regular.ttf")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause") and (visible or not get_tree().paused):  # not over the post-Mission screen
		_show(not visible)
	elif visible and e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_R:
		_show(false)
		get_tree().call_group("checkpoint", "restore_checkpoint")
	else:
		return
	get_viewport().set_input_as_handled()


func _show(on: bool) -> void:
	visible = on
	queue_redraw()  # the objective may have moved on
	get_tree().paused = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_CAPTURED


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.7))
	_centered(size.y / 2 - 50, "PAUSED", Color.WHITE, 12)
	var run := get_tree().get_first_node_in_group("checkpoint")
	if run:
		_centered(size.y / 2 - 22, run.objective(), Color.WHITE, 8)
	_centered(size.y / 2 + 10, "ESC  RESUME", Color(1, 1, 1, 0.85), 8)
	_centered(size.y / 2 + 26, "R  RESTART FROM CHECKPOINT", Color(1, 1, 1, 0.85), 8)


func _centered(y: float, s: String, col: Color, fs: int) -> void:
	draw_string(_font, Vector2(size.x / 2 - s.length() * fs / 2.0, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
