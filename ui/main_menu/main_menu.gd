## Main menu: Continue (the latest unfinished slot, hidden if none), New game, Load, Mission select,
## Free mode, Settings, Quit. New game and Load pick one of the three slots; overwriting asks first.
## Mission select picks a slot, then one of its cleared Missions (with its Mission Record) to replay.
## Loading a complete slot goes to the Briefing, which replays the finale and returns here.
## Every page fades in over HudPalette.FADE; the menu Theme comes from HudPalette.
extends Control

const BRIEFING := "res://ui/briefing/briefing.tscn"
const FREE_MODE := "res://ui/free_mode/free_mode.tscn"
const TITLE := "GHOST LAYER"
const SettingsPanel := preload("res://ui/settings/settings_panel.gd")

var _box := VBoxContainer.new()


func _ready() -> void:
	GameSettings.apply(GameSettings.load_file())
	get_window().title = "Ghost Layer"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = HudPalette.theme()
	var bg := ColorRect.new()
	bg.color = HudPalette.INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_box.position = Vector2(24, 24)
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)
	_main()


func _main() -> void:
	_clear(TITLE)
	var cont := SaveSlots.continue_slot()
	if cont >= 0:
		_button("ui.menu.continue", func() -> void: _play_slot(cont))
	_button("ui.menu.new_game", func() -> void: _slots(true))
	_button("ui.menu.load", func() -> void: _slots(false))
	_button("ui.menu.mission_select", _select_slot)
	_button("ui.menu.free_mode", func() -> void: get_tree().change_scene_to_file(FREE_MODE))
	_button("ui.menu.settings", _settings)
	_button("ui.menu.quit", func() -> void: get_tree().quit())
	_focus_first()


func _slots(new_game: bool) -> void:
	_clear("ui.menu.pick_new" if new_game else "ui.menu.load")
	for i in SaveSlots.COUNT:
		var s := SaveSlots.read(i)
		var b := _button("%d  %s" % [i + 1, slot_label(s)], Callable())
		if new_game:
			b.pressed.connect(func() -> void:
				if s.is_empty():
					_new_game(i)
				else:
					_confirm(tr("ui.menu.overwrite").format({n = i + 1}), func() -> void: _new_game(i), _slots.bind(true)))
		else:
			b.disabled = s.is_empty()
			b.pressed.connect(func() -> void: _play_slot(i))
	_button("ui.back", _main)
	_focus_first()


## A slot's row: EMPTY, COMPLETE or its next Mission, then when it was saved (SaveSlots.label, translated).
func slot_label(s: Dictionary) -> String:
	if s.is_empty():
		return tr("ui.slot.empty")
	var what := tr("ui.slot.complete") if s.complete else tr("ui.mission.%d" % s.record.mission)
	return "%s  %s" % [what, Time.get_datetime_string_from_unix_time(s.saved, true)]


func _select_slot() -> void:
	_clear("ui.menu.pick_select")
	for i in SaveSlots.COUNT:
		var s := SaveSlots.read(i)
		var b := _button("%d  %s" % [i + 1, slot_label(s)], func() -> void: _missions(i, s))
		b.disabled = s.is_empty() or s.missions.is_empty()  # a new slot has nothing to select
	_button("ui.back", _main)
	_focus_first()


func _missions(slot: int, s: Dictionary) -> void:
	_clear("ui.menu.mission_select")
	for k in Campaign.MISSIONS.size():
		var m: Dictionary = s.missions.get(str(k), {})
		if m.is_empty():
			continue
		var b: Dictionary = m.best
		var row := tr("ui.menu.record").format({mission = tr("ui.mission.%d" % k), rank = b.rank,
			time = "%d:%02d" % [int(b.time) / 60, int(b.time) % 60], kills = b.kills, alerts = b.alerts})
		_button(row, func() -> void:
				Campaign.record = s.record
				Campaign.missions = s.missions
				Campaign.gear = s.gear
				Campaign.slot = slot
				Campaign.play(get_tree(), m.pre.duplicate(true), scene_file_path, false, true))
	_button("ui.back", _select_slot)
	_focus_first()


func _new_game(slot: int) -> void:
	Campaign.start()
	Campaign.slot = slot
	Campaign.save()
	get_tree().change_scene_to_file(BRIEFING)


func _play_slot(slot: int) -> void:
	var s := SaveSlots.read(slot)
	Campaign.record = s.record
	Campaign.missions = s.missions
	Campaign.gear = s.gear
	Campaign.slot = slot
	get_tree().change_scene_to_file(BRIEFING)


func _settings() -> void:
	_box.hide()
	var p := SettingsPanel.new()
	p.position = Vector2(24, 24)
	p.closed.connect(func() -> void:
		_box.show()
		_main())  # rebuilt: the language may have changed
	add_child(p)


## The question as the page title, then YES and NO in place of the page.
func _confirm(text: String, yes: Callable, no: Callable) -> void:
	_clear(text)
	_button("ui.yes", yes)
	_button("ui.no", no)
	_focus_first.call_deferred(true)


func _clear(title: String) -> void:
	for c in _box.get_children():
		c.queue_free()
	var l := HudPalette.label(title, HudPalette.TITLE_SIZE, HudPalette.WHITE)
	l.custom_minimum_size.y = 28
	_box.add_child(l)
	HudPalette.fade(_box)


func _button(text: String, on_press: Callable) -> Button:
	var b := HudPalette.menu_button(text, on_press)
	b.pressed.connect(Mixer.click)
	_box.add_child(b)
	return b


## Focus the first enabled row; `last` focuses the last one instead (NO, on a confirm).
func _focus_first(last := false) -> void:
	await get_tree().process_frame  # the old buttons are still children until freed
	var rows := _box.get_children().filter(func(c: Node) -> bool: return c is Button and not c.disabled and not c.is_queued_for_deletion())
	if not rows.is_empty():
		(rows.back() if last else rows[0]).grab_focus()
