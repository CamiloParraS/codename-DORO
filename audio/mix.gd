class_name Mix
extends Node
## Autoload `Mixer` (class Mix): the buses, the music that follows the guards, ambience, SFX and the Codec duck.
## Master -> Music, SFX (PSX bitcrush), UI (UI and Codec), Ambience; Voice and Radio (band-passed, second bitcrush) send to SFX. The settings screen calls
## set_volume(bus, 0..1) / volume(bus). A Codec call player calls codec_call(true) and (false).

const NoFulton := preload("res://areas/no_fulton.gd")
const MASTER := &"Master"
const MUSIC := &"Music"
const SFX := &"SFX"
const UI := &"UI"
const AMBIENCE := &"Ambience"
const VOICE := &"Voice"
const RADIO := &"Radio"
const BUSES := [MUSIC, SFX, UI, AMBIENCE, VOICE, RADIO]
const DUCK_SPEED := 24.0   # dB per second, into and out of the duck
const FADE_DB := 60.0      # dB per second, music crossfade
const SILENT := -60.0
## A value is one path, or an Array of variants (one is picked at random per play).
const STREAMS := {
	&"alert": "res://assets/audio/music_alert.ogg",
	&"evasion": "res://assets/audio/music_evasion.ogg",
	&"patrol": "res://assets/audio/music_patrol.ogg",
	&"ambience": "res://assets/audio/ambience_hum.ogg",
	&"ambience_outdoor": "res://assets/audio/ambience_outdoor.ogg",
	&"knock": "res://assets/audio/sfx_knock.ogg",
	&"sting_question": "res://assets/audio/sting_question.ogg",
	&"sting_alert": "res://assets/audio/sting_alert.ogg",
	&"sting_relief": "res://assets/audio/sting_relief.ogg",
	&"footstep": ["res://assets/audio/sfx_step_0.ogg", "res://assets/audio/sfx_step_1.ogg", "res://assets/audio/sfx_step_2.ogg",
		"res://assets/audio/sfx_step_3.ogg", "res://assets/audio/sfx_step_4.ogg"],
	&"footstep_metal": ["res://assets/audio/sfx_step_metal_0.ogg", "res://assets/audio/sfx_step_metal_1.ogg", "res://assets/audio/sfx_step_metal_2.ogg",
		"res://assets/audio/sfx_step_metal_3.ogg", "res://assets/audio/sfx_step_metal_4.ogg", "res://assets/audio/sfx_step_metal_5.ogg",
		"res://assets/audio/sfx_step_metal_6.ogg", "res://assets/audio/sfx_step_metal_7.ogg"],
	&"shot_quiet": "res://assets/audio/sfx_shot_quiet.ogg",
	&"shot_quiet_rifle": "res://assets/audio/sfx_shot_quiet_rifle.ogg",
	&"shot_loud": "res://assets/audio/sfx_shot_loud.ogg",
	&"takedown": "res://assets/audio/sfx_takedown.ogg",
	&"body_fall": "res://assets/audio/sfx_body_fall.ogg",
	&"dart_hit": "res://assets/audio/sfx_dart_hit.ogg",
	&"dart_vest": "res://assets/audio/sfx_dart_vest.ogg",
	&"choke": "res://assets/audio/sfx_choke.ogg",
	&"mag_land": ["res://assets/audio/sfx_mag_land_0.ogg", "res://assets/audio/sfx_mag_land_1.ogg"],
	&"ladder": ["res://assets/audio/sfx_ladder_0.ogg", "res://assets/audio/sfx_ladder_1.ogg", "res://assets/audio/sfx_ladder_2.ogg"],
	&"fulton_launch": "res://assets/audio/sfx_fulton_launch.ogg",
	&"fulton_lift": "res://assets/audio/sfx_fulton_lift.ogg",
	&"radio_on": "res://assets/audio/sfx_radio_on.ogg",
	&"radio_off": "res://assets/audio/sfx_radio_off.ogg",
	&"ui_click": "res://assets/audio/sfx_ui_click.ogg",
	&"radio_static": "res://assets/audio/sfx_radio_static.ogg",
}
const STEP_DB := -2.0           # a standing (run) footstep
const CROUCH_STEP_DB := -14.0   # a crouched footstep: much quieter than STEP_DB...
const CARRY_STEP_DB := -5.0     # a Fireman's-carry footstep
const CROUCH_STEP_CUTOFF_HZ := 1500.0  # ...and muffled by a lowpass
const CARRY_STEP_PITCH := 0.8   # heavier

const OUTDOOR_DB := -24.0  # crickets bed under open sky

var _vol := {}             # bus -> linear 0..1
var _duck := 0.0           # current music duck, dB (0 or MusicState.DUCK_DB)
var _duck_to := 0.0
var _state := MusicState.new()
var _beat := AlertBeat.new()
var _music := {}           # track -> AudioStreamPlayer
var _scaled := false       # a hit-stop owns Engine.time_scale until it is restored
var _outdoor: AudioStreamPlayer
var _blip: AudioStreamPlayer   # one player for every text blip: a new blip cuts the last, so none stack


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # the hit-stop must end (and the stings play) while paused
	setup_buses()
	for t in [&"patrol", &"alert", &"evasion"]:
		_music[t] = _looped(t, MUSIC)
	_looped(&"ambience", AMBIENCE).volume_db = -12.0  # quiet bed under everything
	_outdoor = _looped(&"ambience_outdoor", AMBIENCE)


