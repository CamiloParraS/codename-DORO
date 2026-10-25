## Builds areas/research_annex/research_annex.tscn, the Main block greybox, from the Research annex
## diagram's variant A data (.scratch/area-redesign/issues/09-research-annex-diagram.md), bakes its navmesh
## and prints how far the navmesh reaches. Until the layout settles this file is the Research annex's
## source: change the data here and rebuild, don't hand-edit the scene.
##   godot --headless --path . --script tools/build_research_annex.gd
## Data is in diagram metres (tools/area_builder.gd). Guard positions are provisional until Countermeasure
## tuning (.scratch/area-redesign/issues/10-countermeasure-tuning.md).
extends "res://tools/area_builder.gd"

const OUT := "res://areas/research_annex/research_annex.tscn"
const FENCE := Color(0.7, 0.72, 0.75)
const RAIL := Color(0.8, 0.3, 0.25)

## Walkable ground, solid from -1 up to its top h: [rect, material, h, tint]. The quarry pit takes the
## south-east corner (x 62-76, y 30-76); the road runs out of the north gate to a barrier.
const LAND := [
	[[4, 4, 72, 26], "ground", 0, Color.WHITE],    # the north strip
	[[4, 30, 58, 46], "ground", 0, Color.WHITE],   # the lab plot, the yard and the dock
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
	["Container1", [14, 58, 3, 8], 0, 2.6, "metal", Color(0.75, 0.3, 0.25)],
	["Container2", [44, 56, 8, 3], 0, 2.6, "metal", Color(0.3, 0.5, 0.8)],
	["Truck", [28, 16, 7, 3], 0, 3, "metal", Color(0.45, 0.5, 0.4)],
	["DockCrate1", [58, 36, 3, 4], 0, 2.6, "metal", Color(0.6, 0.55, 0.4)],
	["DockCrate2", [57, 48, 3, 6], 0, 2.6, "metal", Color(0.6, 0.55, 0.4)],
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
## The lab's interior walls, 0.4 m thick and 3.6 m high, with 2 m doorway gaps: [name, "H" (runs east) or
## "V" (runs south), centre line, from, to, gaps [[from, to]]]. A wall cut by gaps is numbered from 1.
const WALLS := [
	["WallCorrN", "H", 42, 6, 54, [[12, 14], [24, 26], [36, 38], [48, 50]]],  # N1, office, lab, vault
	["WallCorrS", "H", 45, 6, 54, [[10, 12], [30, 32], [44, 46]]],            # lobby, Archive, loading hall
	["WallN1Office", "V", 18, 32, 41.8, []],
	["WallOfficeLab", "V", 30, 32, 41.8, []],
	["WallLabVault", "V", 42, 32, 41.8, []],
	["WallLobbyArchive", "V", 24, 45.2, 54, []],
	["WallArchiveHall", "V", 40, 45.2, 54, []],
]
const WALL_T := 0.4
const WALL_H := 3.6
## Sentry towers: raised walkable slabs on a central leg: [name, rect, top h, material].
const DECKS := [["GateTower", [30, 5, 6, 6], 5, "metal"], ["YardTower", [40, 70, 6, 6], 5, "metal"]]
## Low cover: [rect, h0].
const LOW := [
	[[20, 60, 6, 1.2], 0], [[48, 70, 4, 1.2], 0], [[8, 20, 6, 1.2], 0], [[44, 22, 6, 1.2], 0],
	[[26, 52, 6, 1.2], 0], [[20, 34, 5, 1.2], 0], [[8, 48, 1.2, 3], 0],
]
## Enterable buildings: [name, rect, height, doors [[side, centre]], tint, base]. The lab's six doors:
## lobby and Archive back door (S), office and lab (N), corridor end and loading hall (E).
const BUILDINGS := [
	["Lab", [6, 32, 48, 22], 4.0, [["S", 14.0], ["S", 32.0], ["N", 24.0], ["N", 38.0], ["E", 43.0], ["E", 50.0]],
		Color(0.85, 0.85, 0.8), 0.0],
]
## No Fulton under a roof: [name, rect, h0, h1]: the lab and under the pump house.
const ROOMS := [["Lab", [6, 32, 48, 22], 0, 4], ["PumpCrawl", [28, 56, 8, 10], 0, 3.5]]
## The stilted pump house: a 10 m Crawlspace under it, from the yard north to the Archive's back door.
const CRAWLSPACES := [
	{name = "PumpCrawl", rect = [28, 56, 8, 10], h = 3.5, mat = "wood", tint = Color(0.8, 0.7, 0.55), axis_x = 32.0},
]
## Wedges up to the towers: {name, rect, h0, h1, up: the high side}. 8 m long (the diagram's 3 m is too
## steep to walk); the gate stair turns west to clear the truck.
const RAMPS := [
	{name = "GateStair", rect = [22, 7.5, 8, 3], h0 = 0.0, h1 = 5.0, up = "E", mat = "metal", tint = Color(0.6, 0.6, 0.6)},
	{name = "YardStair", rect = [32, 71, 8, 3], h0 = 0.0, h1 = 5.0, up = "E", mat = "metal", tint = Color(0.6, 0.6, 0.6)},
]

## Guard posts: [name, [x, y, h], facing, meta, route [[x, y, meta]]]. Meta: hold / scan / chat.
## 9 posts, 10 guards as spawned (A4 is the chatting pair), plus the researcher's escort.
const GUARD_POSTS := [
	["PostA1", [16, 67.5, 0], 0, {}, [[44, 67.5, {hold = 4.0, f = 0}]]],                 # south yard walk
	["PostA2", [10, 50, 0], 90, {scan = 60.0}, []],                                      # lobby
	["PostA3", [8, 43.5, 0], 90, {}, [[11, 43.5, {hold = 5.0, f = 180}], [52, 43.5, {hold = 4.0, f = 270}]]],  # corridor, end to end; looks into the lobby through its doorway (Spoof spot: the lobby guard is witnessed)
	["PostA4", [20, 58.5, 0], 0, {chat = true}, []],                                     # the pair by the container: eavesdrop spot
	["PostA5", [14, 14, 0], 90, {}, [[56, 14, {hold = 4.0, f = 180}], [56, 24, {}]]],    # north strip loop
	["PostA6", [40, 8, 0], 180, {scan = 60.0}, []],                                      # north gate
	["PostA7", [12, 36, 0], 180, {scan = 60.0}, []],                                     # N1, facing its doorway
	["PostA8", [37, 47, 0], 0, {scan = 60.0}, []],                                       # Archive desk, back to the files
	["PostA9", [58, 66, 0], 340, {scan = 60.0}, []],                                     # dock south, by the crate
]
const EXTRA_POSTS := [
	["PostExtra1", [38, 68, 0], 270, {}, [[32, 68.5, {hold = 3.0, f = 0}], [44, 70, {}]]],  # Stealth L2: the crawl's south mouth
	["PostExtra2", [56, 40, 0], 270, {hold = 5.0}, []],   # Combat L2: the dock
	["PostExtra3", [12.5, 57, 0], 0, {hold = 5.0}, []],   # Combat L2: the front of the lab
]
const TARGET_POSTS := [  # the lead researcher: the lab, then the office, by the corridor
	["TargetPost1", [36, 36, 0], 90, {hold = 6.0}, [[24, 36, {hold = 6.0, f = 270}]]],
]
const SENTRIES := [
	["SentryGate", [33, 8, 5], 180, {scan = 90.0}],
	["SentryYard", [43, 73, 5], 320, {scan = 90.0}],
]
## Camera mounts: [name, [x, y, h], facing, pole base h]. Without a pole base the mount is on the lab's
## wall, facing away from it; the dock's stands on a pole, facing both east doors.
const CAMERAS := [
	["CamFront", [9, 54.05, 3.5], 125], ["CamArchiveBack", [37, 54.05, 3.5], 235],
	["CamNorthDoor", [44, 31.95, 3.5], 315], ["CamDock", [58, 43, 4], 270, 0.0],
]
const SPOTS := {
	OperativeStart = [8, 72, 0], RoadEntry = [40, 2, 0], Extraction = [70, 10, 0],
	ResupplyCrate = [55, 64, 1], SafeRoom = [48, 36, 0], ResearchFiles = [27, 50, 0],
}
const INTEL := {IntelOffice = [24, 37], IntelVault = [48, 37]}  # the files in the Archive are the last step
const START_FACING := 45
## Set dressing (tools/area_builder.gd _dress): [model, [x, y, h], facing, scale]. Kept off guard routes,
## doorways, the Crawlspace mouths and stair feet.
const DRESS := [
	# corridor and room lights (the roof's underside is at 4)
	["ceiling_lamp", [15, 43.5, 3.8], 0], ["ceiling_lamp", [30, 43.5, 3.8], 0], ["ceiling_lamp", [45, 43.5, 3.8], 0],
	["ceiling_lamp", [12, 37, 3.8], 0], ["ceiling_lamp", [24, 37, 3.8], 0], ["ceiling_lamp", [36, 37, 3.8], 0],
	["ceiling_lamp", [48, 37, 3.8], 0], ["ceiling_lamp", [15, 49.5, 3.8], 0], ["ceiling_lamp", [32, 49.5, 3.8], 0],
	["ceiling_lamp", [47, 49.5, 3.8], 0],
	# N1: lockers and racking on the west wall
	["locker", [6.6, 39.5, 0], 90], ["shelf", [6.5, 35, 0], 90], ["shelf", [6.5, 35.8, 0], 90],
	# office
	["table", [27, 38, 0], 0], ["monitor", [26.7, 38, 0.96], 0], ["pc", [27.6, 38, 0.96], 0],
	["chair", [27, 39.2, 0], 180], ["cabinet_b", [28.5, 32.6, 0], 180],
	# lab: benches along both side walls
	["table", [31.2, 37, 0], 90], ["monitoring_screen", [31.1, 36.6, 0.96], 270],
	["table", [40.8, 37, 0], 90], ["monitor", [40.9, 37.3, 0.96], 90], ["pc", [40.9, 36.4, 0.96], 90],
	# vault
	["cabinet_b", [44, 32.6, 0], 180], ["cabinet_b", [45.3, 32.6, 0], 180], ["cardboard_box", [52.5, 40.5, 0], 20],
	# lobby
	["vending_machine", [23.3, 52, 0], 270], ["chair", [6.5, 47, 0], 90], ["chair", [6.5, 48, 0], 90],
	# Archive: racking on the south and west walls
	["shelf", [34.5, 53.4, 0], 180], ["shelf", [35.3, 53.4, 0], 180], ["shelf", [36.1, 53.4, 0], 180],
	["shelf", [36.9, 53.4, 0], 180], ["shelf", [37.7, 53.4, 0], 180],
	["shelf", [24.6, 47.5, 0], 90], ["shelf", [24.6, 48.3, 0], 90],
	# loading hall
	["pallet_stack", [51.5, 52.5, 0], 0], ["crate_wide", [42.5, 52.8, 0], 0], ["cardboard_box", [44.5, 53.1, 0], 30],
	["cabinet_a", [53.4, 46.5, 0], 270],
	# outside: floodlights at the gate and over the Extraction point
	["lamp_post", [74, 12, 0], 270], ["lamp_post", [45.5, 5, 0], 180], ["lamp_post", [4.6, 66, 0], 90],
	["barrel_a", [36.5, 17.5, 0], 0], ["barrel_b", [37.3, 18.1, 0], 0], ["tank_tall", [73.5, 27, 0], 0],
	["cone", [37, 1, 0], 0], ["cone", [43, 1, 0], 0],
	# yard and dock
	["pallet_stack", [5.5, 60, 0], 90], ["generator", [24, 74.5, 0], 0], ["jerrycan", [26.3, 74.6, 0], 30],
	["drum", [60.5, 70, 0], 0], ["drum", [61, 70.8, 0], 40], ["pallet", [56, 73, 0], 0],
]
## Out on the plain past the north fence, into the fog.
const BACKDROP_DRESS := [
	["chimney", [20, -25, 0], 0, 2.0], ["tank_tall", [64, -20, 0], 0, 2.5], ["shed", [-15, 30, 0], 90, 1.5],
]
## The diagram's three, plus the Dock its deception Approaches send guards to.
const SPOOFS := {SpoofYard = [26, 70, 0], SpoofNorth = [12, 24, 0], SpoofQuarry = [60, 20, 0], SpoofDock = [59, 58, 0]}

## What the navmesh must reach from the start: every room, every doorway, both tower tops and every objective.
const REACH := {
	CorridorW = [8, 43.5, 0], CorridorE = [52, 43.5, 0], N1 = [12, 36, 0], Office = [24, 36, 0], Lab = [36, 36, 0],
	Vault = [48, 36, 0], Lobby = [10, 50, 0], Archive = [27, 50, 0], LoadingHall = [47, 50, 0],
	DoorN1 = [13, 42, 0], DoorOffice = [25, 42, 0], DoorLab = [37, 42, 0], DoorVault = [49, 42, 0],
	DoorLobby = [11, 45, 0], DoorArchive = [31, 45, 0], DoorHall = [45, 45, 0],
	FrontDoor = [14, 53.85, 0], ArchiveBackDoor = [32, 53.85, 0], OfficeNorthDoor = [24, 32.15, 0],
	LabNorthDoor = [38, 32.15, 0], CorridorEastDoor = [53.85, 43, 0], HallEastDoor = [53.85, 50, 0],
	NorthStrip = [20, 24, 0], WestLane = [5, 43, 0], Dock = [58, 58, 0], Yard = [20, 70, 0],
	GateTowerTop = [35, 6, 5], YardTowerTop = [45, 75, 5], Extraction = [70, 10, 0], RoadEntry = [40, 2, 0],
}
## The two carry routes, researcher to Extraction, as waypoints the shortest path is forced through.
const CARRY := {
	"North door, open strip" = [[36, 36, 0], [38, 30.6, 0], [52, 26, 0], [70, 10, 0]],
	"Corridor and dock" = [[36, 36, 0], [37, 43.5, 0], [53, 43.5, 0], [57, 40, 0], [58, 26, 0], [70, 10, 0]],
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
	_dress(_root.get_node("Backdrop"), BACKDROP_DRESS)
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
	_intel({IntelOffice = INTEL.IntelOffice, IntelVault = INTEL.IntelVault, ResearchFiles = SPOTS.ResearchFiles})
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


## The plain outside the fence and the quarry pit, 14 m deep, open to the south and east. No collision:
## the fences, the rim and tower rails and the road barrier close every edge, so no kill volume is needed.
## ponytail: the rest of the Backdrop kit (distant blocks, skyline, fog) is its own build.
func _backdrop() -> void:
	var bd := _group(_root, "Backdrop")
	bd.add_to_group("backdrop", true)
	for p in [
		["PlainW", [-160, -160, 222, 400], -0.2, -0.1, "ground", Color(0.8, 0.8, 0.75)],
		["PlainN", [62, -160, 178, 190], -0.2, -0.1, "ground", Color(0.8, 0.8, 0.75)],
		["PitWallW", [61, 30, 1, 210], -14, -0.1, "stone", Color(0.65, 0.6, 0.55)],
		["PitWallN", [62, 29, 178, 1], -14, -0.1, "stone", Color(0.65, 0.6, 0.55)],
		["PitFloor", [62, 30, 178, 210], -14.2, -14, "stone", Color(0.5, 0.48, 0.45)],
	]:
		var m := MeshInstance3D.new()
		m.name = p[0]
		var r: Array = p[1]
		m.mesh = _box_mesh(Vector3(r[2], p[3] - p[2], r[3]), _mat(p[4], p[5]))
		m.position = Vector3(r[0] + r[2] / 2.0 - 40.0, (p[2] + p[3]) / 2.0, r[1] + r[3] / 2.0 - 40.0)
		_add(bd, m)
