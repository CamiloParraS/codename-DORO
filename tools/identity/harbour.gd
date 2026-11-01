## The Harbour's identity (tools/area_identity.gd, read by tools/build_harbour.gd and so by tools/build_core.gd, which
## stands on the same ground): the Operations building's inner doors, the freight lift as a lift (a platform, guide
## rails, a striped header, its sign), the lift panel's sign, the warehouses' shutters and lettering, the smoke break
## and the Foreman's manifest board, a raised boom at the road gate. Diagram metres; dress is [model, [x, y, h],
## facing, scale] (solid from 0.6 m tall), props are mesh-only.
extends RefCounted

const DECK := 2.0
const DARK := Color(0.28, 0.29, 0.31)
const SHUTTER := Color(0.7, 0.75, 0.8)

const D := {
	# the Operations building's inner doorways (its walls are SOLID boxes in build_harbour.gd): the lobby's two doors,
	# the control room and the locker room off the lift hall
	doorways = [
		{at = [20.5, 29.5], along_x = true, out = -1.0, t = 0.3, wall_h = 4.0, width = 2.0, mat = "panels", tint = Color.WHITE},
		{at = [20.5, 34.5], along_x = true, out = 1.0, t = 0.3, wall_h = 4.0, width = 2.0, mat = "panels", tint = Color.WHITE},
		{at = [17.0, 23.0], along_x = false, out = -1.0, t = 0.3, wall_h = 4.0, width = 2.0, mat = "panels", tint = Color.WHITE},
		{at = [17.0, 39.5], along_x = false, out = -1.0, t = 0.3, wall_h = 4.0, width = 2.0, mat = "panels", tint = Color.WHITE},
	],
	dress = [["boom_gate", [35, 1.0, 0], 270]],  # the road gate's boom, raised
	# past the fence, mesh-only (build_harbour.gd _surroundings): the bay's traffic, the far shore's yards, the clifftop town.
	# A crane's boom is a second model at the tower's top, 10.5 m (half its 21 m length at scale 3) out toward the water.
	backdrop = [
		# a freighter at anchor east of the channel and a barge off the breakwater (bow north, bridge aft)
		["freighter_hull", [109, 70, -3.2], 0, Vector3(1.0, 1, 0.8)], ["freighter_bridge", [109, 89, 1.8], 0, 1.0],
		["freighter_hull", [113, -12, -3.2], 0, Vector3(0.7, 0.7, 0.5)],
		["buoy_green", [104, 12, -2.2], 0], ["buoy_red", [88, 40, -2.2], 0], ["buoy_green", [76, 100, -2.2], 0],
		["buoy_red", [70, 112, -2.2], 0],
		# the far shore's cranes over the water and its container yard
		["crane_tower", [124, 100, 1], 0, 3.0], ["crane_boom", [113.5, 100, 25], 180, 3.0],
		["crane_tower", [20, 124, 1], 0, 3.0], ["crane_boom", [20, 113.5, 25], 270, 3.0],
		["container_a", [127, 50, 1], 0, 7.4, "cargo", Color(0.75, 0.55, 0.45)], ["container_b", [130, 50, 1], 0, 7.4, "cargo", Color(0.55, 0.65, 0.75)],
		["container_b", [127, 50, 3.6], 0, 7.4, "cargo", Color(0.6, 0.6, 0.6)], ["container_a", [133, 50, 1], 0, 7.4, "cargo", Color.WHITE],
		["container_a", [127, 58, 1], 0, 7.4, "cargo", Color(0.55, 0.65, 0.75)], ["container_a", [130, 58, 1], 0, 7.4, "cargo", Color(0.75, 0.55, 0.45)],
		["container_b", [130, 58, 3.6], 0, 7.4, "cargo", Color(0.6, 0.6, 0.6)], ["container_b", [136, 58, 1], 0, 7.4, "cargo", Color(0.7, 0.7, 0.4)],
		["container_a", [127, 108, 1], 0, 7.4, "cargo", Color(0.6, 0.6, 0.6)], ["container_b", [130, 108, 1], 0, 7.4, "cargo", Color(0.75, 0.55, 0.45)],
		["container_a", [130, 108, 3.6], 0, 7.4, "cargo", Color(0.55, 0.65, 0.75)], ["container_b", [133, 108, 1], 0, 7.4, "cargo", Color.WHITE],
		["lamp_post", [122.5, 34, 1], 90], ["lamp_post", [122.5, 80, 1], 90], ["lamp_post", [50, 122.5, 1], 0],
		# the clifftop town: street lamps along the road above the edge, sheds and a water tower at the north and south ends
		["lamp_post", [-9, -60, 14], 270], ["lamp_post", [-9, -20, 14], 270], ["lamp_post", [-9, 22, 14], 270], ["lamp_post", [-9, 70, 14], 270],
		["shed", [-14, -42, 14], 90, 1.3], ["shed", [-15, -72, 14], 90, 1.1], ["shed", [-14, 84, 14], 90, 1.3], ["van", [-8, -44, 14], 100],
		["water_tower", [-18, 90, 14], 0, 6.0], ["chimney", [-24, 106, 14], 0, 1.8], ["block_hall", [-20, 100, 14], 0, 0.9],
		# hills behind the far shore, grey in the fog
		["mountain_a", [185, 30, 0.5], 200, 0.8], ["mountain_b", [180, 125, 0.5], 150, 0.7], ["mountain_a", [40, 190, 0.5], 80, 0.8],
	],
	props = [
		["bucket", [77.4, 59.3, DECK], 0], ["ashtray", [77.4, 59.3, DECK + 0.52], 0],  # the smoke break's sand bucket
		["life_ring", [76.4, 55.7, DECK + 1.3], 180],
		["notice_board", [41.02, 59.5, 1.0], 90], ["crate_small", [76.6, 58.9, DECK], 20],  # the smokers' stool  # the Foreman's manifest, on the container at the end of his lane
		["call_button", [13.0, 37.48, 1.2], 0],
	],
	trim = [
		# the freight lift: its platform, striped edge and header over the mouth, guide rails in the corners
		["LiftPlatform", [6.5, 28, 6.5, 8], 0.0, 0.06, "deck_plate", Color(0.8, 0.82, 0.85)],
		["LiftEdge", [12.6, 28, 0.4, 8], 0.06, 0.07, "hazard"],
		["LiftHeader", [13.6, 26.5, 0.4, 11], 5.2, 5.8, "hazard"],
		["LiftRailN", [13.45, 26.5, 0.3, 0.3], 0.0, 6.0, "metal", DARK], ["LiftRailS", [13.45, 37.2, 0.3, 0.3], 0.0, 6.0, "metal", DARK],
		# Warehouse A's bay shutter, down, on the forecourt side; Warehouse B's on the lanes
		["WhAShutter", [16.6, 47.9, 4.2, 0.1], 0.0, 3.6, "corrugated", SHUTTER], ["WhADrum", [16.4, 47.55, 4.6, 0.4], 3.6, 4.1, "metal", DARK],
		["WhAJambW", [16.3, 47.85, 0.3, 0.15], 0.0, 3.6, "hazard"], ["WhAJambE", [20.8, 47.85, 0.3, 0.15], 0.0, 3.6, "hazard"],
		["WhBShutter", [40.0, 33.6, 0.1, 3.8], 0.0, 3.6, "corrugated", SHUTTER], ["WhBDrum", [40.0, 33.4, 0.4, 4.2], 3.6, 4.1, "metal", DARK],
		["WhBJambN", [39.95, 33.3, 0.15, 0.3], 0.0, 3.6, "hazard"], ["WhBJambS", [39.95, 37.4, 0.15, 0.3], 0.0, 3.6, "hazard"],
	],
	markings = [[[41.2, 57.6, 2.6, 0.25], 0.3]],  # lane W's end, where the Foreman turns his back
	# the lift panel's lamp, a second light at the slipway's tip
	beacons = [[[22.6, 20.45, 2.4], Color(0.3, 1, 0.45), 3.0, -1], [[7.1, 77.1, 2.2], Color(1, 0.15, 0.1), 5.0, 0.5]],
	signs = [
		["sign.operations", [23.03, 35.5, 3.15], 90, 2.6, "white", 0.45], ["sign.lift_control", [21.95, 20.33, 2.35], 180, 1.5, "hazard", 0.3],
		["sign.freight_lift", [2.03, 35.4, 3.4], 90, 3.2, "dark", 0.8], ["sign.gatehouse", [42, 14.03, 3.3], 180, 1.6, "white", 0.35],
		["sign.warehouse_a", [9.5, 47.97, 4.2], 0, 3.4, "dark", 0.7], ["sign.warehouse_b", [40.03, 35.5, 4.6], 90, 3.0, "dark", 0.6],
	],
}
