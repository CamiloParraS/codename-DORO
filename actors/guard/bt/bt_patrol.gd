@tool
extends BTAction
## Walk the patrol route, pausing at each point.


func _tick(delta: float) -> Status:
	agent.patrol(delta)
	return RUNNING
