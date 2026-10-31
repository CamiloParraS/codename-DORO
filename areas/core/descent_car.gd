## The Descent's car (tools/cine/core.gd builds it, the take CineDescent animates it): the panel's five lights, the gate,
## the motor hum and the dark pulse that hides the cut. Every property below is a value track of the take, so a skip (a seek
## to the take's end) lands in the same state as the natural end. The Dominant Voice is read from the Mission's record the
## way the finale reads it (DescentLogic), never a second rule.
extends Node3D

const GATE_TRAVEL := 1.1   # m each grille slides from open to shut
const GATE_CLANG := 0.9    # `gate` past which the shut gate clangs, once

var lit := 0.0:        # 0..5: how many panel lights are on
	set(v):
		var voice := DescentLogic.lit_voice(lit, v)
		lit = v
		_apply()
		if voice != "" and is_inside_tree():
			Mixer.blip(VoiceBlip.base(voice))
var settle := 0.0:     # 0..1: the other Voices dim to 40% of the Dominant Voice's
	set(v):
		settle = v
		_apply()
var dark := 0.0:       # 0..1: the black pulse over the screen
	set(v):
		dark = v
		if _veil:
			_veil.visible = v > 0.0
			_veil.color.a = v
var gate := 0.0:       # 0 open .. 1 shut
	set(v):
		if v >= GATE_CLANG and gate < GATE_CLANG and is_inside_tree():
			Mixer.play(&"knock", Mixer.SFX)
		gate = v
		_move_gate()
var motor := 0.0:      # 0..1: the lift's motor, a low hum
	set(v):
		motor = v
		_hum()

var _lamps: Array[StandardMaterial3D] = []
var _veil: ColorRect
var _hummer: AudioStreamPlayer
var _shut := {}       # side -> the grille's x when shut


func _ready() -> void:
	for voice in Aigis.VOICES:
		var lamp := get_node_or_null("Panel/Lamp" + voice.capitalize()) as MeshInstance3D
		_lamps.append((lamp.mesh as BoxMesh).material as StandardMaterial3D if lamp else null)
	var layer := CanvasLayer.new()
	layer.layer = 2  # over the HUD, under the take's bars (3)
	_veil = ColorRect.new()
	_veil.color = Color(0, 0, 0, 0)
	_veil.visible = false
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_veil)
	add_child(layer)
	var noise := get_parent().get_node_or_null("Cine/CineDescentRig/Cam") as PhantomCamera3D
	if noise and noise.noise:
		noise.noise.set_trauma(1.0)  # the take's amplitude track is the shake; trauma is not saved with the scene
	for side in ["W", "E"]:
		var leaf := get_node_or_null("Gate" + side) as Node3D
		if leaf:
			_shut[side] = leaf.position.x
	_apply()
	_move_gate()


## The Dominant Voice: the Mission's record (a Preset's, in Free mode), else the lowest band.
func dominant() -> String:
	var run := get_parent().get_node_or_null("MissionRun") as MissionRun
	return DescentLogic.dominant_of(run.record if run else Aigis.new_record())


func _apply() -> void:
	if _lamps.is_empty():
		return
	var e := DescentLogic.energies(lit, settle, dominant())
	for i in _lamps.size():
		if _lamps[i]:
			_lamps[i].emission_energy_multiplier = e[i]


func _move_gate() -> void:
	for side in ["W", "E"]:
		var leaf := get_node_or_null("Gate" + side) as Node3D
		if leaf and _shut.has(side):
			leaf.position.x = _shut[side] + (-1.0 if side == "W" else 1.0) * GATE_TRAVEL * (1.0 - gate)


func _hum() -> void:
	if not is_inside_tree():
		return
	if _hummer == null:
		var s: AudioStreamOggVorbis = load("res://assets/audio/ambience_hum.ogg")
		s.loop = true
		_hummer = AudioStreamPlayer.new()
		_hummer.stream = s
		_hummer.bus = Mixer.SFX
		add_child(_hummer)
	if motor > 0.0 and not _hummer.playing:
		_hummer.play()
	elif motor <= 0.0 and _hummer.playing:
		_hummer.stop()
	_hummer.pitch_scale = 0.45 + 0.35 * motor
	_hummer.volume_db = linear_to_db(maxf(motor, 0.001)) - 6.0
