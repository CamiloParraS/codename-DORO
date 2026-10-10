## F3 debug overlay (grows with the other tickets): this Mission's tally and Habit points so far.
extends Label


func _ready() -> void:
	visible = false
	position = Vector2(8, 8)
	add_theme_font_size_override("font_size", 8)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("debug_overlay"):
		visible = not visible


func _process(_delta: float) -> void:
	if not visible:
		return
	var run := get_tree().get_first_node_in_group("mission_tally")
	if not run:
		text = "no Mission"
		return
	var s := "TALLY\n"
	for k: String in run.tally.counts:
		s += "  %s %d\n" % [k, run.tally.counts[k]]
	s += "POINTS (before tug of war)\n"
	var p: Dictionary = run.tally.points()
	for h: String in p:
		s += "  %s %d\n" % [h, p[h]]
	text = s
