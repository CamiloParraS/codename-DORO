## Where a Mission ends once its objectives are done. Its collision mask must include the Operative's layer.
extends Area3D

signal reached


func _enter_tree() -> void:
	add_to_group("extraction")  # before MissionRun's _ready looks for it


func _ready() -> void:
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("operative"):
			reached.emit())
