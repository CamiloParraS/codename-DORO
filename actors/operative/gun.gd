## Shared gun rules, node-free: a load, a reserve, a reload, an optional suppressor that breaks. Subclasses
## set their own sizes in `_init`.
class_name Gun
extends RefCounted

const RELOAD_TIME := 1.5
const SPREAD_ONE_HAND := 0.05  # radians of aim error while carrying; both hands is dead on

var label := ""          # on the HUD weapon card
var crosshair := ""      # file in res://assets/textures/
var automatic := false   # fires while the button is held
var lethal := false      # kills guards and breaks cameras instead of tranquilizing
var fire_interval := 0.0 # seconds between shots
var kick := 0.0          # radians of camera recoil per shot
var cooldown := 0.0
var load_size := 0
var total := 0           # rounds in a full resupply, load included
var pip_count := 0       # pips on the card's column
var loaded := 0
var reserve := 0
var reload_left := 0.0
var suppressor_max := -1 # shots before the suppressor breaks; -1 = it never breaks
var suppressor := -1
var resupply := -1       # rounds a crate adds, capped at total; -1 = a full resupply


## Radians of aim error: none with both hands, SPREAD_ONE_HAND while carrying.
func spread(carrying: bool) -> float:
	return SPREAD_ONE_HAND if carrying else 0.0


func reloading() -> bool:
	return reload_left > 0.0


func suppressed() -> bool:
	return suppressor != 0


## Resupply crate: a fresh suppressor, and either a full load and reserve or `resupply` more rounds
## (never past `total`).
func refill() -> void:
	if resupply < 0:
		loaded = load_size
		reserve = total - load_size
	else:
		reserve = mini(reserve + resupply, total - loaded)
	reload_left = 0.0
	cooldown = 0.0
	suppressor = suppressor_max


func can_fire() -> bool:
	return loaded > 0 and not reloading() and cooldown <= 0.0


## Spends a round; false when the gun can't fire. Empties start a reload (held off while carrying).
func fire(carrying: bool) -> bool:
	if not can_fire():
		return false
	loaded -= 1
	if suppressor > 0:
		suppressor -= 1
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
