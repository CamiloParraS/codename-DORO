@tool
extends BTAction
## Walk to the spot (alert.last_known), then look around it. Runs until the state changes.

@export var speed := 1.6
@export var sweep := 1.5  # look-around turn amplitude


func _generate_name() -> String:
	return "Search spot %.1f m/s" % speed


func _tick(delta: float) -> Status:
	agent.search(delta, speed, sweep)
	return RUNNING
