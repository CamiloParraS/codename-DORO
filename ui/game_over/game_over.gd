## Game Over: a black screen with the post-Mission screen's fade and font, one Metis line picked at
## random, "CONTINUES n", then CONTINUE (the last Checkpoint) or QUIT TO MENU. MissionRun opens it on death.
extends Control

signal continued
signal quit

const POST := preload("res://ui/post_mission/post_mission.gd")
const LINES := ["gameover.01", "gameover.02", "gameover.03", "gameover.04", "gameover.05", "gameover.06"]

var continues := 0
var line: String = LINES.pick_random()
var _total := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modulate.a = 0.0
	theme = Theme.new()
	theme.default_font = load(POST.FONT)
	theme.default_font_size = 8
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	_label(box, "GAME OVER", 12, HudPalette.WHITE)
	_label(box, "METIS: " + tr(line), 8, HudPalette.WHITE).custom_minimum_size.x = 480
	_label(box, "CONTINUES %d" % continues, 8, HudPalette.CHROME_DIM)
	var go := _button(box, "CONTINUE", continued.emit)
	_button(box, "QUIT TO MENU", quit.emit)
	go.grab_focus.call_deferred()


func _process(delta: float) -> void:
	_total += delta
	modulate.a = minf(_total / POST.FADE, 1.0)


func _label(box: Control, text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	box.add_child(l)
	return l


func _button(box: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(Mixer.click)
	b.pressed.connect(on_press)
	box.add_child(b)
	return b
