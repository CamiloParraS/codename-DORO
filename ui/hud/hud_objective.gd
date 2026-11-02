## The current objective, top-centre under the phase plate, and the CHECKPOINT card when a step is done (playtest 1:
## the objective was only said once, in a call the player clicked through, and a Checkpoint passed unannounced).
## The HUD owns one: update() each frame with the MissionRun, draw() on its design canvas. The line wipes in on a
## change and holds sand for HIGHLIGHT before it settles to white; the card shows for CARD_TIME under it.
class_name HudObjective
extends RefCounted

const Y := 142.0          # design px: the label's baseline, clear of the phase plate (its bottom is at 106) at any window size
const WIDTH := 640.0      # design px the line wraps at
const WIPE := 0.25        # s a new line takes to type across
const HIGHLIGHT := 1.6    # s a new line stays sand
const CARD_TIME := 2.2    # s the CHECKPOINT card shows
const CARD_FADE := 0.3

var text := ""
var step := -1
var age := INF            # s since the line changed
var card_left := 0.0      # s the CHECKPOINT card has left


## Reads what to show from `run` (a MissionRun, or null for none). `line` overrides the run's objective (a Mission 1
## lesson). True when a step was just done: the HUD plays the Checkpoint sound.
func update(delta: float, run: Node, line := "") -> bool:
	age += delta
	card_left = maxf(card_left - delta, 0.0)
	if not run:
		text = ""
		return false
	var now: String = line if line != "" else run.objective()
	if now != text:
		text = now
		age = 0.0
	var done: bool = step >= 0 and run.step > step  # a restore to an earlier Checkpoint goes back without a card
	step = run.step
	if done:
		card_left = CARD_TIME
	return done


## Draws on `c` (design px, `d` the design size) at `alpha`: 0 hides it (a take), the radio dims it.
func draw(c: CanvasItem, d: Vector2, alpha: float) -> void:
	if text == "" or alpha <= 0.0:
		return
	var x := d.x / 2.0
	var lit := age < HIGHLIGHT
	HudPalette.hud_label(c, Vector2(x, Y), TranslationServer.translate("ui.hud.objective"), 15, Color(HudPalette.SAND, alpha), 0.24, HudPalette.LABEL_BOLD, 1)
	var shown := text.left(ceili(text.length() * clampf(age / WIPE, 0.0, 1.0)))
	var rows := HudPalette.wrap(shown, WIDTH, HudPalette.FIGURE_MED, 22)
	for i in rows.size():
		HudPalette.hud_text(c, Vector2(x, Y + 30 + i * 28), rows[i], 22, Color(HudPalette.SAND if lit else HudPalette.LIGHT, alpha), HudPalette.FIGURE_MED, 1)
	if card_left > 0.0:
		var a := alpha * minf(card_left / CARD_FADE, clampf((CARD_TIME - card_left) / 0.12, 0.0, 1.0))
		var word := TranslationServer.translate("ui.hud.checkpoint").to_upper()
		var f := HudPalette.tracked(HudPalette.DISPLAY, 22, 0.4)
		var w := f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, HudPalette.legible(c, 22)).x + 48.0
		var y := Y + 40 + rows.size() * 28
		c.draw_rect(Rect2(x - w / 2.0, y, w, 38), Color(HudPalette.GLASS, 0.86 * a))
		c.draw_rect(Rect2(x - w / 2.0, y, 4, 38), Color(HudPalette.SAND, a))
		HudPalette.hud_text(c, Vector2(x, y + 27), word, 22, Color(HudPalette.LIGHT, a), f, 1, false)
