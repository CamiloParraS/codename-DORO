## The Core room's doorway: the first time the Operative steps in, the security director speaks to Aigis.
extends Area3D

const WHO := "SECURITY DIRECTOR"
const LINE := "core.director.01"

var _spoke := false


func _ready() -> void:
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("operative") and not _spoke:
			_spoke = true
			get_tree().call_group("radio_log", "say", WHO, tr(LINE))
			for g: Guard in get_tree().get_nodes_in_group("targets"):  # the director talks with his hands
				g.speak_gesture(3.0))
