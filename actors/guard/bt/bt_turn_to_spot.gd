@tool
extends BTAction
## The "huh?" beat: stop and turn toward the spot for `duration` seconds.

@export var duration := 1.0


func _generate_name() -> String:
	return "Turn to spot %.1fs" % duration


func _tick(delta: float) -> Status:
	agent.face(agent.alert.last_known, delta)
	return SUCCESS if get_elapsed_time() >= duration else RUNNING
