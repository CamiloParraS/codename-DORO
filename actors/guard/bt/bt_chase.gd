@tool
extends BTAction
## Run at the Operative's last known position, facing them while in sight.


func _tick(delta: float) -> Status:
	agent.chase(delta)
	return RUNNING
