## Builds areas/harbour/harbour.tscn, the Harbour as three connected Encounters (pw-feel issue 07, drawn in
## .scratch/pw-feel/prototypes/harbour-encounters.html on the Tanker berth outline of area-redesign issue 04),
## and bakes its navmesh. This file is the Harbour's source: change the data here and rebuild, don't
## hand-edit the scene. build_core.gd builds the Core on the same data.
##   godot --headless --path . --script tools/build_harbour.gd
## Data is in diagram metres (tools/area_builder.gd).
extends "res://tools/area_builder.gd"

const OUT := "res://areas/harbour/harbour.tscn"
const DECK := 2.0         # the freighter's deck height above the quay
const CONTAINER_H := 2.6
const KERB_H := 0.5       # no jump, so a kerb holds the Operative off the sea

## The three Encounters, one per objective step, joined safe → exposed → safe: [id, name, problem, rect,
## exit spot [x, y, h], next]. Guard posts carry their Encounter as `enc` meta. The north yard (gatehouse,
## road) belongs to none: it is where reinforcements come in and Targets run to.
const ENCOUNTERS := [
	[1, "Perimeter", "timing", [64.6, 3.2, 12.6, 57], [65.4, 46, DECK], 2],             # the freighter deck; exit down the gangway
	[2, "Loading yard", "positioning", [26, 19, 36, 47], [27, 39.3, 0], 3],          # container lanes; exit along Warehouse B's south wall
	[3, "Operations building", "manipulation", [2, 18, 24, 60], [11, 74, 0], 0],     # Ops round the lift mouth; exit to the slipway
]

