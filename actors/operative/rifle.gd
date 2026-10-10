## Suppressed assault rifle rules, node-free: 30-round load, 60 total, ~1.5 s silent reload (the Tranq's).
## The suppressor breaks after 10 shots; from then on every shot is loud.
class_name Rifle
extends Gun

const LOAD := 30
const ROUNDS := 60
const SUPPRESSOR_SHOTS := 10
const INTERVAL := 0.1  # 600 rounds a minute
const KICK := 0.012    # radians of camera recoil per shot
const NOISE_RANGE := 40.0  # metres a loud shot is heard, through walls


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
