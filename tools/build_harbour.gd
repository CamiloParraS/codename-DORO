## Builds areas/harbour/harbour.tscn, the Tanker berth greybox, from the Harbour diagram's variant B data
## (.scratch/area-redesign/issues/04-harbour-diagram.md), and bakes its navmesh. Until the layout settles
## this file is the Harbour's source: change the data here and rebuild, don't hand-edit the scene.
##   godot --headless --path . --script tools/build_harbour.gd
## Data is in diagram metres (tools/area_builder.gd).
extends "res://tools/area_builder.gd"

const OUT := "res://areas/harbour/harbour.tscn"
const DECK := 2.0         # the freighter's deck height above the quay
const CONTAINER_H := 2.6
const KERB_H := 0.5       # no jump, so a kerb holds the Operative off the sea


## Walkable at quay height, top at 0: [rect, material].
const LAND := [
	[[2, 2, 60, 68], "quay"],     # the yard
	[[26, -6, 8, 8], "quay"],     # the road through the north fence
	[[48, 70, 8, 9], "pier"],       # south pier, the Extraction point at its tip
	[[62, 60, 8, 7], "pier"],       # the pontoon under the stern pier
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
	["KerbS1", [2, 69.7, 46, 0.3], 0, KERB_H, "kerb", Color(0.85, 0.85, 0.8)],
	["KerbS2", [56, 69.7, 6, 0.3], 0, KERB_H, "kerb", Color(0.85, 0.85, 0.8)],
	["KerbPierW", [47.7, 70, 0.3, 9.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbPierE", [56, 70, 0.3, 9.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbPierTip", [47.7, 79, 8.6, 0.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbPontoonS", [62, 66.7, 8, 0.3], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
	["KerbPontoonE", [69.7, 60, 0.3, 7], 0, KERB_H, "planks", Color(0.8, 0.8, 0.8)],
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
	# yard, east to west
	["Crane", [54, 18, 4, 4], 0, 8, "hatch", Color(1.0, 0.78, 0.2)],
	["CraneBoom", [58, 19.5, 7, 1], 7.5, 8, "hatch", Color(1.0, 0.78, 0.2)],
	["ResupplyCrate", [58.5, 49, 1, 1], 0, 1, "wood", Color(0.6, 0.9, 0.6)],
	["Container1", [44, 42, 3, 10], 0, CONTAINER_H, "metal", Color(0.75, 0.3, 0.25)],
	["Container2", [38, 56, 3, 8], 0, CONTAINER_H, "metal", Color(0.3, 0.5, 0.8)],
	["LiftControl", [16, 19, 5, 5], 0, 3.5, "panels", Color.WHITE],
	# the freight lift, set into the cliff, mouth east
	["LiftWallN", [2, 26, 12, 0.5], 0, 6, "concrete", Color(0.75, 0.75, 0.75)],
	["LiftWallS", [2, 37.5, 12, 0.5], 0, 6, "concrete", Color(0.75, 0.75, 0.75)],
	["LiftRoof", [2, 26, 12, 12], 6, 6.5, "concrete", Color(0.75, 0.75, 0.75)],
]
## The crane is open lattice: its tower and boom sit on the guards' layer, which blocks bodies but not sight,
## shots or the camera. Only these parts block sight: [name, rect, h0, h1], the machinery base and the top plate.
const CRANE_SOLID := [["CraneBase", [54, 18, 4, 4], 0, 2.4], ["CranePlate", [54, 18, 4, 4], 7.7, 8]]
## Low cover: [rect, h0].
const LOW := [
	[[51, 28, 1, 12], 0], [[44, 22, 6, 1.2], 0], [[26, 45, 8, 1.2], 0], [[16, 40, 6, 1.2], 0],
	[[48, 14, 1.2, 6], 0], [[52, 56, 6, 1.2], 0],
]
## Enterable buildings: [name, rect, height, doors [[side, centre]], tint, base, wall material]. A door is a 2 m gap.
const BUILDINGS := [
	["Gatehouse", [36, 6, 12, 8], 4.0, [["W", 10.0], ["S", 42.0]], Color.WHITE, 0.0, "panels"],
	["WarehouseA", [6, 48, 18, 16], 5.0, [["E", 54.0], ["N", 14.0]], Color(0.9, 0.9, 0.9), 0.0, "corrugated"],
]
## Crawlspaces: a structure [name, rect, height, material, tint] with a 1.2 m tunnel through it along
## x = axis_x (N-S) or y = axis_y (E-W). Mouths get a carry block each.
const CRAWLSPACES := [
	{name = "StackCrawl", rect = [28, 51, 10, 5], h = CONTAINER_H, mat = "cargo", tint = Color.WHITE, axis_x = 33.0},
	{name = "WarehouseBCrawl", rect = [26, 28.5, 14, 10], h = 6.0, mat = "corrugated", tint = Color(0.8, 0.88, 1.0), axis_x = 33.0},
	{name = "SternPierCrawl", rect = [58.5, 60, 10, 7], h = 1.5, mat = "pier", tint = Color.WHITE, axis_y = 64.0},
]
## Ladders: [name, bottom [x, y, h], top [x, y, h]]. The rungs run up the face at the bottom marker.
const LADDERS := [
	["LadderCrane", [56, 22.5, 0], [56, 20.5, 8]],
	["LadderWarehouseB", [40.5, 31, 0], [38.5, 31, 6]],
]
## The gangway: a ramp from the port rail gap down to the quay.
const GANGWAY := {top = [65, 46], bottom = [61, 46], width = 2.4}

## Guard posts: [name, [x, y, h], facing, meta, route [[x, y, meta]]]. Meta: hold / scan / chat.
const GUARD_POSTS := [
	["PostO1", [70, 25, DECK], 90, {hold = 5.0}, []],                                 # deck look-out across the starboard hatches
	["PostO2", [70.5, 30, DECK], 180, {}, [[70.5, 42, {}]]],                          # port-side deck loop
	["PostP", [73, 58, DECK], 0, {chat = true}, []],                                  # smoke break behind the bridge
	["PostO5", [66.5, 45, DECK], 10, {scan = 60.0}, []],                              # gangway head
	["PostY1", [58, 24, 0], 180, {}, [[58, 48, {hold = 4.0, f = 90}], [57, 59, {}]]],  # quay; holds facing the gangway foot
	["PostY2", [12, 57, 0], 80, {scan = 90.0}, []],                                   # on the manifests
	["PostY3", [30, 47.5, 0], 90, {}, [[43, 47.5, {}], [46, 64, {}], [28, 62, {}]]],   # container lanes
	["PostY4", [40, 18, 0], 180, {scan = 90.0}, []],                                  # gatehouse post
	["PostY5", [17, 32, 0], 90, {scan = 60.0}, []],                                   # lift chokepoint
	["PostY6", [22, 22, 0], 90, {}, [[48, 20.5, {hold = 6.0, f = 90}], [48, 40, {}], [22, 43, {}]]],     # centre loop round Warehouse B; holds facing the gatehouse post (Spoof spot: whoever moves PostY4 is witnessed)
]
const EXTRA_POSTS := [
	["PostExtra1", [30, 44, 0], 0, {}, [[33, 40, {hold = 3.0, f = 0}], [33, 57.5, {hold = 3.0, f = 0}]]],  # Stealth L2: looks into both Crawlspaces
	["PostExtra2", [26, 55, 0], 90, {hold = 5.0}, []],   # Combat L2: Warehouse A east door
	["PostExtra3", [45, 17, 0], 135, {hold = 5.0}, []],  # Combat L2: gatehouse south door
]
const TARGET_POSTS := [  # ponytail: the Core's director waits by the lift until the Core Mission builds the gallery room
	["TargetPost1", [10, 30, 0], 180, {}, [[10, 35, {}]]],
]
const SENTRIES := [
	["SentryCrane", [56, 19.5, 8], 200, {scan = 90.0}],
	["SentryWarehouseB", [34, 31, 6], 160, {scan = 90.0}],
]
## Camera mounts: [name, [x, y, h], facing, pole base h]. Without a pole base the mount is on a wall face.
const CAMERAS := [
	["CamWarehouseA", [24.05, 47.95, 4], 310], ["CamPier", [56.5, 61.5, 3], 80, 0.0],
	["CamGatehouse", [36, 14, 3.8], 200], ["CamLift", [14.05, 26.25, 5], 110],
]
const SPOTS := {
	OperativeStart = [71, 7, DECK], RoadEntry = [30, -2, 0], Extraction = [52, 77, 0],
	ResupplyCrate = [59, 49.5, 1], FreightLift = [8, 32, 0], SafeRoom = [46, 7.5, 0],
}
const SPOOFS := {SpoofDock = [52, 72], SpoofWarehouse = [42, 40], SpoofGatehouse = [40, 16.5], SpoofLiftControl = [18.5, 26]}
## Mission 1's tutorial teaches eavesdropping here: 2 m beside PostY1's quay route, in Voiceprint range of its check-ins.
const EAVESDROP := {EavesdropSpot = [56, 36]}
const INTEL := {IntelManifests = [9, 60], IntelRadioLog = [44, 9], IntelLift = [8, 32]}

## Set dressing (tools/area_builder.gd _dress): [model, [x, y, h], facing, scale]. Kept off guard routes,
## doorways, Crawlspace mouths and Ladders.
const DRESS := [
	# quay: bollards on the edge, floodlights leaning over the yard
	["bollard", [61, 8, 0], 0], ["bollard", [61, 16, 0], 0], ["bollard", [61, 30, 0], 0],
	["bollard", [61, 42, 0], 0], ["bollard", [61, 52, 0], 0],
	["lamp_post", [61.2, 12, 0], 270], ["lamp_post", [61.2, 34, 0], 270], ["lamp_post", [61.2, 57, 0], 270],
	["lamp_post", [55.5, 78.5, 0], 270],  # over the Extraction point at the pier tip
	["lamp_post", [35, 3.5, 0], 225], ["lamp_post", [3.5, 44, 0], 90],
	# pier
	["crate_small", [49, 72, 0], 10], ["supply_crate", [49.2, 72.6, 0.36], 80], ["drum", [55, 71.5, 0], 0],
	# north-west corner and the lift control hut
	["drum", [3.5, 3.5, 0], 0], ["drum", [4.4, 3.6, 0], 30], ["barrel_a", [3.7, 4.5, 0], 0],
	["tank_tall", [4.5, 14, 0], 0], ["generator", [18.5, 17, 0], 0], ["jerrycan", [21, 17, 0], 60],
	# road in: cones either side of the barrier lane
	["cone", [27, 0, 0], 0], ["cone", [33, 0, 0], 0], ["cone", [27, -3, 0], 0], ["cone", [33, -3, 0], 0],
	# Warehouse A outside, by its north door
	["pallet_stack", [8.5, 45.5, 0], 0], ["crate_wide", [19.5, 45.8, 0], 0],
	["barrel_b", [22.5, 46, 0], 0], ["barrel_a", [23.2, 46.6, 0], 40],
	["pipe_riser", [25.5, 36, 0], 90],  # on Warehouse B's west wall
	["drum", [48, 51.5, 0], 0], ["drum", [48.7, 50.8, 0], 20],
	# Warehouse A inside: racking on the south wall, stock, lights
	["crate_wide", [16.3, 63, 0], 0], ["crate_small", [16, 63, 0.67], 15], ["crate_wide", [18.3, 63, 0], 0],
	["pallet_stack", [21.5, 61.5, 0], 0], ["crate_wide", [8.5, 50.5, 0], 90],
	["cardboard_box", [20.5, 49, 0], 15], ["cardboard_box", [21.3, 49.2, 0], 40],
	["ceiling_lamp", [11, 56, 4.8], 0], ["ceiling_lamp", [19, 56, 4.8], 0],
	# gatehouse inside: the radio desk and a locker
	["table", [39, 7, 0], 0], ["monitor", [39, 7, 0.96], 0], ["chair", [39, 8.3, 0], 180],
	["locker", [36.7, 12.5, 0], 90], ["ceiling_lamp", [42, 10, 3.8], 0],
	["vent_unit", [40, 8, 4.3], 0],  # on the gatehouse roof
	# freighter deck
	["drum", [73, 6.5, DECK], 0], ["drum", [73.8, 7, DECK], 40], ["crate_wide", [75.5, 44, DECK], 90],
	# the freight lift lit from inside, so the way down reads from the yard; sandbags at the road gate
	["ceiling_lamp", [7, 32, 5.9], 0], ["sandbags", [23.5, 5, 0], 0], ["pipe_arch", [3.6, 20, 0], 0],
	# second pass: the lift as a working freight bay (cabinets, generator, pipes, lamps over the mouth)
	["cabinet_b", [4, 26.9, 0], 0], ["cabinet_a", [5.5, 26.9, 0], 0], ["generator", [4.5, 36.7, 0], 180],
	["pipe_riser", [2.6, 29, 0], 270], ["ceiling_lamp", [11.5, 28, 5.9], 0], ["ceiling_lamp", [11.5, 36, 5.9], 0],
	# Warehouse A stock along the walls, the middle kept open for PostY2's sweep
	["pallet_stack", [8, 62.5, 0], 0], ["supply_crate", [11, 62.8, 0], 0], ["cabinet_b", [6.6, 55, 0], 270],
	["cabinet_a", [6.6, 56.4, 0], 270], ["drum", [22.8, 58, 0], 0], ["drum", [23, 59, 0], 30],
	["barrel_b", [22.6, 60, 0], 0], ["vent_unit", [12, 63.4, 3], 180],
	# gatehouse: the guard room's screens, cabinets and a drinks machine
	["monitoring_screen", [42.5, 6.9, 0], 0], ["cabinet_a", [47.3, 12.5, 0], 90], ["cabinet_b", [47.3, 11, 0], 90],
	["vending_machine", [37.2, 7, 0], 0],
	# a parked van in the north-west corner
	["van", [10, 8, 0], 90],
	# deck: mast lights over the bow (the start) and the starboard walk, some cargo by the port rail
	["lamp_post", [68.2, 8, DECK], 90], ["lamp_post", [76.2, 41, DECK], 270],
	["pallet", [67.5, 22, DECK], 0], ["crate_small", [67.3, 23.5, DECK], 20],
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
	[[14.5, 27.5, 0.2, 9], 0], [[18.3, 27.5, 0.2, 9], 0],   # the lift's loading box
	[[14.5, 27.5, 4, 0.2], 0], [[14.5, 36.3, 4, 0.2], 0],
]
## Small lights with a lamp you can see from afar: [[x, y, h], colour, range, pole base h or -1 for none].
const BEACONS := [
	[[55.9, 79.1, 2.2], Color(1, 0.15, 0.1), 7.0, 0.5],    # the Extraction pier tip
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
		_marker(eavesdrops, n, EAVESDROP[n] + [0], 0, {}, "eavesdrop_spot")

	_actors()
	var ep := _area(_root, "ExtractionPoint", SPOTS.Extraction, Vector3(4, 3, 4), "res://areas/extraction_point.gd")
	ep.position.y = 1.5
	_intel(INTEL)
	var sea := _area(_root, "Sea", [40, 40, -5.5], Vector3(160, 5, 160), "res://areas/sea.gd")
	sea.collision_mask = 1  # the Operative's layer
	_save(OUT)
	quit()


# --- Harbour-only builders ---------------------------------------------------------------------

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
