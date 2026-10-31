## Where things are in an Area, for a Mission's log and tutorial: the builders' diagram metres, the Encounter a position
## is in, and the exit marker nearest it. Static; MissionRun asks.
class_name MissionPlaces
extends RefCounted

const DIAGRAM_ORIGIN := 40.0  # tools/area_builder.gd _p: the log writes places in the builders' metres
const EXIT_NEAR := 5.0  # metres from an encounter_exit marker that name the way the Operative left


## The encounter_exit marker within EXIT_NEAR of pos (its name: Gangway, SternDrop), or "".
static func exit_near(tree: SceneTree, pos: Vector3) -> String:
	for m: Node3D in tree.get_nodes_in_group("encounter_exit"):
		if m.global_position.distance_to(pos) <= EXIT_NEAR:
			return m.name
	return ""


## The Encounter (its id) whose $Encounters marker rect holds pos, or 0. Areas without them have none.
static func encounter_at(tree: SceneTree, pos: Vector3) -> int:
	for m: Marker3D in tree.get_nodes_in_group("encounter"):
		var size: Vector2 = m.get_meta("size")
		var d := pos - m.global_position
		if d.x >= 0.0 and d.z >= 0.0 and d.x <= size.x and d.z <= size.y:
			return m.get_meta("id")
	return 0


## A world position as the Area builders write it: [x, y, h] in diagram metres.
static func diagram(p: Vector3) -> Vector3:
	return Vector3(p.x + DIAGRAM_ORIGIN, p.z + DIAGRAM_ORIGIN, p.y)


## The same seen from above: diagram x and y (a Dossier mark).
static func diagram_xy(p: Vector3) -> Vector2:
	return Vector2(p.x + DIAGRAM_ORIGIN, p.z + DIAGRAM_ORIGIN)


static func where(p: Vector3) -> String:
	var d := diagram(p)
	return "(%d, %d, %d)" % [d.x, d.y, d.z]


static func flat(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
