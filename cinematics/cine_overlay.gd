## What a take draws over the picture: the 2.39:1 letterbox bars, the lower-third (a Mission's intro card text), the
## skip ring while the key is held, and an outro's fade to black. Pure drawing from four numbers the runner sets.
class_name CineOverlay
extends Control

var lines: Array[String] = []   # translated: name, area, stamp
var third := 0.0                # lower-third opacity
var skip := 0.0                 # 0..1 skip hold; 0 hides the ring
var black := 0.0                # opacity of the fade to black


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var bar := CineLogic.bar_height(size)
	draw_rect(Rect2(0, 0, size.x, bar), Color.BLACK)
	draw_rect(Rect2(0, size.y - bar, size.x, bar), Color.BLACK)
	var k := size.y / HudPalette.DESIGN_H
	var d := size / k
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var y := d.y - bar / k - 70.0 - maxf(0, lines.size() - 1) * 34.0
	if third > 0.0 and not lines.is_empty():
		var x := 110.0
		for i in lines.size():
			var big := i == 0
			var fs := 64 if big else 26
			var font: Font = HudPalette.tracked(HudPalette.DISPLAY, fs, 0.16 if big else 0.28)
			HudPalette.hud_text(self, Vector2(x, y), lines[i].to_upper() if not big else lines[i], fs, Color(HudPalette.LIGHT if big else HudPalette.LIGHT_2, third), font, 0, false)
			y += 70.0 if big else 34.0
	if skip > 0.0:
		var c := Vector2(d.x - 90.0, d.y - maxf(bar / k, 0.0) - 70.0)
		draw_arc(c, 22.0, 0.0, TAU, 40, Color(HudPalette.LIGHT, 0.25), 2.0)
		draw_arc(c, 22.0, -PI / 2.0, -PI / 2.0 + TAU * skip, 40, HudPalette.LIGHT, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if black > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, black))
