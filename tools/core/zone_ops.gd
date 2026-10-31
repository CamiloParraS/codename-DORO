## Encounter 2, the operations building (positioning): the north door is sealed, Gate and LiftHall stand 20.5 m
## apart. Step 1 is the lift panel (hold E, the code is known by now), step 2 the lift.
extends "res://tools/core/zone.gd"

const D := {
	start = [26, 46, 0],
	seal = [["OpsNorthPlug", [19, 19.85, 2, 0.3], 0, 4, "panels", Color.WHITE]],
	posts = [
		["PostGate", [20, 45, 0], 120, {scan = 60.0, role = "gatekeeper", enc = 2}, []],
		["PostLiftHall", [15.5, 25, 0], 180, {hold = 5.0, role = "interceptor", enc = 2}, []],  # faces down the hall; his back to the control room's door
	],
	encounters = [[2, "Operations building", "positioning", [2, 18, 24, 30], [8, 32, 0], 3]],
	exits = {Lift = [8, 32, 0]},
	objectives = {IntelLiftPanel = {at = [22, 22.2, 0], console = 4.0, prompt = "ui.prompt.enter_code"}},
	intel = {IntelLift = [8, 32]},
	reach = {OpsEastDoor = [23.2, 32, 0], Panel = [21.5, 22.6, 0], LiftHallBack = [16.4, 23, 0], LiftMouth = [8, 32, 0]},
}
