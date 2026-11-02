## Mission 1's deck lessons, node-free (playtest 1: a new player skipped the Codec call and didn't know what to do;
## the tips timed out before they were read). Each lesson is a line on the HUD's objective line that waits for the
## player instead of timing out: crouch, use the Scanner, get past (or take down) O1, record the smoke break (step 1
## itself, no line of its own), get off the ship. None blocks the Mission: a later one done closes every earlier one,
## so a player who walks straight past O1 skips the first three. Only the campaign's Mission 1 (the Harbour) runs them.
class_name Lessons
extends RefCounted

## Per lesson: its text key ("" for step 1's own objective) and the action whose binding the line names.
const LINES := [["objective.m1.l1", "crouch"], ["objective.m1.l2", "item_use"], ["objective.m1.l3", ""], ["", ""],
	["objective.m1.l5", "radio"]]
const EXIT := 4            # the last lesson: get off the ship (where the radio is taught)
const PAST_O1_Y := 25.0    # diagram m: aft of O1's walk across the deck (y 19)

var done := 0              # lessons behind the player; LINES.size() once the deck is over


## The open lesson's index after `facts`, or -1 once they are all done. facts: crouched, scanning (the Scanner on),
## o1_down, y (the Operative's diagram y), recorded (step 1 done), off_deck (in a later Encounter).
func update(facts: Dictionary) -> int:
	var reached := 0
	if facts.crouched:
		reached = 1
	if facts.scanning:
		reached = 2
	if facts.o1_down or facts.y > PAST_O1_Y:
		reached = 3
	if facts.recorded:
		reached = 4
	if facts.off_deck:
		reached = LINES.size()
	done = maxi(done, reached)
	return done if done < LINES.size() else -1


## The line for lesson `i` with its key named for running text ("" for step 1's, or none).
static func line(i: int) -> String:
	if i < 0 or LINES[i][0] == "":
		return ""
	var text := TranslationServer.translate(LINES[i][0])
	return text.format({key = Prompts.word(LINES[i][1])}) if LINES[i][1] != "" else text
