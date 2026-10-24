## The sea under an Area: an Operative who drops into it dies (the Game Over screen).
extends Area3D


func _ready() -> void:
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("operative"):
			get_tree().call_group("checkpoint", "game_over"))
