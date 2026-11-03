## One request to a language model (ADR 0002), as a node so it can own an HTTPRequest. ask() sends a
## provider-neutral prompt ({system, user}) with a JSON Schema and emits answered(text) or failed(why), once.
## Each provider is a static body/text pair; Gemini is the only one so far.
##
## Gemini: POST .../v1beta/models/<model>:generateContent, header x-goog-api-key, the schema as
## generationConfig.responseJsonSchema; the answer is candidates[0].content.parts[].text (thought parts skipped).
## Checked on 2026-11-03: gemini-3.5-flash-lite answers in ~1.2 s; 3.1 took 8-26 s on the free tier, and
## 2.5-flash-lite is closed to new users (404).
class_name LlmClient
extends Node

signal answered(text: String)
signal failed(why: String)

const GEMINI_URL := "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
const TIMEOUT := 12.0  # s; the request runs behind the outro and the Rank page, so a slow one still lands
const KEY_ENV := "GEMINI_API_KEY"  # the developer's machine supplies the key here when Settings has none

var _http: HTTPRequest


## The key to use: Settings first, then the environment. "" when there is none.
static func key() -> String:
	var k: String = GameSettings.current.get("llm_key", "")
	return k if k != "" else OS.get_environment(KEY_ENV)


func ask(prompt: Dictionary, schema: Dictionary) -> void:
	var k := key()
	if k == "":
		failed.emit.call_deferred("no API key")
		return
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_done)
	var model: String = GameSettings.current.get("llm_model", GameSettings.DEFAULTS.llm_model)
	var err := _http.request(GEMINI_URL % model.uri_encode(), ["Content-Type: application/json", "x-goog-api-key: " + k],
		HTTPClient.METHOD_POST, JSON.stringify(gemini_body(prompt, schema)))
	if err != OK:
		failed.emit.call_deferred("request not sent (%d)" % err)


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		failed.emit("no reply (result %d)" % result)
		return
	if code != 200:
		failed.emit("HTTP %d" % code)
		return
	var text := gemini_text(body.get_string_from_utf8())
	if text == "":
		failed.emit("no answer in the reply")
	else:
		answered.emit(text)


## The generateContent body for a {system, user} prompt and a JSON Schema.
static func gemini_body(prompt: Dictionary, schema: Dictionary) -> Dictionary:
	return {
		systemInstruction = {parts = [{text = prompt.system}]},
		contents = [{role = "user", parts = [{text = prompt.user}]}],
		generationConfig = {responseMimeType = "application/json", responseJsonSchema = schema},
	}


## The answer text in a generateContent reply, or "" when it has none (an error, a block, no candidates).
static func gemini_text(reply: String) -> String:
	var json := JSON.new()
	if json.parse(reply) != OK or not json.data is Dictionary:
		return ""
	var cands: Variant = json.data.get("candidates")
	if not (cands is Array and not cands.is_empty() and cands[0] is Dictionary):
		return ""
	var parts: Variant = cands[0].get("content", {}).get("parts")
	if not parts is Array:
		return ""
	var out := ""
	for p: Variant in parts:
		if p is Dictionary and p.get("text") is String and not p.get("thought", false):
			out += p.text
	return out
