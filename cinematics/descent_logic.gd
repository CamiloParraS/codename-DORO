## The Descent's panel, node-free: five lights, one per Voice, come on in table order; the Dominant Voice's stays the
## brightest and the others settle to 40% of it, so the player sees their Lethality before the debate.
class_name DescentLogic
extends RefCounted

const FLASH := 3.5   # every light's emission as it comes on
const DIM := 0.4     # the other Voices' share of the Dominant Voice's, once settled


## The Dominant Voice for `record`, the way the finale reads it (never a second rule).
static func dominant_of(record: Dictionary) -> String:
	return Finale.from_record(record).band


## Each Voice's emission energy (Aigis.VOICES order): `lit` runs 0..5 (light i is on from i to i+1), `settle` 0..1 dims
## the others from FLASH to DIM of the Dominant Voice's.
static func energies(lit: float, settle: float, dominant: String) -> Array[float]:
	var out: Array[float] = []
	for i in Aigis.VOICES.size():
		var final := FLASH * (1.0 if Aigis.VOICES[i] == dominant else DIM)
		out.append(clampf(lit - i, 0.0, 1.0) * lerpf(FLASH, final, clampf(settle, 0.0, 1.0)))
	return out


## The Voice whose light has just come on going from `from` to `to`, or "": a blip each. A jump (a skip) blips nothing.
static func lit_voice(from: float, to: float) -> String:
	var k := int(to)
	if k > int(from) and k >= 1 and k <= Aigis.VOICES.size() and to - from < 1.0:
		return Aigis.VOICES[k - 1]
	return ""
