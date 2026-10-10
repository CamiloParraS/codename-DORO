## Suppressed assault rifle rules, node-free: 30-round load, 60 total, ~1.5 s silent reload (the Tranq's).
## The suppressor breaks after 10 shots; from then on every shot is loud.
class_name Rifle
extends Tranq

const LOAD := 30
const ROUNDS := 60
const SUPPRESSOR_SHOTS := 10
const BODY_HITS := 2   # body hits that kill; a headshot kills outright
const INTERVAL := 0.1  # 600 rounds a minute
const KICK := 0.012    # radians of camera recoil per shot
const NOISE_RANGE := 40.0  # metres a loud shot is heard, through walls

var suppressor := SUPPRESSOR_SHOTS


func _init() -> void:
	label = "RIF"
	crosshair = "crosshair_21"
	automatic = true
	fire_interval = INTERVAL
	kick = KICK
	load_size = LOAD
	pip_count = 6
	loaded = LOAD
	reserve = ROUNDS - LOAD


func suppressed() -> bool:
	return suppressor > 0


func fire(carrying: bool) -> bool:
	var quiet := suppressed()
	if not super.fire(carrying):
		return false
	if quiet:
		suppressor -= 1
	return true


func refill() -> void:
	loaded = LOAD
	reserve = ROUNDS - LOAD
	reload_left = 0.0
	cooldown = 0.0
	suppressor = SUPPRESSOR_SHOTS
