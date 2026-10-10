## Tranq pistol rules, node-free: 4-dart load, 8 darts total, ~1.5 s silent reload. The Rifle extends
## it with its own sizes. Its suppressor never breaks.
class_name Tranq
extends RefCounted

const LOAD_SIZE := 4
const TOTAL := 8
const RELOAD_TIME := 1.5
const BODY_DELAY := 3.0      # a body shot Neutralizes this long after the hit
const SPREAD := 0.0          # radians of aim error with both hands
const SPREAD_ONE_HAND := 0.05

var label := "TRQ"      # on the HUD weapon card
var crosshair := "crosshair_4_small"  # file in res://assets/textures/
var automatic := false   # fires while the button is held
var fire_interval := 0.0 # seconds between shots
var kick := 0.0          # radians of camera recoil per shot
var cooldown := 0.0
var load_size := LOAD_SIZE
var pip_count := LOAD_SIZE  # pips on the card's column
var loaded := LOAD_SIZE
var reserve := TOTAL - LOAD_SIZE
var reload_left := 0.0


func reloading() -> bool:
	return reload_left > 0.0


func suppressed() -> bool:
	return true


## Resupply crate: a full load and a full reserve.
func refill() -> void:
	loaded = load_size
	reserve = TOTAL - LOAD_SIZE
	reload_left = 0.0
	cooldown = 0.0


func can_fire() -> bool:
	return loaded > 0 and not reloading() and cooldown <= 0.0


## Spends a dart; false when the pistol can't fire. Empties start a reload (held off while carrying).
func fire(carrying: bool) -> bool:
	if not can_fire():
		return false
	loaded -= 1
	cooldown = fire_interval
	if loaded == 0:
		reload(carrying)
	return true


## Starts a reload; false when full, out of darts, already reloading or carrying.
func reload(carrying: bool) -> bool:
	if carrying or reloading() or loaded == load_size or reserve == 0:
		return false
	reload_left = RELOAD_TIME
	return true


## Runs the reload. Carrying cancels one in progress; an empty load restarts it once the hands are free.
func tick(delta: float, carrying: bool) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if carrying:
		reload_left = 0.0
		return
	if reloading():
		reload_left -= delta
		if reload_left <= 0.0:
			reload_left = 0.0
			var n := mini(load_size - loaded, reserve)
			loaded += n
			reserve -= n
	elif loaded == 0:  # emptied while carrying: reload as soon as the hands are free
		reload(false)


static func spread(carrying: bool) -> float:
	return SPREAD_ONE_HAND if carrying else SPREAD
