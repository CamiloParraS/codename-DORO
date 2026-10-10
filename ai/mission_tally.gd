## One Mission's live event counts, the flat dictionary Aigis.complete_mission reads. Node-free.
## Edges are the caller's job: set_alert(active) every frame, guard_down() once per guard put Down.
## Lethality events (kill, target_kill, spawned, targets) join with the kill ticket.
class_name MissionTally
extends RefCounted

var counts := {}
var alert_active := false


func add(event: String, n := 1) -> void:
	counts[event] = int(counts.get(event, 0)) + n


## Call with "is any alert active now"; a rise counts as one alert raised.
func set_alert(active: bool) -> void:
	if active and not alert_active:
		add("alert")
	alert_active = active


## A guard put Down: quiet (Stealth) only while no alert is active.
func guard_down() -> void:
	if not alert_active:
		add("quiet_down")


## The Habit points so far (before the tug of war), for the overlay.
func points() -> Dictionary:
	return Aigis.mission_points(counts)


## The post-Mission icon strip: [{habit, level, arrow}] in Habit-table order. level is 0-3 under the
## same cap complete_mission clamps with (the next Mission's), so the strip shows what Aigis will
## answer; arrow is +1 / -1 / 0 for points risen / fallen / unchanged.
static func strip(before: Dictionary, after: Dictionary) -> Array:
	var out := []
	var cap_index := Aigis.carry_index(before.mission)
	for h in Aigis.HABITS:
		var b := int(before.points.get(h, 0))
		var a := int(after.points.get(h, 0))
		out.append({"habit": h, "level": Aigis.level(a, cap_index), "arrow": signi(a - b)})
	return out
