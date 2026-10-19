## The campaign: every Mission as data, by Mission index (0-2 = Missions 1-3, 3 = Core; the index sets
## the cap and budget), and the campaign record played through in memory (the saves ticket writes it).
class_name Campaign
extends RefCounted

const HARBOUR := "res://areas/harbour/harbour.tscn"
const RELAY_STATION := "res://areas/relay_station/relay_station.tscn"
const RESEARCH_ANNEX := "res://areas/research_annex/research_annex.tscn"

## title; area: the Area scene; targets: Target names (each is killed or carried to Extraction); steps, in order:
## {intel: the pickup in the Area that completes it, objective: what the pause screen shows, call: the live
## Codec call it triggers}. codec: the full-screen Codec call before the Mission. A call is [[speaker, key], ...].
## ponytail: the Core plays an intel step in the Harbour until the Core Mission lands with its own objective.
const MISSIONS := [
	{title = "MISSION 1: HARBOUR", area = HARBOUR, targets = [],
		codec = [["handler", "codec.m1.01"], ["operative", "codec.m1.02"], ["analyst", "codec.m1.03"], ["analyst", "codec.m1.04"], ["handler", "codec.m1.05"]], steps = [
		{intel = "IntelManifests", objective = "FIND THE SHIPPING MANIFESTS AT WAREHOUSE A", call = [["analyst", "live.m1.s1.01"]]},
		{intel = "IntelRadioLog", objective = "COPY THE RELAY STATION'S RADIO LOG AT THE GATEHOUSE", call = [["analyst", "live.m1.s2.01"]]},
	]},
	{title = "MISSION 2: RADIO RELAY STATION", area = RELAY_STATION, targets = ["RELAY CHIEF"],
		codec = [["handler", "codec.m2.01"], ["operative", "codec.m2.02"], ["analyst", "codec.m2.03"], ["handler", "codec.m2.04"]], steps = [
		{intel = "RelayConsole", objective = "SABOTAGE THE RELAY CONSOLE: HOLD E FOR 5 SECONDS", call = [["handler", "live.m2.s1.01"], ["analyst", "live.m2.s1.02"]]},
	]},
	{title = "MISSION 3: RESEARCH ANNEX", area = RESEARCH_ANNEX, targets = ["LEAD RESEARCHER"],
		codec = [["handler", "codec.m3.01"], ["operative", "codec.m3.02"], ["analyst", "codec.m3.03"], ["analyst", "codec.m3.04"]], steps = [
		{intel = "ResearchFiles", objective = "EXTRACT THE RESEARCH FILES THAT REVEAL THE CORE", call = [["analyst", "live.m3.s1.01"], ["analyst", "live.m3.s1.02"]]},
	]},
	{title = "CORE", area = HARBOUR, targets = ["SECURITY DIRECTOR"],
		codec = [["handler", "codec.m4.01"], ["operative", "codec.m4.02"], ["analyst", "codec.m4.03"], ["analyst", "codec.m4.04"]], steps = [
		{intel = "IntelLift", objective = "REACH THE FREIGHT LIFT", call = [["handler", "live.m4.s1.01"]]},
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
