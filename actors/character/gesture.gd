## Which talking clip a speaker plays: one per line, taking turns. Node-free.
class_name Gesture
extends RefCounted

const CLIPS := ["talk", "talk_b"]
const HEATED := ["talk", "argue", "talk_b"]  # the Target's chat; argue is long, so it plays from its start
const LONG := "argue"

var _n := 0


func next(heated := false) -> String:
	_n += 1
	var clips := HEATED if heated else CLIPS
	return clips[(_n - 1) % clips.size()]
