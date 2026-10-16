## The campaign: every Mission as data, by Mission index (0-2 = Missions 1-3, 3 = Core; the index sets
## the cap and budget), and the campaign record played through in memory (the saves ticket writes it).
class_name Campaign
extends RefCounted

const HARBOUR := "res://areas/harbour/harbour.tscn"
const RELAY_STATION := "res://areas/relay_station/relay_station.tscn"

## title; area: the Area scene; targets: Target names (each is killed or carried to Extraction); steps, in order:
## {intel: the pickup in the Area that completes it, objective: what the pause screen shows}.
## ponytail: Missions 3 and the Core play intel steps in the Harbour until the Research annex
## and the Core Mission land with their own objectives.
const MISSIONS := [
	{title = "MISSION 1: HARBOUR", area = HARBOUR, targets = [], steps = [
		{intel = "IntelManifests", objective = "FIND THE SHIPPING MANIFESTS AT WAREHOUSE A"},
		{intel = "IntelRadioLog", objective = "COPY THE RELAY STATION'S RADIO LOG AT THE GATEHOUSE"},
	]},
	{title = "MISSION 2: RADIO RELAY STATION", area = RELAY_STATION, targets = ["RELAY CHIEF"], steps = [
		{intel = "RelayConsole", objective = "SABOTAGE THE RELAY CONSOLE: HOLD E FOR 5 SECONDS"},
	]},
	{title = "MISSION 3: RESEARCH ANNEX", area = HARBOUR, targets = ["LEAD RESEARCHER"], steps = [
		{intel = "IntelManifests", objective = "FIND THE RESEARCH FILES AT WAREHOUSE A"},
	]},
	{title = "CORE", area = HARBOUR, targets = ["SECURITY DIRECTOR"], steps = [
		{intel = "IntelLift", objective = "REACH THE FREIGHT LIFT"},
	]},
]

## The campaign being played. Only a committed post-Mission screen moves it on (MissionRun).
static var record := Aigis.new_record()


## New game.
static func start() -> void:
	record = Aigis.new_record()


## Past the Core.
static func done() -> bool:
	return record.mission >= MISSIONS.size()


## What to do now in Mission mission_index with step steps done: the step's objective, then extract.
static func objective(mission_index: int, step: int) -> String:
	var steps: Array = MISSIONS[mission_index].steps
	return steps[step].objective if step < steps.size() else "REACH THE EXTRACTION POINT"


## Start the Mission record.mission names in its Area. Committing its post-Mission screen goes to
## return_to, and moves Campaign.record on only when campaign is set (Free mode passes its own record).
static func play(tree: SceneTree, mission_record: Dictionary, return_to: String, campaign := false) -> void:
	var area: Node = load(MISSIONS[mission_record.mission].area).instantiate()
	var run: MissionRun = area.get_node("MissionRun")
	run.record = mission_record
	run.return_to = return_to
	run.campaign = campaign
	tree.change_scene_to_node(area)
