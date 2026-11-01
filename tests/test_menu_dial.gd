@tool
extends McpTestSuite

## The main menu's dial: whole on the title; dimmed with the menu open, and faintest on the side under the list.
## Node-free.


func suite_name() -> String:
	return "menu_dial"


func test_the_title_shows_the_whole_dial() -> void:
	for a in [0.0, PI / 2, PI, -PI / 2]:
		assert_eq(MenuDial.fade(a, 0.0), 1.0, "at %.2f" % a)


func test_the_open_menu_dims_the_dial_and_most_under_the_list() -> void:
	var right := MenuDial.fade(0.0, 1.0)  # pointing at the list
	var left := MenuDial.fade(PI, 1.0)
	assert_true(left < 1.0, "the whole dial dims")
	assert_true(right < left, "the side under the list recedes further")
	assert_true(absf(right - MenuDial.OPEN_DIM * MenuDial.OPEN_EDGE) < 0.001)


func test_the_dial_is_softer_than_the_old_band() -> void:
	assert_true(MenuDial.STRENGTH < 0.34, "under the first dial's strength")
	assert_true(MenuDial.BAND_W < 44.0)
