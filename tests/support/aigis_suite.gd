@tool
extends McpTestSuite

## What the Aigis suites (test_aigis.gd, test_aigis_plan.gd) share: records, profiles and tallies to feed it.

const CORE := 3


## A record about to play `mission` with the given points (missing Habits = 0).
func _record(mission: int, points := {}) -> Dictionary:
	var r := Aigis.new_record()
	r.mission = mission
	r.points.merge(points, true)
	return r


func _profile(points: Dictionary) -> Dictionary:
	var p: Dictionary = Aigis.new_record().points
	p.merge(points, true)
	return p


func _steps(plan: Dictionary) -> Array:
	return plan.picks.map(func(p: Dictionary) -> String: return p.step)


## A tally with an alert, so the no-alert Stealth rule stays out of the way.
func _loud(extra := {}) -> Dictionary:
	var t := {"alert": 1}
	t.merge(extra, true)
	return t
