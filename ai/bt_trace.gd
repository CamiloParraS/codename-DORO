## Which branch of a behaviour tree is running, as text for the debug overlay. Node-free.
class_name BtTrace
extends RefCounted


## The names of the running tasks from the root down: "Guard > Patrol > Walk route".
static func running_path(root: BTTask) -> String:
	var names: Array[String] = []
	var task := root
	while task:
		names.append(task.get_task_name())
		var next: BTTask = null
		for i in task.get_child_count():
			if task.get_child(i).get_status() == BTTask.RUNNING:
				next = task.get_child(i)
				break
		task = next
	return " > ".join(names)
