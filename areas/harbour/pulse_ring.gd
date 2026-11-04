## The eavesdrop spot's ring (build_harbour.gd): a slow, shallow pulse of its opacity, unscaled so its pixels stay square.
extends Sprite3D

const BASE := 0.3
const SWING := 0.15
const PERIOD := 1.8  # s


func _process(_delta: float) -> void:
	modulate.a = BASE + SWING * sin(Time.get_ticks_msec() / 1000.0 * TAU / PERIOD)
