## A playtest's self-record, node-free: per Mission its time (all of it, pauses excluded by the caller),
## counts of darts, rifle shots, Spoofed transmissions, takedowns, Fultons and Hold-ups, every idle over
## IDLE_LOG, and the run's shape: when the Operative was first spotted, when it entered each Encounter (and
## by which exit it left the last), each Alert and the Encounter it began in, and each tutorial tip shown.
## Idle = seconds since the last progress event: a step done, a Checkpoint, an Alert ending (the edge
## tick() sees). Alert and Evasion time never counts. The Hint tracker reads idle_seconds() and keeps no timer.
## Spoof send = one transmission Glaukopis judged (a Codec Spoof or a report-in), believed or exposed.
## Notes are the run's other moments in words (who spotted, a guard down, a step, a Continue), and the trail is
## where the Operative stood every TRAIL_EVERY seconds, in diagram metres (the Area builders' x, y, h).
## The file keeps every run: each Mission is appended once it ends, under its start time and label.
class_name SessionLog
extends RefCounted

const IDLE_LOG := 60.0
const LOGGED := ["dart", "rifle", "spoof", "takedown", "fulton", "holdup"]  # event names count() keeps
const TRAIL_EVERY := 10.0
const MAX_BYTES := 1 << 20  # a log past this starts over rather than grow without end

static var current := SessionLog.new()  # one per game run, fed by MissionRun

## [{mission, seconds, <LOGGED counts>, idles: [seconds], spotted: seconds or -1,
##   encounters: [[id, seconds, exit]], alerts: [[encounter, seconds]], tips: [[verb, seconds]],
##   notes: [[seconds, text]], trail: [[seconds, Vector3 (x, y, h), encounter]], label, started, written}]
var missions := []
var _idle := 0.0
var _alerting := false


## label: the Area and the mode, for the header line.
func start_mission(index: int, label := "") -> void:
	finish_mission()
	var m := {mission = index, seconds = 0.0, idles = [], open = true, spotted = -1.0, encounters = [], alerts = [], tips = [],
		notes = [], trail = [], label = label, started = Time.get_datetime_string_from_system(false, true), written = false}
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


## A guard's (or camera's) meter started filling on the Operative; only the first time counts, noted with
## who and where when given.
func spotted(by := "", where := "") -> void:
	if not missions.is_empty() and missions.back().spotted < 0.0:
		missions.back().spotted = seconds()
		if by != "":
			note("first spotted by %s, Operative at %s" % [by, where])


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


## Something worth a line in the run's timeline.
func note(text: String) -> void:
	if not missions.is_empty():
		missions.back().notes.append([seconds(), text])


## The Operative's position (x, y, h) and Encounter, kept every TRAIL_EVERY seconds.
func place(at: Vector3, enc: int) -> void:
	if missions.is_empty():
		return
	var trail: Array = missions.back().trail
	if trail.is_empty() or seconds() - trail.back()[0] >= TRAIL_EVERY:
		trail.append([seconds(), at, enc])


## The Mission ended or was left: log a running idle. Safe to call twice.
func finish_mission() -> void:
	if not missions.is_empty() and missions.back().open:
		progress()
		missions.back().open = false


func to_text() -> String:
	var s := ""
	for m: Dictionary in missions:
		s += _mission_text(m)
	return s


## One Mission: its header, its counts, every timed line in order, its idles, then its trail.
static func _mission_text(m: Dictionary) -> String:
	var s := "== %s  %s\n" % [m.started, m.label] if m.label != "" else ""
	s += "mission %d time %d s darts %d rifle %d spoofs %d takedowns %d fultons %d holdups %d alerts %d\n" % [
		m.mission, m.seconds, m.dart, m.rifle, m.spoof, m.takedown, m.fulton, m.holdup, m.alerts.size()]
	s += "  first spotted %s\n" % ("never" if m.spotted < 0.0 else "%d s" % m.spotted)
	var lines := []  # [seconds, text]
	for e: Array in m.encounters:
		lines.append([e[1], "encounter %d%s" % [e[0], " (left by %s)" % e[2] if e[2] != "" else ""]])
	for a: Array in m.alerts:
		lines.append([a[1], "alert in encounter %d" % a[0]])
	for t: Array in m.tips:
		lines.append([t[1], "tip %s" % t[0]])
	lines.append_array(m.notes)
	lines.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for l: Array in lines:
		s += "  %d s: %s\n" % [l[0], l[1]]
	for i: float in m.idles:
		s += "  idle %d s\n" % i
	if not m.trail.is_empty():
		s += "  trail (s: x y h E):\n"
		for k in range(0, m.trail.size(), 6):
			var row: Array = m.trail.slice(k, k + 6).map(func(p: Array) -> String:
				return "%4d: %d %d %d E%d" % [p[0], p[1].x, p[1].y, p[1].z, p[2]])
			s += "   " + "   ".join(row) + "\n"
	return s + "\n"


## Appends each finished Mission not yet written: the file keeps earlier runs (past MAX_BYTES it starts over).
func write(path: String) -> void:
	var text := ""
	for m: Dictionary in missions:
		if not m.open and not m.written:
			text += _mission_text(m)
			m.written = true
	append(path, text)


static func append(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else null
	if f == null or f.get_length() > MAX_BYTES:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_string(text)


## The Mission still running, rewritten in full: if the game dies, the next run recovers it (recover()).
func write_live(path: String) -> void:
	if missions.is_empty() or not missions.back().open:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(_mission_text(missions.back()).trim_suffix("\n") + "  (the game stopped here: a crash, or closed from outside)\n\n")


## A live file left behind by a run that never ended is appended to the log, then removed.
static func recover(live: String, path: String) -> void:
	if FileAccess.file_exists(live):
		append(path, FileAccess.get_file_as_string(live))
		DirAccess.remove_absolute(live)
