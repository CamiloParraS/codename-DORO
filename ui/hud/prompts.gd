## Key prompts read from the InputMap, so every screen names the real binding: "[E] CARRY", "HOLD [G] FULTON".
## Keyboard and mouse only. Node-free.
class_name Prompts
extends RefCounted

const MOUSE := {
	MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_WHEEL_UP: "WHEEL", MOUSE_BUTTON_WHEEL_DOWN: "WHEEL",
}
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


## "[E] CARRY": the key, then the translated verb.
static func verb(action: String, label_key: String) -> String:
	return "[%s] %s" % [key(action), TranslationServer.translate(label_key)]


## "HOLD [G] FULTON".
static func hold(action: String, label_key: String) -> String:
	return "%s %s" % [TranslationServer.translate("ui.prompt.hold"), verb(action, label_key)]
