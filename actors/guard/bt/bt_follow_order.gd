@tool
extends BTAction
## Carry out a believed radio order (go check a place, hold position). Fails when there is none.


func _tick(delta: float) -> Status:
	return RUNNING if agent.follow_order(delta) else FAILURE
