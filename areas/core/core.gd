## The Core Mission's Area: the Harbour's rules (harbour.gd), but committing the post-Mission screen leaves
## the Operative in the Core room, where the terminal hands off to the finale. A replay never plays the
## finale: it ends on the Rank page like any other Mission.
extends "res://areas/harbour/harbour.gd"

var _descended := false  # the Descent plays once


func _ready() -> void:
	super()
	for i in get_tree().get_nodes_in_group("intel"):  # after lift_door's own connection: the door frees first
		if i.name == "IntelLift":
			i.reached.connect(_descend)
	if $MissionRun.replay:
		return
	$CoreTerminal.leave_to = $MissionRun.return_to
	$MissionRun.return_to = ""
	var finale := Control.new()
	finale.set_script(load("res://ui/finale/finale.gd"))
	finale.leave_to = $CoreTerminal.leave_to
	add_child(finale)


## Reinforcements: down the road ($Spots/SurfaceEntry) while the Operative is on the surface, down the lift
## ($Spots/RoadEntry, in the corridor) once he is below, west of the cliff (diagram x < 0).
func _entry_for(pos: Vector3) -> Marker3D:
	return $Spots/RoadEntry if pos.x < -40.0 else $Spots/SurfaceEntry


## The lift is reached: the Descent plays once per run (the take is the ride; the Operative comes out in the corridor).
func _descend() -> void:
	if _descended:
		return
	_descended = true
	$MissionRun.play_take("CineDescent")
