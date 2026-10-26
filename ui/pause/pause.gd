## Pause menu (Esc): the current objective and the controls, then Resume, Restart from checkpoint
## (group "checkpoint", the MissionRun), Abort Mission (back to where the Mission was started from,
## nothing applied), Settings and Quit to menu (confirmed in place). Fades in and out over HudPalette.FADE
## on a near-opaque scrim, with the HUD hidden underneath.
extends Control

const SettingsPanel := preload("res://ui/settings/settings_panel.gd")
const MENU := "res://ui/main_menu/main_menu.tscn"
## [action, verb key], in the order a player learns them; keys are read from the InputMap.
const CONTROLS := [
	["walk", "ui.ctl.walk"], ["crouch", "ui.ctl.crouch"], ["aim", "ui.ctl.aim"], ["fire", "ui.ctl.fire"],
	["reload", "ui.ctl.reload"], ["weapon_tranq", "ui.ctl.tranq"], ["weapon_rifle", "ui.ctl.rifle"],
	["interact", "ui.ctl.interact"], ["kill_takedown", "ui.ctl.kill"], ["fulton", "ui.ctl.fulton"],
	["item_use", "ui.ctl.item_use"], ["item_next", "ui.ctl.item_next"], ["knock", "ui.ctl.knock"],
	["radio", "ui.ctl.radio"], ["shoulder_swap", "ui.ctl.shoulder"],
]

var _open := false
var _objective := HudPalette.label("")
var _menu := VBoxContainer.new()
var _resume: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	theme = HudPalette.theme()
	var dim := ColorRect.new()
	dim.color = HudPalette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_menu.position = Vector2(24, 24)
	_menu.add_theme_constant_override("separation", 4)
	add_child(_menu)
	var title := HudPalette.label("ui.pause.title", HudPalette.TITLE_SIZE, HudPalette.WHITE)
	title.custom_minimum_size.y = 28
	_menu.add_child(title)
	_menu.add_child(HudPalette.label("ui.pause.objective", HudPalette.HEADING_SIZE, HudPalette.CHROME_DIM))
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD
	_objective.custom_minimum_size = Vector2(590, 22)
	_objective.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_objective.add_theme_color_override("font_color", HudPalette.WHITE)
	_menu.add_child(_objective)
	_resume = _button("ui.pause.resume", func() -> void: _show(false))
	_button("ui.pause.restart", func() -> void:
		_show(false)
		get_tree().call_group("checkpoint", "restore_checkpoint"))
	_button("ui.pause.abort", _abort)
	_button("ui.menu.settings", _settings)
	_button("ui.pause.quit", func() -> void: _confirm("ui.pause.quit_confirm", _quit))
	var gap := Control.new()
	gap.custom_minimum_size.y = 12
	_menu.add_child(gap)
	_menu.add_child(HudPalette.label("ui.pause.controls", HudPalette.HEADING_SIZE, HudPalette.CHROME_DIM))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("v_separation", 6)
	_menu.add_child(grid)
	var rows: Array = [["WASD", "ui.ctl.move"]]
	rows.append_array(CONTROLS.map(func(c: Array) -> Array: return [Prompts.key(c[0]), c[1]]))
	for r: Array in rows:
		var cell := HBoxContainer.new()
		cell.custom_minimum_size.x = 196
		var k := HudPalette.label(r[0], HudPalette.HEADING_SIZE, HudPalette.WHITE)
		k.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		k.custom_minimum_size.x = 48
		cell.add_child(k)
		cell.add_child(HudPalette.label(r[1], HudPalette.HEADING_SIZE, HudPalette.CHROME_DIM))
		grid.add_child(cell)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause") and (_open or not get_tree().paused):  # not over the post-Mission screen
		_show(not _open)
		get_viewport().set_input_as_handled()


func _show(on: bool) -> void:
	_open = on
	Mixer.click()
	var run := get_tree().get_first_node_in_group("checkpoint")
	_objective.text = run.objective() if run else ""  # the objective may have moved on
	get_tree().paused = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_CAPTURED
	var hud := get_tree().get_first_node_in_group("radio_log") as CanvasItem
	if hud:
		hud.visible = not on  # the busy HUD would ghost through the scrim
	if on:
		visible = true
		HudPalette.fade(self)
		_resume.grab_focus()
	else:
		HudPalette.fade(self, false).finished.connect(hide)


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


## The question in place of the menu, then YES and NO (focused).
func _confirm(text: String, yes: Callable) -> void:
	_menu.hide()
	var box := VBoxContainer.new()
	box.position = Vector2(24, 24)
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var q := HudPalette.label(text, HudPalette.TITLE_SIZE, HudPalette.WHITE)
	q.custom_minimum_size.y = 28
	box.add_child(q)
	box.add_child(HudPalette.menu_button("ui.yes", yes))
	var no := HudPalette.menu_button("ui.no", func() -> void:
		box.queue_free()
		_menu.show()
		_resume.grab_focus())
	box.add_child(no)
	no.grab_focus()
	HudPalette.fade(box)


func _button(text: String, on_press: Callable) -> Button:
	var b := HudPalette.menu_button(text, on_press)
	_menu.add_child(b)
	return b
