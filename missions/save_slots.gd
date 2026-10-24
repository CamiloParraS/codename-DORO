## Three autosave campaign slots (user://slot_N.json): next Mission index, Habit points, Lethality,
## denominator, a complete flag, the save time and the cleared Missions (Campaign.missions: pre-Mission
## record and Mission Record each; a file without them reads as none). Written after the post-Mission screen commits; an
## unreadable or malformed file is an empty slot. Node-free: `dir` is injectable for tests.
class_name SaveSlots
extends RefCounted

const COUNT := 3
const USER := "user://"


static func path(slot: int, dir := USER) -> String:
	return dir.path_join("slot_%d.json" % slot)


static func write(slot: int, record: Dictionary, now: int, dir := USER, missions := {}) -> void:
	var f := FileAccess.open(path(slot, dir), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({record = record, saved = now, complete = record.mission >= Campaign.MISSIONS.size(), missions = missions}))


## {record, saved, complete, missions}, or {} for a missing or unreadable slot. A malformed cleared
## Mission is dropped, not the slot.
static func read(slot: int, dir := USER) -> Dictionary:
	var f := FileAccess.open(path(slot, dir), FileAccess.READ)
	if not f:
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary and d.get("record") is Dictionary and d.get("saved") is float):
		return {}
	var out := _record(d.record)
	if out.is_empty():
		return {}
	var missions := {}
	var raw: Variant = d.get("missions", {})
	for k: String in raw if raw is Dictionary else {}:
		var m: Variant = raw[k]
		var pre := _record(m.get("pre")) if m is Dictionary else {}
		var best := _best(m.get("best")) if m is Dictionary else {}
		if k.is_valid_int() and not pre.is_empty() and not best.is_empty():
			missions[k] = {pre = pre, best = best}
	return {record = out, saved = int(d.saved), complete = out.mission >= Campaign.MISSIONS.size(), missions = missions}


static func _record(r: Variant) -> Dictionary:
	if not (r is Dictionary and r.get("points") is Dictionary and r.has_all(["mission", "lethality", "denominator"])):
		return {}
	var out := Aigis.new_record()
	for k in ["mission", "lethality", "denominator"]:
		if not r[k] is float:
			return {}
		out[k] = int(r[k])
	for h: String in Aigis.HABITS:
		if not r.points.get(h) is float:
			return {}
		out.points[h] = int(r.points[h])
	return out


static func _best(b: Variant) -> Dictionary:
	if not (b is Dictionary and b.get("rank") in Rank.LETTERS and b.get("time") is float and b.get("kills") is float and b.get("alerts") is float):
		return {}
	return {rank = b.rank, time = b.time, kills = int(b.kills), alerts = int(b.alerts)}


## The most recently written unfinished slot, or -1.
static func continue_slot(dir := USER) -> int:
	var best := -1
	var when := -1
	for i in COUNT:
		var s := read(i, dir)
		if not s.is_empty() and not s.complete and s.saved > when:
			best = i
			when = s.saved
	return best


## "EMPTY", "COMPLETE  <time>" or "<next Mission title>  <time>".
static func label(slot_data: Dictionary) -> String:
	if slot_data.is_empty():
		return "EMPTY"
	var what := "COMPLETE" if slot_data.complete else String(Campaign.MISSIONS[slot_data.record.mission].title)
	return "%s  %s" % [what, Time.get_datetime_string_from_unix_time(slot_data.saved, true)]
