## The Core Mission's Area: the Harbour's rules (harbour.gd), but committing the post-Mission screen leaves
## the Operative in the Core room, where the terminal hands off to the finale. A replay never plays the
## finale: it ends on the Rank page like any other Mission.
extends "res://areas/harbour/harbour.gd"


func _ready() -> void:
	super()
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
