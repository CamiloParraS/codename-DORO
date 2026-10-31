## Encounter 1, the quay and yard (timing): the Operative lands at the south pier, the east way times Y1 and lane W,
## the west way meets Gate. The freighter stands empty.
extends "res://tools/core/zone.gd"

const D := {
	start = [52, 77, 0],
	posts = [
		["PostY1", [58, 28, 0], 180, {role = "patroller", enc = 1}, [[58, 46, {hold = 4.0, f = 270}]]],  # holds facing the yard, his back to the pier walk
		["PostLaneW", [42.5, 39, 0], 270, {hold = 3.0, role = "patroller", enc = 1}, [[42.5, 56.5, {hold = 5.0, f = 0}]]],  # the Foreman's lane, no code
		["PostObserver", [38.5, 38, 6], 150, {scan = 90.0, role = "observer", enc = 1}, []],  # Warehouse B roof, 7.3 m from lane W: E1's test pair
	],
	encounters = [[1, "Quay and yard", "timing", [26, 19, 36, 61], [26, 46, 0], 2]],
	exits = {Forecourt = [26, 46, 0], Alley = [25.5, 38, 0]},
	spots = {OperativeStart = [52, 77, 0]},
	reach = {PierMouth = [52, 70, 0], Stack = [30, 66, 0], Forecourt = [28, 46.8, 0], MidLane = [48.5, 38, 0], AlleyMouth = [30, 39.1, 0]},
}
