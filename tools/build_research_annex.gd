## Builds areas/research_annex/research_annex.tscn from the level-pass map
## (.scratch/pw-feel/prototypes/research-annex-onboarding.html: a ring-shaped lab, three Encounters), bakes its
## navmesh and prints how far the navmesh reaches. Until the layout settles this file is the Research annex's
## source: change the data here and rebuild, don't hand-edit the scene.
##   godot --headless --path . --script tools/build_research_annex.gd
## Data is in diagram metres (tools/area_builder.gd).
extends "res://tools/area_builder.gd"

const OUT := "res://areas/research_annex/research_annex.tscn"
const FENCE := Color(0.7, 0.72, 0.75)
const RAIL := Color(0.8, 0.3, 0.25)

## Walkable ground, solid from -1 up to its top h: [rect, material, h, tint]. The quarry pit takes the
## south-east corner (x 62-76, y 30-76); the road runs out of the north gate to a barrier.
const LAND := [
	[[4, 4, 72, 14], "ground", 0, Color.WHITE],    # the north strip, 14 m deep
	[[56, 18, 20, 12], "ground", 0, Color.WHITE],  # the north-east yard, over the quarry rim: the Extraction
	[[4, 18, 58, 58], "ground", 0, Color.WHITE],   # the lab plot, the yard and the dock
	[[36, -8, 8, 12], "ground", 0, Color.WHITE],   # the road in through the gate
]
## Solid boxes: [name, rect, h0, h1, material, tint].
const SOLID := [
	["FenceW", [3.8, 4, 0.2, 72], 0, 3, "metal", FENCE],
	["FenceS", [4, 75.8, 58, 0.2], 0, 3, "metal", FENCE],
	["FenceN1", [4, 3.8, 32, 0.2], 0, 3, "metal", FENCE],
	["FenceN2", [44, 3.8, 32, 0.2], 0, 3, "metal", FENCE],
	["FenceE", [75.8, 4, 0.2, 26], 0, 3, "metal", FENCE],
	["RoadSideW", [35.8, -8, 0.2, 11.8], 0, 3, "metal", FENCE],
	["RoadSideE", [44, -8, 0.2, 11.8], 0, 3, "metal", FENCE],
	["RoadBarrier", [36, -8.4, 8, 0.4], 0, 1.2, "metal", Color(0.9, 0.5, 0.2)],
	# the quarry pit's rim: no jump, so a 1 m rail holds the Operative
	["RailQN", [62, 29.8, 14, 0.2], 0, 1, "metal", RAIL],
	["RailQW", [61.8, 30, 0.2, 46], 0, 1, "metal", RAIL],
	["Container1", [14, 58, 3, 8], 0, 2.6, "metal", Color(0.42, 0.32, 0.27)],
	["Container2", [44, 56, 8, 3], 0, 2.6, "metal", Color(0.28, 0.34, 0.4)],
	["Truck", [50, 6, 7, 3], 0, 3, "metal", Color(0.45, 0.5, 0.4)],
	["DockCrate1", [58, 36, 3, 4], 0, 2.6, "metal", Color(0.36, 0.34, 0.3)],
	["DockCrate2", [58, 48, 3, 6], 0, 2.6, "metal", Color(0.36, 0.34, 0.3)],
	["ResupplyCrate", [54.5, 63.5, 1, 1], 0, 1, "wood", Color(0.6, 0.9, 0.6)],
	# tower deck rails, open at the stair tops: off an outer edge the Operative would clear the fence
	["RailGateN", [30, 5, 6, 0.2], 5, 6, "metal", RAIL],
	["RailGateE", [35.8, 5, 0.2, 6], 5, 6, "metal", RAIL],
	["RailGateS", [30, 10.8, 6, 0.2], 5, 6, "metal", RAIL],
	["RailGateW", [30, 5, 0.2, 2.5], 5, 6, "metal", RAIL],
	["RailYardN", [40, 70, 6, 0.2], 5, 6, "metal", RAIL],
	["RailYardE", [45.8, 70, 0.2, 6], 5, 6, "metal", RAIL],
	["RailYardS", [40, 75.8, 6, 0.2], 5, 6, "metal", RAIL],
	["RailYardW1", [40, 70, 0.2, 1], 5, 6, "metal", RAIL],
	["RailYardW2", [40, 74, 0.2, 2], 5, 6, "metal", RAIL],
]
## The lab's interior walls, 0.4 m thick and 3.6 m high, with doorway gaps: [name, "H" (runs east) or "V" (runs
## south), centre line, from, to, gaps [[from, to]]]. A wall cut by gaps is numbered from 1. The lab is a ring: the
## north corridor (y 28..31) and the south corridor (y 41..44), joined by the west (x 6..9) and east (x 53..56)
## passages round the middle block (lab, clean room, vault). Corners break the sight lines; Evasion can circle.
const WALLS := [
	["WallNorthRow", "H", 28, 6, 56, [[12, 14], [24, 26], [37, 39], [50, 52]]],   # lockers, office, server room, security
	["WallLockerOffice", "V", 18, 18.2, 27.8, []],
	["WallOfficeServer", "V", 32, 18.2, 27.8, [[21, 23]]],                         # room to room: office <-> server room
	["WallServerSecurity", "V", 44, 18.2, 27.8, []],
	["WallBlockN", "H", 31, 9, 53, [[14, 16], [31, 33], [46, 48]]],                # lab, clean room, the vault's front door
	["WallBlockS", "H", 41, 9, 53, [[22, 24], [35, 37]]],                          # lab, clean room
	["WallBlockW", "V", 9, 31, 41, [[35, 37]]],                                    # lab onto the west passage
	["WallBlockE", "V", 53, 31, 41, []],
	["WallLabClean", "V", 30, 31.2, 40.8, [[33, 36]]],                             # the researcher's walk
	["WallCleanVault", "V", 40, 31.2, 40.8, [[37, 39]]],                           # the vault's back door
	["WallSouthRow", "H", 44, 6, 56, [[10, 12], [30, 32], [46, 48]]],              # lobby, Archive, loading hall
	["WallLobbyArchive", "V", 24, 44.2, 54, []],
	["WallArchiveHall", "V", 40, 44.2, 54, [[44.2, 46.2]]],                        # A8's spoof walk to the hall
]
const WALL_T := 0.4
const WALL_H := 3.6
## Sentry towers: raised walkable slabs on a central leg: [name, rect, top h, material].
const DECKS := [["GateTower", [30, 5, 6, 6], 5, "metal"], ["YardTower", [40, 70, 6, 6], 5, "metal"]]
## Low cover: [rect, h0]. On the strip, between V1's line and the path along the lab wall; the researcher's bench;
## the lobby counter.
const LOW := [
	[[20, 60, 6, 1.2], 0], [[48, 70, 4, 1.2], 0], [[9, 14.6, 5, 1.2], 0], [[64, 20, 6, 1.2], 0],
	[[25.5, 52, 5, 1.2], 0], [[16, 37.5, 6, 1.2], 0], [[8, 48, 1.2, 3], 0],
]
## Enterable buildings: [name, rect, height, doors [[side, centre]], tint, base]. The lab's six doors: the front door
## and the Archive back door (S), office and security (N), the west passage (W), the loading hall (E, past the dock
## guard).
const BUILDINGS := [
	["Lab", [6, 18, 50, 36], 4.0, [["S", 14.0], ["S", 32.0], ["N", 22.0], ["N", 47.0], ["W", 36.0], ["E", 49.0]],
		Color(0.85, 0.85, 0.8), 0.0],
]
## No Fulton under a roof: [name, rect, h0, h1]: the lab and under the pump house.
const ROOMS := [["Lab", [6, 18, 50, 36], 0, 4], ["PumpCrawl", [28, 56, 8, 10], 0, 3.5]]
## The stilted pump house: a 10 m Crawlspace under it, from the yard north to the Archive's back door.
const CRAWLSPACES := [
	{name = "PumpCrawl", rect = [28, 56, 8, 10], h = 3.5, mat = "wood", tint = Color(0.8, 0.7, 0.55), axis_x = 32.0},
]
## Wedges up to the towers: {name, rect, h0, h1, up: the high side}. 8 m long (the diagram's 3 m is too
## steep to walk).
const RAMPS := [
	{name = "GateStair", rect = [22, 7.5, 8, 3], h0 = 0.0, h1 = 5.0, up = "E", mat = "metal", tint = Color(0.6, 0.6, 0.6)},
	{name = "YardStair", rect = [32, 71, 8, 3], h0 = 0.0, h1 = 5.0, up = "E", mat = "metal", tint = Color(0.6, 0.6, 0.6)},
]

