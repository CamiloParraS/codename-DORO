## The Core Mission's Area: the Harbour's rules (harbour.gd), but committing the post-Mission screen leaves
## the Operative in the Core room, where the terminal hands off to the finale.
extends "res://areas/harbour/harbour.gd"


func _ready() -> void:
	super()
	$CoreTerminal.leave_to = $MissionRun.return_to
	$MissionRun.return_to = ""
	var finale := Control.new()
	finale.set_script(load("res://ui/finale/finale.gd"))
	finale.leave_to = $CoreTerminal.leave_to
	add_child(finale)
