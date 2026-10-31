@tool
extends BTCondition
## Succeeds while the Operative is inside the distance the guard keeps.


func _generate_name() -> String:
	return "Operative too close"


func _tick(_delta: float) -> Status:
	return SUCCESS if agent.too_close() else FAILURE