## Guard posts: [name, [x, y, h], facing, meta, route [[x, y, meta]]]. Meta: hold / scan; `enc` is the Encounter
## (ENCOUNTERS); `detour` the Caution search group, when it isn't the Encounter: E2's strip and core search apart
## (playtest 6: in Caution V1, A5 and A3 bunched at A5's post by the Extraction); `holdup` what a Hold-up gets
## out of him. 8 guards (P1 is a chatting pair), plus the researcher's escort.
## Spoof voices: any Hold-up, or the security room's pair through its north wall (EAVESDROP).
## Map: .scratch/pw-feel/prototypes/research-annex-onboarding.html.
const GUARD_POSTS := [
	["PostA1", [30, 68, 0], 0, {hold = 3.0, role = "patroller", enc = 1}, [[40, 68, {hold = 6.0, f = 180}]]],  # yard: past the crawl mouth; his east stop times the dock walk (18 m from A9)
	["PostA3", [37, 29.5, 0], 270, {hold = 4.0, role = "patroller", enc = 2, detour = "core"}, [[50, 29.5, {hold = 6.0, f = 90}]]],  # north corridor; his east stop, past the vault's front door, is its window
	["PostA5", [60, 4.5, 0], 270, {hold = 4.0, role = "patroller", enc = 2, detour = "strip"}, [[60, 13, {hold = 8.0, f = 150}]]],   # across the strip's east end; his south stop watches the Extraction
	["PostP1", [50, 21, 0], 0, {chat = true, role = "investigator", enc = 2, detour = "core"}, []],                             # the night shift chatting in the security room: record them through its north wall from the strip; in the core's net
	["PostA8", [37, 51, 0], 270, {scan = 60.0, role = "observer", enc = 3}, []],                               # Archive, facing the files and both doors: spoof him to the hall
	["PostA9", [57, 62, 0], 270, {scan = 60.0, role = "observer", enc = 1, holdup = "code"}, []],              # dock, facing the yard: the Hold-up is from the south, behind him (19 m from anyone)
	["PostV1", [8, 13, 0], 180, {hold = 3.0, role = "patroller", enc = 2, detour = "strip"}, [[26, 13, {hold = 3.0, f = 90}]]],  # the strip's west half; his west stop looks down the west lane's mouth
]
const EXTRA_POSTS := [
	["PostExtra1", [38, 68, 0], 270, {role = "patroller"}, [[32, 68.5, {hold = 3.0, f = 0}], [44, 70, {}]]],  # Stealth L2: the crawl's south mouth
	["PostExtra2", [9, 21, 0], 90, {hold = 5.0, role = "interceptor"}, []],     # Combat L2: the locker room, the researcher's safe room
	["PostExtra3", [12.5, 57, 0], 0, {hold = 5.0, role = "interceptor"}, []],   # Combat L2: the front of the lab
]
const TARGET_POSTS := [  # the lead researcher: her bench facing the west door, then the clean room facing the vault's back door
	["TargetPost1", [16, 34, 0], 270, {hold = 15.0, enc = 2}, [[36, 34, {hold = 12.0, f = 120}]]],
]
const SENTRIES := [
	["SentryGate", [33, 8, 5], 180, {scan = 90.0}],
	["SentryYard", [43, 73, 5], 320, {scan = 90.0}],
]
## Camera mounts: [name, [x, y, h], facing, pole base h]. Without a pole base the mount is on the lab's
## wall, facing away from it; the dock's stands on a pole, looking down the dock towards the yard.
const CAMERAS := [
	["CamFront", [9, 54.05, 3.5], 125], ["CamArchiveBack", [37, 54.05, 3.5], 160], ["CamDock", [58, 43, 4], 225, 0.0],
]
const SPOTS := {
	OperativeStart = [8, 72, 0], RoadEntry = [40, 2, 0], Extraction = [70, 24, 0],
	ResupplyCrate = [55, 64, 1], SafeRoom = [12, 23, 0], ResearchFiles = [27, 50, 0],  # the safe room: the locker room, ~35 m from the reinforcements' gate
}
## The three Encounters, one per objective step: [id, name, problem, rect]. E2 and E3 never share a shout (15.5 m).
const ENCOUNTERS := [
	[1, "Yard", "timing", [4, 54, 58, 22]],
	[2, "Strip and core", "positioning", [4, 4, 72, 37]],
	[3, "Archive", "manipulation", [4, 41, 58, 13]],
]
## Where the Operative leaves an Encounter: the session log names the one taken.
const EXITS := {
	WestLane = [5, 17, 0], WestDoor = [6, 36, 0], FrontDoor = [14, 54, 0], CrawlSouth = [32, 66, 0], ArchiveBackDoor = [32, 54, 0],
	OfficeNorthDoor = [22, 18, 0], SecurityNorthDoor = [47, 18, 0], HallEastDoor = [56, 49, 0],
}
## Mission 3's steps (Campaign data names them). watch (objective_watch.gd): A9's Hold-up answer (the node keeps
## the old name, IntelOffice, so Campaign is unchanged); then the vault and the files are walk-ins.
const INTEL := {IntelVault = [47, 36]}  # the files in the Archive are the last step
const OBJECTIVES := {IntelOffice = {at = [57, 62, 0], watch = "answer", guards = ["GuardA9"]}}
## Where to record the security room's pair: on the strip under the room's north wall, 4.3 m from each seat.
const EAVESDROP := {EavesdropSpot = [50, 16.8, 0]}
const START_FACING := 45
## Set dressing (tools/area_dressing.gd _dress): [model, [x, y, h], facing, scale]. Kept off guard routes,
## doorways, the Crawlspace mouths and stair feet.
const DRESS := [
	# corridor, passage and room lights (the roof's underside is at 4)
	["ceiling_lamp", [15, 29.5, 3.8], 0], ["ceiling_lamp", [31, 29.5, 3.8], 0], ["ceiling_lamp", [46, 29.5, 3.8], 0],
	["ceiling_lamp", [15, 42.5, 3.8], 0], ["ceiling_lamp", [31, 42.5, 3.8], 0], ["ceiling_lamp", [46, 42.5, 3.8], 0],
	["ceiling_lamp", [7.5, 36, 3.8], 0], ["ceiling_lamp", [54.5, 36, 3.8], 0],
	["ceiling_lamp", [12, 23, 3.8], 0], ["ceiling_lamp", [25, 23, 3.8], 0], ["ceiling_lamp", [38, 23, 3.8], 0], ["ceiling_lamp", [50, 23, 3.8], 0],
	["ceiling_lamp", [19, 36, 3.8], 0], ["ceiling_lamp", [35, 36, 3.8], 0], ["ceiling_lamp", [47, 36, 3.8], 0],
	["ceiling_lamp", [15, 49.5, 3.8], 0], ["ceiling_lamp", [32, 49.5, 3.8], 0], ["ceiling_lamp", [48, 49.5, 3.8], 0],
	# locker room: lockers and racking on the west wall
	["locker", [6.6, 22, 0], 90], ["locker", [6.6, 23, 0], 90], ["shelf", [6.5, 26, 0], 90], ["shelf", [6.5, 26.8, 0], 90],
	# office: the desk off the line from the north door to the corridor and the server room
	["table", [20, 25.5, 0], 0], ["monitor", [19.7, 25.5, 0.96], 0], ["pc", [20.6, 25.5, 0.96], 0],
	["chair", [20, 26.7, 0], 180], ["cabinet_b", [29.5, 18.6, 0], 180],
	# server room: racks along the east wall
	["cabinet_b", [43.2, 20, 0], 270], ["cabinet_b", [43.2, 21.3, 0], 270], ["cabinet_b", [43.2, 22.6, 0], 270],
	["cabinet_b", [43.2, 23.9, 0], 270], ["cabinet_b", [43.2, 25.2, 0], 270],
	# security: the monitor desk on the east wall
	["table", [54.8, 22, 0], 90], ["monitor", [54.9, 22.3, 0.96], 90], ["pc", [54.9, 21.4, 0.96], 90], ["locker", [55.4, 26, 0], 270],
	# lab: the researcher's bench (LOW) with a screen on it, a second bench on the south wall
	["monitoring_screen", [19, 38.1, 1.0], 0], ["table", [12, 39.8, 0], 0], ["monitor", [12, 39.8, 0.96], 0],
	# vault: cabinets either side of the front door
	["cabinet_b", [42, 31.6, 0], 180], ["cabinet_b", [43.3, 31.6, 0], 180], ["cabinet_b", [50.7, 31.6, 0], 180],
	["cabinet_b", [52, 31.6, 0], 180], ["cardboard_box", [51.8, 40, 0], 20],
	# lobby
	["vending_machine", [23.3, 52, 0], 270], ["chair", [6.5, 46, 0], 90], ["chair", [6.5, 47, 0], 90],
	# Archive: racking on the south and west walls
	["shelf", [34.5, 53.4, 0], 180], ["shelf", [35.3, 53.4, 0], 180], ["shelf", [36.1, 53.4, 0], 180],
	["shelf", [36.9, 53.4, 0], 180], ["shelf", [37.7, 53.4, 0], 180],
	["shelf", [24.6, 47.5, 0], 90], ["shelf", [24.6, 48.3, 0], 90],
	# loading hall
	["pallet_stack", [54.2, 52.5, 0], 0], ["crate_wide", [42.5, 52.8, 0], 0], ["cardboard_box", [44.5, 53.1, 0], 30],
	["cabinet_a", [55.4, 45.5, 0], 270],
	# outside: floodlights at the gate, over the Extraction point and over the dock guard (the yard's landmark, lit from the start)
	["lamp_post", [74, 27, 0], 270], ["lamp_post", [61.2, 60, 0], 270], ["lamp_post", [45.5, 5, 0], 180], ["lamp_post", [4.6, 66, 0], 90],
	["barrel_a", [16, 5.5, 0], 0], ["barrel_b", [16.8, 6.1, 0], 0], ["tank_tall", [74, 19, 0], 0],
	["cone", [37, 1, 0], 0], ["cone", [43, 1, 0], 0],
	# yard and dock
	["pallet_stack", [5.5, 60, 0], 90], ["generator", [24, 74.5, 0], 0], ["jerrycan", [26.3, 74.6, 0], 30],
	["drum", [60.5, 70, 0], 0], ["drum", [61, 70.8, 0], 40], ["pallet", [56, 73, 0], 0],
	["crate_wide", [50, 74.6, 0], 0], ["cardboard_box", [50.3, 74.6, 0.67], 25],
	# the north strip: stock along the fence, a checkpoint barrier inside the gate
	["pallet_stack", [8, 5.6, 0], 0], ["crate_wide", [10.6, 5.2, 0], 0], ["drum", [66, 5.5, 0], 0], ["drum", [66.8, 5.9, 0], 30],
	["jersey_barrier", [22, 5, 0], 0],
	# the lab's roof: air handlers and a dish (seen from the towers)
	["vent_unit", [15, 24, 4.3], 0], ["vent_unit", [32, 48, 4.3], 90], ["vent_unit", [46, 24, 4.3], 0],
	["sat_dish", [50, 36, 4.3], 30, 0.7],
]
## Paint: the road's centre line out of the gate, the stop line, the truck's bay; inside, a colour per corridor
## (north blue, south yellow) so the Operative knows which side of the ring it is on.
const MARKINGS := [
	[[9, 29.4, 44, 0.2], 0, 0, Color(0.3, 0.55, 0.95)], [[9, 42.4, 44, 0.2], 0, 0, Color(1.0, 0.78, 0.2)],
	[[39.9, -120, 0.2, 124], 2.0, 0, Color(0.95, 0.95, 0.92)], [[36.2, 2.4, 7.6, 0.3], 0, 0, Color(0.95, 0.95, 0.92)],
	[[49, 5.4, 9, 0.15], 0], [[49, 9.6, 9, 0.15], 0], [[49, 5.4, 0.15, 4.35], 0],
]
## Out on the plain past the north fence, into the fog (heights from _ground_h).
const BACKDROP_DRESS := [
	["chimney", [20, -25], 0, 2.0], ["tank_tall", [64, -20], 0, 2.5], ["shed", [-15, 30], 90, 1.5], ["water_tower", [90, 14], 0, 6.0],
	["shed", [-14, 46], 90, 1.2], ["van", [-12, 38], 20], ["jersey_barrier", [37, -12], 0], ["jersey_barrier", [43, -16], 0],
	# the quarry floor: gravel heaps, a parked van, drums
	["mound", [75, 45], 0, 2.0, "ground", Color(0.75, 0.72, 0.68)], ["mound", [92, 62], 40, 2.6, "ground", Color(0.75, 0.72, 0.68)],
	["mound", [70, 72], 70, 1.6, "ground", Color(0.75, 0.72, 0.68)], ["van", [84, 50], 30], ["drum", [80, 52], 0], ["drum", [80.8, 52.6], 0],
	["lamp_post", [66, 40], 90],
]
const TERRAIN := Color(0.8, 0.8, 0.75)
const GROUND_RECT := [-158, -158, 400, 400]
const GROUND_HOLES := [[4, 4, 72, 26], [4, 30, 58, 46], [36, -118, 8, 122]]  # the Area's land, the road
const WOODS := [  # [model, rects, count, scale from, to, seed]
	["pine", [[-70, -70, 60, 200], [-10, 84, 72, 60], [-70, -80, 100, 60], [50, -80, 110, 60]], 130, 2.2, 3.4, 51],
	["poplar", [[-70, -70, 60, 200], [-10, 84, 72, 60], [-70, -80, 100, 60]], 70, 1.6, 2.4, 52],
	["pine_small", [[-30, -40, 30, 140], [0, 82, 60, 20]], 40, 1.6, 2.6, 53], ["dead_tree", [[-60, -60, 220, 200]], 12, 1.2, 1.8, 54],
]
const WOODS_CLEAR := [[-2, -2, 84, 84], [30, -120, 20, 125], [58, 26, 200, 200]]  # 6 m off the fences, the road, the pit
const PYLONS := [[-100, -40], [-40, -42], [20, -44], [80, -46], [140, -48]]
const ROAD_POLES := [[45.5, -108], [45.5, -84], [45.5, -60], [45.5, -36], [45.5, -12]]
## Spoof destinations. SpoofHall takes the Archive guard out through the hall door, never into a corridor.
const SPOOFS := {SpoofYard = [26, 70, 0], SpoofNorth = [18, 15.5, 0], SpoofQuarry = [66, 24, 0], SpoofDock = [59, 58, 0], SpoofHall = [51, 50, 0]}

