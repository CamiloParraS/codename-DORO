## Title, then the main menu: Continue (the latest unfinished slot, hidden if none), New game, Load, Mission select,
## Free mode, Settings, Quit. New game and Load pick one of the three slots; overwriting asks first.
## Mission select picks a slot, then one of its cleared Missions (with its Mission Record) to replay.
## Loading a complete slot goes to the Briefing, which replays the finale and returns here.
## Drawn in design px (1080 tall) under a scaled stage: the drifting backdrop and scanlines are one UiScan, the
## list is a UiMenu. Press any key leaves the title; the logo fades up and the prompt breathes (still under reduced motion).
extends Control

const BRIEFING := "res://ui/briefing/briefing.tscn"
const FREE_MODE := "res://ui/free_mode/free_mode.tscn"
const SettingsPanel := preload("res://ui/settings/settings_panel.gd")
const DIAL_SECS := 120.0   # s per turn of the dial
const BAND := Vector2(1100, 52)

var _stage := Control.new()
var _menu := UiMenu.new(UiMenu.WIDTH, true)
var _logo := Control.new()
var _band := Control.new()
var _press: Label
var _slot := Label.new()
var _dial := Control.new()
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
	_slot.add_theme_font_override("font", HudPalette.tracked(HudPalette.DISPLAY, 26, 0.2))
	_slot.add_theme_font_size_override("font_size", 26)
	_stage.add_child(_slot)
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
	var right := TextureRect.new()  # a soft shade behind the list, so it reads without a panel
	right.texture = tex
	right.flip_h = true
	right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	right.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right.anchor_left = 0.55
	right.modulate = Color(1, 1, 1, 0.7)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)


func _layout() -> void:
	var k := size.y / HudPalette.DESIGN_H
	_stage.scale = Vector2(k, k)
	_stage.size = size / k
	var d := _stage.size
	_menu.position = Vector2(d.x - 640, 340)
	_dial.position = Vector2(d.x - 1310, -80)


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
	var slashes := _label("///", 26, 0.5, HudPalette.DARK_INK, 500)
	slashes.position = Vector2(116 + proto.get_minimum_size().x + 18, 8)
	_band.add_child(slashes)
	_press = _label(tr("ui.menu.press_any").to_upper(), 28, 0.5, HudPalette.LIGHT, 500)
	_press.position = Vector2(116, 790)
	_stage.add_child(_press)


## One thin set of rings, turning very slowly (120 s per turn).
func _draw_dial() -> void:
	var c := _dial.size / 2
	var col := HudPalette.SOFT
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


## The logo and band fade up in turn; the prompt breathes. The menu is hidden.
func _title() -> void:
	_on_title = true
	_menu.hide()
	_slot.hide()
	_press.show()
	_logo.show()
	_dial.show()
	_band.show()
	UiMotion.rise([_logo, _band], 0.18, 0.7)
	_press.modulate.a = 1.0
	UiMotion.pulse(_press, 0.3, 1.5)


func _input(e: InputEvent) -> void:
	if not _on_title:
		return
	if (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed) or (e is InputEventJoypadButton and e.pressed):
		get_viewport().set_input_as_handled()
		_on_title = false
		_press.hide()
		_main()
		UiMotion.rise([_slot], 0.0, 0.5)


func _main() -> void:
	_menu.show()
	_menu.clear()
	var cont := SaveSlots.continue_slot()
	if cont >= 0:
		_row("ui.menu.continue", func() -> void: _play_slot(cont), "m_continue", "continue")
	_row("ui.menu.new_game", func() -> void: _slots(true), "m_new", "new_game")
	_row("ui.menu.load", func() -> void: _slots(false), "m_load", "load")
	_row("ui.menu.mission_select", _select_slot, "m_missions", "mission_select")
	_row("ui.menu.free_mode", func() -> void: get_tree().change_scene_to_file(FREE_MODE), "m_free", "free_mode")
	_row("ui.menu.settings", _settings, "m_settings", "settings")
	_row("ui.menu.quit", func() -> void: get_tree().quit(), "m_quit", "quit", true)
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
	_row("ui.back", _main, "m_back")
	_page()


## A slot's row: EMPTY, COMPLETE or its next Mission, then when it was saved (SaveSlots.label, translated).
func slot_label(s: Dictionary) -> String:
	if s.is_empty():
		return tr("ui.slot.empty")
	var what := tr("ui.slot.complete") if s.complete else tr("ui.mission.%d" % s.record.mission)
	return "%s  %s" % [what, Time.get_datetime_string_from_unix_time(s.saved, true).left(16)]  # no seconds


func _select_slot() -> void:
	_menu.clear("ui.menu.pick_select")
	for i in SaveSlots.COUNT:
		var s := SaveSlots.read(i)
		var b := _row("%d  %s" % [i + 1, slot_label(s)], func() -> void: _missions(i, s))
		b.disabled = s.is_empty() or s.missions.is_empty()  # a new slot has nothing to select
	_row("ui.back", _main, "m_back")
	_page()


func _missions(slot: int, s: Dictionary) -> void:
	_menu.clear("ui.menu.mission_select")
	for k in Campaign.MISSIONS.size():
		var m: Dictionary = s.missions.get(str(k), {})
		if m.is_empty():
			continue
		var b: Dictionary = m.best
		@warning_ignore("integer_division")
		var row := tr("ui.menu.record").format({mission = tr("ui.mission.%d" % k), rank = b.rank,
			time = "%d:%02d" % [int(b.time) / 60, int(b.time) % 60], kills = b.kills, alerts = b.alerts})
		_row(row, func() -> void:
				Campaign.record = s.record
				Campaign.missions = s.missions
				Campaign.gear = s.gear
				Campaign.slot = slot
				Campaign.play(get_tree(), m.pre.duplicate(true), scene_file_path, false, true))
	_row("ui.back", _select_slot, "m_back")
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


func _row(text: String, on_press: Callable, icon := "", desc := "", danger := false) -> Button:
	var b := _menu.add_row(text, on_press, danger, icon, tr("ui.menu.d." + desc) if desc != "" else "")
	b.pressed.connect(Mixer.click)
	return b


## Finishes a page: focus the first enabled row and open the list.
func _page() -> void:
	_menu.focus_first()
	_menu.open()
