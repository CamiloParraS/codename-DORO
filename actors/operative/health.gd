## The Operative's life, node-free: dies after HITS_TO_DIE hits, regenerates after REGEN_DELAY seconds
## without damage. Also the odds of a guard's shot landing.
class_name Health
extends RefCounted

const HITS_TO_DIE := 4
const REGEN_DELAY := 5.0   # seconds without damage before life comes back
const REGEN_RATE := 0.5    # hits regained per second once it does
const POINT_BLANK := 0.8   # hit chance up close
const FAR := 0.1           # hit chance at RANGE
const RANGE := 30.0        # metres at which the chance bottoms out (guards don't fire beyond it)
const RUNNING := 0.6       # multiplier on the chance while the Operative runs

var damage := 0.0          # in hits: 0 = unhurt
var quiet := 0.0           # seconds since the last hit


func life() -> float:
	return 1.0 - damage / HITS_TO_DIE


func dead() -> bool:
	return damage >= HITS_TO_DIE


func hit() -> void:
	damage = minf(damage + 1.0, HITS_TO_DIE)
	quiet = 0.0


func tick(delta: float) -> void:
	if dead():
		return
	quiet += delta
	if quiet >= REGEN_DELAY:
		damage = maxf(damage - REGEN_RATE * delta, 0.0)


## Chance a guard's shot lands: falls linearly with distance, and again when the Operative runs.
static func hit_chance(distance: float, running: bool) -> float:
	var p := lerpf(POINT_BLANK, FAR, clampf(distance / RANGE, 0.0, 1.0))
	return p * RUNNING if running else p