## What the navmesh must reach from the start: every room, every doorway, both tower tops and every objective.
const REACH := {
	NorthCorridorW = [10, 29.5, 0], NorthCorridorE = [52, 29.5, 0], SouthCorridorW = [10, 42.5, 0], SouthCorridorE = [52, 42.5, 0],
	WestPassage = [7.5, 36, 0], EastPassage = [54.5, 36, 0],
	Lockers = [12, 23, 0], Office = [25, 23, 0], ServerRoom = [38, 23, 0], Security = [50, 22, 0],
	Lab = [16, 34, 0], CleanRoom = [36, 34, 0], Vault = [47, 36, 0], Lobby = [15, 50, 0], Archive = [27, 50, 0], LoadingHall = [51, 50, 0],
	DoorLockers = [13, 28, 0], DoorOffice = [25, 28, 0], DoorServer = [38, 28, 0], DoorSecurity = [51, 28, 0],
	DoorOfficeServer = [32, 22, 0], DoorLabN = [15, 31, 0], DoorCleanN = [32, 31, 0], DoorVaultFront = [47, 31, 0],
	DoorLabS = [23, 41, 0], DoorCleanS = [36, 41, 0], DoorLabW = [9, 36, 0], DoorLabClean = [30, 34.5, 0], DoorVaultBack = [40, 38, 0],
	DoorLobby = [11, 44, 0], DoorArchive = [31, 44, 0], DoorHall = [47, 44, 0], DoorArchiveHall = [40, 45.2, 0],
	FrontDoor = [14, 53.85, 0], ArchiveBackDoor = [32, 53.85, 0], OfficeNorthDoor = [22, 18.15, 0], SecurityNorthDoor = [47, 18.15, 0],
	WestDoor = [6.15, 36, 0], HallEastDoor = [55.85, 49, 0],
	NorthStrip = [30, 14, 0], NorthEastYard = [64, 24, 0], WestLane = [5, 40, 0], Dock = [58, 58, 0], Yard = [20, 70, 0],
	HoldUp = [58.5, 63, 0], EavesdropSpot = [50, 16.8, 0],
	GateTowerTop = [35, 6, 5], YardTowerTop = [45, 75, 5], Extraction = [70, 24, 0], RoadEntry = [40, 2, 0],
}
## The carry routes, researcher to Extraction, as waypoints the shortest path is forced through.
const CARRY := {
	"North, the office door" = [[16, 34, 0], [15, 29.5, 0], [25, 29.5, 0], [22, 18, 0], [56, 16, 0], [70, 24, 0]],
	"East, the hall and the dock" = [[36, 34, 0], [36, 42.5, 0], [47, 42.5, 0], [56, 49, 0], [59, 31, 0], [70, 24, 0]],
	"West, the lane" = [[16, 34, 0], [6, 36, 0], [5, 18, 0], [40, 16.5, 0], [70, 24, 0]],
}


