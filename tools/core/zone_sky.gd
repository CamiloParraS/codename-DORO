## The surface's mood: red alarm lamps on the roofs, the crane and the north shore's sheds, and the Harbour's
## Clifftop slab (x -60..-2, h -3..14), which holds the Core's corridor, plant room and room, so it is rebuilt in
## pieces clear of them (x -34..-2, y 22..42, up to ROOM_H + 0.3) and kept above them (the user, playtest 4: a dark
## face of it showed above the lift door). Pieces: [rect, h0, h1].
extends "res://tools/core/zone.gd"

const D := {
	beacons = [
		[[18.5, 21, 5.0], ALARM, 8.0, 4.3], [[12, 32, 7.2], ALARM, 8.0, 6.5], [[42, 10, 5.0], ALARM, 8.0, 4.3],
		[[15, 56, 6.0], ALARM, 8.0, 5.3], [[28, 30, 6.7], ALARM, 8.0, 6.0], [[56, 20, 8.6], ALARM, 8.0, 8.0],
		[[11, -24, 12.2], ALARM, 10.0, 11.5], [[50, -34, 13.1], ALARM, 10.0, 12.4],
	],
	clifftop = [[[-60, -100, 26, 280], -3, 14], [[-34, -100, 32, 122], -3, 14], [[-34, 42, 32, 138], -3, 14], [[-34, 22, 32, 20], 7.8, 14]],
}
