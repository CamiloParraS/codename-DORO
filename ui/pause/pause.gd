## Pause menu (Esc): the current objective and the controls, then Resume, Restart from checkpoint
## (group "checkpoint", the MissionRun), Abort Mission (back to where the Mission was started from,
## nothing applied), Settings and Quit to menu (confirmed).
extends Control

const SettingsPanel := preload("res://ui/settings/settings_panel.gd")
const MENU := "res://ui/main_menu/main_menu.tscn"
const CONTROLS := ["walk", "crouch", "aim", "fire", "reload", "weapon_tranq", "weapon_rifle", "interact", "kill_takedown", "knock", "radio"]

var _objective := Label.new()
var _menu := VBoxContainer.new()
var _resume: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	theme = Theme.new()
	theme.default_font = load("res://assets/fonts/press_start_2p_regular.ttf")
	theme.default_font_size = 8
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_menu.position = Vector2(24, 24)
	add_child(_menu)
	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 12)
	_menu.add_child(title)
	_menu.add_child(_objective)
	_resume = _button("RESUME", func() -> void: _show(false))
	_button("RESTART FROM CHECKPOINT", func() -> void:
		_show(false)
		get_tree().call_group("checkpoint", "restore_checkpoint"))
	_button("ABORT MISSION", _abort)
	_button("SETTINGS", _settings)
	_button("QUIT TO MENU", func() -> void: _confirm("QUIT TO MENU? THE MISSION IS LOST.", _quit))
	var controls := Label.new()
	controls.text = "WASD MOVE  " + "  ".join(CONTROLS.map(func(a: String) -> String:
		var ev := InputMap.action_get_events(a)
		return "%s %s" % [ev[0].as_text().get_slice(" (", 0) if ev else "?", a.get_slice("_", a.count("_")).to_upper()])).to_upper()
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD
	controls.custom_minimum_size.x = 590
	controls.modulate.a = 0.6
	_menu.add_child(controls)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause") and (visible or not get_tree().paused):  # not over the post-Mission screen
		_show(not visible)
		get_viewport().set_input_as_handled()


func _show(on: bool) -> void:
	visible = on
	Mixer.click()
	var run := get_tree().get_first_node_in_group("checkpoint")
	_objective.text = run.objective() if run else ""  # the objective may have moved on
	get_tree().paused = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_CAPTURED
	if on:
		_resume.grab_focus()


func _abort() -> void:
	var run := get_tree().get_first_node_in_group("checkpoint")
	var back: String = run.return_to if run else MENU
	if run:
		run.abort()
	_leave(back if back != "" else MENU)


func _quit() -> void:
	var run := get_tree().get_first_node_in_group("checkpoint")
	if run:
		run.abort()
	_leave(MENU)


func _leave(scene: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)


func _settings() -> void:
	_menu.hide()
	var p := SettingsPanel.new()
	p.position = Vector2(24, 24)
	p.closed.connect(func() -> void:
		_menu.show()
		_resume.grab_focus())
	add_child(p)


func _confirm(text: String, yes: Callable) -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = text
	d.process_mode = Node.PROCESS_MODE_ALWAYS
	d.confirmed.connect(yes)
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered()


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(on_press)
	_menu.add_child(b)
	return b
