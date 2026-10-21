## Suppressed assault rifle rules, node-free: 12-round load, 36 total, ~1.5 s silent reload (the Tranq's).
## The suppressor breaks after 3 shots; from then on every shot is loud. The crate adds RESUPPLY rounds.
class_name Rifle
extends Gun

const LOAD := 12
const ROUNDS := 36
const RESUPPLY := 12
const SUPPRESSOR_SHOTS := 3
const INTERVAL := 0.1  # 600 rounds a minute
const KICK := 0.012    # radians of camera recoil per shot
const NOISE_RANGE := 25.0  # metres a loud shot is heard, through walls


func _init() -> void:
	label = "RIF"
	crosshair = "crosshair_21"
	automatic = true
	lethal = true
	fire_interval = INTERVAL
	kick = KICK
	load_size = LOAD
	total = ROUNDS
	pip_count = 6
	loaded = LOAD
	reserve = ROUNDS - LOAD
	suppressor_max = SUPPRESSOR_SHOTS
	suppressor = SUPPRESSOR_SHOTS
	resupply = RESUPPLY
