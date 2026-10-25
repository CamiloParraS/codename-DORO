## A Target and his escort's lines for one Mission (text keys target.m<N>.<i>, 1-based Mission number): the
## Target opens, the escort answers, in turns, only while the Operative is in earshot, once per Mission. Node-free.
class_name TargetChatter
extends RefCounted

const TURN := 3.0
const LINES := 3  # per Target, as the line table has them

var keys: Array
var _next := 0
var _clock := 0.0


## mission: the Campaign index (0 = Mission 1).
func _init(mission: int) -> void:
	for i in LINES:
		keys.append("target.m%d.%d" % [mission + 1, i + 1])


## Advances while heard; returns {seat, key} (0 Target, 1 escort) when a line starts, else {}.
func tick(delta: float, heard: bool) -> Dictionary:
	if not heard or _next >= keys.size():
		return {}
	_clock -= delta
	if _clock > 0.0:
		return {}
	_clock = TURN
	_next += 1
	return {seat = (_next - 1) % 2, key = keys[_next - 1]}
