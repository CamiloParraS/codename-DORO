## Pause menu (Esc): the current objective and the controls, then Resume, Restart from checkpoint
## (group "checkpoint", the MissionRun), Abort Mission (back to where the Mission was started from,
## nothing applied), Settings and Quit to menu (confirmed in place). Drawn in design px under a scaled stage on a
## near-opaque scrim with black bands, the HUD hidden underneath. The white-bar list is a UiMenu; the open and the
## list's rows are stepped, never eased.
extends Control

const SettingsPanel := preload("res://ui/settings/settings_panel.gd")
const MENU := "res://ui/main_menu/main_menu.tscn"
const GOLD := Color("cbb26b")
## [action, verb key], in the order a player learns them; keys are read from the InputMap.
const CONTROLS := [
	["walk", "ui.ctl.walk"], ["crouch", "ui.ctl.crouch"], ["aim", "ui.ctl.aim"], ["fire", "ui.ctl.fire"],
	["reload", "ui.ctl.reload"], ["weapon_tranq", "ui.ctl.tranq"], ["weapon_rifle", "ui.ctl.rifle"],
	["interact", "ui.ctl.interact"], ["kill_takedown", "ui.ctl.kill"], ["fulton", "ui.ctl.fulton"],
	["item_use", "ui.ctl.item_use"], ["item_next", "ui.ctl.item_next"], ["knock", "ui.ctl.knock"],
	["radio", "ui.ctl.radio"], ["shoulder_swap", "ui.ctl.shoulder"],
]

var _open := false
var _stage := Control.new()
var _objective := Label.new()
var _mission := Label.new()
var _menu := UiMenu.new(760)
var _confirm_box := PanelContainer.new()
var _confirm_menu := UiMenu.new(420)
var _confirm_q := Label.new()
var _resume: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(HudPalette.SCRIM, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	resized.connect(_layout)
	for y in [0.0, 970.0]:  # the black bands
		var band := ColorRect.new()
		band.color = Color.BLACK
		band.position = Vector2(0, y)
		band.size = Vector2(1920, 110)
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.set_meta(&"band", true)
		_stage.add_child(band)
	var slab := PanelContainer.new()  # PAUSED, dark on a white slab
	var sbox := StyleBoxFlat.new()
	sbox.bg_color = HudPalette.LIGHT
	sbox.content_margin_left = 100
	sbox.content_margin_right = 80
	sbox.content_margin_top = 16
	sbox.content_margin_bottom = 14
	slab.add_theme_stylebox_override("panel", sbox)
	slab.position = Vector2(0, 150)
	var title := _text("ui.pause.title", 84, 0.14, HudPalette.DARK_INK)
	slab.add_child(title)
	_stage.add_child(slab)
	var obj_head := _text("ui.pause.objective", 22, 0.3, GOLD)
	obj_head.position = Vector2(100, 296)
	_stage.add_child(obj_head)
	_objective = _text("", 34, 0.08, HudPalette.LIGHT)
	_objective.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD
	_objective.custom_minimum_size.x = 760
	_objective.position = Vector2(100, 334)
	_stage.add_child(_objective)
	_mission = _text("", 22, 0.2, HudPalette.LIGHT_2)
	_mission.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_menu.position = Vector2(100, 450)
	_stage.add_child(_menu)
	_resume = _row(_menu, "ui.pause.resume", func() -> void: _show(false))
	_row(_menu, "ui.pause.restart", func() -> void:
		_show(false)
		get_tree().call_group("checkpoint", "restore_checkpoint"))
	_row(_menu, "ui.pause.abort", _abort)
	_row(_menu, "ui.menu.settings", _settings)
	_row(_menu, "ui.pause.quit", func() -> void: _ask(), true)
	_controls()
	_build_confirm()
	_layout()


func _text(s: String, fs: int, em: float, col: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, fs, em))
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _row(menu: UiMenu, text: String, on_press: Callable, danger := false) -> Button:
	var b := menu.add_row(text, on_press, danger)
	b.pressed.connect(Mixer.click)
	return b


