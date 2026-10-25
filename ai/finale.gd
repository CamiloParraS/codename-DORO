## The finale as data, node-free: the single unfailable order, the Final debate (one line per Voice, the
## Dominant Voice last, Glaukopis by Spoofing level), the Dominant Voice's ending, the Epilogue call and the
## stills. Lines are [speaker, key] (text/lines.csv). The ui/finale/finale.gd scene plays the stages.
class_name Finale
extends RefCounted

const ORDER := "Transmit memories"
const STAGES := ["order", "debate", "ending", "epilogue", "over"]
const ENDING_LINES := 5          # 4-6 per ending; the last is addressed to the Operative
const EPILOGUE := ["handler", "analyst", "handler", "analyst"]
## ponytail: stand-in stills (CC0 textures already in the project) until real stock stills are chosen.
const STILLS := {
	"pallas": [{path = "res://assets/textures/stone_07_128.png", credit = "ambientCG / Poly Haven, CC0 1.0"}],
	"nike": [{path = "res://assets/textures/metal_05_128.png", credit = "ambientCG / Poly Haven, CC0 1.0"}],
	"gorgo": [{path = "res://assets/textures/brick_07_128.png", credit = "Tiny Texture Pack 2, Screaming Brain Studios, CC0 1.0"}],
}

var band: String      # the Dominant Voice, which is the ending
var spoofing: int     # the Spoofing level the Core saw, 0-3
var stage := "order"


func _init(b: String, spoofing_level: int) -> void:
	band = b
	spoofing = spoofing_level


static func from_record(record: Dictionary) -> Finale:
	return Finale.new(Aigis.resolve_ending(Aigis.lethality_ratio(record)),
		Aigis.level(int(record.points.get("spoofing", 0)), Aigis.CAPS.size() - 1))


## "Transmit memories": the radial's only order. It always works.
func transmit() -> void:
	if stage == "order":
		stage = "debate"


func next() -> void:
	stage = STAGES[mini(STAGES.find(stage) + 1, STAGES.size() - 1)]


## [[voice, key], ...]: the other Voices in table order, then the Dominant Voice.
static func debate(dominant: String, spoofing_level: int) -> Array:
	var out := []
	for v: String in Aigis.VOICES:
		if v == dominant:
			continue
		out.append([v, "finale.debate.glaukopis.%d" % spoofing_level if v == "glaukopis" else "finale.debate.%s.%s" % [v, dominant]])
	out.append([dominant, "finale.debate.%s.%s" % [dominant, dominant]])
	return out


static func ending(dominant: String) -> Array:
	var out := []
	for i in range(1, ENDING_LINES):
		out.append([dominant, "finale.end.%s.%d" % [dominant, i]])
	out.append([dominant, "finale.end.%s.operative" % dominant])
	return out


## The ending's lines, then the one on the Recruits (Metis's contractors in the next war), whatever the ending.
static func epilogue(dominant: String) -> Array:
	var out := []
	for i in EPILOGUE.size():
		out.append([EPILOGUE[i], "finale.epi.%s.%d" % [dominant, i + 1]])
	out.append(["handler", "finale.epi.recruits"])
	return out


static func stills(dominant: String) -> Array:
	return STILLS[dominant]
