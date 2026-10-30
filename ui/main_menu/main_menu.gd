## Title, then the main menu: Continue (the latest unfinished slot, hidden if none), New game, Load, Mission select,
## Free mode, Settings, Quit. New game and Load pick one of the three slots; overwriting asks first.
## Mission select picks a slot, then one of its cleared Missions (with its Mission Record) to replay.
## Loading a complete slot goes to the Briefing, which replays the finale and returns here.
## Drawn in design px (1080 tall) under a scaled stage: the drifting backdrop and scanlines are one UiScan, the
## list is a UiMenu. Press any key leaves the title; its glitch and flashes are skipped under reduced motion.
extends Control

const BRIEFING := "res://ui/briefing/briefing.tscn"
const FREE_MODE := "res://ui/free_mode/free_mode.tscn"
const SettingsPanel := preload("res://ui/settings/settings_panel.gd")
const SLICE_EVERY := 7.0   # s between the white slice across GHOST
const SHINE_EVERY := 6.0   # s between the shine passes on the Aigis band
const SHINE_SECS := 2.4
const DIAL_SECS := 120.0   # s per turn of the dial
const BAND := Vector2(1100, 52)

var _stage := Control.new()
var _menu := UiMenu.new()
var _logo := Control.new()
var _slice: Label
var _band := Control.new()
var _shine := TextureRect.new()
var _slashes: Label
var _press: Label
var _slot := Label.new()
var _dial := Control.new()
var _flash := ColorRect.new()
var _on_title := true
var _t := 0.0


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
	var scan := UiScan.make(HudPalette.BACKDROP, true, true, Color(0.7, 0.7, 0.74))
	add_child(scan)
	_shade()
	_stage.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_stage)
	_build_title()
	_stage.add_child(_menu)
	_slot.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, 22, 0.2))
	_slot.add_theme_font_size_override("font_size", 22)
	_stage.add_child(_slot)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	resized.connect(_layout)
	_layout()
	_title()


func _shade() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(HudPalette.INK, 0.8))
	grad.set_color(1, Color(HudPalette.INK, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_to = Vector2(1, 0)
	var shade := TextureRect.new()
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.anchor_right = 0.6
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _layout() -> void:
	var k := size.y / HudPalette.DESIGN_H
	_stage.scale = Vector2(k, k)
	_stage.size = size / k
	var d := _stage.size
	_menu.position = Vector2(d.x - 740, 330)
	_dial.position = Vector2(d.x - 1310, -80)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _label(text: String, font_size: int, em: float, col: Color, weight := 400, font: Font = HudPalette.DISPLAY) -> Label:
	var l := Label.new()
	l.text = text
	var f := FontVariation.new()
	f.base_font = font
	f.spacing_glyph = roundi(font_size * em)
	if weight != 400:
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("weight"): weight}
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_title() -> void:
	_dial.size = Vector2(1240, 1240)
	_dial.pivot_offset = _dial.size / 2
	_dial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial.draw.connect(_draw_dial)
	_stage.add_child(_dial)
	_logo.position = Vector2(110, 250)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_logo)
	var ghost := _label("GHOST", 250, 0.01, HudPalette.LIGHT, 700)
	ghost.position = Vector2(-8, -60)
	_logo.add_child(ghost)
	_slice = _label("GHOST", 250, 0.01, Color.WHITE, 700)
	_slice.position = ghost.position
	_slice.visible = false
	_logo.add_child(_slice)
	var layer := _label("LAYER", 118, 0.62, HudPalette.LIGHT)
	layer.position = Vector2(4, 190)
	_logo.add_child(layer)
	_band.position = Vector2(0, 672)
	_band.size = BAND
	_band.clip_contents = true
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_band)
	var grad := Gradient.new()
	grad.set_color(0, Color(HudPalette.LIGHT, 0.95))
	grad.set_color(1, Color(HudPalette.LIGHT, 0.0))
	grad.set_offset(0, 0.55)
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(1, 0)
	var fill := TextureRect.new()
	fill.texture = gt
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.size = BAND
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(fill)
	var proto := _label(tr("ui.menu.protocol").to_upper(), 26, 0.5, HudPalette.DARK_INK, 500)
	proto.position = Vector2(116, 8)
	_band.add_child(proto)
	_slashes = _label("///", 26, 0.5, HudPalette.DARK_INK, 500)
	_slashes.position = Vector2(116 + proto.get_minimum_size().x + 18, 8)
	_band.add_child(_slashes)
	var sg := Gradient.new()
	sg.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
	sg.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var st := GradientTexture2D.new()
	st.gradient = sg
	st.fill_to = Vector2(1, 0)
	_shine.texture = st
	_shine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shine.size = Vector2(160, BAND.y)
	_shine.position = Vector2(-160, 0)
	_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(_shine)
	_press = _label(tr("ui.menu.press_any").to_upper(), 22, 0.5, HudPalette.LIGHT, 500)
	_press.position = Vector2(116, 790)
	_stage.add_child(_press)


