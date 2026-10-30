## Concentric rings that turn very slowly: an outer set and an inner set in opposite directions. Pure drawing, one
## colour; set `secs_outer` / `secs_inner` per turn. Used behind the title and the game over screen.
class_name UiDial
extends Control

var color := Color(0.81, 0.83, 0.82, 0.34)
var secs_outer := 120.0
var secs_inner := 120.0
var _t := 0.0


func _init(diameter := 1240.0) -> void:
	custom_minimum_size = Vector2.ONE * diameter
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := size.x / 1000.0
	var c := size / 2
	for ring: Array in [[486.0, 0.55, 2.0, 0.0], [458.0, 0.5, 1.5, 0.0]]:  # [radius, alpha, width, unused], turning against
		draw_arc(c, ring[0] * s, 0, TAU, 160, Color(color, color.a * ring[1]), ring[2] * s, true)
	var outer := -TAU * _t / secs_outer
	for i in 18:  # the segmented band
		var a := outer + TAU * i / 18.0
		draw_arc(c, 420 * s, a, a + TAU / 18.0 - 0.09, 12, Color(color, color.a * 0.5), 46 * s, true)
	var inner := TAU * _t / secs_inner
	for i in 36:
		var a := inner + TAU * i / 36.0
		draw_arc(c, 366 * s, a, a + TAU / 36.0 - 0.06, 8, Color(color, color.a * 0.6), 6 * s, true)
	draw_arc(c, 300 * s, 0, TAU, 128, Color(color, color.a * 0.7), 3 * s, true)
