## Game Over: a black screen with the shared panel fade and font, one Metis line picked at
## random, "CONTINUES n", then CONTINUE (the last Checkpoint) or QUIT TO MENU. MissionRun opens it on death.
extends Control

signal continued
signal quit

const LINES := ["gameover.01", "gameover.02", "gameover.03", "gameover.04", "gameover.05", "gameover.06"]

var continues := 0
var line: String = LINES.pick_random()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = HudPalette.theme()
	var bg := ColorRect.new()
	bg.color = HudPalette.INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	_label(box, tr("ui.gameover.title"), HudPalette.TITLE_SIZE, HudPalette.DANGER)
	var said := _label(box, "%s: %s" % [tr("ui.who.metis"), tr(line)], HudPalette.BODY_SIZE, HudPalette.WHITE)
	said.add_theme_font_override("font", HudPalette.BODY)
	said.custom_minimum_size.x = HudPalette.COLUMN
	_label(box, tr("ui.gameover.continues").format({n = continues}), HudPalette.HEADING_SIZE, HudPalette.CHROME_DIM)
	var go := _button(box, "ui.menu.continue", continued.emit)
	_button(box, "ui.pause.quit", quit.emit)
	go.grab_focus.call_deferred()
	HudPalette.fade(self)


func _label(box: Control, text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	box.add_child(l)
	return l


func _button(box: Control, text: String, on_press: Callable) -> Button:
	var b := HudPalette.menu_button(text, on_press)
	b.pressed.connect(Mixer.click)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(b)
	return b
