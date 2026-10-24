## The campaign: every Mission as data, by Mission index (0-2 = Missions 1-3, 3 = Core; the index sets
## the cap and budget), and the campaign record played through in memory (the saves ticket writes it).
class_name Campaign
extends RefCounted

const HARBOUR := "res://areas/harbour/harbour.tscn"
const RELAY_STATION := "res://areas/relay_station/relay_station.tscn"
const RESEARCH_ANNEX := "res://areas/research_annex/research_annex.tscn"
const CORE := "res://areas/core/core.tscn"

## title; area: the Area scene; targets: Target names (each is killed or carried to Extraction); steps, in order:
## {intel: the node in group "intel" whose `reached` completes it (a pickup, a console, an objective watch),
## objective: what the pause screen shows, call: the live Codec call it triggers, hint: Metis's two Hints, a
## direction then the route}. open: the live call that states step 1 as the Mission starts. codec: the full-screen
## Codec call before the Mission. A call is [[speaker, key], ...].
const MISSIONS := [
	{title = "MISSION 1: HARBOUR", area = HARBOUR, targets = [],
		open = [["analyst", "live.m1.open.01"]],
		codec = [["handler", "codec.m1.01"], ["operative", "codec.m1.02"], ["analyst", "codec.m1.03"], ["analyst", "codec.m1.04"], ["handler", "codec.m1.05"]], steps = [
		{intel = "IntelSmokeBreak", objective = "objective.m1.s1", call = [["analyst", "live.m1.s1.01"]], hint = ["hint.m1.s1.1", "hint.m1.s1.2"]},
		{intel = "IntelForeman", objective = "objective.m1.s2", call = [["analyst", "live.m1.s2.01"]], hint = ["hint.m1.s2.1", "hint.m1.s2.2"]},
		{intel = "IntelLiftPanel", objective = "objective.m1.s3", call = [["analyst", "live.m1.s3.01"]], hint = ["hint.m1.s3.1", "hint.m1.s3.2"]},
	]},
	{title = "MISSION 2: RADIO RELAY STATION", area = RELAY_STATION, targets = ["RELAY CHIEF"],
		open = [["analyst", "live.m2.open.01"]],
		codec = [["handler", "codec.m2.01"], ["operative", "codec.m2.02"], ["analyst", "codec.m2.03"], ["handler", "codec.m2.04"]], steps = [
		{intel = "IntelGarage", objective = "objective.m2.s1", call = [["analyst", "live.m2.s1.01"]], hint = ["hint.m2.s1.1", "hint.m2.s1.2"]},
		{intel = "RelayConsole", objective = "objective.m2.s2", call = [["handler", "live.m2.s2.01"], ["analyst", "live.m2.s2.02"]], hint = ["hint.m2.s2.1", "hint.m2.s2.2"]},
		{intel = "IntelMess", objective = "objective.m2.s3", call = [["analyst", "live.m2.s3.01"]], hint = ["hint.m2.s3.1", "hint.m2.s3.2"]},
	]},
	{title = "MISSION 3: RESEARCH ANNEX", area = RESEARCH_ANNEX, targets = ["LEAD RESEARCHER"],
		open = [["analyst", "live.m3.open.01"]],
		codec = [["handler", "codec.m3.01"], ["operative", "codec.m3.02"], ["analyst", "codec.m3.03"], ["analyst", "codec.m3.04"]], steps = [
		{intel = "IntelOffice", objective = "objective.m3.s1", call = [["analyst", "live.m3.s1.01"]], hint = ["hint.m3.s1.1", "hint.m3.s1.2"]},
		{intel = "IntelVault", objective = "objective.m3.s2", call = [["analyst", "live.m3.s2.01"]], hint = ["hint.m3.s2.1", "hint.m3.s2.2"]},
		{intel = "ResearchFiles", objective = "objective.m3.s3", call = [["analyst", "live.m3.s3.01"], ["analyst", "live.m3.s3.02"]], hint = ["hint.m3.s3.1", "hint.m3.s3.2"]},
	]},
	{title = "CORE", area = CORE, targets = ["SECURITY DIRECTOR"],
		open = [["analyst", "live.m4.open.01"]],
		codec = [["handler", "codec.m4.01"], ["operative", "codec.m4.02"], ["analyst", "codec.m4.03"], ["analyst", "codec.m4.04"]], steps = [
		{intel = "IntelOps", objective = "objective.m4.s1", call = [["analyst", "live.m4.s1.01"]], hint = ["hint.m4.s1.1", "hint.m4.s1.2"]},
		{intel = "IntelLift", objective = "objective.m4.s2", call = [["handler", "live.m4.s2.01"]], hint = ["hint.m4.s2.1", "hint.m4.s2.2"]},
	]},
]

## The campaign being played. Only a committed post-Mission screen moves it on (MissionRun).
static var record := Aigis.new_record()
## The save slot (0-2) the campaign autosaves to; -1 = none.
static var slot := -1


## New game.
static func start() -> void:
	record = Aigis.new_record()
	slot = -1


## Past the Core.
static func done() -> bool:
	return record.mission >= MISSIONS.size()


## What to do now in Mission mission_index with step steps done: the step's objective, then extract.
static func objective(mission_index: int, step: int) -> String:
	var steps: Array = MISSIONS[mission_index].steps
	return TranslationServer.translate(steps[step].objective) if step < steps.size() else TranslationServer.translate("objective.extract")


## Start the Mission record.mission names in its Area. Committing its post-Mission screen goes to
## return_to, and moves Campaign.record on only when campaign is set (Free mode passes its own record).
static func play(tree: SceneTree, mission_record: Dictionary, return_to: String, campaign := false) -> void:
	var area: Node = load(MISSIONS[mission_record.mission].area).instantiate()
	var run: MissionRun = area.get_node("MissionRun")
	run.record = mission_record
	run.return_to = return_to
	run.campaign = campaign
	tree.change_scene_to_node(area)
