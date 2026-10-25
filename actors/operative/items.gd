## The Operative's two items, node-free: the Scanner (3 charges, shows cones for ~10 s) and the Magazine
## (4 per Mission, thrown as a knock). The wheel cycles which one F uses. The resupply crate refills both, once.
class_name Items
extends RefCounted

enum Kind { SCANNER, MAGAZINE }

const SCANNER_CHARGES := 3
const MAGAZINES := 4
const SCANNER_TIME := 10.0
const SCANNER_RANGE := 30.0  # metres: guards and cameras farther than this stay hidden
const THROW_RANGE := 15.0    # metres on level ground
const THROW_ANGLE := deg_to_rad(40.0)
const GRAVITY := 9.8

var selected := Kind.SCANNER
var max_charges := SCANNER_CHARGES  # Requisition raises these on a first clear (Operative.equip)
var max_magazines := MAGAZINES
var scan_time := SCANNER_TIME
var charges := SCANNER_CHARGES
var magazines := MAGAZINES
var scan_left := 0.0
var crate_used := false


func cycle(dir: int) -> void:
	selected = posmod(selected + dir, Kind.size()) as Kind


## On the item card: the selected item's name and what it has left.
func label() -> String:
	return "SCAN" if selected == Kind.SCANNER else "MAG"


func count() -> int:
	return charges if selected == Kind.SCANNER else magazines


func scanning() -> bool:
	return scan_left > 0.0


## Tap F on the Scanner. Spends a charge; false when it has none. Usable while carrying.
func use_scanner() -> bool:
	if charges == 0:
		return false
	charges -= 1
	scan_left = scan_time
	return true


func can_throw(carrying: bool) -> bool:
	return magazines > 0 and not carrying


## Release F on the Magazine. Spends one; false when it has none or the Operative is carrying.
func throw(carrying: bool) -> bool:
	if not can_throw(carrying):
		return false
	magazines -= 1
	return true


func tick(delta: float) -> void:
	scan_left = maxf(scan_left - delta, 0.0)


## Resupply crate: one use per Mission. Refills both items and every gun; false once spent.
## Lives here so the Checkpoint snapshot of Items carries it.
func resupply(guns: Array) -> bool:
	if crate_used:
		return false
	crate_used = true
	refill()
	for g in guns:
		g.refill()
	return true


func refill() -> void:
	charges = max_charges
	magazines = max_magazines


## Points of a thrown Magazine's flight from `from` along the flat `heading`, one every `step` seconds:
## a fixed launch angle and speed that carry THROW_RANGE on level ground.
static func arc(from: Vector3, heading: Vector3, steps: int, step := 0.1) -> PackedVector3Array:
	var flat := Vector3(heading.x, 0, heading.z).normalized()
	var speed := sqrt(THROW_RANGE * GRAVITY / sin(2 * THROW_ANGLE))
	var pts := PackedVector3Array()
	for i in steps + 1:
		var t := i * step
		pts.append(from + flat * speed * cos(THROW_ANGLE) * t + Vector3.UP * (speed * sin(THROW_ANGLE) * t - 0.5 * GRAVITY * t * t))
	return pts
