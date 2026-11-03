## Aigis Voice's comment on a Mission just completed (ADR 0002). start() writes the Dossier fallback into
## the record's last.analysis at once, then asks the model; a reply that passes AigisVoice.parse replaces it.
## The node lives under the tree root so the reply can land after the post-Mission screen is gone; if the
## record was committed to the campaign meanwhile, the slot is saved again with the new comment.
class_name AigisComment
extends Node

var after := {}  # the record complete_mission returned; last.analysis is written in place
var facts := {}


## campaign: only a campaign Mission shows the saw page and keeps the record, so only it asks the model.
static func start(run: Node, record: Dictionary, campaign: bool) -> void:
	var plan := Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), record.mission)
	var said := AigisVoice.fallback(record, plan)
	said.source = "fallback"
	record.last.analysis = said
	if not campaign or DisplayServer.get_name() == "headless" or LlmClient.key() == "":  # the suite and the playthroughs never call out
		return
	var c := AigisComment.new()
	c.process_mode = Node.PROCESS_MODE_ALWAYS  # the outro and the post-Mission screen pause the tree; the request must run under them
	c.after = record
	c.facts = AigisVoice.facts(record, plan)
	run.get_tree().root.add_child(c)
	c._ask()


func _ask() -> void:
	var llm := LlmClient.new()
	add_child(llm)
	llm.answered.connect(_on_answer)
	llm.failed.connect(func(why: String) -> void:
		SessionLog.current.note("aigis voice: fallback (%s)" % why)
		queue_free())
	llm.ask(AigisVoice.prompt(facts), AigisVoice.SCHEMA)


func _on_answer(text: String) -> void:
	var said := AigisVoice.parse(text, facts)
	if said.is_empty():
		SessionLog.current.note("aigis voice: fallback (reply refused)")
	else:
		said.source = "llm"
		after.last.analysis = said
		if is_same(Campaign.record, after) and MissionRun.saves_on_commit(after):
			Campaign.save()  # committed before the reply landed: the slot gets the comment too
	queue_free()