## The controls, two columns of key and verb, on the right.
func _controls() -> void:
	var side := VBoxContainer.new()
	side.name = "Side"
	side.add_theme_constant_override("separation", 18)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(side)
	side.add_child(_mission)
	var head := _text("ui.pause.controls", 26, 0.26, HudPalette.LIGHT)
	side.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 14)
	side.add_child(grid)
	var rows: Array = [["WASD", "ui.ctl.move"]]
	rows.append_array(CONTROLS.map(func(c: Array) -> Array: return [Prompts.key(c[0]), c[1]]))
	for r: Array in rows:
		var cell := HBoxContainer.new()
		cell.custom_minimum_size.x = 285
		cell.add_theme_constant_override("separation", 12)
		var k := _text(r[0], 20, 0.06, HudPalette.LIGHT)
		k.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		k.custom_minimum_size.x = 64
		cell.add_child(k)
		cell.add_child(_text(r[1], 20, 0.16, HudPalette.LIGHT_2))
		grid.add_child(cell)


func _build_confirm() -> void:
	_confirm_box.visible = false
	var box := StyleBoxFlat.new()
	box.bg_color = Color("0a0d0f")
	box.border_width_top = 6
	box.border_color = HudPalette.DMG
	box.content_margin_left = 60
	box.content_margin_right = 60
	box.content_margin_top = 50
	box.content_margin_bottom = 56
	_confirm_box.add_theme_stylebox_override("panel", box)
	_confirm_box.custom_minimum_size.x = 1000
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 36)
	_confirm_q = _text("ui.pause.quit_confirm", 52, 0.06, HudPalette.LIGHT)
	_confirm_q.autowrap_mode = TextServer.AUTOWRAP_WORD
	_confirm_q.custom_minimum_size.x = 880
	v.add_child(_confirm_q)
	v.add_child(_confirm_menu)
	_confirm_box.add_child(v)
	_stage.add_child(_confirm_box)
	_row(_confirm_menu, "ui.yes", _quit)
	_row(_confirm_menu, "ui.no", func() -> void:
		_confirm_box.hide()
		_menu.show()
		_resume.grab_focus())


func _layout() -> void:
	var k := size.y / HudPalette.DESIGN_H
	_stage.scale = Vector2(k, k)
	_stage.size = size / k
	var d := _stage.size
	var side := _stage.get_node_or_null("Side") as Control
	if side:
		side.position = Vector2(d.x - 100 - 600, 150)
	for c in _stage.get_children():
		if c.has_meta(&"band"):
			c.size.x = d.x
	_confirm_box.position = Vector2((d.x - 1000) / 2, 330)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause") and (_open or not get_tree().paused):  # not over the post-Mission screen
		_show(not _open)
		get_viewport().set_input_as_handled()


func _show(on: bool) -> void:
	_open = on
	Mixer.click()
	var run := get_tree().get_first_node_in_group("checkpoint")
	_objective.text = run.objective() if run else ""  # the objective may have moved on
	_mission.text = tr("ui.mission.%d" % run.record.mission).to_upper() if run and "record" in run else ""
	get_tree().paused = on
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if on else Input.MOUSE_MODE_CAPTURED
	var hud := get_tree().get_first_node_in_group("radio_log") as CanvasItem
	if hud:
		hud.visible = not on  # the busy HUD would ghost through the scrim
	if on:
		visible = true
		_confirm_box.hide()
		_menu.show()
		HudPalette.fade(self)
		_resume.grab_focus()
		_menu.open()
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
	_stage.hide()
	var p := SettingsPanel.new()
	p.closed.connect(func() -> void:
		_stage.show()
		_resume.grab_focus())
	add_child(p)


## The question in place of the menu, then YES and NO (NO focused).
func _ask() -> void:
	_menu.hide()
	_confirm_box.show()
	_confirm_menu.focus_first(true)
	_confirm_menu.open()
