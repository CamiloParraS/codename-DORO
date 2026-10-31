## Encounter 3, the Core room (manipulation): 20 x 20 x 7.5 m, one floor door off the corridor (y 31-33, up to 4 m)
## and a high door (y 22.3-25.3, h 3.5-6.1: at 2.2 m high the navmesh shut it) onto the plant room's mezzanine. A
## gallery 3 m deep runs along the north wall (at 2.2 the navmesh dropped it) with a 1 m parapet that hides a crouched
## Operative and a gap at x -20.6 to -19.4 to drop through (3.5 m, no fall damage), onto crates 1.2 m high: the
## Operative lands behind them unseen and goes round either end. One guard (Core1, his back to the crates), the
## director pacing beside the terminal and his escort: one net by design. The terminal is the Extraction point.
extends "res://tools/core/zone.gd"

const D := {
	start = [-15, 32, 0],
	land = [[-34, 22, 20, 20]],
	solid = [
		["ConsoleDesk", [-33.7, 30.5, 1.2, 3], 0, 1, "metal", Color.WHITE],  # the Core terminal's desk
		["RoomN", [-34, 22, 20, 0.3], 0, ROOM_H, "brick", WALL], ["RoomS", [-34, 41.7, 20, 0.3], 0, ROOM_H, "brick", WALL],
		["RoomW", [-34, 22.3, 0.3, 19.4], 0, ROOM_H, "brick", WALL], ["RoomRoof", [-34, 22, 20, 20], ROOM_H, ROOM_H + 0.3, "metal", Color(0.6, 0.6, 0.6)],
		["RoomE1", [-14.3, 25.3, 0.3, 5.7], 0, ROOM_H, "brick", WALL], ["RoomE2", [-14.3, 33, 0.3, 9], 0, ROOM_H, "brick", WALL],
		["RoomELintel", [-14.3, 31, 0.3, 2], 4, ROOM_H, "brick", WALL],
		["RoomEGalleryLow", [-14.3, 22.3, 0.3, 3], 0, GALLERY, "brick", WALL], ["RoomEGalleryHigh", [-14.3, 22.3, 0.3, 3], GALLERY + 2.6, ROOM_H, "brick", WALL],
		["Gallery", [-34, 22.3, 19.7, 3], GALLERY - 0.2, GALLERY, "metal", Color(0.75, 0.75, 0.7)],
		["GalleryRailW", [-34, 25.1, 13.4, 0.2], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],
		["GalleryRailE", [-19.4, 25.1, 5.1, 0.2], GALLERY, GALLERY + 1, "rust", Color(0.9, 0.75, 0.3)],
		["DropCrate1", [-22.6, 27.2, 1.6, 1.3], 0, 1.2, "wood", Color(0.9, 0.8, 0.6)], ["DropCrate2", [-21, 27.4, 1.6, 1.2], 0, 1.2, "wood", Color(0.85, 0.75, 0.55)],
		["DropCrate3", [-19.4, 27.2, 1.6, 1.3], 0, 1.2, "wood", Color(0.9, 0.8, 0.6)],
	],
	rooms = [["CoreRoom", ROOM, 0, ROOM_H]],
	posts = [["PostCore1", [-20, 30, 0], 180, {scan = 90.0, role = "observer", enc = 3}, []]],  # his back to the crates under the gallery's drop
	target_posts = [["TargetPost1", [-26, 36, 0], 90, {hold = 5.0}, [[-26, 30, {hold = 5.0, f = 270}]]]],  # north stop 28 → 30 (playtest 2): from 28 he saw the drop's landing past the crates
	encounters = [[3, "Core room", "manipulation", [-34, 22, 36, 20], [-24, 32, 0], 0]],
	exits = {Gallery = [-14.5, 23.4, GALLERY]},
	dress = [
		["ceiling_lamp", [-24, 27, 7.2], 0], ["ceiling_lamp", [-24, 37, 7.2], 0], ["ceiling_lamp", [-17, 32, 7.2], 0],
		["ceiling_lamp", [-28, 23.4, 7.2], 0],  # over the gallery
		["monitoring_screen", [-33.1, 31, 1], 90], ["monitoring_screen", [-33.1, 33, 1], 90],
		["cabinet_b", [-33.5, 38, 0], 90], ["cabinet_b", [-33.5, 39.3, 0], 90], ["cabinet_a", [-33.5, 25, 0], 90],
		["pipe_riser", [-14.9, 41, 0], 270],
		# server racks down the north (under the gallery) and south walls, clear of the guards' and the director's beats
		["cabinet_b", [-28, 22.55, 0], 180], ["cabinet_b", [-26.8, 22.55, 0], 180], ["cabinet_b", [-25.6, 22.55, 0], 180],
		["cabinet_b", [-22, 22.55, 0], 180], ["cabinet_b", [-17.6, 22.55, 0], 180], ["cabinet_b", [-16.4, 22.55, 0], 180],
		["cabinet_b", [-28, 41.45, 0], 0], ["cabinet_b", [-26.8, 41.45, 0], 0], ["cabinet_b", [-25.6, 41.45, 0], 0],
		["cabinet_b", [-22, 41.45, 0], 0], ["cabinet_b", [-20.8, 41.45, 0], 0], ["cabinet_b", [-19.6, 41.45, 0], 0],
		["generator", [-16.6, 38.5, 0], 90], ["vent_unit", [-24, 41.5, 5.5], 0],
		["crate_wide", [-32.6, 40.8, 0], 90], ["cardboard_box", [-32.5, 39.6, 0], 15], ["drum", [-15.7, 25.5, 0], 0],
		["ceiling_lamp", [-14.8, 32, 3.8], 0],  # over the room's door
	],
	markings = [  # hazard paint round the terminal and along the gallery's foot
		[[-32.4, 29.8, 0.15, 4.4], 0], [[-32.4, 29.8, 2.6, 0.15], 0], [[-32.4, 34.05, 2.6, 0.15], 0], [[-29.95, 29.8, 0.15, 4.4], 0],
		[[-30, 23.8, 12, 0.12], 0], [[-30, 40.1, 12, 0.12], 0],
	],
	spots = {SafeRoom = [-30, 25, 0], Extraction = [-31, 32, 0]},  # Extraction is the terminal: the Mission ends there, not on entering the room
	areas = [  # a director left lying anywhere in the room counts as dealt with (the room was the Extraction point until playtest 2)
		["CoreRoomZone", [-24, 32, 1.5], Vector3(18, 3, 18), "res://areas/target_zone.gd"],
		["CoreEntry", [-16, 32, 1.5], Vector3(2, 3, 4), "res://areas/core/core_entry.gd"],
		["CoreTerminal", [-31.5, 32, 1.5], Vector3(3, 3, 4), "res://areas/core/core_terminal.gd"],
	],
	reach = {Gallery = [-26, 23.8, GALLERY], RoomDoor = [-15, 32, 0], Room = [-24, 32, 0], DropLanding = [-20, 26.2, 0], Director = [-26, 36, 0], DirectorRoute = [-26, 30, 0], SafeRoom = [-30, 25, 0], Terminal = [-31, 32, 0]},
}
