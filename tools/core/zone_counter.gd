## Countermeasure spots: the Harbour's, with the freighter's three moved to where the Core is crossed.
## Order matters (harbour.gd): the first extra is Stealth L2's patrol, the rest are Combat L2's guards.
extends "res://tools/core/zone.gd"

const D := {
	extra_posts = [
		["PostExtra1", [30, 44, 0], 0, {role = "patroller"}, [[33, 40, {hold = 3.0, f = 0}], [33, 57.5, {hold = 3.0, f = 0}]]],
		["PostExtra2", [15.5, 31, 0], 90, {hold = 5.0, role = "interceptor"}, []],
		["PostExtra3", [49, 59, 0], 0, {hold = 5.0, role = "gatekeeper"}, []],  # the mid lane's south end, in view from the pier
	],
	sentries = [["SentryCrane", [56, 19.5, 8], 230, {scan = 90.0}], ["SentryWarehouseA", [23.5, 50, 5], 90, {scan = 90.0}]],
	cameras = [
		["CamPier", [56.6, 69.4, 3], 0, 0.0],  # a pole at the pier mouth, up the quay
		["CamLanes", [53.5, 25, 3], 194, 0.0], ["CamOps", [22, 42.05, 3.6], 150], ["CamAlley", [25.95, 29, 5], 200],
	],
}
