## When the Area's road entry sends Reinforcements, node-free: a squad at once on every Alert, then another
## every EVERY s while an Alert holds (never in Evasion), topping up to CAP alive. Dropping out of Alert
## cancels the wait, so the next Alert starts over with an immediate squad.
class_name Reinforcements
extends RefCounted

const EVERY := 30.0
const SQUAD := 3
const SQUAD_L3 := 5   # Combat L3
const CAP := 6        # reinforcements alive at a time
const LEAVE_AFTER := 60.0  # s without an Alert before any reinforcement still around is taken back

var _clock := 0.0
var _alerted := false
var _quiet := 0.0  # seconds since the last Alert


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
	_quiet = 0.0 if alerted else _quiet + delta
	return maxi(mini(squad, CAP - alive), 0) if wave else 0


## Does a standing reinforcement leave now: it is back at the entry on patrol, or the Alert has been over
## for LEAVE_AFTER s (stuck in Evasion, or lost on the way back).
func leaves(on_patrol: bool, at_entry: bool) -> bool:
	return (on_patrol and at_entry) or _quiet >= LEAVE_AFTER
