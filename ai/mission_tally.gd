## One Mission's live event counts, the flat dictionary Aigis.complete_mission reads. Node-free.
## Edges are the caller's job: add("alert") once per completed Radio call, alert_active every frame,
## guard_down() once per guard put Down.
## Lethality events: the Area adds spawned (guards actually spawned); kill, target_kill and targets
## join with the kill and Targets tickets.
class_name MissionTally
extends RefCounted

var counts := {}
var alert_active := false  # the Area is in Alert


func add(event: String, n := 1) -> void:
	counts[event] = int(counts.get(event, 0)) + n


## A guard put Down: quiet (Stealth) only while no alert is active.
func guard_down() -> void:
	if not alert_active:
		add("quiet_down")


## The Habit points so far (before the tug of war), for the overlay.
func points() -> Dictionary:
	return Aigis.mission_points(counts)


## The post-Mission icon strip: [{habit, level, arrow}] in Habit-table order. level is 0-3 under the
## same cap complete_mission clamps with (the next Mission's), so the strip shows what Aigis will
## answer; arrow is +1 / -1 / 0 for points risen / fallen / unchanged. The before points are held to
## that same clamp, so points a Free mode Preset holds above it don't show as a phantom fall.
static func strip(before: Dictionary, after: Dictionary) -> Array:
	var out := []
	var cap_index := Aigis.carry_index(before.mission)
	var most := Aigis.carry_max(before.mission)
	for h in Aigis.HABITS:
		var b := mini(int(before.points.get(h, 0)), most)
		var a := int(after.points.get(h, 0))
		out.append({"habit": h, "level": Aigis.level(a, cap_index), "arrow": signi(a - b)})
	return out
