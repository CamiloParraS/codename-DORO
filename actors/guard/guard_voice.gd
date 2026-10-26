class_name GuardVoice
extends AudioStreamPlayer3D
## A guard's one reused voice player (child of the Guard). Bark decides what and how often; this plays
## a random take on the Voice bus, or the Radio bus for radio lines, and sequences the radio squelch.

const SQUELCH := 0.2  # seconds from the radio-on squelch to the line

static var barks := Bark.new()  # cooldowns, shared by every guard
static var _takes := {}         # event -> AudioStreamRandomizer

var calling := false  # the line playing is a Radio call's
var _seq := 0         # bumped by cut_call(): a pending sequence from before it gives up


func _init() -> void:
	name = "Voice"
	volume_db = 4.0  # sits above the music
	position.y = 1.6
	max_distance = 30.0
	attenuation_filter_cutoff_hz = 3500.0
	emission_angle_enabled = true  # muffled when the guard faces away
	emission_angle_degrees = 90.0


## Say a take of `event` unless this guard said it too recently. `key` stands in for the guard's name in
## the cooldown (a line one guard of the group says: "*"). True when it plays.
func say(event: StringName, key := "") -> bool:
	if not is_inside_tree() or not barks.request(key if key != "" else str(get_parent().name), event, Time.get_ticks_msec() / 1000.0):
		return false
	calling = false
	stream = _takes_of(event)
	bus = Mix.RADIO if Bark.on_radio(event) else Mix.VOICE
	pitch_scale = Bark.pitch(str(get_parent().name))
	play()
	return true


## The spotter's shout, then the Radio call's line behind a squelch while `still` says the call goes on.
## The guard plays the radio-off squelch when the call completes.
func call_in(still: Callable) -> void:
	_seq += 1
	var mine := _seq
	if say(&"spotted"):
		await finished
		if mine != _seq or not still.call():
			return
	Mixer.play(&"radio_on", Mix.RADIO)
	await get_tree().create_timer(SQUELCH).timeout
	if mine == _seq and still.call() and say(&"contact"):
		calling = true


## A one-off radio window: squelch on, the line, squelch off.
func radio_line(event: StringName, key := "") -> void:
	if not is_inside_tree() or not barks.request(key if key != "" else str(get_parent().name), event, Time.get_ticks_msec() / 1000.0):
		return
	_seq += 1
	var mine := _seq
	Mixer.play(&"radio_on", Mix.RADIO)
	await get_tree().create_timer(SQUELCH).timeout
	if mine != _seq:
		return
	calling = false
	stream = _takes_of(event)
	bus = Mix.RADIO
	pitch_scale = Bark.pitch(str(get_parent().name))
	play()
	await finished
	if mine == _seq:
		Mixer.play(&"radio_off", Mix.RADIO)


## A dart or choke during the call: cuts the call's line and any sequence behind it, with no off squelch.
func cut_call() -> void:
	_seq += 1
	if calling:
		stop()
		calling = false


static func _takes_of(event: StringName) -> AudioStreamRandomizer:
	if not _takes.has(event):
		var r := AudioStreamRandomizer.new()
		var seen := []
		var d := Bark.dir(event)
		for f in DirAccess.get_files_at(d):
			f = f.trim_suffix(".import").trim_suffix(".remap")  # an export lists the remaps
			if Bark.wants(event, f) and not f in seen:
				seen.append(f)
				r.add_stream(-1, load(d + "/" + f))
		_takes[event] = r
	return _takes[event]
