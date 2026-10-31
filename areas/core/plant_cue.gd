## The corridor, at the plant room's door: the first time the Operative passes, the camera turns to the stair
## inside, lit green (playtest 4: the quiet way went unseen). Once per run.
extends Area3D

const SECS := 0.4

var _cued := false


func _ready() -> void:
	body_entered.connect(func(b: Node3D) -> void:
		if b.is_in_group("operative") and not _cued:
			_cued = true
			b.glance($"../Spots/PlantStair".global_position, SECS))
