@tool
extends McpTestSuite

## Spec binding table: every verb is a named InputMap action.
const EXPECTED := {
	"move_forward": [KEY_W],
	"move_back": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"walk": [KEY_SHIFT],
	"crouch": [KEY_C, KEY_CTRL],
	"shoulder_swap": [KEY_TAB],
	"aim": [MOUSE_BUTTON_RIGHT],
	"fire": [MOUSE_BUTTON_LEFT],
	"weapon_tranq": [KEY_1],
	"weapon_rifle": [KEY_2],
	"reload": [KEY_R],
	"item_next": [MOUSE_BUTTON_WHEEL_DOWN],
	"item_prev": [MOUSE_BUTTON_WHEEL_UP],
	"item_use": [KEY_F],
	"interact": [KEY_E],
	"kill_takedown": [KEY_X],
	"knock": [KEY_V],
	"radio": [KEY_Q],
	"codec_advance": [MOUSE_BUTTON_LEFT, KEY_SPACE, KEY_ENTER],
	"pause": [KEY_ESCAPE],
	"debug_overlay": [KEY_F3],
}


func suite_name() -> String:
	return "input_map"


func _codes(action: String) -> Array:
	var codes := []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			codes.append((ev as InputEventKey).keycode)
		elif ev is InputEventMouseButton:
			codes.append((ev as InputEventMouseButton).button_index)
	return codes


func test_every_spec_action_is_bound() -> void:
	InputMap.load_from_project_settings()  # the editor's runtime InputMap starts without project actions
	for action in EXPECTED:
		assert_true(InputMap.has_action(action), "missing action %s" % action)
		if not InputMap.has_action(action):
			continue
		var got := _codes(action)
		got.sort()
		var want: Array = EXPECTED[action].duplicate()
		want.sort()
		assert_eq(got, want, "bindings of %s" % action)


func test_f8_is_unbound() -> void:
	for action in InputMap.get_actions():
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var key := ev as InputEventKey
				assert_true(key.keycode != KEY_F8 and key.physical_keycode != KEY_F8, "%s binds F8" % action)
