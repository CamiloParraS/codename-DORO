## When the Area's road entry sends Reinforcements, node-free: one squad per completed Radio call (the
## AlertChain's `alerts`), topping up to CAP alive; never for Caution. They stay through Evasion and
## Caution and leave once the chain is back to Normal.
class_name Reinforcements
extends RefCounted

const SQUAD := 3
const SQUAD_L3 := 5   # Combat L3
const CAP := 6        # reinforcements alive at a time

var _answered := 0  # completed calls already answered


## One frame. alerts: the chain's completed calls so far; alive: reinforcements standing. Returns how
## many to send now: a squad once per new completed call.
func tick(alerts: int, alive: int, squad: int) -> int:
	_answered = mini(_answered, alerts)  # a Checkpoint restore starts a fresh chain
	if alerts <= _answered:
		return 0
	_answered = alerts
	return maxi(mini(squad, CAP - alive), 0)


## Does a standing reinforcement leave now: Caution has ended.
static func leaves(phase: AlertChain.Phase) -> bool:
	return phase == AlertChain.Phase.NORMAL