func _build() -> void:
	_root = Node3D.new()
	_root.name = "ResearchAnnex"
	_root.set_script(load("res://areas/harbour/harbour.gd"))

	var nav := _nav_region()
	var land := _group(nav, "Land")
	for l in LAND:
		_box(land, "Land%d" % land.get_child_count(), l[0], -1, l[2], l[1], l[3])
	var solid := _group(nav, "Solid")
	for s in SOLID:
		_box(solid, s[0], s[1], s[2], s[3], s[4], s[5])
	_camera_poles(solid, CAMERAS)
	for d in DECKS:
		_box(solid, d[0], d[1], d[2] - 0.3, d[2], d[3], Color(0.55, 0.6, 0.7))
		var r: Array = d[1]
		_box(solid, d[0] + "Leg", [r[0] + r[2] / 2 - 0.5, r[1] + r[3] / 2 - 0.5, 1, 1], 0, d[2] - 0.3, "metal", Color(0.5, 0.5, 0.5))
	for l in LOW:
		_box(solid, "Low%d" % solid.get_child_count(), l[0], l[1], l[1] + LOW_H, "wood", Color(0.9, 0.8, 0.6))
	for b in BUILDINGS:
		_building(_group(solid, b[0]), b)
	for w in WALLS:
		_wall_run(solid.get_node("Lab"), w)
	for r in RAMPS:
		_ramp(solid, r)
	_dress(nav, DRESS)
	var crawl := _group(nav, "Crawlspaces")
	for c in CRAWLSPACES:
		_crawlspace(_group(crawl, c.name), c)
	_bake(nav)
	var nm := nav.navigation_mesh

	_backdrop()
	_surroundings()
	_markings(MARKINGS)
	_mood("research_annex")

	var spots := _group(_root, "Spots")
	for n in SPOTS:
		_marker(spots, n, SPOTS[n], START_FACING if n == "OperativeStart" else 0, {}, "spot")
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
		_marker(spoofs, n, SPOOFS[n], 0, {}, "spoof_place")

	_rooms(ROOMS)
	_actors()
	var ep := _area(_root, "ExtractionPoint", SPOTS.Extraction, Vector3(4, 3, 4), "res://areas/extraction_point.gd")
	ep.position.y += 1.5
	_intel({IntelVault = INTEL.IntelVault, ResearchFiles = SPOTS.ResearchFiles})
	var encounters := _group(_root, "Encounters")  # MissionRun reads which one the Operative is in
	for e in ENCOUNTERS:
		_marker(encounters, "Encounter%d" % e[0], [e[3][0], e[3][1], 0], 0, {id = e[0], size = Vector2(e[3][2], e[3][3])}, "encounter")
	for n in EXITS:
		_marker(encounters, n, EXITS[n], 0, {}, "encounter_exit")
	var eavesdrops := _group(_root, "EavesdropSpots")
	for n in EAVESDROP:
		_marker(eavesdrops, n, EAVESDROP[n], 0, {}, "eavesdrop_spot")
	for n in OBJECTIVES:
		var o: Dictionary = OBJECTIVES[n]
		var w := _area(_root.get_node("Intel"), n, [o.at[0], o.at[1], o.at[2] + 1.5], Vector3(1, 1, 1), "res://areas/objective_watch.gd")
		w.set("verb", o.watch)
		w.set("guards", PackedStringArray(o.guards))
	_save(OUT)
	await _report_reach(nm, SPOTS.OperativeStart, REACH, CARRY)
	quit()


