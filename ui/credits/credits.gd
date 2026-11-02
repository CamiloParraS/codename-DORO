## The credits after the campaign's ending: the title, who made it, then everyone whose work is in it (docs/CREDITS.md,
## by name only), rolling up a black screen into "Thank you for playing", which holds. Holding the advance key
## speeds the roll; Esc, or any press once it has stopped, leaves to `then`.
class_name Credits
extends Control

const MENU := "res://ui/main_menu/main_menu.tscn"
const SPEED := 64.0      # design px/s
const FAST := 6.0        # times faster while the advance key is held
const HOLD := 6.0        # s "Thank you for playing" holds before the screen leaves on its own
const ROW := 46.0        # a name's line
const HEAD_GAP := 120.0  # above a heading
const EDGE := 150.0      # px at the top and bottom where rows fade out
const AUTHOR := "Camilo Parra"

## [heading key, names]. A heading of "" is the title block.
const SECTIONS := [
	["ui.credits.made_by", [AUTHOR]],
	["ui.credits.models", ["Quaternius", "Kenney", "Pizza Doggy", "Elbolilloduro", "yugg0", "godgoldfear", "valsekamerplant",
		"Plewr", "chilly_durango", "n0mad", "Titanium Rat", "Puck", "Vinrax", "Hans Woofington", "Mixamo"]],
	["ui.credits.textures", ["Screaming Brain Studios", "ambientCG", "Poly Haven", "Foxhead"]],
	["ui.credits.fonts", ["Barlow, Jeremy Tribby", "Antonio and Michroma, Vernon Adams", "Press Start 2P, Cody Boisclair", "VT323, Peter Hull"]],
	["ui.credits.music", ["SRG774"]],
	["ui.credits.sound", ["Kenney", "qubodup", "SukritSen", "Audionautics", "bretbernhoft", "serøutōnin--deprivəd", "Drkvixn91",
		"DeqstersLab", "bruce965", "carroll27", "LukaCafuka", "nomiqbomi", "tix99", "vestibule-door", "martian", "IENBA",
		"Flying_Deer_Fx", "amholma", "colorsCrimsonTears", "e__"]],
	["ui.credits.photos", ["Jakub Flis", "Alec Favale", "Sebastien Gabriel"]],
	["ui.credits.shaders", ["Zorochase"]],
	["ui.credits.tools", ["Godot Engine", "LimboAI, Serhii Snitsaruk", "Phantom Camera, Ramokz"]],
]

static var then := MENU  # set by the finale before it comes here

var _y := 0.0       # how far the roll has risen
var _held := 0.0    # s since the roll stopped
var _rows: Array = []  # [y offset, kind, text]: "title", "head", "name", "thanks"
var _end := 0.0     # the roll's length: where it stops with the thanks centred
var _leaving := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var y := 0.0
	_rows.append([y, "title", "GHOST LAYER"])
	y += 200.0
	for s: Array in SECTIONS:
		_rows.append([y, "head", tr(s[0]).to_upper()])
		y += 64.0
		for n: String in s[1]:
			_rows.append([y, "name", n])
			y += ROW
		y += HEAD_GAP
	y += 560.0  # the last names have rolled off when the thanks settles
	_rows.append([y, "thanks", tr("ui.credits.thanks").to_upper()])
	_end = y + 40.0 + HudPalette.DESIGN_H / 2  # stops with the thanks centred (rows enter 40 px below the screen)
	add_child(UiScan.make())
	HudPalette.fade(self)


func _process(delta: float) -> void:
	if _y < _end:
		var fast := Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		_y = minf(_y + delta * SPEED * (FAST if fast else 1.0), _end)
	else:
		_held += delta
		if _held > HOLD:
			_leave()
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") or (_y >= _end and e.is_pressed() and not e.is_echo()):
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	UiTransition.go(get_tree(), then if then != "" else MENU)


func _draw() -> void:
	var k := size.y / HudPalette.DESIGN_H
	var d := size / k
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	draw_rect(Rect2(Vector2.ZERO, d), HudPalette.INK)
	var start := d.y + 40.0  # the first row enters from below
	for r: Array in _rows:
		var y: float = start + r[0] - _y
		if y < -80.0 or y > d.y + 120.0:
			continue
		var a := clampf(minf(y, d.y - y) / EDGE, 0.0, 1.0)
		match r[1]:
			"title":
				HudPalette.hud_text(self, Vector2(d.x / 2, y), r[2], 96, Color(HudPalette.LIGHT, a), HudPalette.tracked(HudPalette.DISPLAY, 96, 0.12), 1, false)
				draw_rect(Rect2(d.x / 2 - 60, y + 40, 120, PixelKit.PX), Color(HudPalette.MINT, a))
			"head":
				HudPalette.hud_text(self, Vector2(d.x / 2, y), r[2], 24, Color(HudPalette.MINT, a), HudPalette.tracked(HudPalette.DISPLAY, 24, 0.3), 1, false)
			"name":
				HudPalette.hud_text(self, Vector2(d.x / 2, y), r[2], 30, Color(HudPalette.LIGHT, a * 0.92), HudPalette.FIGURE_MED, 1, false)
			"thanks":
				HudPalette.hud_text(self, Vector2(d.x / 2, y), r[2], 44, Color(HudPalette.LIGHT, a), HudPalette.tracked(HudPalette.DISPLAY, 44, 0.24), 1, false)
	if _y < _end:
		var hint := tr("ui.credits.hold").format({key = Prompts.key("codec_advance")})
		HudPalette.hud_text(self, Vector2(d.x - 80, d.y - 56), hint, 22, HudPalette.LIGHT_3, HudPalette.tracked(HudPalette.DISPLAY, 22, 0.2), 2, false)
