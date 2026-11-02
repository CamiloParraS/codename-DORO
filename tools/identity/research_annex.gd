## The Research annex's identity (tools/area_identity.gd, read by tools/build_research_annex.gd): a clinical lab
## (white panel walls and tiled floors, fume hoods, lab benches, gas, a specimen fridge), a clean room behind PVC
## strip curtains, a vault with a round door swung open and deposit boxes, an archive of filing cabinets, and
## the quarry it stands over (mine carts, a conveyor, blasting kit). The builder's DRESS keeps what was there.
## Diagram metres; dress is [model, [x, y, h], facing, scale] (solid from 0.6 m tall), props are mesh-only.
extends RefCounted

const STEEL := Color(0.5, 0.52, 0.55)
const PLINTH := Color(0.85, 0.87, 0.9)

const D := {
	dress = [
		# the lab: fume hoods on the north wall, benches and the fridge on the south, gas by the west door
		["fume_hood", [11.0, 31.62, 0], 180], ["fume_hood", [19.0, 31.62, 0], 180],
		["lab_bench", [13.0, 40.4, 0], 0], ["lab_bench", [26.5, 40.4, 0], 0], ["specimen_fridge", [28.95, 40.42, 0], 0],
		["gas_cylinders", [9.38, 32.6, 0], 90], ["biohazard_bin", [10.0, 40.3, 0], 0],
		# the clean room: an isolator on the south wall, a fridge by the north door; strip curtains in its three doorways
		["glovebox", [32.6, 40.38, 0], 0], ["specimen_fridge", [38.9, 31.6, 0], 180],
		["strip_curtain", [30, 34.5, 0], 90, Vector3(1.5, 1, 1)], ["strip_curtain", [32, 31, 0], 0], ["strip_curtain", [36, 41, 0], 0],
		# the vault: its round door swung in against the north wall, deposit boxes on the south
		["vault_door", [49.5, 31.64, 0], 180], ["deposit_boxes", [46.5, 40.37, 0], 0], ["deposit_boxes", [49.6, 40.37, 0], 0],
		# the archive: filing cabinets either side of its north door, racking on the south and west walls
		["filing_cabinet", [25.3, 44.71, 0], 180], ["filing_cabinet", [25.8, 44.71, 0], 180], ["filing_cabinet", [26.3, 44.71, 0], 180],
		["filing_cabinet", [26.8, 44.71, 0], 180], ["filing_cabinet", [27.3, 44.71, 0], 180], ["filing_cabinet", [27.8, 44.71, 0], 180],
		["filing_cabinet", [28.3, 44.71, 0], 180], ["filing_cabinet", [33.6, 44.71, 0], 180], ["filing_cabinet", [34.1, 44.71, 0], 180],
		["filing_cabinet", [34.6, 44.71, 0], 180], ["filing_cabinet", [35.1, 44.71, 0], 180], ["filing_cabinet", [35.6, 44.71, 0], 180],
		["filing_cabinet", [36.1, 44.71, 0], 180],
		["shelving", [35.2, 53.43, 0], 0], ["shelving", [37.2, 53.43, 0], 0], ["shelving", [24.47, 48.0, 0], 90],
		# the office's files
		["filing_cabinet", [27.6, 18.81, 0], 180], ["filing_cabinet", [28.1, 18.81, 0], 180],
	],
	props = [
		["microscope", [17.2, 38.1, 1.0], 0], ["whiteboard", [29.75, 38.6, 1.0], 270], ["keypad", [45.3, 30.78, 1.3], 180],
		["whiteboard", [18.25, 23, 1.0], 90], ["notice_board", [6.32, 50.5, 1.2], 90],
		["tnt", [64.2, 29.3, 0], 90], ["tnt", [64.5, 29.4, 0], 70], ["detonator", [65.3, 29.3, 0], 180], ["lantern", [62.1, 29.5, 1.0], 0],
		["lantern", [72, 29.9, 1.0], 0], ["pickaxe", [66.2, 29.5, 0], 0],  # blasting kit by the quarry rim
		["cardboard_box", [35.0, 53.43, 0.95], 0], ["cardboard_box", [37.4, 53.43, 0.3], 10], ["cardboard_box", [24.47, 47.6, 0.95], 90],
	],
	trim = [
		["LabFloor", [6.3, 18.3, 49.4, 35.4], 0.0, 0.015, "concrete", Color(0.95, 0.97, 0.98)],
		["CleanFloor", [30.2, 31.2, 9.6, 9.6], 0.015, 0.025, "concrete", Color(1.4, 1.42, 1.45)],
		# what the walk-in steps stand on: the vault's plinth, the archive's trolley
		["VaultPlinth", [46.65, 35.7, 0.7, 0.6], 0.0, 0.45, "metal", PLINTH], ["VaultPlinthBand", [46.65, 35.7, 0.7, 0.6], 0.45, 0.55, "hazard"],
		["FilesTrolley", [26.65, 49.7, 0.7, 0.6], 0.0, 0.45, "metal", PLINTH], ["FilesTrolleyBand", [26.65, 49.7, 0.7, 0.6], 0.45, 0.55, "hazard"],
		["BlastSignPost", [68.95, 29.6, 0.1, 0.1], 1.0, 1.1, "metal", STEEL],
	],
	signs = [
		["sign.annex", [14, 54.03, 3.42], 180, 6.4, "white", 0.6],
		["sign.lab", [15, 30.77, 3.05], 0, 1.6, "blue", 0.35], ["sign.lab", [23, 41.23, 3.05], 180, 1.6, "blue", 0.35],
		["sign.clean_room", [32, 30.77, 3.05], 0, 1.8, "green", 0.35], ["sign.clean_room", [36, 41.23, 3.05], 180, 1.8, "green", 0.35],
		["sign.vault", [47, 30.77, 3.05], 0, 1.6, "red", 0.35], ["sign.authorised", [43.6, 30.77, 1.75], 0, 2.2, "hazard", 0.35],
		["sign.lockers", [13, 28.23, 3.05], 180, 1.4, "white", 0.3], ["sign.office", [25, 28.23, 3.05], 180, 1.4, "white", 0.3],
		["sign.server", [38, 28.23, 3.05], 180, 1.6, "white", 0.3], ["sign.security", [51, 28.23, 3.05], 180, 1.6, "white", 0.3],
		["sign.reception", [11, 43.77, 3.05], 0, 1.6, "white", 0.3], ["sign.archive", [31, 43.77, 3.05], 0, 1.4, "white", 0.3],
		["sign.loading", [47, 43.77, 3.05], 0, 1.8, "white", 0.3], ["sign.loading", [56.03, 52.2, 2.0], 90, 1.8, "hazard", 0.4],
		["sign.blasting", [69, 29.77, 1.35], 0, 2.6, "hazard", 0.5],
	],
	# warm lamps over the vault's and the Archive's steps, a red lamp over the clean room's airlock
	beacons = [[[47, 36, 2.6], Color(1, 0.85, 0.5), 4.0, -1], [[27, 50, 2.6], Color(1, 0.85, 0.5), 4.0, -1], [[32, 30.6, 3.4], Color(1, 0.15, 0.1), 3.0, -1]],
	# the quarry floor (Backdrop, no colliders): [model, [x, y], facing, scale], standing on the pit's ground
	backdrop = [
		["mine_cart", [70, 40], 90], ["mine_cart", [72.2, 40.6], 80], ["conveyor", [78, 50], 0], ["gravel", [74, 43], 0, 2.0],
		["tnt", [67.5, 36.5], 0], ["tnt", [67.8, 36.8], 30], ["detonator", [66.8, 35.8], 45], ["bucket", [71, 38], 0],
		# a working quarry: a crane (the boom, a third element of h above the ground, hangs off the tower toward the pit's middle),
		# a crusher belt, a generator and a shed for the site office, barriers round the haul road, lamps on the floor
		["crane_tower", [100, 38], 0, 2.0], ["crane_boom", [93, 38, 16], 180, 2.0], ["shed", [76, 94], 0, 1.2],
		["conveyor", [102, 80], 90], ["conveyor", [98, 92], 0], ["generator", [86, 40], 0], ["gas_cylinders", [88.6, 40.6], 20],
		["engine_hoist", [84, 66], 250], ["sandbags", [66, 54], 0], ["jersey_barrier", [88, 76], 0], ["jersey_barrier", [92, 76], 0],
		["pipe_arch", [80, 90], 90], ["drum", [100, 45], 0], ["drum", [101, 46], 20], ["pallet_stack", [96, 50], 30],
		["mine_cart", [90, 86], 20], ["pickaxe", [72, 58], 50], ["shovel", [72.8, 58.4], 10], ["lamp_post", [88, 48], 90], ["lamp_post", [78, 88], 0],
		["mound", [100, 92], 20, 2.2, "ground", Color(0.75, 0.72, 0.68)], ["van", [70, 92], 200],
		# out on the plain: a works to the west, tanks and a stack to the south, a mast and dish on the rim, a container yard
		["block_long", [-70, 12], 90, 1.2], ["block_hall", [-60, -30], 0], ["tank_wide", [-45, 72], 0], ["block_hall", [34, 112], 0, 1.1],
		["chimney", [10, 104], 0, 2.4], ["tank_tall", [70, 108], 0, 3.0], ["lattice_mast", [-30, 96], 0, 1.5], ["sat_dish", [98, -24], 20, 2.0],
		["shed", [100, 0], 0, 1.3], ["container_a", [20, 98], 0, 7.4, "cargo", Color(0.75, 0.55, 0.45)],
		["container_b", [23.2, 98], 0, 7.4, "cargo", Color(0.55, 0.65, 0.75)], ["container_a", [26.4, 98], 0, 7.4, "cargo", Color(0.6, 0.6, 0.6)],
		["container_b", [21.6, 98], 0, 7.4, "cargo", Color.WHITE],
	],
}
