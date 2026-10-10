@tool
extends BTCondition
## Succeeds while the guard's alert state is `state`.

@export var state: GuardAlert.State


func _generate_name() -> String:
	return "In %s" % GuardAlert.State.keys()[state]


func _tick(_delta: float) -> Status:
	return SUCCESS if agent.alert.state == state else FAILURE