## One thin set of rings, turning very slowly (120 s per turn).
func _draw_dial() -> void:
	var c := _dial.size / 2
	var col := Color(0.81, 0.83, 0.82)
	_dial.draw_arc(c, 486, 0, TAU, 160, Color(col, 0.34 * 0.55), 2.0, true)
	_dial.draw_arc(c, 420, 0, TAU, 160, Color(col, 0.34 * 0.5), 1.5, true)
	for i in 18:  # segmented band
		var a := TAU * i / 18.0
		_dial.draw_arc(c, 392, a, a + TAU / 18.0 - 0.09, 12, Color(col, 0.34 * 0.42), 44.0, true)
	for i in 36:
		var a := TAU * i / 36.0
		_dial.draw_arc(c, 366, a, a + TAU / 36.0 - 0.06, 8, Color(col, 0.34 * 0.6), 6.0, true)
	_dial.draw_arc(c, 300, 0, TAU, 128, Color(col, 0.34 * 0.7), 3.0, true)


func _reduced() -> bool:
	return GameSettings.current.get("reduce_motion", false)


func _process(delta: float) -> void:
	_t += delta
	_dial.rotation = TAU * _t / DIAL_SECS
	_slashes.text = "/".repeat(int(_t / 0.42) % 3 + 1)
	_press.visible = int(_t / 0.7) % 2 == 0
	var shine := fmod(_t, SHINE_EVERY)
	_shine.position.x = -160.0 + floorf(clampf(shine / SHINE_SECS, 0.0, 1.0) * 30.0) / 30.0 * (BAND.x + 160.0) if not _reduced() else -160.0
	var s := fmod(_t, SLICE_EVERY)  # two frames of white slice across GHOST, offset each time
	_slice.visible = _on_title and not _reduced() and _t > 2.6 and s > 6.3 and s < 6.42
	if _slice.visible:
		_slice.position.x = -8.0 + (-14.0 if s < 6.36 else 10.0)
		_slice.clip_contents = false


## The logo cuts in on a two-frame white flash; the menu is hidden.
func _title() -> void:
	_on_title = true
	_menu.hide()
	_slot.hide()
	_press.show()
	_logo.show()
	_dial.show()
	_band.show()
	if _reduced():
		return
	UiMotion.cut(_logo)
	UiMotion.cut(_band, 0.2)
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(_flash, "color:a", 0.8, 0.0)
	t.tween_interval(0.04)
	t.tween_property(_flash, "color:a", 0.0, 0.0)
	t.tween_interval(0.04)
	t.tween_property(_flash, "color:a", 0.5, 0.0)
	t.tween_interval(0.04)
	t.tween_property(_flash, "color:a", 0.0, 0.0)


func _input(e: InputEvent) -> void:
	if not _on_title:
		return
	if (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed) or (e is InputEventJoypadButton and e.pressed):
		get_viewport().set_input_as_handled()
		_on_title = false
		_press.hide()
		_main()


