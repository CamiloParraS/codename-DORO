@tool
extends BTAction
## A small idle habit at a patrol stop: looks around for the rest of the stop.


func _tick(_delta: float) -> Status:
	agent.fidget()
	return SUCCESS
