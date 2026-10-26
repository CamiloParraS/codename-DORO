class_name ChatterVoice
extends RefCounted
## How a guard conversation line sounds: a caution bark clip when the line's text is that clip's, else a
## text mumble (VoiceBlip) pitched by the speaker. Node-free; GuardVoice.speak plays it.

## Line key -> file in assets/audio/barks/caution/ (the key's English text is the clip's words).
const CLIPS := {
	"chat.idle.3.a": "I tell ya, these guard shifts lately have been killers.ogg",
	"chat.smoke.3.a": "I tell ya, these guard shifts lately have been killers.ogg",
	"chat.idle.5.b": "I don't buy that.ogg",
	"chat.idle.6.b": "Eyes open!.ogg",
	"chat.smoke.5.b": "So I heard.ogg",
}
## Mumble level on the Voice bus, 3D-attenuated like a bark. Tune by ear; keep at or under GuardVoice.BARK_DB.
const MUMBLE_DB := 0.0
const PITCH_MIN := 0.6
const PITCH_MAX := 1.6


static func clip_for(key: String) -> String:
	return CLIPS.get(key, "")


static func clip_path(key: String) -> String:
	return Bark.BARKS + "caution/" + clip_for(key)


## A guard's mumble pitch, the same every time and spread wide so two speakers sound distinct.
static func pitch(who: String) -> float:
	return PITCH_MIN + (hash(who) % 11) * (PITCH_MAX - PITCH_MIN) / 10.0
