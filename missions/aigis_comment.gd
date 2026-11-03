## Aigis Voice's comment on a Mission just completed (ADR 0002). start() writes the Dossier fallback into
## the record's last.analysis at once, then asks the model; a reply that passes AigisVoice.parse replaces it.
## While the request is out the fallback carries pending = true (the saw page shows ANALYSING; saves drop the
## flag). The node lives under the tree root so the reply can land after the post-Mission screen is gone; if the
## record was committed to the campaign meanwhile, the slot is saved again with the new comment.
## Every request's outcome goes to LOG_PATH (the Session log is written at Extraction, before any reply lands).
class_name AigisComment
extends Node

const LOG_PATH := "user://aigis_voice_log.txt"
const LOG_MAX := 64 * 1024  # bytes: past this the log starts over

var after := {}  # the record complete_mission returned; last.analysis is written in place
var facts := {}
var _sent := 0  # ticks (ms) when the request went out


## campaign: only a campaign Mission shows the saw page and keeps the record, so only it asks the model.
static func start(run: Node, record: Dictionary, campaign: bool) -> void:
	var plan := Aigis.plan_mission(record.points, Aigis.lethality_ratio(record), record.mission)
	var said := AigisVoice.fallback(record, plan)
	said.source = "fallback"
	record.last.analysis = said
	if DisplayServer.get_name() == "headless":  # the suite and the playthroughs never call out
		return
	if not campaign or LlmClient.key() == "":
		log_line("not asked (%s): the stock comment" % ("no API key" if campaign else "not a campaign Mission"))
		return
	said.pending = true
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
	llm.failed.connect(_keep_fallback)
	_sent = Time.get_ticks_msec()
	log_line("asked %s (%s) about %s" % [GameSettings.current.get("llm_model", ""), facts.language, facts.mission])
	llm.ask(AigisVoice.prompt(facts), AigisVoice.SCHEMA)


func _on_answer(text: String) -> void:
	var said := AigisVoice.parse(text, facts)
	if said.is_empty():
		_keep_fallback("reply refused: " + text.replace("
", " ").left(400))
		return
	log_line("comment in %d ms, %s: %s" % [Time.get_ticks_msec() - _sent, said.voice, " / ".join(said.lines)])
	said.source = "llm"
	said.language = facts.language  # the Briefing shows it only in the language it was written in
	after.last.analysis = said
	if is_same(Campaign.record, after) and MissionRun.saves_on_commit(after):
		Campaign.save()  # committed before the reply landed: the slot gets the comment too
	queue_free()


func _keep_fallback(why: String) -> void:
	log_line("fallback after %d ms (%s)" % [Time.get_ticks_msec() - _sent, why])
	after.last.analysis.erase("pending")
	queue_free()


## One timestamped line appended to `path` (LOG_PATH), started over once it passes LOG_MAX.
static func log_line(text: String, path := LOG_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else null
	if f == null or f.get_length() > LOG_MAX:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line("%s  %s" % [Time.get_datetime_string_from_system(false, true), text])
