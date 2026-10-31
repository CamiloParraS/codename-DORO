## The Ascent's rules, node-free: which sets exist (one per ending), how hard the shaft shakes and how the car's lamp
## flickers for each. The sets themselves are built by tools/cine/core_ascent.gd and shown by areas/core/ascent_set.gd.
class_name AscentLogic
extends RefCounted

const KEY := "CineAscent"
const SET := "DescentCab/Shaft/Ascent"   # under the shaft strip, so the floors slide past with it
const VARIANTS := ["pallas", "nike", "gorgo"]   # Finale.STILLS' keys: one per ending
const TRAUMA := {pallas = 0.0, nike = 0.5, gorgo = 1.0}   # PhantomCameraNoise3D trauma, squared into the amplitude track


static func trauma(variant: String) -> float:
	return TRAUMA.get(variant, 0.0)


## The car lamp's brightness multiplier `t` seconds in: Pallas steady, Nike stuttering, Gorgo guttering low.
static func flicker(variant: String, t: float) -> float:
	match variant:
		"nike":
			return 1.0 if sin(t * 23.0) * sin(t * 7.3 + 1.0) > -0.25 else 0.15
		"gorgo":
			return clampf(0.55 + 0.45 * sin(t * 31.0) * sin(t * 11.0 + 2.0), 0.0, 1.0)
	return 1.0