func _process(delta: float) -> void:
	var states := []
	for g in get_tree().get_nodes_in_group("guards"):
		if not g.is_down():
			states.append(g.alert.state)
	var now := Time.get_ticks_msec() / 1000.0
	var cue := _beat.update(states, now)
	if cue != &"":
		play(&"sting_" + cue)
		if cue == &"alert":
			rumble(0.3, 0.6, 0.15)
			var spotted := get_tree().get_first_node_in_group("operative")
			if spotted:
				spotted.kick(0.06)
	var op := get_tree().get_first_node_in_group("operative")
	apply_scale(_beat.scale(now, get_tree().paused or (op != null and op.health.dead())))
	var want := _state.update(delta, states)
	if op == null:
		want = &""  # menus and briefings: no patrol loop
	for t in _music:
		var p: AudioStreamPlayer = _music[t]
		p.volume_db = move_toward(p.volume_db, MusicState.ceiling_db(t) if t == want else SILENT, FADE_DB * delta)
	var sky := op != null and NoFulton.open_sky(get_tree(), op.global_position)
	_outdoor.volume_db = move_toward(_outdoor.volume_db, OUTDOOR_DB if sky else SILENT, 12.0 * delta)
	advance_duck(delta)


## A short freeze for a hit or a takedown; the same hit-stop the "!" uses.
func hit_stop(secs: float) -> void:
	_beat.stop(Time.get_ticks_msec() / 1000.0, secs)


## Pad rumble, no-op without a pad. Everything felt through the hands goes through here.
func rumble(weak: float, strong: float, secs: float) -> void:
	for pad in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, weak, strong, secs)


## Touches Engine.time_scale only while a hit-stop is on or being restored.
func apply_scale(s: float) -> void:
	if s != 1.0 or _scaled:
		Engine.time_scale = s
		_scaled = s != 1.0


## Creates the buses once; safe to call again.
func setup_buses() -> void:
	for b in BUSES:
		if AudioServer.get_bus_index(b) >= 0:
			continue
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, b)
		AudioServer.set_bus_send(i, &"Master")
		if b == VOICE or b == RADIO:
			AudioServer.set_bus_send(i, SFX)
		if b == RADIO:
			var hp := AudioEffectHighPassFilter.new()
			hp.cutoff_hz = 400.0
			var lp := AudioEffectLowPassFilter.new()
			lp.cutoff_hz = 3200.0
			var lofi := AudioEffectDistortion.new()
			lofi.mode = AudioEffectDistortion.MODE_LOFI
			lofi.drive = 0.4
			for fx in [hp, lp, lofi]:
				AudioServer.add_bus_effect(i, fx)
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


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## One text blip on the UI/Codec bus at `pitch` (see VoiceBlip). Cuts the previous blip.
func blip(pitch: float) -> void:
	if not _blip:
		_blip = AudioStreamPlayer.new()
		_blip.stream = blip_tone()
		_blip.bus = UI
		_blip.volume_db = -10.0
		add_child(_blip)
	_blip.pitch_scale = pitch
	_blip.play()


func stop_blips() -> void:
	if _blip:
		_blip.stop()


## A generated 40 ms square-ish tone at 440 Hz with a linear decay; blip() and GuardVoice.speak pitch-shift it.
static func blip_tone() -> AudioStreamWAV:
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


## A UI click on the UI bus (menus, pause).
func click() -> void:
	play(&"ui_click")


## A non-positional one-shot of `sound` on `bus` (stings, clicks, the radio squelch).
func play(sound: StringName, bus := UI) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = load(pick(sound))
	p.bus = bus
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()


## The path to play for `sound`: its only stream, or a random variant.
static func pick(sound: StringName) -> String:
	var v: Variant = STREAMS[sound]
	return v if v is String else v.pick_random()


## Which stream a shot uses: a suppressed rifle, the tranq gun's pistol, or the loud rifle.
static func shot_sound(quiet: bool, lethal := false) -> StringName:
	if not quiet:
		return &"shot_loud"
	return &"shot_quiet_rifle" if lethal else &"shot_quiet"


## The footstep sound for a floor `surface` tag ("metal" from the Area generators; anything else is concrete).
static func step_sound(surface: StringName) -> StringName:
	return &"footstep_metal" if surface == &"metal" else &"footstep"


static func step_db(crouching: bool, carrying := false) -> float:
	if carrying:
		return CARRY_STEP_DB
	return CROUCH_STEP_DB if crouching else STEP_DB


## A one-shot on the SFX bus, 3D at `at`'s position (or at `pos` when given, e.g. where a Magazine lands).
## Returns the player (a Fulton lift bends its pitch).
static func sfx_at(at: Node3D, sound: StringName, pos := Vector3.INF, db := 0.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = load(pick(sound))
	p.bus = SFX
	p.volume_db = db
	p.pitch_scale = randf_range(0.9, 1.1)
	p.finished.connect(p.queue_free)
	at.add_child(p)
	if pos != Vector3.INF:
		p.global_position = pos
	p.play()
	return p


func _apply(bus: StringName) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(volume(bus)) + (_duck if bus == MUSIC else 0.0))


func _looped(sound: StringName, bus: StringName) -> AudioStreamPlayer:
	var s: AudioStreamOggVorbis = load(pick(sound))
	s.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.bus = bus
	p.volume_db = SILENT
	add_child(p)
	p.play()
	return p
