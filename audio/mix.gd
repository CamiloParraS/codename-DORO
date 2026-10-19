class_name Mix
extends Node
## Autoload `Mixer` (class Mix): the buses, the music that follows the guards, ambience, SFX and the Codec duck.
## Master -> Music, SFX (PSX bitcrush), UI (UI and Codec), Ambience. The settings screen calls
## set_volume(bus, 0..1) / volume(bus). A Codec call player calls codec_call(true) and (false).

const MUSIC := &"Music"
const SFX := &"SFX"
const UI := &"UI"
const AMBIENCE := &"Ambience"
const BUSES := [MUSIC, SFX, UI, AMBIENCE]
const DUCK_SPEED := 24.0   # dB per second, into and out of the duck
const FADE_DB := 60.0      # dB per second, music crossfade
const SILENT := -60.0
const STREAMS := {
	&"alert": "res://assets/audio/music_alert.ogg",
	&"evasion": "res://assets/audio/music_evasion.ogg",
	&"ambience": "res://assets/audio/ambience_hum.ogg",
	&"footstep": "res://assets/audio/sfx_footstep.ogg",
	&"knock": "res://assets/audio/sfx_knock.ogg",
}

var _vol := {}             # bus -> linear 0..1
var _duck := 0.0           # current music duck, dB (0 or MusicState.DUCK_DB)
var _duck_to := 0.0
var _state := MusicState.new()
var _music := {}           # track -> AudioStreamPlayer
var _blip: AudioStreamPlayer   # one player for every text blip: a new blip cuts the last, so none stack


func _ready() -> void:
	setup_buses()
	for t in [&"alert", &"evasion"]:
		_music[t] = _looped(t, MUSIC)
	_looped(&"ambience", AMBIENCE).volume_db = -12.0  # quiet bed under everything


func _process(delta: float) -> void:
	var states := []
	for g in get_tree().get_nodes_in_group("guards"):
		if not g.is_down():
			states.append(g.alert.state)
	var want := _state.update(delta, states)
	for t in _music:
		var p: AudioStreamPlayer = _music[t]
		p.volume_db = move_toward(p.volume_db, 0.0 if t == want else SILENT, FADE_DB * delta)
	advance_duck(delta)


## Creates the buses once; safe to call again.
func setup_buses() -> void:
	for b in BUSES:
		if AudioServer.get_bus_index(b) >= 0:
			continue
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, b)
		AudioServer.set_bus_send(i, &"Master")
		if b == SFX:
			var crush := AudioEffectDistortion.new()
			crush.mode = AudioEffectDistortion.MODE_LOFI
			crush.drive = 0.4  # ponytail: tune by ear; LOFI only cuts bit depth, not sample rate
			AudioServer.add_bus_effect(i, crush)


func set_volume(bus: StringName, linear: float) -> void:
	_vol[bus] = clampf(linear, 0.0, 1.0)
	_apply(bus)


func volume(bus: StringName) -> float:
	return _vol.get(bus, 1.0)


func codec_call(playing: bool) -> void:
	_duck_to = MusicState.duck_db(playing)


func advance_duck(delta: float) -> void:
	_duck = move_toward(_duck, _duck_to, DUCK_SPEED * delta)
	_apply(MUSIC)


## One text blip on the UI/Codec bus at `pitch` (see VoiceBlip). Cuts the previous blip.
func blip(pitch: float) -> void:
	if not _blip:
		_blip = AudioStreamPlayer.new()
		_blip.stream = _blip_tone()
		_blip.bus = UI
		_blip.volume_db = -10.0
		add_child(_blip)
	_blip.pitch_scale = pitch
	_blip.play()


func stop_blips() -> void:
	if _blip:
		_blip.stop()


## A generated 40 ms square-ish tone at 440 Hz with a linear decay; blip() pitch-shifts it.
static func _blip_tone() -> AudioStreamWAV:
	var rate := 22050
	var n := rate / 25
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var sq := 1.0 if fmod(i * 440.0 / rate, 1.0) < 0.5 else -1.0
		data.encode_s16(i * 2, int(sq * 9000.0 * (1.0 - float(i) / n)))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


## A one-shot on the SFX bus, 3D at `at`'s position.
static func sfx_at(at: Node3D, sound: StringName) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = load(STREAMS[sound])
	p.bus = SFX
	p.pitch_scale = randf_range(0.9, 1.1)
	p.finished.connect(p.queue_free)
	at.add_child(p)
	p.play()


func _apply(bus: StringName) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(volume(bus)) + (_duck if bus == MUSIC else 0.0))


func _looped(sound: StringName, bus: StringName) -> AudioStreamPlayer:
	var s: AudioStreamOggVorbis = load(STREAMS[sound])
	s.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.bus = bus
	p.volume_db = SILENT
	add_child(p)
	p.play()
	return p
