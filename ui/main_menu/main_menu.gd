## Main menu: Continue (the latest unfinished slot, hidden if none), New game, Load, Mission select,
## Free mode, Settings, Quit. New game and Load pick one of the three slots; overwriting asks first.
## Mission select picks a slot, then one of its cleared Missions (with its Mission Record) to replay.
## Loading a complete slot goes to the Briefing, which replays the finale and returns here.
extends Control

const BRIEFING := "res://ui/briefing/briefing.tscn"
const FREE_MODE := "res://ui/free_mode/free_mode.tscn"
const SettingsPanel := preload("res://ui/settings/settings_panel.gd")

var _box := VBoxContainer.new()


func _ready() -> void:
	GameSettings.apply(GameSettings.load_file())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Theme.new()
	theme.default_font = load("res://assets/fonts/press_start_2p_regular.ttf")
	theme.default_font_size = 8
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_box.position = Vector2(24, 24)
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	_main()


func _main() -> void:
	_clear("CODENAME DORO")
	var cont := SaveSlots.continue_slot()
	if cont >= 0:
		_button("CONTINUE", func() -> void: _play_slot(cont))
	_button("NEW GAME", func() -> void: _slots(true))
	_button("LOAD", func() -> void: _slots(false))
	_button("MISSION SELECT", _select_slot)
	_button("FREE MODE", func() -> void: get_tree().change_scene_to_file(FREE_MODE))
	_button("SETTINGS", _settings)
	_button("QUIT", func() -> void: get_tree().quit())
	_focus_first()


func _slots(new_game: bool) -> void:
	_clear("NEW GAME: PICK A SLOT" if new_game else "LOAD")
	for i in SaveSlots.COUNT:
		var s := SaveSlots.read(i)
		var b := _button("%d  %s" % [i + 1, SaveSlots.label(s)], Callable())
		if new_game:
			b.pressed.connect(func() -> void:
				if s.is_empty():
					_new_game(i)
				else:
					_confirm("OVERWRITE SLOT %d?" % (i + 1), func() -> void: _new_game(i)))
		else:
			b.disabled = s.is_empty()
			b.pressed.connect(func() -> void: _play_slot(i))
	_button("BACK", _main)
	_focus_first()


func _select_slot() -> void:
	_clear("MISSION SELECT: PICK A SLOT")
	for i in SaveSlots.COUNT:
		var s := SaveSlots.read(i)
		var b := _button("%d  %s" % [i + 1, SaveSlots.label(s)], func() -> void: _missions(i, s))
		b.disabled = s.is_empty() or s.missions.is_empty()  # a new slot has nothing to select
	_button("BACK", _main)
	_focus_first()


func _missions(slot: int, s: Dictionary) -> void:
	_clear("MISSION SELECT")
	for k in Campaign.MISSIONS.size():
		var m: Dictionary = s.missions.get(str(k), {})
		if m.is_empty():
			continue
		var b: Dictionary = m.best
		_button("%s  %s  %d:%02d  KILLS %d  ALERTS %d" % [Campaign.MISSIONS[k].title, b.rank, int(b.time) / 60, int(b.time) % 60, b.kills, b.alerts],
			func() -> void:
				Campaign.record = s.record
				Campaign.missions = s.missions
				Campaign.slot = slot
				Campaign.play(get_tree(), m.pre.duplicate(true), scene_file_path, false, true))
	_button("BACK", _select_slot)
	_focus_first()


func _new_game(slot: int) -> void:
	Campaign.start()
	Campaign.slot = slot
	SaveSlots.write(slot, Campaign.record, int(Time.get_unix_time_from_system()))
	get_tree().change_scene_to_file(BRIEFING)


func _play_slot(slot: int) -> void:
	var s := SaveSlots.read(slot)
	Campaign.record = s.record
	Campaign.missions = s.missions
	Campaign.slot = slot
	get_tree().change_scene_to_file(BRIEFING)


func _settings() -> void:
	_box.hide()
	var p := SettingsPanel.new()
	p.position = Vector2(24, 24)
	p.closed.connect(_box.show)
	add_child(p)


func _confirm(text: String, yes: Callable) -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = text
	d.confirmed.connect(yes)
	d.canceled.connect(d.queue_free)
	d.confirmed.connect(d.queue_free)
	add_child(d)
	d.popup_centered()


func _clear(title: String) -> void:
	for c in _box.get_children():
		c.queue_free()
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 12)
	_box.add_child(l)


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(Mixer.click)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	_box.add_child(b)
	return b


func _focus_first() -> void:
	await get_tree().process_frame  # the old buttons are still children until freed
	for c in _box.get_children():
		if c is Button and not c.disabled and not c.is_queued_for_deletion():
			c.grab_focus()
			return
