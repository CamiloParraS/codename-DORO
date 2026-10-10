## Tranq pistol rules, node-free: 4-dart load, 8 darts total, ~1.5 s silent reload. Its suppressor never breaks.
class_name Tranq
extends Gun

const LOAD_SIZE := 4
const TOTAL := 8
const BODY_DELAY := 3.0      # a body shot Neutralizes this long after the hit


func _init() -> void:
	label = "TRQ"
	crosshair = "crosshair_4_small"
	load_size = LOAD_SIZE
	total = TOTAL
	pip_count = LOAD_SIZE
	loaded = LOAD_SIZE
	reserve = TOTAL - LOAD_SIZE

