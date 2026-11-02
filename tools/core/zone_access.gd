## The way down: the freight lift's cut through the west cliff (y 30.7-33.3) with a lintel over it, a short corridor
## (x -14 to the lift at 2), and the plant room off the corridor (door x -8 to -6) whose stair climbs to a mezzanine
## and the Core room's gallery. The stair ends flush with the mezzanine's edge at y 25 (at 24.8 the slab's lip stopped
## the Operative), along the west wall in view of the corridor door (a ladder there went unnoticed in playtest 1).
## Two green ceiling lamps (`lit`) light the door and the stair, and PlantCue turns the camera to the stair once.
## Identity: the lift door in a striped blast frame under a CORE ACCESS sign, a service tunnel's cable tray and pipe,
## the plant room's door, pumps and pipework.
extends "res://tools/core/zone.gd"

const HAZ_DARK := Color(0.3, 0.3, 0.32)
const PIPE := Color(0.85, 0.7, 0.6)

const D := {
	start = [8, 32, 0],
	land = [[-14, 31, 16, 2], [-14, 22, 10, 9]],
	solid = [
		["CliffN", [-2, -6, 4, 36.7], -3, 14, "stone", Color(0.8, 0.75, 0.7)],
		["CliffS", [-2, 33.3, 4, 42.7], -3, 14, "stone", Color(0.8, 0.75, 0.7)],
		["CliffLintel", [-2, 30.7, 4, 2.6], 4.3, 14, "stone", Color(0.8, 0.75, 0.7)],
		["CorridorN1", [-14, 30.7, 6, 0.3], 0, 4, "brick", Color(0.7, 0.72, 0.75)],  # the plant room's door, x -8 to -6
		["CorridorN2", [-6, 30.7, 8, 0.3], 0, 4, "brick", Color(0.7, 0.72, 0.75)],
		["CorridorS", [-14, 33, 16, 0.3], 0, 4, "brick", Color(0.7, 0.72, 0.75)],
		["CorridorRoof", [-14, 30.7, 16, 2.6], 4, 4.3, "metal", Color(0.6, 0.6, 0.6)],
		["PlantN", [-14, 22, 10, 0.3], 0, ROOM_H, "brick", WALL], ["PlantE", [-4.3, 22.3, 0.3, 8.4], 0, ROOM_H, "brick", WALL],
		["PlantSHigh", [-14, 30.7, 10, 0.3], 4.3, ROOM_H, "brick", WALL], ["PlantRoof", [-14, 22, 10, 9], ROOM_H, ROOM_H + 0.3, "metal", Color(0.6, 0.6, 0.6)],
		["Mezzanine", [-14, 22.3, 5, 2.7], GALLERY - 0.2, GALLERY, "metal", Color(0.75, 0.75, 0.7)],
		["MezzRailS", [-11.5, 24.8, 2.5, 0.2], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],  # open over the stair
		["MezzRailE1", [-9.2, 22.3, 0.2, 0.7], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],
		["MezzRailE2", [-9.2, 24.2, 0.2, 0.8], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],
	],
	ramps = [{name = "PlantStair", rect = [-14, 25, 2.5, 4.6], h0 = 0.0, h1 = GALLERY, up = "N", mat = "metal", tint = Color(0.6, 0.6, 0.6)}],
	rooms = [["Corridor", [-14, 30.7, 16, 2.6], 0, 4], ["PlantRoom", [-14, 22, 10, 9], 0, ROOM_H]],
	exits = {RoomDoor = [-15, 32, 0]},
	dress = [
		["ceiling_lamp", [-4, 32, 3.8], 0], ["ceiling_lamp", [-10, 32, 3.8], 0],
		["pipe_riser", [-4.9, 28, 0], 270],
		["ceiling_lamp", [-7, 31.4, 3.8], 0], ["ceiling_lamp", [-11, 27.5, 7.2], 0],  # `lit`: the plant room's door and the stair
		# the plant room: a generator and drums, clear of the stair (x -14 to -11.5) and the door (x -8 to -6)
		["generator", [-6.5, 26.5, 0], 90], ["drum", [-5.2, 23, 0], 0], ["drum", [-5.3, 24, 0], 30],
		["pump", [-9.5, 22.65, 0], 180], ["pump", [-7.0, 22.65, 0], 180],
	],
	lit = [[-7, 31.4], [-11, 27.5]],  # ceiling lamps of `dress` that glow green (LIT_COLOUR), the way to the stair (playtest 4)
	markings = [
		[[-14, 31.95, 16, 0.1], 1.0],  # down the corridor's middle
		[[-7.1, 28.9, 0.2, 3.4], 0, 0.0, Color(0.4, 1.0, 0.5)], [[-11.5, 28.8, 4.6, 0.2], 0, 0.0, Color(0.4, 1.0, 0.5)],  # the green guide to the stair
	],
	spots = {RoadEntry = [-2, 32, 0], PlantStair = [-12.5, 26.5, 2]},  # PlantStair is where PlantCue turns the camera
	areas = [["PlantCue", [-7, 32, 1.5], Vector3(2, 3, 2.6), "res://areas/core/plant_cue.gd"]],
	doorways = [{at = [-7, 30.85], along_x = true, t = 0.3, wall_h = 4.0, width = 2.0, out = 1.0, style = "door", mat = "brick", tint = Color(0.7, 0.72, 0.75)}],
	trim = [
		# the lift door's frame, both faces, and the plate over it up to the cut's lintel (LiftDoor itself is build_core.gd's)
		["LiftJambN", [1.0, 30.7, 0.15, 0.3], 0.0, 3.3, "hazard"], ["LiftJambS", [1.0, 33.0, 0.15, 0.3], 0.0, 3.3, "hazard"],
		["LiftHead", [1.0, 30.7, 0.15, 2.6], 3.0, 3.3, "hazard"], ["LiftPlate", [0.5, 30.7, 0.5, 2.6], 3.3, 4.3, "metal", HAZ_DARK],
		["LiftJambNW", [0.35, 30.7, 0.15, 0.3], 0.0, 3.3, "hazard"], ["LiftJambSW", [0.35, 33.0, 0.15, 0.3], 0.0, 3.3, "hazard"],
		# the tunnel: a cable tray along its south wall, a pipe along the north
		["CableTray", [-13.8, 32.85, 15.6, 0.15], 3.1, 3.16, "metal", Color(0.55, 0.57, 0.6)], ["Cables", [-13.8, 32.88, 15.6, 0.1], 3.16, 3.22, "metal", Color(0.2, 0.2, 0.22)],
		["TunnelPipe", [-13.8, 31.0, 15.6, 0.2], 3.55, 3.75, "rust", PIPE],
		["CoreSignHangN", [-12.52, 31.6, 0.04, 0.04], 3.75, 4.0, "metal", HAZ_DARK], ["CoreSignHangS", [-12.52, 32.4, 0.04, 0.04], 3.75, 4.0, "metal", HAZ_DARK],
		# the plant room's pipework, along the north and east walls
		["PlantPipeN", [-9.5, 22.3, 5.2, 0.25], 2.3, 2.55, "rust", PIPE], ["PlantPipeE", [-4.55, 22.3, 0.25, 8.4], 2.3, 2.55, "rust", PIPE],
	],
	signs = [
		["sign.core_access", [2.03, 32, 4.85], 90, 2.6, "red", 0.5], ["sign.plant_room", [-7, 31.03, 3.05], 180, 1.8, "white", 0.3],
		["sign.core", [-12.5, 32, 3.55], 90, 1.6, "red", 0.4],
	],
	props = [["keypad", [1.6, 33.28, 1.3], 180], ["valve_wheel", [-4.39, 25.5, 1.4], 270], ["valve_wheel", [-4.39, 27.0, 1.4], 270]],
	reach = {Corridor = [-6, 32, 0], PlantDoor = [-7, 30, 0], PlantStair = [-12.75, 30.1, 0], Mezzanine = [-12, 23.5, GALLERY]},
}
