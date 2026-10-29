## The bridge's aft door: Harbour opens it for a guard sent in by split_pair and shuts it behind him.
## Outside the NavRegion; it only holds bodies back.
extends StaticBody3D

const SLIDE := 1.3  # along x, clear of the 1.2 m opening
const TIME := 0.4

@onready var _shut_x := position.x


func open() -> void:
	_slide(_shut_x + SLIDE)


func close() -> void:
	_slide(_shut_x)


func _slide(x: float) -> void:
	create_tween().tween_property(self, "position:x", x, TIME)