## One WALLS entry: the boxes between its gaps.
func _wall_run(parent: Node3D, w: Array) -> void:
	var spans := _spans(w[3], w[4], w[5])
	for i in spans.size():
		var s: Array = spans[i]
		var c: float = w[2] - WALL_T / 2
		var rect := [s[0], c, s[1] - s[0], WALL_T] if w[1] == "H" else [c, s[0], WALL_T, s[1] - s[0]]
		_box(parent, w[0] + (str(i + 1) if spans.size() > 1 else ""), rect, 0, WALL_H, "brick", Color(0.8, 0.78, 0.72))


## The quarry pit's sheer west and north walls and the road out; _surroundings lays the ground. No collision:
## the fences, the rim and tower rails and the road barrier close every edge, so no kill volume is needed.
## ponytail: the rest of the Backdrop kit (distant blocks, skyline, fog) is its own build.
func _backdrop() -> void:
	var bd := _group(_root, "Backdrop")
	bd.add_to_group("backdrop", true)
	for p in [
		["PitWallW", [61, 30, 1, 60], -14, -0.1, "stone", Color(0.65, 0.6, 0.55)],
		["PitWallN", [62, 29, 48, 1], -14, -0.1, "stone", Color(0.65, 0.6, 0.55)],
		["RoadNorth", [36, -118, 8, 110], -1, 0, "ground", Color.WHITE],
	]:
		var m := MeshInstance3D.new()
		m.name = p[0]
		var r: Array = p[1]
		m.mesh = _box_mesh(Vector3(r[2], p[3] - p[2], r[3]), _mat(p[4], p[5]))
		m.position = Vector3(r[0] + r[2] / 2.0 - 40.0, (p[2] + p[3]) / 2.0, r[1] + r[3] / 2.0 - 40.0)
		_add(bd, m)


