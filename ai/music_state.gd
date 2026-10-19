class_name MusicState
extends RefCounted
## Which music track plays: the highest guard state in the Mission picks it, and a change holds
## at least HOLD seconds. Patrol and Suspicion are ambience only (Suspicion gets a sting, no music).
## Node-free; the Mix autoload feeds it every frame.

const HOLD := 2.0
const DUCK_DB := -6.0  # music level while a Codec call plays

var track := &""     # current track: &"", &"alert" or &"evasion"
var _since := HOLD   # seconds since the last change


## `states` are the GuardAlert.State values of the guards that are up. Returns the track to play.
func update(delta: float, states: Array) -> StringName:
	_since += delta
	var want := &""
	if GuardAlert.State.ALERT in states:
		want = &"alert"
	elif GuardAlert.State.EVASION in states:
		want = &"evasion"
	if want != track and _since >= HOLD:
		track = want
		_since = 0.0
	return track


static func duck_db(call_playing: bool) -> float:
	return DUCK_DB if call_playing else 0.0
