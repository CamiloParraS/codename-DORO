## Tranq pistol rules, node-free: 4-dart load, 8 darts total, ~1.5 s silent reload. Its suppressor never breaks.
class_name Tranq
extends Gun

const LOAD_SIZE := 4
const TOTAL := 8
const BODY_DELAY := 3.0      # a body shot Neutralizes this long after the hit
const SPREAD := 0.0          # radians of aim error with both hands
const SPREAD_ONE_HAND := 0.05


func _init() -> void:
	label = "TRQ"
	crosshair = "crosshair_4_small"
	load_size = LOAD_SIZE
	total = TOTAL
	pip_count = LOAD_SIZE
	loaded = LOAD_SIZE
	reserve = TOTAL - LOAD_SIZE


static func spread(carrying: bool) -> float:
	return SPREAD_ONE_HAND if carrying else SPREAD