## The plain round the fences rolls into hills further out; the quarry pit (x > 62, y > 30) is 14 m deep and
## climbs out in benches on its far sides; the road north is kept level.
func _ground_h(x: float, y: float) -> float:
	var n := _noise.get_noise_2d(x, y)
	var d := maxf(maxf(4.0 - x, x - 76.0), maxf(maxf(4.0 - y, y - 76.0), 0.0))
	var h := -0.1 + smoothstep(20.0, 90.0, d) * (8.0 + 7.0 * n) + n * 0.4 * smoothstep(5.0, 15.0, d)
	h += smoothstep(90.0, 150.0, d) * 22.0 * (n + 1.0)  # far ridges on the skyline
	if y < 4.0:
		h = lerpf(-0.1, h, smoothstep(5.0, 12.0, absf(x - 40.0)))
	if x >= 62.0 and y >= 30.0:
		var out := maxf(maxf(x - 110.0, y - 100.0), 0.0)  # metres past the pit floor's edge
		if out < 24.0:
			var k := floorf(out / 6.0)
			return -14.0 + 3.5 * (k + smoothstep(4.0, 6.0, out - 6.0 * k))
	return h


var _noise := FastNoiseLite.new()


func _surroundings() -> void:
	_noise.seed = 3
	_noise.frequency = 0.025
	var bd: Node3D = _root.get_node("Backdrop")
	var g := _group(bd, "Surroundings")
	g.owner = _root
	_heightfield(g, "Plain", GROUND_RECT, 4.0, _ground_h, GROUND_HOLES, "terrain", TERRAIN, "res://areas/research_annex/plain.res")
	_dress(bd, BACKDROP_DRESS.map(func(it: Array) -> Array:
		var at: Array = [it[1][0], it[1][1], _ground_h(it[1][0], it[1][1])]
		return [it[0], at] + it.slice(2)), false)
	for w in WOODS:
		_scatter(g, w[0].to_pascal_case() + "Woods", w[0], w[1], w[2], _ground_h, w[3], w[4], w[5], WOODS_CLEAR, 1.0)
	# rocks: no clearance, their own skins, casting shadows
	_scatter(g, "PitRocks", "boulder_b", [[64, 32, 44, 66]], 22, -14.0, 1.0, 2.5, 55, [], 0, SKINS.boulder_b, true)
	_scatter(g, "RimRocks", "boulder_a", [[-20, -20, 120, 18], [-20, 80, 80, 14]], 18, _ground_h, 0.8, 2.0, 56, WOODS_CLEAR, 0, SKINS.boulder_a, true)
	_power_line(g, "pylon", PYLONS.map(func(p: Array) -> Array: return [p[0], p[1], _ground_h(p[0], p[1]) - 0.2]))
	_power_line(g, "utility_pole", ROAD_POLES.map(func(p: Array) -> Array: return [p[0], p[1], _ground_h(p[0], p[1])]))
