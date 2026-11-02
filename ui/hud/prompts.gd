## Key prompts read from the InputMap, so every screen names the real binding: "[E] CARRY", "HOLD [G] FULTON".
## key() is a keycap's legend (HudPalette.keycap draws LMB, RMB, MMB, WHEEL as a mouse); word() is the same binding
## for running text, where a mouse button is spelled out ("CLICK", "RIGHT CLICK": playtest 1, "what is LMB?").
## Keyboard and mouse only. Node-free.
class_name Prompts
extends RefCounted

const MOUSE := {
	MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_WHEEL_UP: "WHEEL", MOUSE_BUTTON_WHEEL_DOWN: "WHEEL",
}
const WORDS := {LMB = "ui.mouse.left", RMB = "ui.mouse.right", MMB = "ui.mouse.middle", WHEEL = "ui.mouse.wheel"}
const KEYS := {KEY_ESCAPE: "ESC", KEY_CTRL: "CTRL", KEY_ENTER: "ENTER", KEY_SPACE: "SPACE"}


## The short name of the action's first binding: E, LMB, WHEEL, SHIFT, TAB.
static func key(action: String) -> String:
	var ev := InputMap.action_get_events(action) if InputMap.has_action(action) else []
	if ev.is_empty():
		return "?"
	if ev[0] is InputEventMouseButton:
		return MOUSE.get(ev[0].button_index, "MOUSE")
	var code: Key = ev[0].keycode if ev[0].keycode else ev[0].physical_keycode
	return KEYS.get(code, OS.get_keycode_string(code).to_upper())


## The action's first binding for running text: key(), with a mouse button spelled out (CLICK, RIGHT CLICK).
static func word(action: String) -> String:
	var k := key(action)
	return TranslationServer.translate(WORDS[k]) if WORDS.has(k) else k


## "[E] CARRY": the key, then the translated verb.
static func verb(action: String, label_key: String) -> String:
	return "[%s] %s" % [word(action), TranslationServer.translate(label_key)]


## "HOLD [G] FULTON".
static func hold(action: String, label_key: String) -> String:
	return "%s %s" % [TranslationServer.translate("ui.prompt.hold"), verb(action, label_key)]
