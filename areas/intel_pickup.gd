## Intel: walking into it completes the objective step that names it. MissionRun shows only the
## current step's pickup and ignores the rest. An item (the default) is the dossier turning over a small ring;
## a place to walk into (item off: the Core's lift) is a short light column over a wider ring (ObjectiveMarker).
extends "res://areas/extraction_point.gd"

const ITEM_RING := 0.32
const SPOT_RING := 0.9
const SPOT_BEAM := [0.6, 3.0, 2.6]  # radius, height, fade_m

@export var item := true


func _enter_tree() -> void:
	add_to_group("intel")


func _ready() -> void:
	super()
	var slab := get_node_or_null("Mesh")  # the greybox slab an Area built before ObjectiveMarker still holds
	if slab:
		slab.queue_free()
	var mark := Node3D.new()
	mark.name = "Mark"
	if item:
		add_child(ObjectiveMarker.item())
		mark.add_child(ObjectiveMarker.ring(ITEM_RING))
	else:
		mark.add_child(ObjectiveMarker.ring(SPOT_RING))
		mark.add_child(ObjectiveMarker.beam(SPOT_BEAM[0], SPOT_BEAM[1], SPOT_BEAM[2]))
	add_child(mark)
	ObjectiveMarker.ground(mark, 3.0)
