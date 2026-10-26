## Which talking clip a speaker plays: one per line, taking turns. Node-free.
class_name Gesture
extends RefCounted

const CLIPS := ["talk", "talk_b"]

var _n := 0


func next() -> String:
	_n += 1
	return CLIPS[(_n - 1) % CLIPS.size()]
