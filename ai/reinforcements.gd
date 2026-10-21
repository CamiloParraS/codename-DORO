## When the Area's road entry sends Reinforcements, node-free: a squad at once on every Alert, then another
## every EVERY s while an Alert holds (never in Evasion), topping up to CAP alive. Dropping out of Alert
## cancels the wait, so the next Alert starts over with an immediate squad.
class_name Reinforcements
extends RefCounted

const EVERY := 30.0
const SQUAD := 3
const SQUAD_L3 := 5   # Combat L3
const CAP := 6        # reinforcements alive at a time

var _clock := 0.0
var _alerted := false


## One frame. alerted: any guard in ALERT; alive: reinforcements standing. Returns how many to send now.
func tick(delta: float, alerted: bool, alive: int, squad: int) -> int:
	var wave := false
	if alerted:
		if not _alerted:
			_clock = EVERY
			wave = true
		else:
			_clock -= delta
			if _clock <= 0.0:
				_clock += EVERY
				wave = true
	_alerted = alerted
	return maxi(mini(squad, CAP - alive), 0) if wave else 0
