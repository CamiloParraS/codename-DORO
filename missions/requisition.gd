## Recruits and Requisition (pw-feel 05), node-free. A first clear pays 1 Recruit point per Fultoned guard
## (Targets none), x1.5 rounded down on an S, plus ALIVE_TARGET_BONUS for a carry_only Target carried out alive; a replay pays none. Points buy four permanent upgrades; the
## first S on Missions 1-3 unlocks that Mission's item, free, first clear or replay. kit() is what a
## first-clear Mission is played with; replays and Free mode get BASE. Saved with the slot (to_dict).
class_name Requisition
extends RefCounted

## id: {name, effect, key in the kit, base value, step per buy, buys, price}. 23 points buy all.
const UPGRADES := {
	scanner = {name = "SCANNER CELLS", effect = "SCANNER CHARGES", stat = "scanner", step = 1, buys = 2, price = 3},
	magazines = {name = "MAGAZINE POUCH", effect = "MAGAZINES", stat = "magazines", step = 2, buys = 2, price = 2},
	fultons = {name = "SPARE BALLOON", effect = "FULTON BALLOONS", stat = "fultons", step = 1, buys = 2, price = 4},
	darts = {name = "DART RESERVE", effect = "TRANQ DARTS", stat = "darts", step = 4, buys = 1, price = 5},
}
## By Mission index (the Core has none): {id, name, effect, the kit key and value it sets}.
const ITEMS := [
	{id = "long_scan", name = "LONG SCAN", effect = "SCANNER LASTS 15 S", stat = "scan_time", value = 15.0},
	{id = "heavy_suppressor", name = "HEAVY SUPPRESSOR", effect = "SUPPRESSOR LASTS 5 SHOTS", stat = "suppressor", value = 5},
	{id = "quick_hold", name = "QUICK HOLD", effect = "FULTON HOLD 2 S", stat = "fulton_time", value = 2.0},
]
const Operative := preload("res://actors/operative/operative.gd")
const BASE := {
	scanner = Items.SCANNER_CHARGES, magazines = Items.MAGAZINES, fultons = Operative.FULTONS, darts = Tranq.TOTAL,
	scan_time = Items.SCANNER_TIME, suppressor = Rifle.SUPPRESSOR_SHOTS, fulton_time = Operative.FULTON_TIME,
}
const S_BONUS := 1.5
const ALIVE_TARGET_BONUS := 2  # points for a carry_only Target carried out alive (a first clear only)

var points := 0
var bought := {}                       # upgrade id: buys made
var unlocked_items: Array[String] = []
var signed := 0                        # Recruits the last first clear paid (RECRUITS SIGNED); not saved
var due := false                       # the Requisition screen opens at the next briefing; not saved


## A post-Mission screen committed Mission k (MissionRun): banks the Recruits on a first clear, unlocks
## the item on its first S, and marks the screen due after a first clear before the Core.
func settle(k: int, fultoned: int, first_s: bool, first_clear: bool, bonus := 0) -> void:
	if first_s and k < ITEMS.size() and ITEMS[k].id not in unlocked_items:
		unlocked_items.append(ITEMS[k].id)
	if not first_clear:
		return
	signed = (int(fultoned * S_BONUS) if first_s else fultoned) + bonus
	points += signed
	due = k < ITEMS.size()


func unlocked(id: String) -> bool:
	return id in unlocked_items


func capped(id: String) -> bool:
	return bought.get(id, 0) >= UPGRADES[id].buys


func can_buy(id: String) -> bool:
	return UPGRADES.has(id) and not capped(id) and points >= UPGRADES[id].price


## Validated against the balance and the cap; the caller saves the slot.
func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	points -= UPGRADES[id].price
	bought[id] = bought.get(id, 0) + 1
	return true


## Something to buy now: the screen opens on its own only then.
func worth_opening() -> bool:
	return UPGRADES.keys().any(can_buy)


func value(id: String) -> int:
	return BASE[UPGRADES[id].stat] + UPGRADES[id].step * bought.get(id, 0)


func kit() -> Dictionary:
	var out := BASE.duplicate()
	for id: String in UPGRADES:
		out[UPGRADES[id].stat] = value(id)
	for it: Dictionary in ITEMS:
		if unlocked(it.id):
			out[it.stat] = it.value
	return out


func to_dict() -> Dictionary:
	return {points = points, bought = bought.duplicate(), items = unlocked_items.duplicate()}


## From a slot file; anything missing or malformed reads as none.
static func from_dict(d: Variant) -> Requisition:
	var r := Requisition.new()
	if not d is Dictionary:
		return r
	if d.get("points") is float:
		r.points = maxi(int(d.points), 0)
	var b: Variant = d.get("bought")
	for id: String in UPGRADES:
		if b is Dictionary and b.get(id) is float and int(b[id]) in range(1, UPGRADES[id].buys + 1):
			r.bought[id] = int(b[id])
	var known := ITEMS.map(func(it: Dictionary) -> String: return it.id)
	var items: Variant = d.get("items")
	for id: Variant in items if items is Array else []:
		if id is String and id in known and id not in r.unlocked_items:
			r.unlocked_items.append(id)
	return r
