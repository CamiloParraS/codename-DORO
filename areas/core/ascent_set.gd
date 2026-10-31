## The Ascent's set (tools/cine/core_ascent.gd builds it under the shaft strip): three dressings of the one shaft, one per
## ending. show_variant() lights the chosen one, opens the car's back and roof to the sky, gives the take's camera that
## ending's sky and shake, and starts the fire; the rail, the clip and the camera never branch. The car's lamp flickers
## by AscentLogic. Hidden, and not processing, until the finale picks a variant.
extends Node3D

const OPENED := ["CabBack", "CabRoof"]   # the camera leaves the car backwards and upwards
const CAMERA := "Cine/CineAscentRig/Cam"

@export var skies: Dictionary = {}   # variant -> Environment (the Area's Mood, recoloured)

var variant := ""
var _t := 0.0
var _lamp_energy := -1.0


func _ready() -> void:
	visible = false
	set_process(false)


func show_variant(v: String) -> void:
	variant = v
	visible = true
	for c in get_children():
		var on: bool = c.name == "Ascent" + v.capitalize()
		if c.name.begins_with("Ascent"):
			c.visible = on
			for p in c.find_children("*", "CPUParticles3D", true, false):
				(p as CPUParticles3D).emitting = on
	var car := get_node("../..")
	var area := car.get_parent()
	var sky := area.get_node_or_null("Cine/AscentSkyline") as Node3D
	if sky:
		sky.visible = true
	for n in OPENED:
		var part := car.get_node_or_null(n) as Node3D
		if part:
			part.visible = false
	var lamp := car.get_node_or_null("CabLamp") as OmniLight3D
	if lamp:
		if _lamp_energy < 0.0:
			_lamp_energy = lamp.light_energy
		if v == "gorgo":
			lamp.light_color = Color(1.0, 0.3, 0.2)
	var cam := area.get_node_or_null(CAMERA) as PhantomCamera3D
	if cam:
		cam.environment = skies.get(v)
		if cam.noise:
			cam.noise.set_trauma(AscentLogic.trauma(v))
	var op = area.get_node_or_null("Operative")  # the host only copies a pcam's sky when it changes while active
	if op and op.camera:
		op.camera.environment = skies.get(v)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	var lamp := get_node("../../CabLamp") as OmniLight3D
	lamp.light_energy = _lamp_energy * AscentLogic.flicker(variant, _t)
	for l in get_node("Ascent" + variant.capitalize()).find_children("Sway*", "Node3D", true, false):
		l.rotation.z = 0.35 * sin(_t * 2.1 + l.position.y)
