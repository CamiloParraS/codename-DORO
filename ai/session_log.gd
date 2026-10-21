## A playtest's self-record, node-free: per Mission its time (all of it, pauses excluded by the caller)
## and counts of darts, rifle shots and Spoofed transmissions, plus every idle over IDLE_LOG.
## Idle = seconds since the last progress event: a step done, a Checkpoint, an Alert ending (the edge
## tick() sees). Alert and Evasion time never counts. The Hint tracker reads idle_seconds() and keeps no timer.
## Spoof send = one transmission Glaukopis judged (a Codec Spoof or a report-in), believed or exposed.
class_name SessionLog
extends RefCounted

const IDLE_LOG := 60.0
const LOGGED := ["dart", "rifle", "spoof"]  # event names count() keeps

static var current := SessionLog.new()  # one per game run, fed by MissionRun

var missions := []  # [{mission, seconds, dart, rifle, spoof, idles: [seconds]}]
var _idle := 0.0
var _alerting := false


func start_mission(index: int) -> void:
	finish_mission()
	missions.append({mission = index, seconds = 0.0, dart = 0, rifle = 0, spoof = 0, idles = [], open = true})
	_idle = 0.0
	_alerting = false


## Once per unpaused frame; alerting = any guard in Alert or Evasion.
func tick(delta: float, alerting: bool) -> void:
	if missions.is_empty():
		return
	missions.back().seconds += delta
	if _alerting and not alerting:
		progress()
	_alerting = alerting
	if not alerting:
		_idle += delta


## A step done or a Checkpoint taken; an idle over IDLE_LOG ends here and is logged.
func progress() -> void:
	if not missions.is_empty() and _idle > IDLE_LOG:
		missions.back().idles.append(_idle)
	_idle = 0.0


## Seconds played in the current (latest) Mission.
func seconds() -> float:
	return 0.0 if missions.is_empty() else missions.back().seconds


func idle_seconds() -> float:
	return _idle


func count(event: String) -> void:
	if event in LOGGED and not missions.is_empty():
		missions.back()[event] += 1


## The Mission ended or was left: log a running idle. Safe to call twice.
func finish_mission() -> void:
	if not missions.is_empty() and missions.back().open:
		progress()
		missions.back().open = false


func to_text() -> String:
	var s := ""
	for m: Dictionary in missions:
		s += "mission %d time %d s darts %d rifle %d spoofs %d\n" % [m.mission, m.seconds, m.dart, m.rifle, m.spoof]
		for i: float in m.idles:
			s += "  idle %d s\n" % i
	return s


## Rewrites the whole log (one file per game run).
func write(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(to_text())
