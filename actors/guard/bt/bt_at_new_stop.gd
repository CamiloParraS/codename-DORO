@tool
extends BTCondition
## True once per patrol stop, a frame into it: the moment to decide whether to fidget.


func _tick(_delta: float) -> Status:
	return SUCCESS if agent.at_new_stop() else FAILURE
