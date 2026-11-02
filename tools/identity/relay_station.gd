## The Relay station's identity (tools/area_identity.gd, read by tools/build_relay_station.gd): the garage as a
## working motor-pool garage, its vehicle keys on the east wall by the Hold-up's guard; the mess as a canteen; the
## relay console as a radio bay wired to the mast; a sign on every building. The builder's DRESS keeps what was there.
## Diagram metres; dress is [model, [x, y, h], facing, scale] (solid from 0.6 m tall), props are mesh-only.
extends RefCounted

const HAZARD := Color(0.9, 0.72, 0.1)
const CABLE := Color(0.08, 0.08, 0.08)

const D := {
	dress = [
		# garage: the workbench under its tool wall, metal racking, tyres in the corner, the engine hoist by the van
		["workbench", [55.2, 62.78, 0], 180], ["shelving", [51.6, 62.58, 0], 180],
		["tyre_stack", [56.9, 71.25, 0], 0], ["tyre_stack", [56.1, 71.3, 0], 40], ["tyre_stack", [57.2, 70.45, 0], 15],
		["engine_hoist", [53.5, 70.6, 0], 270],
		# mess: a kitchen counter on the north wall, a second table and chairs on the south side
		["counter", [58.6, 38.65, 3], 180], ["table", [61, 44.3, 3], 0], ["chair", [61, 43.2, 3], 0],
		["chair", [56, 45.2, 3], 180], ["chair", [61, 45.2, 3], 180],
		# the relay console: radio racks beside the desk
		["radio_rack", [41.65, 17.82, 6], 180], ["radio_rack", [42.27, 17.82, 6], 180],
		# the fuel hut's pump, facing the yard
		["fuel_pump", [63.6, 73.4, 0], 270],
		# OFFICE pack and 3D Retro World: the garage's bin, a water cooler in the mess, and the summit office's second desk
		# against the south wall (its chair north of it), archive cabinets and a cooler on the east wall
		["trash_can", [44.8, 71.4, 0], 0], ["water_cooler", [62.1, 38.75, 3], 180],
		["office_desk", [59.0, 17.2, 6], 0], ["office_chair", [59.0, 15.9, 6], 180],
		["file_cabinet_big", [63.4, 13.0, 6], 270], ["file_cabinet_big", [63.4, 14.6, 6], 270], ["water_cooler", [63.3, 16.9, 6], 270],
	],
	props = [
		["tool_board", [55.2, 62.34, 1.15], 180], ["car_battery", [51.2, 62.65, 0.62], 180], ["jerrycan", [52.1, 62.6, 0.62], 180],
		["key_cabinet", [57.3, 64.8, 1.1], 270, 1.6], ["notice_board", [57.68, 69.5, 1.1], 270],
		# the mess's kitchen: a camp burner and pan on the counter, an ice box beside it, a thermos and mugs on the table
		["camp_cooker", [58.2, 38.65, 3.9], 0], ["camp_pan", [59.1, 38.65, 3.9], 20], ["ice_box", [60.5, 38.8, 3.0], 0],
		["thermal_bottle", [56.3, 44.2, 3.96], 0], ["mug", [61.3, 44.3, 3.96], 0], ["mug", [55.8, 44.5, 3.96], 120],
		["fire_extinguisher", [45.3, 62.35, 1.1], 180],  # the garage's, on its north wall
		# the summit office's second desk (top 0.89 m)
		["office_monitor", [59.1, 17.3, 6.89], 0], ["office_keyboard", [59.1, 16.75, 6.89], 0], ["office_mouse", [59.8, 16.75, 6.89], 0],
		["desk_lamp", [58.2, 17.4, 6.89], 0], ["mug", [60.0, 17.5, 6.89], 0], ["paper_stack", [57.9, 16.9, 6.89], 10],
		["wall_clock", [58.6, 38.32, 5.0], 0], ["notice_board", [63.68, 42, 4.2], 270], ["wall_clock", [57, 8.33, 8.4], 0],
	],
	trim = [
		# cables from the radio racks along the floor to the mast, and up its south face
		["CableRack", [41.5, 15.4, 0.3, 2.1], 6.0, 6.06, "metal", CABLE], ["CableRun", [39.6, 15.4, 2.2, 0.3], 6.0, 6.06, "metal", CABLE],
		["CableMast", [39.6, 14.0, 0.3, 1.6], 6.0, 6.06, "metal", CABLE], ["CableRiser", [39.6, 13.95, 0.3, 0.12], 6.0, 9.5, "metal", CABLE],
	],
	signs = [
		["sign.garage", [43.97, 67, 4.65], 270, 3.6, "blue", 0.6], ["sign.no_smoking", [58.03, 70, 1.8], 90, 1.4, "red", 0.3],
		["sign.keys", [57.68, 64.8, 2.25], 270, 1.4, "hazard", 0.3],
		["sign.fuel", [69, 65.97, 2.2], 0, 1.8, "hazard", 0.45], ["sign.no_smoking", [65.97, 71.0, 1.6], 270, 1.4, "red", 0.3],
		["sign.mess", [58, 46.03, 6.2], 180, 2.4, "white", 0.45], ["sign.office", [52, 18.03, 9.25], 180, 2.2, "white", 0.45],
		["sign.relay", [37, 14.03, 9.6], 180, 4.0, "blue", 0.7], ["sign.high_voltage", [37, 14.03, 8.5], 180, 3.2, "hazard", 0.45],
		["sign.barracks", [24.6, 50.03, 6.2], 180, 2.6, "white", 0.5],
	],
	markings = [
		# the van's service bay, outlined on the garage floor
		[[45.0, 68.4, 7.1, 0.2], 0, 0, HAZARD], [[45.0, 68.4, 0.2, 3.3], 0, 0, HAZARD], [[51.9, 68.4, 0.2, 3.3], 0, 0, HAZARD],
		[[56.9, 66, 0.6, 2], 0.25, 0, HAZARD],  # the east door's threshold, where the Hold-up comes in
	],
	# past the rails, mesh-only (build_relay_station.gd _surroundings), standing on the hillside at [x, y]: a valley outpost
	# south of the motor pool with its sodium lamps, masts on the north ridge, a hut up the west slope
	backdrop = [
		["shed", [10, 128], 0, 1.4], ["shed", [26, 134], 90, 1.2], ["shed", [-6, 138], 0, 1.2], ["water_tower", [58, 124], 0, 6.0],
		["tank_wide", [-18, 126], 0, 0.8], ["van", [16, 130], 30], ["lattice_mast", [68, 140], 0, 1.6],
		["lamp_post", [18, 122], 0], ["lamp_post", [34, 130], 0], ["lamp_post", [2, 132], 180],
		["jersey_barrier", [14, 124], 0], ["jersey_barrier", [18, 124], 0], ["pallet_stack", [22, 128], 20], ["drum", [24, 130], 0],
		["lattice_mast", [-45, -30], 0, 2.0], ["lattice_mast", [75, -34], 0, 1.6], ["sat_dish", [-20, -22], 330, 1.5],
		["shed", [-40, 30], 90, 1.0],
	],
	beacons = [
		[[37, 11, 34.4], Color(1, 0.1, 0.05), 10.0, -1],  # the aircraft warning lamp on the antenna
		[[40.2, 18.55, 7.2], Color(0.3, 1, 0.45), 4.0, -1], [[41.9, 18.2, 6.1], Color(0.3, 1, 0.45), 3.0, -1],  # the console's status lamps
		[[57.6, 64.8, 2.6], Color(1, 0.8, 0.4), 3.5, -1],  # a bulb over the key cabinet
		[[5.2, 10.2, 6.1], Color(0.3, 1, 0.45), 3.0, -1], [[12.8, 10.2, 6.1], Color(0.3, 1, 0.45), 3.0, -1],  # the helipad's corners
		[[5.2, 17.8, 6.1], Color(0.3, 1, 0.45), 3.0, -1], [[12.8, 17.8, 6.1], Color(0.3, 1, 0.45), 3.0, -1],
	],
}
