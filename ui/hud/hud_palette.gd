## One colour per meaning, so the player can tell who is acting. Chrome is the Operative's own
## information; cyan is only ever Aigis; red is danger or empty; amber marks EVASION and nothing else.
class_name HudPalette
extends RefCounted

const WHITE := Color.WHITE  # a live or highlighted value
const CHROME := Color(0.86, 0.88, 0.86)  # Operative info: life, ammo, stance, labels
const CHROME_DIM := Color(0.86, 0.88, 0.86, 0.8)  # reserve counts, empty pips, hints
const AIGIS := Color("2bd4f5")  # detection arcs, Voice tags, habit ticks
const AIGIS_DIM := Color(0.17, 0.83, 0.96, 0.35)  # a barely-there arc
const DANGER := Color(1, 0.22, 0.2)  # ALERT, low life, empty magazine, edge flash
const EVASION := Color(1, 0.69, 0.1)  # EVASION chip and bar
const SHADE := Color(0, 0, 0, 0.55)  # card backing
