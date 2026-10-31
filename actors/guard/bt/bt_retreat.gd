@tool
extends BTAction
## Back away from the Operative, facing it, until Engage.RETREAT_TO m off. A sequence under a non-dynamic
## selector keeps running this without asking again, which is what stops the guard flipping back and forth.


func _tick(delta: float) -> Status:
	return SUCCESS if agent.retreat(delta) else RUNNING