## Walkable at quay height, top at 0: [rect, material].
const LAND := [
	[[2, 2, 60, 68], "quay"],     # the yard
	[[26, -6, 8, 8], "quay"],     # the road through the north fence
	[[48, 70, 8, 9], "pier"],     # south pier
	[[62, 60, 8, 7], "pier"],     # the pontoon under the stern pier
	[[7, 70, 8, 7], "pier"],      # the slipway behind Warehouse A, the Extraction point at its tip
]
## Solid boxes: [name, rect, h0, h1, material, tint].
const SOLID := [
	["Cliff", [-2, -6, 4, 82], -3, 14, "rock", Color(0.85, 0.85, 0.95)],
	["FenceW", [2, 1.8, 24, 0.4], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
	["FenceE", [34, 1.8, 28, 0.4], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
	["RoadSideW", [25.8, -6, 0.4, 7.8], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
	["RoadSideE", [33.8, -6, 0.4, 7.8], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
	["RoadBarrier", [26, -6.2, 8, 0.4], 0, 1.2, "metal", Color(0.9, 0.5, 0.2)],
	# kerbs along the sea
	["KerbE1", [61.7, 2, 0.3, 42.8], 0, KERB_H, "kerb", Color(0.85, 0.85, 0.8)],
	["KerbE2", [61.7, 47.2, 0.3, 12.8], 0, KERB_H, "kerb", Color(0.85, 0.85, 0.8)],
	["KerbE3", [61.7, 67, 0.3, 3], 0, KERB_H, "kerb", Color(0.85, 0.85, 0.8)],
	["KerbS1", [2, 69.7, 5, 0.3], 0, KERB_H, "kerb", Color(0.85, 0.85, 0.8)],
	["KerbS1b", [15, 69.7, 33, 0.3], 0, KERB_H, "kerb", Color(0.85, 0.85, 0.8)],
	["KerbS2", [56, 69.7, 6, 0.3], 0, KERB_H, "kerb", Color(0.85, 0.85, 0.8)],
	["KerbPierW", [47.7, 70, 0.3, 9.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbPierE", [56, 70, 0.3, 9.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbPierTip", [47.7, 79, 8.6, 0.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbPontoonS", [62, 66.7, 8, 0.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbPontoonE", [69.7, 60, 0.3, 7], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbSlipW", [6.7, 70, 0.3, 7.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbSlipE", [15, 70, 0.3, 7.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbSlipTip", [6.7, 77, 8.6, 0.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	# the freighter: hull to deck height, bow, rails with a gap for the gangway and the stern drop
	["Hull", [65, 11, 12, 49], -3, DECK, "deck", Color(0.7, 0.78, 0.95)],
	["Bow", [67.5, 5, 7, 6], -3, DECK, "deck", Color(0.7, 0.78, 0.95)],
	["BowTip", [69.5, 3.5, 3, 1.5], -3, DECK, "deck", Color(0.7, 0.78, 0.95)],
	["RailPort1", [65, 11, 0.2, 33.8], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailPort2", [65, 47.2, 0.2, 12.8], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailStarboard", [76.8, 11, 0.2, 49], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailBowW", [67.5, 3.5, 0.2, 7.5], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailBowE", [74.3, 3.5, 0.2, 7.5], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailBowFront", [67.5, 3.3, 7, 0.2], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailShoulderW", [65, 10.9, 2.5, 0.2], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailShoulderE", [74.5, 10.9, 2.5, 0.2], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailSternW", [65, 59.8, 3.6, 0.2], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["RailSternE", [69.6, 59.8, 7.4, 0.2], DECK, DECK + RAIL_H, "rust", Color(0.9, 0.4, 0.32)],
	["Bridge", [67, 48, 8, 8], DECK, DECK + 6, "superstructure", Color(0.9, 0.95, 1.0)],
	["DeckContainer1", [74, 20, 3, 7], DECK, DECK + CONTAINER_H, "metal", Color(0.3, 0.5, 0.8)],
	["DeckContainer2", [73, 30, 2.4, 8], DECK, DECK + CONTAINER_H, "metal", Color(0.8, 0.4, 0.2)],
	["DeckContainer3", [66.5, 36, 2.4, 6], DECK, DECK + CONTAINER_H, "metal", Color(0.3, 0.6, 0.35)],
	["HatchStarboard", [73, 12, 3, 7], DECK, DECK + LOW_H, "hatch_cover", Color(0.85, 0.9, 0.85)],
	["HatchPort", [68, 12, 2.5, 5], DECK, DECK + LOW_H, "hatch_cover", Color(0.85, 0.9, 0.85)],
	# the Loading yard: two columns of containers either side of a 3 m mid lane (x 47-50), with lane W
	# (x 41-44) beyond; the gaps in the columns are staggered so no cross lane runs straight through
	["Crane", [54, 18, 4, 4], 0, 8, "hatch", Color(1.0, 0.78, 0.2)],
	["CraneBoom", [58, 19.5, 7, 1], 7.5, 8, "hatch", Color(1.0, 0.78, 0.2)],
	["ResupplyCrate", [58.5, 49, 1, 1], 0, 1, "wood", Color(0.6, 0.9, 0.6)],
	["Container1", [44, 42, 3, 10], 0, CONTAINER_H, "metal", Color(0.75, 0.3, 0.25)],
	["Container2", [38, 56, 3, 8], 0, CONTAINER_H, "metal", Color(0.3, 0.5, 0.8)],
	["Container3", [44, 26, 3, 10], 0, CONTAINER_H, "metal", Color(0.3, 0.6, 0.35)],
	["Container4", [50, 32, 3, 8], 0, CONTAINER_H, "metal", Color(0.8, 0.4, 0.2)],
	["Container5", [50, 46, 3, 8], 0, CONTAINER_H, "metal", Color(0.3, 0.5, 0.8)],
	["Container6", [38, 44, 3, 8], 0, CONTAINER_H, "metal", Color(0.75, 0.3, 0.25)],
	# the freight lift, set into the cliff, mouth east (lined up over the Core: don't move it)
	["LiftWallN", [2, 26, 12, 0.5], 0, 6, "concrete", Color(0.75, 0.75, 0.75)],
	["LiftWallS", [2, 37.5, 12, 0.5], 0, 6, "concrete", Color(0.75, 0.75, 0.75)],
	["LiftRoof", [2, 26, 12, 12], 6, 6.5, "concrete", Color(0.75, 0.75, 0.75)],
	# the Operations building's inside: control room (north), lobby, locker room (south), and the lift hall
	# (x 14-17) along the lift mouth, joined to the control and locker rooms by doors at y 22-24 and 38.5-40.5
	["OpsWallN1", [17, 29.35, 2.5, 0.3], 0, 4, "panels", Color.WHITE],
	["OpsWallN2", [21.5, 29.35, 1.5, 0.3], 0, 4, "panels", Color.WHITE],
	["OpsWallS1", [17, 34.35, 2.5, 0.3], 0, 4, "panels", Color.WHITE],
	["OpsWallS2", [21.5, 34.35, 1.5, 0.3], 0, 4, "panels", Color.WHITE],
	["OpsWallW1", [16.85, 20, 0.3, 2], 0, 4, "panels", Color.WHITE],
	["OpsWallW2", [16.85, 24, 0.3, 5.5], 0, 4, "panels", Color.WHITE],
	["OpsWallW3", [16.85, 34.5, 0.3, 4], 0, 4, "panels", Color.WHITE],
	["OpsWallW4", [16.85, 40.5, 0.3, 1.5], 0, 4, "panels", Color.WHITE],
	["LiftPanel", [21.5, 20.3, 1.2, 0.6], 0, 1.2, "metal", Color.WHITE],
	# shuts the exit strip off from the yard: the way to the slipway is through Encounter 3
	["FenceExit", [24.3, 64, 0.4, 5.7], 0, 3, "metal", Color(0.6, 0.65, 0.6)],
]
## The crane is open lattice: its tower and boom sit on the guards' layer, which blocks bodies but not sight,
## shots or the camera. Only these parts block sight: [name, rect, h0, h1], the machinery base and the top plate.
const CRANE_SOLID := [["CraneBase", [54, 18, 4, 4], 0, 2.4], ["CranePlate", [54, 18, 4, 4], 7.7, 8]]
## Low cover: [rect, h0].
const LOW := [
	[[44, 22, 6, 1.2], 0], [[26, 45, 8, 1.2], 0], [[48, 14, 1.2, 6], 0], [[52, 56, 6, 1.2], 0],
	[[8, 43, 5, 1.2], 0],        # the forecourt, in front of the lift housing
	[[66, 21, 1.2, 3], DECK],    # deck crates by the port rail, halfway from the hatches to Container 3
]
## Enterable buildings: [name, rect, height, doors [[side, centre(, width)]], tint, base, wall material].
const BUILDINGS := [
	["Gatehouse", [36, 6, 12, 8], 4.0, [["W", 10.0], ["S", 42.0]], Color.WHITE, 0.0, "panels"],
	["WarehouseA", [6, 48, 18, 16], 5.0, [["E", 54.0], ["N", 14.0], ["S", 14.0]], Color(0.9, 0.9, 0.9), 0.0, "corrugated"],
	# its west side is open across the lift mouth (y 26.5-37.5)
	["Operations", [14, 20, 9, 22], 4.0, [["W", 32.0, 11.0], ["E", 32.0], ["N", 20.0], ["S", 20.0]], Color(0.85, 0.9, 1.0), 0.0, "panels"],
]
## Crawlspaces: a structure [name, rect, height, material, tint] with a 1.2 m tunnel through it along
## x = axis_x (N-S) or y = axis_y (E-W). Mouths get a carry block each.
const CRAWLSPACES := [
	{name = "StackCrawl", rect = [28, 51, 10, 5], h = CONTAINER_H, mat = "cargo", tint = Color.WHITE, axis_x = 33.0},
	{name = "WarehouseBCrawl", rect = [26, 28.5, 14, 10], h = 6.0, mat = "corrugated", tint = Color(0.8, 0.88, 1.0), axis_x = 33.0},
	{name = "SternPierCrawl", rect = [58.5, 60, 10, 7], h = 1.5, mat = "pier", tint = Color.WHITE, axis_y = 64.0},
]
## No Fulton under a roof: [name, rect, h0, h1]. Everything else, the deck and the roofs included, is open sky.
const ROOMS := [
	["Operations", [14, 20, 9, 22], 0, 4], ["LiftHousing", [2, 26, 12, 12], 0, 6], ["WarehouseA", [6, 48, 18, 16], 0, 5],
	["Gatehouse", [36, 6, 12, 8], 0, 4], ["StackCrawl", [28, 51, 10, 5], 0, 1.2], ["WarehouseBCrawl", [26, 28.5, 14, 10], 0, 1.2],
	["SternPierCrawl", [58.5, 60, 10, 7], 0, 1.2],
]
## Ladders: [name, bottom [x, y, h], top [x, y, h]]. The rungs run up the face at the bottom marker.
const LADDERS := [
	["LadderCrane", [56, 22.5, 0], [56, 20.5, 8]],
	["LadderWarehouseB", [40.5, 31, 0], [38.5, 31, 6]],
]
## The gangway: a ramp from the port rail gap down to the quay.
const GANGWAY := {top = [65, 46], bottom = [61, 46], width = 2.4}

## Guard posts: [name, [x, y, h], facing, meta, route [[x, y, meta]]]. Meta: hold / scan / chat, and
## role (gatekeeper, observer, patroller, interceptor, investigator), enc (Encounter), holdup (what a
## Hold-up gets out of him: text key holdup.<answer>; without it, his Voiceprint). 11 spawned: 5 / 3 / 3.
const GUARD_POSTS := [
	# E1 Perimeter: learn the rhythm. O2 keeps aft of y 42, out of sight of a Hold-up behind O1.
	["PostO1", [70, 25, DECK], 90, {hold = 5.0, role = "observer", enc = 1}, []],                          # look-out across the starboard hatches
	["PostO2", [70.5, 42, DECK], 180, {role = "patroller", enc = 1}, [[72, 47, {hold = 6.0, f = 180}]]],  # paces aft; chats 6 s at the bridge door
	["PostP", [73, 58, DECK], 0, {chat = "smoke", role = "investigator", enc = 1}, []],                         # smoke break behind the bridge: step 1
	["PostO5", [66.5, 45, DECK], 0, {scan = 120.0, role = "gatekeeper", enc = 1}, []],                      # gangway head, sweeps up the deck
	# E2 Loading yard: overlapping threats
	["PostY1", [58, 24, 0], 180, {role = "patroller", enc = 2}, [[58, 48, {hold = 4.0, f = 90}], [57, 59, {}]]],  # quay; holds facing the gangway foot
	["PostForeman", [48.5, 24, 0], 180, {role = "patroller", enc = 2, holdup = "lift_code"},                 # the lane loop: step 2
		[[48.5, 39, {hold = 3.0, f = 270}], [42.5, 39, {}], [42.5, 54, {hold = 3.0, f = 90}], [48.5, 54, {}]]],
	["PostObserver", [38.5, 38, 6], 150, {scan = 90.0, role = "observer", enc = 2}, []],                     # Warehouse B roof's south-east edge (from the middle the roof hides the ground)
	# E3 Operations: three guarded doors
	["PostGate", [20, 45, 0], 120, {scan = 60.0, role = "gatekeeper", enc = 3}, []],                          # south door, watches the yard's exit
	["PostAlley", [24.5, 44, 0], 0, {role = "interceptor", enc = 3}, [[24.5, 22, {hold = 3.0, f = 0}]]],     # the alley; holds facing the north door's approach
	["PostOps", [21.5, 23, 0], 0, {hold = 5.0, role = "investigator", enc = 3}, [[20.5, 32, {hold = 3.0, f = 90}]]],  # at the lift panel, then the lobby
]
## Order matters (harbour.gd): the first is Stealth L2's patrol, the rest are Combat L2's guards.
const EXTRA_POSTS := [
	["PostExtra1", [30, 44, 0], 0, {role = "patroller"}, [[33, 40, {hold = 3.0, f = 0}], [33, 57.5, {hold = 3.0, f = 0}]]],  # looks into both lane Crawlspaces
	["PostExtra2", [15.5, 31, 0], 90, {hold = 5.0, role = "interceptor"}, []],   # in the lift hall
	["PostExtra3", [59, 44, 0], 45, {hold = 5.0, role = "gatekeeper"}, []],      # at the gangway foot
]
const TARGET_POSTS := [  # ponytail: unused, the Core places its own director; kept for a Harbour Target
	["TargetPost1", [10, 30, 0], 180, {}, [[10, 35, {}]]],
]
const SENTRIES := [
	["SentryCrane", [56, 19.5, 8], 230, {scan = 90.0}],
	["SentryBridge", [71, 52, 8], 0, {scan = 90.0}],
]
## Camera mounts: [name, [x, y, h], facing, pole base h]. Without a pole base the mount is on a wall face.
const CAMERAS := [
	["CamGangway", [67, 47.95, 5], 340], ["CamLanes", [53.5, 25, 3], 194, 0.0],
	["CamOps", [22, 42.05, 3.6], 150], ["CamAlley", [25.95, 29, 5], 200],
]
## DeckEntry: reinforcements for an Operative nearer the deck come out of the bridge (harbour.gd).
const SPOTS := {
	OperativeStart = [71, 7, DECK], RoadEntry = [30, -2, 0], DeckEntry = [71, 46.6, DECK], Extraction = [11, 74, 0],
	ResupplyCrate = [59, 49.5, 1], FreightLift = [8, 32, 0], SafeRoom = [46, 7.5, 0],
}
const SPOOFS := {SpoofDock = [52, 72], SpoofWarehouse = [42, 40], SpoofGatehouse = [40, 16.5], SpoofForecourt = [14, 46]}
## Where to eavesdrop the smoke break: [x, y, h]. Within 6 m of the pair's B seat, the bridge corner hiding it from A.
const EAVESDROP := {EavesdropSpot = [75.9, 53, DECK]}
## Mission 1's steps (Campaign data names them), each done with a verb rather than a walk-in pickup
## (areas/intel_pickup.gd). watch (objective_watch.gd): a guard's Voiceprint or Hold-up answer; console (relay_console.gd): hold E.
const OBJECTIVES := {
	IntelSmokeBreak = {at = [75.9, 53, DECK], watch = "voiceprint", guards = ["GuardPA", "GuardPB"]},
	IntelForeman = {at = [48.5, 50, 0], watch = "answer", guards = ["GuardForeman"]},
	IntelLiftPanel = {at = [22, 22.2, 0], console = 4.0, prompt = "ui.prompt.enter_code"},
}
## Safe → exposed → safe crossings, as drawn and timed in the prototype: [id, Encounter, [[x, y, h]...]]. The build
## checks both ends are on the navmesh; the prototype's vision sim times them (.scratch/pw-feel/research/harbour-generator-data.md).
const CROSSINGS := [
	["X1", 1, [[67.2, 16.5, DECK], [66.6, 20.6, DECK]]], ["X2", 1, [[65.7, 24.4, DECK], [65.7, 35.6, DECK]]],
	["X3", 1, [[69.6, 41.6, DECK], [72, 45.4, DECK]]], ["X4", 1, [[76, 43, DECK], [75.9, 53, DECK]]],
	["X5", 1, [[65.4, 46, DECK], [53.6, 47.5, 0]]], ["X6", 1, [[66, 50, DECK], [69.1, 59.4, DECK]]],
	["X7", 2, [[53.6, 45.5, 0], [48.5, 43, 0]]], ["X8", 2, [[51, 57.5, 0], [48.5, 47, 0]]],
	["X9", 2, [[47.5, 37, 0], [27, 39.1, 0]]], ["X10", 3, [[26.5, 39.4, 0], [23.2, 32, 0]]],
	["X11", 3, [[31, 26.5, 0], [20, 19.6, 0]]], ["X12", 3, [[15.5, 34, 0], [21.2, 21.8, 0]]],
	["X13", 3, [[20, 42.6, 0], [11, 73, 0]]],
]

## Set dressing (tools/area_builder.gd _dress): [model, [x, y, h], facing, scale]. Kept off guard routes,
## doorways, Crawlspace mouths, lanes and Ladders.
const DRESS := [
	# quay: bollards on the edge, floodlights leaning over the yard
	["bollard", [61, 8, 0], 0], ["bollard", [61, 16, 0], 0], ["bollard", [61, 30, 0], 0],
	["bollard", [61, 42, 0], 0], ["bollard", [61, 52, 0], 0],
	["lamp_post", [61.2, 12, 0], 270], ["lamp_post", [61.2, 34, 0], 270], ["lamp_post", [61.2, 57, 0], 270],
	["lamp_post", [55.5, 78.5, 0], 270], ["lamp_post", [14.4, 76.5, 0], 270],  # the south pier, the slipway
	["lamp_post", [35, 3.5, 0], 225], ["lamp_post", [3.5, 44, 0], 90],
	# pier
	["crate_small", [49, 72, 0], 10], ["supply_crate", [49.2, 72.6, 0.36], 80], ["drum", [55, 71.5, 0], 0],
	# north-west corner, by the Operations building's north door
	["drum", [3.5, 3.5, 0], 0], ["drum", [4.4, 3.6, 0], 30], ["barrel_a", [3.7, 4.5, 0], 0],
	["tank_tall", [4.5, 14, 0], 0], ["generator", [16, 17, 0], 0], ["jerrycan", [14.5, 17.5, 0], 60],
	# road in: cones either side of the barrier lane
	["cone", [27, 0, 0], 0], ["cone", [33, 0, 0], 0], ["cone", [27, -3, 0], 0], ["cone", [33, -3, 0], 0],
	# the forecourt, by Warehouse A's north door
	["pallet_stack", [8.5, 45.5, 0], 0], ["barrel_b", [22.5, 46.5, 0], 0], ["barrel_a", [23.2, 47.1, 0], 40],
	["drum", [36.5, 58.5, 0], 0], ["drum", [37.2, 57.8, 0], 20],
	# Warehouse A inside: racking on the south wall (clear of the south door, x 13-15), stock, lights
	["crate_wide", [17.3, 63, 0], 0], ["crate_small", [17, 63, 0.67], 15], ["crate_wide", [19.3, 63, 0], 0],
	["pallet_stack", [21.5, 61.5, 0], 0], ["crate_wide", [8.5, 50.5, 0], 90],
	["cardboard_box", [20.5, 49, 0], 15], ["cardboard_box", [21.3, 49.2, 0], 40],
	["ceiling_lamp", [11, 56, 4.8], 0], ["ceiling_lamp", [19, 56, 4.8], 0],
	# gatehouse inside: the radio desk and a locker
	["table", [39, 7, 0], 0], ["monitor", [39, 7, 0.96], 0], ["chair", [39, 8.3, 0], 180],
	["locker", [36.7, 12.5, 0], 90], ["ceiling_lamp", [42, 10, 3.8], 0],
	["vent_unit", [40, 8, 4.3], 0],  # on the gatehouse roof
	# freighter deck
	["drum", [73, 6.5, DECK], 0], ["drum", [73.8, 7, DECK], 40],
	# the freight lift lit from inside, so the way down reads from the yard; sandbags at the road gate
	["ceiling_lamp", [7, 32, 5.9], 0], ["sandbags", [23.5, 5, 0], 0], ["pipe_arch", [3.6, 20, 0], 0],
	# the lift as a working freight bay (cabinets, generator, pipes, lamps over the mouth)
	["cabinet_b", [4, 26.9, 0], 0], ["cabinet_a", [5.5, 26.9, 0], 0], ["generator", [4.5, 36.7, 0], 180],
	["pipe_riser", [2.6, 29, 0], 270], ["ceiling_lamp", [11.5, 28, 5.9], 0], ["ceiling_lamp", [11.5, 36, 5.9], 0],
	# Warehouse A stock along the walls, the middle kept open
	["pallet_stack", [8, 62.5, 0], 0], ["supply_crate", [10.5, 62.8, 0], 0], ["cabinet_b", [6.6, 55, 0], 270],
	["cabinet_a", [6.6, 56.4, 0], 270], ["drum", [22.8, 58, 0], 0], ["drum", [23, 59, 0], 30],
	["barrel_b", [22.6, 60, 0], 0], ["vent_unit", [11, 63.4, 3], 180],
	# gatehouse: the guard room's screens, cabinets and a drinks machine
	["monitoring_screen", [42.5, 6.9, 0], 0], ["cabinet_a", [47.3, 12.5, 0], 90], ["cabinet_b", [47.3, 11, 0], 90],
	["vending_machine", [37.2, 7, 0], 0],
	# the Operations building: the control room's screens, the locker room's cabinets, lights
	["monitoring_screen", [19, 20.6, 0], 0], ["cabinet_a", [22.4, 28.5, 0], 270], ["cabinet_b", [22.4, 39, 0], 270],
	["cabinet_a", [22.4, 37.5, 0], 270], ["ceiling_lamp", [20, 25, 3.8], 0], ["ceiling_lamp", [20, 32, 3.8], 0],
	["ceiling_lamp", [20, 38, 3.8], 0], ["ceiling_lamp", [15.5, 31, 3.8], 0],
	# a parked van in the north-west corner
	["van", [10, 8, 0], 90],
	# deck: mast lights over the bow (the start) and the starboard walk
	["lamp_post", [68.2, 8, DECK], 90], ["lamp_post", [76.2, 41, DECK], 270],
]
## Seen over the cliff and across the water: no gameplay, far enough to sit in the fog.
const BACKDROP_DRESS := [
	["chimney", [-16, 10, 14], 0, 2.0], ["chimney", [-20, 52, 14], 0, 1.6], ["tank_tall", [-10, 18, 14], 0, 3.0],
	# the town on the clifftop
	["block_tall", [-14, 32, 14], 90, 1.4], ["block_wide", [-12, 64, 14], 90], ["block_hall", [-16, -12, 14], 0],
	# the far shore across the bay
	["block_long", [132, 30, 1], 270, 1.5], ["block_hall", [134, 80, 1], 270, 1.3], ["tank_wide", [118, 128, 1], 0],
	["block_wide", [70, 132, 1], 180, 1.4], ["tank_wide", [30, 130, 1], 0, 0.8], ["chimney", [128, 56, 1], 0, 2.4],
	["block_tall", [130, -10, 1], 270, 1.2], ["block_hall", [-10, 134, 1], 180]
]

## Worn yellow paint on the quay, no collision: [rect, dash length (0 = solid)]. Dashes run along the long side.
const MARKINGS := [
	[[26.5, -0.6, 7, 0.3], 0],      # stop line at the gate
	[[29.85, 3, 0.15, 24], 1.5],    # drive from the gate down to Warehouse B
	[[60.8, 3, 0.2, 56], 0],        # quay edge line
	[[57.5, 4, 0.15, 54], 2.0],     # quay lane
	[[48.4, 23.5, 0.15, 33], 1.5],  # the mid lane
]
## Small lights with a lamp you can see from afar: [[x, y, h], colour, range, pole base h or -1 for none].
const BEACONS := [
	[[14.9, 77.1, 2.2], Color(1, 0.15, 0.1), 7.0, 0.5],    # the slipway tip, the Extraction point
	[[55.9, 79.1, 2.2], Color(1, 0.15, 0.1), 5.0, 0.5],    # the south pier tip
	[[66.8, 49, 7.2], Color(1, 0.12, 0.1), 5.0, -1],        # port sidelight on the bridge
	[[75.2, 49, 7.2], Color(0.15, 1, 0.3), 5.0, -1],        # starboard sidelight
	[[71, 52, 10.5], Color(1, 0.95, 0.85), 6.0, 8.0],       # masthead light over the bridge roof
]


func _build() -> void:
	_root = Node3D.new()
	_root.name = "Harbour"
	_root.set_script(load("res://areas/harbour/harbour.gd"))

	var nav := _nav_region()
	var land := _group(nav, "Land")
	for l in LAND:
		_box(land, "Land%d" % land.get_child_count(), l[0], -1, 0, l[1], Color.WHITE)
	var solid := _group(nav, "Solid")
	for s in SOLID:
		_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	_crane_lattice(solid)
	_camera_poles(solid, CAMERAS)
	for l in LOW:
		_box(solid, "Low%d" % solid.get_child_count(), l[0], l[1], l[1] + LOW_H, "wood", Color(0.9, 0.8, 0.6))
	for b in BUILDINGS:
		_building(_group(solid, b[0]), b)
	_gangway(solid)
	_dress(nav, DRESS)
	var crawl := _group(nav, "Crawlspaces")
	for c in CRAWLSPACES:
		_crawlspace(_group(crawl, c.name), c)
	_bake(nav)
	var nm := nav.navigation_mesh

	var ladders := _group(_root, "Ladders")
	for l in LADDERS:
		_ladder(ladders, l)
	_backdrop()
	_dress(_root.get_node("Backdrop"), BACKDROP_DRESS)
	_markings()
	_beacons()
	_mood("harbour")

	var spots := _group(_root, "Spots")
	for n in SPOTS:
		_marker(spots, n, SPOTS[n], 180 if n == "OperativeStart" else 0, {}, "spot")
	var sentries := _group(_root, "SentryHighPoints")
	for s in SENTRIES:
		_marker(sentries, s[0], s[1], s[2], s[3], "sentry_high_point")
	var cams := _group(_root, "CameraMounts")
	for c in CAMERAS:
		_marker(cams, c[0], c[1], c[2], {}, "camera_mount")
	_posts("GuardPosts", GUARD_POSTS, "guard_post")
	_posts("TargetPosts", TARGET_POSTS, "target_post")
	_posts("ExtraGuardPosts", EXTRA_POSTS, "guard_post_extra")
	var spoofs := _group(_root, "SpoofPlaces")
	for n in SPOOFS:
		_marker(spoofs, n, SPOOFS[n] + [0], 0, {}, "spoof_place")
	var eavesdrops := _group(_root, "EavesdropSpots")
	for n in EAVESDROP:
		_marker(eavesdrops, n, EAVESDROP[n], 0, {}, "eavesdrop_spot")
	_rooms(ROOMS)

	_actors()
	var ep := _area(_root, "ExtractionPoint", SPOTS.Extraction, Vector3(4, 3, 4), "res://areas/extraction_point.gd")
	ep.position.y = 1.5
	_objectives()
	var sea := _area(_root, "Sea", [40, 40, -5.5], Vector3(160, 5, 160), "res://areas/sea.gd")
	sea.collision_mask = 1  # the Operative's layer
	_save(OUT)
	await _report_reach(nm, SPOTS.OperativeStart, _reach(), {})
	quit()


# --- Harbour-only builders ---------------------------------------------------------------------

## Mission 1's OBJECTIVES under $Intel, where MissionRun finds every step.
func _objectives() -> void:
	var intel := _group(_root, "Intel")
	for n in OBJECTIVES:
		var o: Dictionary = OBJECTIVES[n]
		var at := [o.at[0], o.at[1], o.at[2] + 1.5]
		if o.has("console"):
			var c := _area(intel, n, at, Vector3(3, 3, 3), "res://areas/relay_station/relay_console.gd")
			c.set("hold_time", o.console)
			c.set("prompt", o.prompt)
			c.set("sweeps", false)
		else:
			var w := _area(intel, n, at, Vector3(1, 1, 1), "res://areas/objective_watch.gd")
			w.set("verb", o.watch)
			w.set("guards", PackedStringArray(o.guards))


## What the navmesh must reach from the start: every objective, the Extraction point, both ends of every crossing.
func _reach() -> Dictionary:
	var r := {Extraction = SPOTS.Extraction, LiftPanel = [21.5, 22.2, 0], Eavesdrop = EAVESDROP.EavesdropSpot}
	for x in CROSSINGS:
		r[x[0] + "a"] = x[2][0]
		r[x[0] + "b"] = x[2][-1]
	return r


## The gangway: a sloped deck from the ship's port gap to the quay, with side rails.
func _gangway(parent: Node3D) -> void:
	var top := _p(GANGWAY.top + [DECK])
	var bottom := _p(GANGWAY.bottom + [0])
	var run := top - bottom
	var length := run.length()
	var basis := Basis(Vector3.BACK, atan2(run.y, run.x))  # tilt about z so +x climbs to the deck
	for part in [["Gangway", 0.0, 0.2, GANGWAY.width], ["GangwayRailN", -GANGWAY.width / 2, 2.0, 0.1], ["GangwayRailS", GANGWAY.width / 2, 2.0, 0.1]]:
		var b := StaticBody3D.new()
		b.name = part[0]
		b.set_meta("surface", "metal")
		var size := Vector3(length, part[2], part[3])
		b.transform = Transform3D(basis, (top + bottom) / 2 + Vector3(0, part[2] / 2 - 0.1, part[1]))
		var shape := CollisionShape3D.new()
		shape.name = "Shape"
		shape.shape = _box_shape(size)
		b.add_child(shape)
		var m := MeshInstance3D.new()
		m.name = "Mesh"
		m.mesh = _box_mesh(size, _mat("rust", Color(0.9, 0.4, 0.32)))
		b.add_child(m)
		parent.add_child(b)


## The sea plane under the Area and the ground the Backdrop blocks stand on.
func _backdrop() -> void:
	var bd := _group(_root, "Backdrop")
	bd.add_to_group("backdrop", true)
	var sea := MeshInstance3D.new()
	sea.name = "SeaPlane"
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.06, 0.1, 0.16)
	m.roughness = 0.15  # glassy, so the sodium lamps and the low sun glint on it
	m.metallic_specular = 0.7
	plane.material = m
	sea.mesh = plane
	sea.position = Vector3(0, -1.0, 0)
	_add(bd, sea)
	# ground under the backdrop blocks: the clifftop west and the far shore east and south (no collision)
	for g in [["Clifftop", [-60, -60, 58, 240], 13, 14, "rock"], ["FarShoreE", [120, -60, 80, 260], -2, 1, "quay"],
			["FarShoreS", [-60, 120, 180, 80], -2, 1, "quay"]]:
		var land := MeshInstance3D.new()
		land.name = g[0]
		var r: Array = g[1]
		land.mesh = _box_mesh(Vector3(r[2], g[3] - g[2], r[3]), _mat(g[4], Color(0.7, 0.7, 0.75)))
		land.position = Vector3(r[0] + r[2] / 2.0 - 40.0, (g[2] + g[3]) / 2.0, r[1] + r[3] / 2.0 - 40.0)
		_add(bd, land)


## Moves the crane's boxes to the guards' layer and adds the CRANE_SOLID parts: bodies with no mesh, the
## crane model already draws them.
func _crane_lattice(solid: Node3D) -> void:
	for n in ["Crane", "CraneBoom"]:
		(solid.get_node(n) as StaticBody3D).collision_layer = 2
	for c in CRANE_SOLID:
		var b := StaticBody3D.new()
		b.name = c[0]
		var r: Array = c[1]
		b.position = _p([r[0] + r[2] / 2.0, r[1] + r[3] / 2.0, (c[2] + c[3]) / 2.0])
		var shape := CollisionShape3D.new()
		shape.name = "Shape"
		shape.shape = _box_shape(Vector3(r[2], c[3] - c[2], r[3]))
		b.add_child(shape)
		solid.add_child(b)


## The MARKINGS strips, a hair above the ground.
func _markings() -> void:
	var g := _group(_root, "Markings")
	var mat := _mat("concrete", Color(1.0, 0.78, 0.2))
	for mk in MARKINGS:
		var r: Array = mk[0]
		var along_x: bool = r[2] > r[3]
		var length: float = r[2] if along_x else r[3]
		var dash: float = mk[1] if mk[1] > 0 else length
		var t := 0.0
		while t < length:
			var d := minf(dash, length - t)
			var strip := MeshInstance3D.new()
			strip.name = "Strip%d" % g.get_child_count()
			strip.mesh = _box_mesh(Vector3(d, 0.02, r[3]) if along_x else Vector3(r[2], 0.02, d), mat)
			strip.position = _p([r[0] + t + d / 2, r[1] + r[3] / 2, 0.01] if along_x else [r[0] + r[2] / 2, r[1] + t + d / 2, 0.01])
			strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_add(g, strip)
			t += dash * 2


## The BEACONS: a glowing lamp, its light and, if it has one, a pole down to its base.
func _beacons() -> void:
	var g := _group(_root, "Beacons")
	for bc in BEACONS:
		var at := _p(bc[0])
		var lamp := MeshInstance3D.new()
		lamp.name = "Lamp%d" % g.get_child_count()
		var sphere := SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = bc[1]
		sphere.material = m
		lamp.mesh = sphere
		lamp.position = at
		_add(g, lamp)
		var l := OmniLight3D.new()
		l.name = "Light"
		l.light_color = bc[1]
		l.omni_range = bc[2]
		l.light_energy = 2.0
		_add(lamp, l)
		if bc[3] >= 0:
			var pole := MeshInstance3D.new()
			pole.name = "Pole"
			var ph: float = bc[0][2] - bc[3] - 0.15
			pole.mesh = _box_mesh(Vector3(0.1, ph, 0.1), _mat("rust", Color(0.6, 0.6, 0.6)))
			pole.position = Vector3(0, -0.15 - ph / 2, 0)
			_add(lamp, pole)