func _main() -> void:
	_menu.show()
	_menu.clear()
	var cont := SaveSlots.continue_slot()
	if cont >= 0:
		_row("ui.menu.continue", func() -> void: _play_slot(cont))
	_row("ui.menu.new_game", func() -> void: _slots(true))
	_row("ui.menu.load", func() -> void: _slots(false))
	_row("ui.menu.mission_select", _select_slot)
	_row("ui.menu.free_mode", func() -> void: get_tree().change_scene_to_file(FREE_MODE))
	_row("ui.menu.settings", _settings)
	_row("ui.menu.quit", func() -> void: get_tree().quit())
	_summary(cont)
	_page()


## The slot summary, bottom left: the Mission it will resume and the Recruit points.
func _summary(slot: int) -> void:
	_slot.visible = slot >= 0
	if slot < 0:
		return
	var s := SaveSlots.read(slot)
	_slot.text = "%s\n%s  %d" % [tr("ui.mission.%d" % s.record.mission).to_upper(), tr("ui.menu.recruits").to_upper(), s.gear.points]
	_slot.position = Vector2(116, _stage.size.y - 96 - _slot.get_minimum_size().y)


func _slots(new_game: bool) -> void:
	_menu.clear("ui.menu.pick_new" if new_game else "ui.menu.load")
	for i in SaveSlots.COUNT:
		var s := SaveSlots.read(i)
		var b := _row("%d  %s" % [i + 1, slot_label(s)], Callable())
		if new_game:
			b.pressed.connect(func() -> void:
				if s.is_empty():
					_new_game(i)
				else:
					_confirm(tr("ui.menu.overwrite").format({n = i + 1}), func() -> void: _new_game(i), _slots.bind(true)))
		else:
			b.disabled = s.is_empty()
			b.pressed.connect(func() -> void: _play_slot(i))
	_row("ui.back", _main)
	_page()


## A slot's row: EMPTY, COMPLETE or its next Mission, then when it was saved (SaveSlots.label, translated).
func slot_label(s: Dictionary) -> String:
	if s.is_empty():
		return tr("ui.slot.empty")
	var what := tr("ui.slot.complete") if s.complete else tr("ui.mission.%d" % s.record.mission)
	return "%s  %s" % [what, Time.get_datetime_string_from_unix_time(s.saved, true)]


func _select_slot() -> void:
	_menu.clear("ui.menu.pick_select")
	for i in SaveSlots.COUNT:
		var s := SaveSlots.read(i)
		var b := _row("%d  %s" % [i + 1, slot_label(s)], func() -> void: _missions(i, s))
		b.disabled = s.is_empty() or s.missions.is_empty()  # a new slot has nothing to select
	_row("ui.back", _main)
	_page()


func _missions(slot: int, s: Dictionary) -> void:
	_menu.clear("ui.menu.mission_select")
	for k in Campaign.MISSIONS.size():
		var m: Dictionary = s.missions.get(str(k), {})
		if m.is_empty():
			continue
		var b: Dictionary = m.best
		var row := tr("ui.menu.record").format({mission = tr("ui.mission.%d" % k), rank = b.rank,
			time = "%d:%02d" % [int(b.time) / 60, int(b.time) % 60], kills = b.kills, alerts = b.alerts})
		_row(row, func() -> void:
				Campaign.record = s.record
				Campaign.missions = s.missions
				Campaign.gear = s.gear
				Campaign.slot = slot
				Campaign.play(get_tree(), m.pre.duplicate(true), scene_file_path, false, true))
	_row("ui.back", _select_slot)
	_page()


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
	_stage.hide()
	var p := SettingsPanel.new()
	p.position = Vector2(24, 24)
	p.closed.connect(func() -> void:
		p.queue_free()
		_stage.show()
		_main())  # rebuilt: the language may have changed
	add_child(p)


## The question as the page title, then YES and NO in place of the page.
func _confirm(text: String, yes: Callable, no: Callable) -> void:
	_menu.clear(text)
	_row("ui.yes", yes)
	_row("ui.no", no)
	_menu.focus_first.call_deferred(true)
	_menu.open()


func _row(text: String, on_press: Callable) -> Button:
	var b := _menu.add_row(text, on_press)
	b.pressed.connect(Mixer.click)
	return b


## Finishes a page: focus the first enabled row and open the list.
func _page() -> void:
	_menu.focus_first()
	_menu.open()
