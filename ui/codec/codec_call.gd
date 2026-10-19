## A Codec call as data: an ordered list of [speaker, key], typed out line by line with a beep per
## character. Paused full-screen calls advance on press(); live calls pass auto to advance() and move
## on by themselves after HOLD seconds. Text is tr(key). Node-free.
class_name CodecCall
extends RefCounted

const HOLD := 2.0  # seconds a finished line stays up in a live call

var lines: Array     # [[speaker, key], ...]
var index := 0
var _blip: VoiceBlip
var _held := 0.0


func _init(l: Array) -> void:
	lines = l
	_start()


func done() -> bool:
	return index >= lines.size()


func speaker() -> String:
	return lines[index][0]


func speaker_name() -> String:
	return tr("codec.speaker." + speaker())


func text() -> String:
	return tr(lines[index][1])


func shown() -> String:
	return _blip.shown()


func typing() -> bool:
	return not _blip.done()


## Types on and returns the beep pitches for the new characters; live calls (auto) then move on.
func advance(delta: float, auto := false) -> Array[float]:
	if done():
		return []
	var was_typing := typing()
	var p := _blip.advance(delta)
	if auto and not was_typing:
		_held += delta
		if _held >= HOLD:
			press()
	return p


## First press reveals the line, the next one moves on.
func press() -> void:
	if done():
		return
	if typing():
		_blip.skip()
	else:
		index += 1
		_start()


func _start() -> void:
	_held = 0.0
	if not done():
		_blip = VoiceBlip.new(text(), speaker())
