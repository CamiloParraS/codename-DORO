## A playtest's self-record, node-free: per Mission its time (all of it, pauses excluded by the caller),
## counts of darts, rifle shots, Spoofed transmissions, takedowns, Fultons and Hold-ups, every idle over
## IDLE_LOG, and the run's shape: when the Operative was first spotted, when it entered each Encounter (and
## by which exit it left the last), each Alert and the Encounter it began in, and each tutorial tip shown.
## Idle = seconds since the last progress event: a step done, a Checkpoint, an Alert ending (the edge
## tick() sees). Alert and Evasion time never counts. The Hint tracker reads idle_seconds() and keeps no timer.
## Spoof send = one transmission Glaukopis judged (a Codec Spoof or a report-in), believed or exposed.
class_name SessionLog
extends RefCounted

const IDLE_LOG := 60.0
const LOGGED := ["dart", "rifle", "spoof", "takedown", "fulton", "holdup"]  # event names count() keeps

static var current := SessionLog.new()  # one per game run, fed by MissionRun

## [{mission, seconds, <LOGGED counts>, idles: [seconds], spotted: seconds or -1,
##   encounters: [[id, seconds, exit]], alerts: [[encounter, seconds]], tips: [[verb, seconds]]}]
var missions := []
var _idle := 0.0
var _alerting := false


func start_mission(index: int) -> void:
	finish_mission()
	var m := {mission = index, seconds = 0.0, idles = [], open = true, spotted = -1.0, encounters = [], alerts = [], tips = []}
	for e: String in LOGGED:
		m[e] = 0
	missions.append(m)
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


## A guard's meter started filling on the Operative; only the first time counts.
func spotted() -> void:
	if not missions.is_empty() and missions.back().spotted < 0.0:
		missions.back().spotted = seconds()


## The Operative walked into Encounter id (0 = between Encounters), leaving by `exit` ("" if unknown).
func enter_encounter(id: int, exit := "") -> void:
	if not missions.is_empty():
		missions.back().encounters.append([id, seconds(), exit])


## An Alert was called while the Operative was in Encounter enc.
func alert(enc: int) -> void:
	if not missions.is_empty():
		missions.back().alerts.append([enc, seconds()])


func tip(verb: String) -> void:
	if not missions.is_empty():
		missions.back().tips.append([verb, seconds()])


## The Mission ended or was left: log a running idle. Safe to call twice.
func finish_mission() -> void:
	if not missions.is_empty() and missions.back().open:
		progress()
		missions.back().open = false


func to_text() -> String:
	var s := ""
	for m: Dictionary in missions:
		s += "mission %d time %d s darts %d rifle %d spoofs %d takedowns %d fultons %d holdups %d alerts %d\n" % [
			m.mission, m.seconds, m.dart, m.rifle, m.spoof, m.takedown, m.fulton, m.holdup, m.alerts.size()]
		s += "  first spotted %s\n" % ("never" if m.spotted < 0.0 else "%d s" % m.spotted)
		for e: Array in m.encounters:
			s += "  %d s: encounter %d%s\n" % [e[1], e[0], " (left by %s)" % e[2] if e[2] != "" else ""]
		for a: Array in m.alerts:
			s += "  %d s: alert in encounter %d\n" % [a[1], a[0]]
		for t: Array in m.tips:
			s += "  %d s: tip %s\n" % [t[1], t[0]]
		for i: float in m.idles:
			s += "  idle %d s\n" % i
	return s


## Rewrites the whole log (one file per game run).
func write(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(to_text())
