class_name InventoryAPI
extends Node
## Gifts and outfits ownership + equipped state.

signal inventory_changed

var gift_counts: Dictionary = {}
var owned_outfits: Array[StringName] = []
var equipped_outfit: StringName = &"casual"
var last_outfit: StringName = &""
var gift_cap: int = 12
var carried_item: StringName = &""


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	gift_counts = {}
	owned_outfits = [&"casual"]
	equipped_outfit = &"casual"
	last_outfit = &""
	gift_cap = 12
	carried_item = &""
	inventory_changed.emit()


func total_gifts() -> int:
	var t := 0
	for v in gift_counts.values():
		t += int(v)
	return t


func gift_count(id: StringName) -> int:
	return int(gift_counts.get(str(id), 0))


func can_buy_gift(id: StringName) -> bool:
	var g := ContentDB.gift(id)
	if g.is_empty():
		return false
	if total_gifts() >= gift_cap:
		return false
	return Game.economy.get_value(&"money") >= float(g.get("price", 0)) * Game.upgrades.gift_price_mult()


func buy_gift(id: StringName) -> bool:
	var g := ContentDB.gift(id)
	if g.is_empty():
		return false
	var price: float = float(g.get("price", 0)) * Game.upgrades.gift_price_mult()
	if not Game.economy.try_spend({"money": price}, &"buy_gift"):
		EventBus.toast("Недостаточно денег", &"warn")
		return false
	if total_gifts() >= gift_cap:
		Game.economy.add(&"money", price, &"refund")
		EventBus.toast("Склад полон", &"warn")
		return false
	_add_gift(id, 1)
	EventBus.toast("Куплено: %s" % str(g.get("name", id)), &"item")
	return true


func _add_gift(id: StringName, amount: int) -> void:
	gift_counts[str(id)] = gift_count(id) + amount
	inventory_changed.emit()


func take_gift(id: StringName) -> bool:
	if gift_count(id) <= 0:
		return false
	if carried_item != &"":
		EventBus.toast("Уже несёшь предмет", &"warn")
		return false
	gift_counts[str(id)] = gift_count(id) - 1
	if gift_count(id) <= 0:
		gift_counts.erase(str(id))
	carried_item = id
	EventBus.carry_changed.emit(carried_item)
	inventory_changed.emit()
	return true


func consume_carried() -> StringName:
	var id := carried_item
	carried_item = &""
	EventBus.carry_changed.emit(carried_item)
	return id


func place_carried_as_stock() -> bool:
	if carried_item == &"":
		return false
	_add_gift(carried_item, 1)
	carried_item = &""
	EventBus.carry_changed.emit(carried_item)
	return true


func own_outfit(id: StringName) -> bool:
	return owned_outfits.has(id)


func buy_outfit(id: StringName) -> bool:
	var o := ContentDB.outfit(id)
	if o.is_empty() or own_outfit(id):
		return false
	var price := float(o.get("price", 0))
	if price > 0.0 and not Game.economy.try_spend({"money": price}, &"buy_outfit"):
		EventBus.toast("Недостаточно денег", &"warn")
		return false
	owned_outfits.append(id)
	inventory_changed.emit()
	EventBus.toast("Новый образ: %s" % str(o.get("name", id)), &"item")
	return true


func equip_outfit(id: StringName) -> bool:
	if not own_outfit(id):
		return false
	last_outfit = equipped_outfit
	equipped_outfit = id
	inventory_changed.emit()
	EventBus.toast("Надето: %s" % str(ContentDB.outfit(id).get("name", id)), &"item")
	return true


func auto_pick_outfit_for(likes: Array) -> StringName:
	var best := equipped_outfit
	var best_score := -999.0
	for oid in owned_outfits:
		var o := ContentDB.outfit(oid)
		var score := float(o.get("quality", 1))
		var style := str(o.get("style", ""))
		if likes.has(style) or likes.has("fashion") and style == "fashion":
			score += 2.0
		if score > best_score:
			best_score = score
			best = oid
	equip_outfit(best)
	return best


func to_dict() -> Dictionary:
	var outfits: Array = []
	for o in owned_outfits:
		outfits.append(str(o))
	return {
		"gift_counts": gift_counts.duplicate(),
		"owned_outfits": outfits,
		"equipped_outfit": str(equipped_outfit),
		"last_outfit": str(last_outfit),
		"gift_cap": gift_cap,
		"carried_item": str(carried_item),
	}


func from_dict(data: Dictionary) -> void:
	gift_counts = data.get("gift_counts", {})
	owned_outfits.clear()
	for o in data.get("owned_outfits", ["casual"]):
		owned_outfits.append(StringName(str(o)))
	equipped_outfit = StringName(str(data.get("equipped_outfit", "casual")))
	last_outfit = StringName(str(data.get("last_outfit", "")))
	gift_cap = int(data.get("gift_cap", 12))
	carried_item = StringName(str(data.get("carried_item", "")))
	inventory_changed.emit()
